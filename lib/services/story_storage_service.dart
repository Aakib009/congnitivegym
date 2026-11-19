import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story_model.dart';
import 'auth_service.dart';

/// Local storage service for saving and retrieving completed Story Builder entries.
class StoryStorageService {
  static const String _storageKeyBase = 'cognitive_gym_saved_stories';

  static String _storageKey() {
    final uid = AuthService.instance.currentUser?.id;
    return (uid != null && uid.isNotEmpty) ? '${_storageKeyBase}_$uid' : _storageKeyBase;
  }

  /// Fetches all saved stories sorted by creation date (newest first).
  static Future<List<StoryModel>> getStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? rawList = prefs.getStringList(_storageKey());

      if (rawList == null || rawList.isEmpty) {
        return [];
      }

      final List<StoryModel> stories = rawList.map((itemStr) {
        final Map<String, dynamic> jsonMap = json.decode(itemStr);
        return StoryModel.fromJson(jsonMap);
      }).toList();

      // Sort newest first
      stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return stories;
    } catch (e) {
      debugPrint('[StoryStorageService] Error loading stories: $e');
      return [];
    }
  }

  /// Persists a new [StoryModel] entry to local storage.
  static Future<bool> saveStory(StoryModel story) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<StoryModel> existing = await getStories();

      // Deduplicate by story id if re-saving or retrying
      existing.removeWhere((s) => s.id == story.id);
      // Prepend newest story
      existing.insert(0, story);

      final List<String> rawList =
          existing.map((s) => json.encode(s.toJson())).toList();

      return await prefs.setStringList(_storageKey(), rawList);
    } catch (e) {
      debugPrint('[StoryStorageService] Error saving story: $e');
      return false;
    }
  }

  /// Deletes a story by [id] from local storage.
  static Future<bool> deleteStory(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<StoryModel> existing = await getStories();

      existing.removeWhere((s) => s.id == id);

      final List<String> rawList =
          existing.map((s) => json.encode(s.toJson())).toList();

      return await prefs.setStringList(_storageKey(), rawList);
    } catch (e) {
      debugPrint('[StoryStorageService] Error deleting story: $e');
      return false;
    }
  }
}
