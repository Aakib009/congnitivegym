import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/debate_message.dart';
import '../models/debate_session.dart';
import '../models/debate_topic.dart';

/// Exception thrown when OpenRouter API calls fail.
class OpenRouterException implements Exception {
  final String message;
  final int? statusCode;

  const OpenRouterException(this.message, {this.statusCode});

  @override
  String toString() => 'OpenRouterException: $message (status: ${statusCode ?? "N/A"})';
}

/// Dedicated service responsible for OpenRouter Chat Completions API integration.
/// Isolates all network requests, authentication, error handling, and prompt construction.
class OpenRouterService {
  OpenRouterService._();

  static final OpenRouterService instance = OpenRouterService._();

  static const String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _envApiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  static const String _primaryModel = 'poolside/laguna-s-2.1:free';

  String? _runtimeApiKey;

  /// Sets an API key at runtime (e.g. from user account settings).
  void setApiKey(String? key) {
    _runtimeApiKey = key?.trim();
  }

  /// Returns active API key from runtime configuration or compile-time environment.
  String get effectiveApiKey {
    if (_runtimeApiKey != null && _runtimeApiKey!.isNotEmpty) {
      return _runtimeApiKey!;
    }
    return _envApiKey;
  }

  /// Indicates whether a valid API key has been provided.
  bool get isConfigured => effectiveApiKey.isNotEmpty;

  /// Optional mock handler for unit and widget testing.
  Future<String> Function(List<Map<String, String>> messages)? mockHandler;

  /// Builds the system prompt for the Cognitive Gym Debate Coach.
  String _buildSystemPrompt({
    required DebateTopic topic,
    required DebateSide userSide,
    required DebateSide aiSide,
    required int currentTurn,
  }) {
    final userSideLabel = userSide == DebateSide.support ? 'SUPPORT (In Favor)' : 'OPPOSE (Against)';
    final aiSideLabel = aiSide == DebateSide.support ? 'SUPPORT (In Favor)' : 'OPPOSE (Against)';

    return '''You are the Cognitive Gym Debate Coach, an intelligent, respectful, and highly analytical AI debate partner in the Cognitive Gym application.

DEBATE CONTEXT:
• Selected Topic: "${topic.title}"
• Topic Description: "${topic.description}"
• User Stance: $userSideLabel
• AI Stance: $aiSideLabel
• Current Turn: $currentTurn of 5

CORE BEHAVIORAL RULES:
1. Act as an intelligent debate partner opposing the user's stance on this topic.
2. Always stay respectful, constructive, and polite.
3. Encourage critical thinking by challenging weak reasoning, logical fallacies, or unexamined premises in the user's argument.
4. Ask thoughtful, open-ended follow-up questions to help the user refine their reasoning.
5. Stay strictly focused on the selected debate topic. Never diverge to unrelated subjects.
6. NEVER insult, demean, or mock the user.
7. NEVER declare a winner or loser. Debate is a tool for cognitive development and perspective exploring.
8. Turn & Concluding Guidance:
   - If turn is 1 to 4: Provide a sharp rebuttal to the user's points (2-4 concise sentences), present counter-perspectives or evidence, and ask a probing follow-up question.
   - If turn is 5 or greater: Respectfully summarize the key perspectives explored during this exchange, provide a balanced closing reflection on the nuances of "${topic.title}", and bring the debate to a natural, respectful conclusion. Do not ask another debate question at turn 5.''';
  }

  /// Generates the opening statement from the AI coach taking the opposing side.
  Future<String> generateOpeningStatement({
    required DebateTopic topic,
    required DebateSide userSide,
  }) async {
    final aiSide = userSide == DebateSide.support ? DebateSide.oppose : DebateSide.support;
    final systemPrompt = _buildSystemPrompt(
      topic: topic,
      userSide: userSide,
      aiSide: aiSide,
      currentTurn: 1,
    );

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {
        'role': 'user',
        'content':
            'Please provide your opening statement for the debate on "${topic.title}". Introduce your assigned stance (${aiSide == DebateSide.support ? 'Supporting' : 'Opposing'}) and present your primary opening argument, then invite my counter-perspective.'
      }
    ];

