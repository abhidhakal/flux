import '../models/transaction_model.dart';
import '../models/user_progress_model.dart';

class UserProgressService {
  static const int streakGraceDays = 1;
  static const int streakResetGapDays = 2;

  static const List<AchievementBadgeDefinition> badgeCatalog = [
    AchievementBadgeDefinition(
      id: 'streak_3',
      title: 'Getting Started',
      description: 'Maintain a 3-day logging streak.',
      metricType: ProgressMetricType.currentStreak,
      threshold: 3,
      iconKey: 'local_fire_department',
    ),
    AchievementBadgeDefinition(
      id: 'streak_7',
      title: 'On A Roll',
      description: 'Maintain a 7-day logging streak.',
      metricType: ProgressMetricType.currentStreak,
      threshold: 7,
      iconKey: 'bolt',
    ),
    AchievementBadgeDefinition(
      id: 'streak_30',
      title: 'Unstoppable',
      description: 'Maintain a 30-day logging streak.',
      metricType: ProgressMetricType.currentStreak,
      threshold: 30,
      iconKey: 'workspace_premium',
    ),
    AchievementBadgeDefinition(
      id: 'active_days_10',
      title: 'Committed',
      description: 'Log spending on 10 unique days.',
      metricType: ProgressMetricType.activeDays,
      threshold: 10,
      iconKey: 'calendar_month',
    ),
    AchievementBadgeDefinition(
      id: 'transactions_100',
      title: 'Century Club',
      description: 'Log 100 transactions.',
      metricType: ProgressMetricType.totalTransactions,
      threshold: 100,
      iconKey: 'receipt_long',
    ),
  ];

  UserProgressSnapshot calculateProgress(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return UserProgressSnapshot.empty().copyWith(
        updatedAt: DateTime.now(),
      );
    }

    final uniqueEpochDays = transactions
        .map((transaction) => _toLocalEpochDay(transaction.createdAt))
        .toSet()
        .toList()
      ..sort();

    if (uniqueEpochDays.isEmpty) {
      return UserProgressSnapshot.empty().copyWith(
        updatedAt: DateTime.now(),
      );
    }

    final todayEpochDay = _toLocalEpochDay(DateTime.now());
    final lastLoggedEpochDay = uniqueEpochDays.last;
    final daysSinceLastLog = todayEpochDay - lastLoggedEpochDay;
    final isStreakActive = daysSinceLastLog <= streakGraceDays;

    var currentStreak = 0;
    if (daysSinceLastLog < streakResetGapDays) {
      currentStreak = 1;
      for (var index = uniqueEpochDays.length - 1; index > 0; index--) {
        final gap = uniqueEpochDays[index] - uniqueEpochDays[index - 1];
        if (gap <= streakResetGapDays) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    var longestStreak = 1;
    var runningStreak = 1;
    for (var index = 1; index < uniqueEpochDays.length; index++) {
      final gap = uniqueEpochDays[index] - uniqueEpochDays[index - 1];
      if (gap <= streakResetGapDays) {
        runningStreak++;
      } else {
        if (runningStreak > longestStreak) {
          longestStreak = runningStreak;
        }
        runningStreak = 1;
      }
    }
    if (runningStreak > longestStreak) {
      longestStreak = runningStreak;
    }

    final lastLoggedDate = _dateFromEpochDay(lastLoggedEpochDay);
    final provisionalSnapshot = UserProgressSnapshot(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      activeDays: uniqueEpochDays.length,
      totalTransactions: transactions.length,
      lastLoggedDate: lastLoggedDate,
      isStreakActive: isStreakActive,
      earnedBadgeIds: const [],
      updatedAt: DateTime.now(),
    );

    return provisionalSnapshot.copyWith(
      earnedBadgeIds: evaluateUnlockedBadgeIds(provisionalSnapshot),
    );
  }

  List<String> evaluateUnlockedBadgeIds(UserProgressSnapshot snapshot) {
    return badgeCatalog
        .where((badge) => badge.isUnlocked(snapshot))
        .map((badge) => badge.id)
        .toList(growable: false);
  }

  static String formatStreakLabel(int streak) {
    if (streak == 1) {
      return '1 day streak';
    }
    return '$streak day streak';
  }

  static int _toLocalEpochDay(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    return DateTime(localDate.year, localDate.month, localDate.day)
            .millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  static DateTime _dateFromEpochDay(int epochDay) {
    return DateTime.fromMillisecondsSinceEpoch(
      epochDay * Duration.millisecondsPerDay,
      isUtc: false,
    );
  }
}
