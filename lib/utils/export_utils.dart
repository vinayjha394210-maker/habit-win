import 'package:habit_win/models/habit.dart';
import 'package:habit_win/services/habit_service.dart';

class ExportUtils {
  static Map<String, dynamic> getOverallHabitProgress(HabitService habitService) {
    final List<Habit> allHabits = habitService.habits;

    if (allHabits.isEmpty) {
      return {
        'totalHabits': 0,
        'completedHabits': 0,
        'overallConsistency': 0.0,
        'longestStreak': 0,
        'currentStreak': 0,
      };
    }

    int totalCompletedHabits = 0;
    int longestOverallStreak = 0;
    int currentOverallStreak = 0; // This will be the "perfect day" streak

    // Calculate total completed habits
    for (final habit in allHabits) {
      totalCompletedHabits += habit.completionDates.length;
    }

    // Calculate overall consistency (using the existing method from HabitService)
    final double overallConsistency = habitService.calculateOverallCompletionRate();

    // Calculate longest individual habit streak
    for (final habit in allHabits) {
      // Recalculate streak to ensure it's up-to-date
      habit.updateStreak();
      if (habit.streak > longestOverallStreak) {
        longestOverallStreak = habit.streak;
      }
    }

    // Calculate current "perfect day" streak
    currentOverallStreak = habitService.calculatePerfectDayStreak();

    return {
      'totalHabits': allHabits.length,
      'completedHabits': totalCompletedHabits,
      'overallConsistency': overallConsistency,
      'longestStreak': longestOverallStreak,
      'currentStreak': currentOverallStreak,
    };
  }
}
