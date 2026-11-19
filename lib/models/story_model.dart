import 'dart:convert';

/// Data model representing a user's completed Story Builder entry.
class StoryModel {
  final String id;
  final List<String> words;
  final String content;
  final DateTime createdAt;
  final int wordCount;
  final int pointsEarned;

  const StoryModel({
    required this.id,
    required this.words,
    required this.content,
    required this.createdAt,
    required this.wordCount,
    this.pointsEarned = 15,
  });

  /// Calculates word count from a text string.
  static int countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  /// Returns a list of required words that are missing from [text].
  ///
  /// Matching ignores case and punctuation differences.
  static List<String> getMissingWords(
    String text,
    List<String> requiredWords,
  ) {
    final cleanText = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');
    final storyTokens = cleanText
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toSet();

    final List<String> missing = [];
    for (final word in requiredWords) {
      final cleanWord = word
          .toLowerCase()
          .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
          .trim();
      if (cleanWord.isEmpty) continue;
      if (!storyTokens.contains(cleanWord)) {
        missing.add(word);
      }
    }
    return missing;
  }

  /// Checks whether [text] contains all [requiredWords], ignoring case and punctuation.
  static bool hasAllRequiredWords(
    String text,
    List<String> requiredWords,
  ) {
    return getMissingWords(text, requiredWords).isEmpty;
  }


  /// Converts model instance into JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'words': words,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'wordCount': wordCount,
      'pointsEarned': pointsEarned,
    };
  }

  /// Factory constructor to deserialize JSON Map into StoryModel instance.
  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      words: List<String>.from(json['words'] as List),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      wordCount: json['wordCount'] as int,
      pointsEarned: (json['pointsEarned'] as int?) ?? 15,
    );
  }

  /// Convenience encoder to JSON string.
  String toRawJson() => json.encode(toJson());

  /// Convenience decoder from JSON string.
  factory StoryModel.fromRawJson(String str) =>
      StoryModel.fromJson(json.decode(str) as Map<String, dynamic>);
}
