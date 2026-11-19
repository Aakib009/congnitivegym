import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Transaction record representing a point grant event.
class PointTransaction {
  final String txId;
  final String source;
  final int points;
  final DateTime timestamp;

  const PointTransaction({
    required this.txId,
    required this.source,
    required this.points,
    required this.timestamp,
  });
}

/// Core transaction engine for awarding points with Anti-Exploitation enforcement.
class PointService {
  PointService._();

  static final PointService instance = PointService._();

  static const String _keyProcessedTxIds = 'point_processed_tx_ids';
  static const String _keyDailyCompletedLessons = 'point_daily_completed_lessons';
  static const String _keyDailyLessonDate = 'point_daily_lesson_date';

  String _userKey(String base) {
    final uid = AuthService.instance.currentUser?.id;
    return (uid != null && uid.isNotEmpty) ? '${base}_$uid' : base;
  }

  /// Evaluates whether a point transaction with [txId] can be executed.
  /// Prevents double-awarding due to app refreshes or retries.
  Future<bool> canProcessTransaction(String txId) async {
    final prefs = await SharedPreferences.getInstance();
    final processed = prefs.getStringList(_userKey(_keyProcessedTxIds)) ?? [];
    return !processed.contains(txId);
  }

  /// Registers [txId] as processed.
  Future<void> markTransactionProcessed(String txId) async {
    final prefs = await SharedPreferences.getInstance();
    final processed = prefs.getStringList(_userKey(_keyProcessedTxIds)) ?? [];
    if (!processed.contains(txId)) {
      processed.add(txId);
      // Keep last 500 transaction IDs to manage storage size efficiently
      if (processed.length > 500) {
        processed.removeAt(0);
      }
      await prefs.setStringList(_userKey(_keyProcessedTxIds), processed);
    }
  }

  /// Checks if a lesson has already been completed today.
  /// Anti-Exploitation Rule: Full points awarded only for first completion per day.
  Future<bool> isLessonCompletedToday(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate(DateTime.now());
    final lastDate = prefs.getString(_userKey(_keyDailyLessonDate)) ?? '';

    if (lastDate != todayStr) {
      // New day, reset completed lessons log
      await prefs.setString(_userKey(_keyDailyLessonDate), todayStr);
      await prefs.setStringList(_userKey(_keyDailyCompletedLessons), []);
      return false;
    }

    final completedList = prefs.getStringList(_userKey(_keyDailyCompletedLessons)) ?? [];
    return completedList.contains(lessonId);
  }

  /// Records a lesson as completed today.
  Future<void> markLessonCompletedToday(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate(DateTime.now());
    await prefs.setString(_userKey(_keyDailyLessonDate), todayStr);

    final completedList = prefs.getStringList(_userKey(_keyDailyCompletedLessons)) ?? [];
    if (!completedList.contains(lessonId)) {
      completedList.add(lessonId);
      await prefs.setStringList(_userKey(_keyDailyCompletedLessons), completedList);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
