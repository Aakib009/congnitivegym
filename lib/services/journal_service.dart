import 'package:flutter/foundation.dart';

import '../models/journal_entry.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'progress_service.dart';

/// Reactive service managing cognitive journal reflections and SQLite persistence.
class JournalService extends ChangeNotifier {
  JournalService._internal();

  static final JournalService instance = JournalService._internal();

  final List<JournalEntry> _entries = [];
  bool _isLoading = false;
  bool _hasInitialLoaded = false;

  List<JournalEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  bool get hasInitialLoaded => _hasInitialLoaded;

  /// Loads entries for the current active user from SQLite.
  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = AuthService.instance.currentUser?.id ?? 'guest';
      final loaded =
          await DatabaseService.instance.getJournalEntries(userId: userId);
      _entries.clear();
      _entries.addAll(loaded);
      _hasInitialLoaded = true;
    } catch (e) {
      debugPrint('[JournalService] Error loading journal entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds and persists a new cognitive reflection entry.
  Future<JournalEntry?> addEntry({
    required String moodEmoji,
    required String moodLabel,
    required String entryText,
    String category = 'Reflection',
  }) async {
    final trimmedText = entryText.trim();
    if (trimmedText.isEmpty) return null;

    final userId = AuthService.instance.currentUser?.id ?? 'guest';
    final entry = JournalEntry(
      id: 'journal_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      moodEmoji: moodEmoji,
      moodLabel: moodLabel,
      entryText: trimmedText,
      category: category,
      createdAt: DateTime.now(),
    );

    try {
      await DatabaseService.instance.insertJournalEntry(entry);
      _entries.insert(0, entry);

      // Award 5 mindfulness XP for completing a journal reflection
      await ProgressService.instance.recordCustomExerciseReward(
        xp: 5,
        decisionMaking: 5,
      );

      notifyListeners();
      return entry;
    } catch (e) {
      debugPrint('[JournalService] Error saving journal entry: $e');
      return null;
    }
  }

  /// Deletes a journal entry from SQLite and active state.
  Future<bool> deleteEntry(String entryId) async {
    try {
      final rowsAffected =
          await DatabaseService.instance.deleteJournalEntry(entryId);
      if (rowsAffected > 0) {
        _entries.removeWhere((e) => e.id == entryId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[JournalService] Error deleting journal entry: $e');
      return false;
    }
  }

  /// Resets internal state for unit test isolation.
  @visibleForTesting
  void resetForTesting() {
    _entries.clear();
    _isLoading = false;
    _hasInitialLoaded = false;
    notifyListeners();
  }

  /// Seeds entries directly in memory for widget testing without disk I/O.
  @visibleForTesting
  void seedEntriesForTesting(List<JournalEntry> testEntries) {
    _entries.clear();
    _entries.addAll(testEntries);
    _isLoading = false;
    _hasInitialLoaded = true;
    notifyListeners();
  }
}
