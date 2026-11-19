import 'package:flutter/foundation.dart';
import '../models/analytics_event.dart';
import 'database_service.dart';

/// Repository isolating all SQLite database access operations for analytics.
class AnalyticsRepository {
  final DatabaseService _dbService;

  AnalyticsRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  /// Inserts a new analytics event into the database.
  Future<void> logEvent(AnalyticsEvent event) async {
    try {
      if (!kIsWeb) {
        await _dbService.insertAnalyticsEvent(event);
      }
    } catch (e) {
      debugPrint('[AnalyticsRepository] Error logging event: $e');
    }
  }

  /// Retrieves recorded analytics events filtered by optional date bounds and user ID.
  Future<List<AnalyticsEvent>> getEvents({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (kIsWeb) {
        return [];
      }
      return await _dbService.getAnalyticsEvents(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('[AnalyticsRepository] Error fetching events: $e');
      return [];
    }
  }

  /// Clears all analytics events.
  Future<void> clearEvents() async {
    try {
      if (!kIsWeb) {
        await _dbService.clearAllAnalyticsEvents();
      }
    } catch (e) {
      debugPrint('[AnalyticsRepository] Error clearing events: $e');
    }
  }
}

