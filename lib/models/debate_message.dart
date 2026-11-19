import '../services/offline_debate_service.dart';

/// Represents the sender of a message in the Debate Arena.
enum MessageSender {
  user,
  ai,
  system,
}

/// Category or function of a message in the debate flow.
enum MessageType {
  text,
  opening,
  rebuttal,
  feedback,
}

/// Current stage of the formal debate.
enum DebateStage {
  opening,
  rebuttal,
  crossExamination,
  closing,
  finished,
}

/// Data model representing a single chat message in a debate session.
class DebateMessage {
  final String id;
  final MessageSender sender;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final MessageType type;
  final DebateStage stage;
  final ArgumentAnalysis? analysis;

  const DebateMessage({
    required this.id,
    required this.sender,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.type = MessageType.text,
    this.stage = DebateStage.opening,
    this.analysis,
  });

  /// Alias for message body text for UI compatibility.
  String get text => message;

  /// Returns true if message was sent by the user.
  bool get isUser => sender == MessageSender.user;

  /// Returns true if message was sent by the AI coach/opponent.
  bool get isAi => sender == MessageSender.ai;

  /// Creates a copy of DebateMessage with modified fields.
  DebateMessage copyWith({
    String? id,
    MessageSender? sender,
    String? senderName,
    String? message,
    DateTime? timestamp,
    MessageType? type,
    DebateStage? stage,
    ArgumentAnalysis? analysis,
  }) {
    return DebateMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      stage: stage ?? this.stage,
      analysis: analysis ?? this.analysis,
    );
  }
}
