import 'package:flutter/material.dart';

/// Data model representing a thought-provoking topic in the Debate Arena.
class DebateTopic {
  final String id;
  final String title;
  final String category;
  final IconData icon;
  final String description;
  final String? imagePath;

  const DebateTopic({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.description,
    this.imagePath,
  });
}