    return await _sendApiRequest(messages);
  }

  /// Sends full conversation history and new user argument to OpenRouter API to generate AI rebuttal.
  Future<String> sendChatMessage({
    required DebateSession session,
    required String userText,
  }) async {
    final systemPrompt = _buildSystemPrompt(
      topic: session.topic,
      userSide: session.userSide,
      aiSide: session.aiSide,
      currentTurn: session.currentTurn,
    );

    final List<Map<String, String>> apiMessages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    // Append existing chat history
    for (final msg in session.messages) {
      if (msg.sender == MessageSender.user) {
        apiMessages.add({'role': 'user', 'content': msg.message});
      } else if (msg.sender == MessageSender.ai) {
        apiMessages.add({'role': 'assistant', 'content': msg.message});
      }
    }

    // Append latest user message if not already added
    if (apiMessages.isEmpty || apiMessages.last['content'] != userText) {
      apiMessages.add({'role': 'user', 'content': userText});
    }

    return await _sendApiRequest(apiMessages);
  }

  /// Requests a structured quality evaluation of the user's debate arguments.
  ///
  /// Returns the RAW model response string; parsing into a 0-100 score is
  /// handled safely by ExerciseScoringService.parseDebateAiEvaluation. The
  /// system prompt pins a strict JSON-only rubric:
  ///   relevance 0-40, reasoning 0-40, engagement 0-20.
  /// Callers must treat any thrown exception as "evaluation unavailable" and
  /// fall back to the deterministic score — completion is never blocked.
  Future<String> evaluateDebateArguments({
    required DebateTopic topic,
    required DebateSide userSide,
    required List<String> userArguments,
  }) async {
    if (userArguments.isEmpty) {
      throw const OpenRouterException('No user arguments to evaluate.');
    }

    final sideLabel =
        userSide == DebateSide.support ? 'SUPPORT (In Favor)' : 'OPPOSE (Against)';
    final systemPrompt = '''You are an objective debate-quality assessor inside the Cognitive Gym training app. Evaluate ONLY the user's arguments below, written by a user arguing $sideLabel on the topic "${topic.title}".

SCORING RUBRIC (in-app training performance, NOT a clinical cognitive measure):
- relevance: 0-40 (how directly the arguments address the topic and the opponent's points)
- reasoning: 0-40 (logical structure, evidence, examples, cause-effect reasoning)
- engagement: 0-20 (whether the arguments respond to and build on the opponent's counterpoints)

Respond with ONLY a JSON object in exactly this format, with integer values and no extra text:
{"relevance": <0-40>, "reasoning": <0-40>, "engagement": <0-20>}''';

    final userContent = userArguments
        .asMap()
        .entries
        .map((e) => 'Argument ${e.key + 1}: ${e.value}')
        .join('\n\n');

    return await _sendApiRequest(
      [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userContent},
      ],
      maxTokens: 200,
      temperature: 0.2,
    );
  }

  /// Helper to post messages array to OpenRouter Chat Completions endpoint.
  Future<String> _sendApiRequest(
    List<Map<String, String>> messages, {
    int maxTokens = 500,
    double temperature = 0.7,
  }) async {
    if (mockHandler != null) {
      return await mockHandler!(messages);
    }

    final apiKey = effectiveApiKey;
    if (apiKey.isEmpty) {
      throw const OpenRouterException(
        'OpenRouter API key is not configured. Please supply an API key via --dart-define=OPENROUTER_API_KEY=... or enter it in Settings.',
        statusCode: 401,
      );
    }

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/cognitive-gym',
          'X-Title': 'Cognitive Gym Debate Arena',
        },
        body: jsonEncode({
          'model': _primaryModel,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final choices = responseData['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final firstChoice = choices.first;
          final messageMap = firstChoice['message'] as Map<String, dynamic>?;
          final content = messageMap?['content']?.toString().trim();

          if (content != null && content.isNotEmpty) {
            return content;
          }
        }
        throw const OpenRouterException('OpenRouter returned an empty response.');
      } else {
        if (kDebugMode) {
          print('[OpenRouterService] API HTTP Error ${response.statusCode}: ${response.body}');
        }
        String errorDetail = 'API Request failed with status ${response.statusCode}.';
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson['error']?['message'] != null) {
            errorDetail = errorJson['error']['message'].toString();
          }
        } catch (_) {}
        throw OpenRouterException(errorDetail, statusCode: response.statusCode);
      }
    } on SocketException catch (e) {
      if (kDebugMode) print('[OpenRouterService] Network socket exception: $e');
      throw const OpenRouterException('Network connection unavailable. Please check your internet connection.');
    } on http.ClientException catch (e) {
      if (kDebugMode) print('[OpenRouterService] HTTP Client exception: $e');
      throw OpenRouterException('Network error: ${e.message}');
    } catch (e) {
      if (e is OpenRouterException) rethrow;
      if (kDebugMode) print('[OpenRouterService] Unexpected exception: $e');
      throw OpenRouterException('An unexpected error occurred: ${e.toString()}');
    }
  }
}
