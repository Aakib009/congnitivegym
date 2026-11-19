/// Represents an individual cognitive journal and mindfulness reflection entry.
class JournalEntry {
  final String id;
  final String userId;
  final String moodEmoji;
  final String moodLabel;
  final String entryText;
  final String category;
  final DateTime createdAt;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.moodEmoji,
    required this.moodLabel,
    required this.entryText,
    this.category = 'Reflection',
    required this.createdAt,
  });

  /// Serializes JournalEntry to a Map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'moodEmoji': moodEmoji,
      'moodLabel': moodLabel,
      'entryText': entryText,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Deserializes a Map from SQLite to a JournalEntry instance.
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: (map['id'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? '',
      moodEmoji: (map['moodEmoji'] as String?) ?? '🌿',
      moodLabel: (map['moodLabel'] as String?) ?? 'Calm',
      entryText: (map['entryText'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'Reflection',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  JournalEntry copyWith({
    String? id,
    String? userId,
    String? moodEmoji,
    String? moodLabel,
    String? entryText,
    String? category,
    DateTime? createdAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      moodLabel: moodLabel ?? this.moodLabel,
      entryText: entryText ?? this.entryText,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
