import 'package:shared_preferences/shared_preferences.dart';
import '../constants/reward_constants.dart';
import 'auth_service.dart';

/// Result details from checking daily study / streak activity.
class StreakUpdateResult {
  final int newStreak;
  final int bestStreak;
  final int bonusPoints;
  final bool isNewDay;

  const StreakUpdateResult({
    required this.newStreak,
    required this.bestStreak,
    required this.bonusPoints,
    required this.isNewDay,
  });
}

/// Service managing daily learning streaks, login streaks, and study time tracking.
class StreakService {
  StreakService._();

  static final StreakService instance = StreakService._();

  static const String _keyLastStudyDate = 'streak_last_study_date';
  static const String _keyCurrentStreak = 'streak_current_count';
  static const String _keyBestStreak = 'streak_best_count';
  static const String _keyTodayStudyMinutes = 'streak_today_study_minutes';
  static const String _keyLastStudyTimeBonusDate = 'streak_last_study_bonus_date';

  String _userKey(String base) {
    final uid = AuthService.instance.currentUser?.id;
    return (uid != null && uid.isNotEmpty) ? '${base}_$uid' : base;
  }

  /// Evaluates study activity for today and returns streak calculation with point bonuses.
  Future<StreakUpdateResult> recordDailyActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _formatDate(now);

    final lastDateStr = prefs.getString(_userKey(_keyLastStudyDate)) ?? '';
    int currentStreak = prefs.getInt(_userKey(_keyCurrentStreak)) ?? 1;
    int bestStreak = prefs.getInt(_userKey(_keyBestStreak)) ?? 1;

    int bonus = 0;
    bool isNewDay = false;

    if (lastDateStr.isEmpty) {
      // First time user studies
      currentStreak = 1;
      bestStreak = 1;
      bonus = RewardConstants.getDailyStreakBonus(1);
      isNewDay = true;
    } else if (lastDateStr == todayStr) {
      // Already recorded today
      isNewDay = false;
      bonus = 0;
    } else {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null) {
        final todayMidnight = DateTime(now.year, now.month, now.day);
        final lastMidnight = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final differenceInDays = todayMidnight.difference(lastMidnight).inDays;
        if (differenceInDays == 1) {
          // Consecutive day study
          currentStreak += 1;
          isNewDay = true;
          bonus = RewardConstants.getDailyStreakBonus(currentStreak);

          // Check weekly streak bonus thresholds
          if (currentStreak == 5) bonus += RewardConstants.study5DaysWeekly;
          if (currentStreak == 7) bonus += RewardConstants.study7DaysWeekly;
          if (currentStreak == 14) bonus += RewardConstants.streak14Day;
          if (currentStreak == 30) bonus += RewardConstants.streak30Day;
          if (currentStreak == 100) bonus += RewardConstants.streak100Day;
        } else {
          // Streak broken
          currentStreak = 1;
          isNewDay = true;
          bonus = RewardConstants.getDailyStreakBonus(1);
        }
      } else {
        currentStreak = 1;
        isNewDay = true;
        bonus = RewardConstants.getDailyStreakBonus(1);
      }
    }

    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }

    await prefs.setString(_userKey(_keyLastStudyDate), todayStr);
    await prefs.setInt(_userKey(_keyCurrentStreak), currentStreak);
    await prefs.setInt(_userKey(_keyBestStreak), bestStreak);

    return StreakUpdateResult(
      newStreak: currentStreak,
      bestStreak: bestStreak,
      bonusPoints: bonus,
      isNewDay: isNewDay,
    );
  }

  /// Records study time in minutes (daily cap 60 mins). Returns awarded bonus points.
  Future<int> addStudyTime(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _formatDate(now);

    final lastBonusDate = prefs.getString(_userKey(_keyLastStudyTimeBonusDate)) ?? '';
    int currentMinutes = prefs.getInt(_userKey(_keyTodayStudyMinutes)) ?? 0;

    if (lastBonusDate != todayStr) {
      currentMinutes = 0;
      await prefs.setString(_userKey(_keyLastStudyTimeBonusDate), todayStr);
    }

    final oldMinutes = currentMinutes;
    final newMinutes = (currentMinutes + minutes).clamp(0, 60);
    await prefs.setInt(_userKey(_keyTodayStudyMinutes), newMinutes);

    // Calculate incremental bonus based on thresholds (15, 30, 45, 60)
    int pointsEarned = 0;
    for (final threshold in [15, 30, 45, 60]) {
      if (oldMinutes < threshold && newMinutes >= threshold) {
        pointsEarned += RewardConstants.studyTimeBonusMap[threshold] ?? 0;
      }
    }

    return pointsEarned;
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
