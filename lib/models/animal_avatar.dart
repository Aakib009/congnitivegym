import 'package:flutter/material.dart';

/// Metadata for animal avatars supported in Cognitive Gym.
class AnimalAvatarInfo {
  final String id;
  final String name;
  final Color themeColor;
  final Color bgColor;

  const AnimalAvatarInfo({
    required this.id,
    required this.name,
    required this.themeColor,
    required this.bgColor,
  });
}

/// Registry and helper class for animal avatars.
class AppAvatars {
  AppAvatars._();

  static const String elephant = 'elephant';
  static const String tiger = 'tiger';
  static const String lion = 'lion';
  static const String raccoon = 'raccoon';
  static const String rabbit = 'rabbit';
  static const String bear = 'bear';
  static const String cat = 'cat';

  static const String defaultAvatarId = raccoon;

  /// Exactly 7 supported animal avatars in defined order.
  static const List<AnimalAvatarInfo> all = [
    AnimalAvatarInfo(
      id: elephant,
      name: 'Elephant',
      themeColor: Color(0xFF3B82F6),
      bgColor: Color(0xFFE0EDFB),
    ),
    AnimalAvatarInfo(
      id: tiger,
      name: 'Tiger',
      themeColor: Color(0xFFEA580C),
      bgColor: Color(0xFFFFF1E6),
    ),
    AnimalAvatarInfo(
      id: lion,
      name: 'Lion',
      themeColor: Color(0xFFD97706),
      bgColor: Color(0xFFFFF7ED),
    ),
    AnimalAvatarInfo(
      id: raccoon,
      name: 'Raccoon',
      themeColor: Color(0xFF0D9488),
      bgColor: Color(0xFFE2ECE9),
    ),
    AnimalAvatarInfo(
      id: rabbit,
      name: 'Rabbit',
      themeColor: Color(0xFFEC4899),
      bgColor: Color(0xFFFCE7F3),
    ),
    AnimalAvatarInfo(
      id: bear,
      name: 'Bear',
      themeColor: Color(0xFF854D0E),
      bgColor: Color(0xFFF3EBE6),
    ),
    AnimalAvatarInfo(
      id: cat,
      name: 'Cat',
      themeColor: Color(0xFF8B5CF6),
      bgColor: Color(0xFFF3E8FF),
    ),
  ];

  /// Retrieve avatar metadata by ID, safely defaulting to [raccoon].
  static AnimalAvatarInfo getById(String? id) {
    final normalized = normalize(id);
    return all.firstWhere(
      (a) => a.id == normalized,
      orElse: () => all.firstWhere((a) => a.id == defaultAvatarId),
    );
  }

  /// Normalizes any raw avatar string (including legacy asset paths or null) to a valid avatar ID.
  static String normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return defaultAvatarId;
    final lower = raw.trim().toLowerCase();
    for (final avatar in all) {
      if (avatar.id == lower) return avatar.id;
    }
    // Also handle legacy asset paths like 'assets/images/raccoon_avatar.png'
    if (lower.contains('raccoon')) return raccoon;
    if (lower.contains('elephant')) return elephant;
    if (lower.contains('tiger')) return tiger;
    if (lower.contains('lion')) return lion;
    if (lower.contains('rabbit')) return rabbit;
    if (lower.contains('bear')) return bear;
    if (lower.contains('cat')) return cat;

    return defaultAvatarId;
  }
}
