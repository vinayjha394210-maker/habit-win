import 'package:flutter/material.dart';
import 'package:habit_win/utils/date_utils.dart' as my_date_utils;
import 'package:habit_win/utils/custom_icons.dart';

enum RepeatType { daily, weekly, monthly, oneTime }

enum TimeOfDayType { all, morning, afternoon, evening }

class Habit {
  final String id;
  String name;
  String color;
  CustomIcon icon; // Changed from String to CustomIcon
  bool goalEnabled;
  int? goalValue;
  String? unit; // New field for goal unit
  List<DateTime> completionDates;
  int streak; // Current consecutive days completed
  int longestStreak; // Longest streak achieved
  RepeatType repeatType;
  List<int> repeatDays; // 1 for Monday, 7 for Sunday
  int repeatDateOfMonth; // For monthly: 1-31
  DateTime? targetDate; // For one-time habits
  TimeOfDayType timeOfDayType;
  DateTime startDate;
  List<TimeOfDay> reminderTimes;
  int streakFreezesUsed;
  DateTime? lastFreezeDate;

  Habit({
    required this.id,
    required this.name,
    required this.color,
    required this.icon, // Changed type to CustomIcon
    this.goalEnabled = false,
    this.goalValue,
    this.unit, // Initialize unit
    List<DateTime>?
    completionDates, // Make it nullable for easier initialization
    this.streak = 0,
    this.longestStreak = 0, // Initialize longest streak
    this.repeatType = RepeatType.daily, // Default to daily
    this.repeatDays = const [],
    this.repeatDateOfMonth = 1, // Default to 1st of the month
    this.targetDate, // For one-time habits
    this.timeOfDayType = TimeOfDayType.all,
    required this.startDate,
    this.reminderTimes = const [],
    this.streakFreezesUsed = 0,
    this.lastFreezeDate,
  }) : completionDates = completionDates ?? []; // Initialize here

  bool isCompletedOn(DateTime date) {
    final normalizedInputDate = my_date_utils.DateUtils.normalizeDateTime(date);
    return completionDates.any(
      (d) => my_date_utils.DateUtils.isSameDay(d, normalizedInputDate),
    );
  }

  bool isHabitDueOnDate(DateTime date) {
    // Normalize the input date to compare only year, month, day
    final normalizedDate = my_date_utils.DateUtils.normalizeDateTime(date);
    final normalizedStartDate = my_date_utils.DateUtils.normalizeDateTime(
      startDate,
    );

    // A habit cannot be due before its start date
    if (normalizedDate.isBefore(normalizedStartDate)) {
      return false;
    }

    switch (repeatType) {
      case RepeatType.daily:
        return true;
      case RepeatType.weekly:
        // Dart's weekday property: Monday is 1, Sunday is 7
        return repeatDays.contains(normalizedDate.weekday);
      case RepeatType.monthly:
        return normalizedDate.day == repeatDateOfMonth;
      case RepeatType.oneTime:
        return targetDate != null &&
            my_date_utils.DateUtils.isSameDay(normalizedDate, targetDate!);
    }
  }

  // Method to mark a habit as complete for a given date
  void complete(DateTime date) {
    final normalizedDate = my_date_utils.DateUtils.normalizeDateTime(
      date,
    ); // Use the provided date, normalized
    // Ensure only one completion per day
    if (!isCompletedOn(normalizedDate)) {
      completionDates = List.from(completionDates)..add(normalizedDate);
      completionDates.sort((a, b) => a.compareTo(b)); // Keep dates sorted
      updateStreak();
      updateLongestStreak(); // Update longest streak after updating current streak
    }
  }

  // Method to toggle habit completion for a given date
  void toggleCompletion(DateTime date) {
    final normalizedDate = my_date_utils.DateUtils.normalizeDateTime(
      date,
    ); // Use the provided date, normalized
    final normalizedDateForComparison =
        my_date_utils.DateUtils.normalizeDateTime(normalizedDate);

    final existingCompletionIndex = completionDates.indexWhere(
      (d) => my_date_utils.DateUtils.isSameDay(d, normalizedDateForComparison),
    );

    if (existingCompletionIndex != -1) {
      // If already completed, unmark it
      completionDates.removeAt(existingCompletionIndex);
    } else {
      // If not completed, mark it
      completionDates.add(normalizedDate);
      completionDates.sort((a, b) => a.compareTo(b)); // Keep dates sorted
    }
    updateStreak(); // Always update streak after toggling
    updateLongestStreak(); // Update longest streak after toggling
  }

  // Method to calculate the current streak without considering freezes
  int calculateCurrentStreak() {
    if (completionDates.isEmpty) {
      return 0;
    }

    // Sort completion dates to ensure correct chronological order
    final List<DateTime> sortedCompletionDates = List.from(completionDates)
      ..sort((a, b) => a.compareTo(b));

    int currentStreak = 0;
    DateTime? lastCompletionDate;

    // Iterate backwards from the most recent completion date
    for (int i = sortedCompletionDates.length - 1; i >= 0; i--) {
      final DateTime currentDay = my_date_utils.DateUtils.normalizeDateTime(
        sortedCompletionDates[i],
      );

      if (lastCompletionDate == null) {
        // First completion date, always starts a streak of 1
        currentStreak = 1;
        lastCompletionDate = currentDay;
      } else {
        final DateTime expectedPreviousDay = lastCompletionDate.subtract(
          const Duration(days: 1),
        );

        if (my_date_utils.DateUtils.isSameDay(
          currentDay,
          expectedPreviousDay,
        )) {
          // Consecutive day
          currentStreak++;
          lastCompletionDate = currentDay;
        } else if (currentDay.isBefore(expectedPreviousDay)) {
          // Gap detected, streak broken
          break;
        }
      }
    }
    return currentStreak;
  }

  // Method to update the longest streak
  void updateLongestStreak() {
    if (streak > longestStreak) {
      longestStreak = streak;
    }
  }

  // Helper to check if the habit was completed in a given week (any of its repeatDays)
  bool _wasCompletedInWeek(DateTime weekStartDate) {
    final normalizedWeekStartDate = my_date_utils.DateUtils.normalizeDateTime(
      weekStartDate,
    );
    for (int i = 0; i < 7; i++) {
      final currentDate = normalizedWeekStartDate.add(Duration(days: i));
      if (repeatDays.contains(currentDate.weekday) &&
          isCompletedOn(currentDate)) {
        return true;
      }
    }
    return false;
  }

  // Helper to check if the habit was completed in a given month (on its repeatDateOfMonth)
  bool _wasCompletedInMonth(DateTime monthDate) {
    final normalizedMonthDate = my_date_utils.DateUtils.normalizeDateTime(
      monthDate,
    );
    final expectedCompletionDate = DateTime(
      normalizedMonthDate.year,
      normalizedMonthDate.month,
      repeatDateOfMonth,
    );
    return isCompletedOn(expectedCompletionDate);
  }

  // Method to update the streak based on completion dates (including freezes)
  void updateStreak() {
    if (completionDates.isEmpty) {
      streak = 0;
      return;
    }

    // Sort completion dates to ensure correct chronological order
    completionDates.sort((a, b) => a.compareTo(b));

    int currentStreak = 0;
    DateTime?
    lastConsideredPeriodStart; // The start of the last period (day, week, month) that contributed to the streak

    // Get the most recent completion date
    final DateTime mostRecentCompletion =
        my_date_utils.DateUtils.normalizeDateTime(completionDates.last);

    // Determine the current period start based on repeatType
    if (repeatType == RepeatType.daily || repeatType == RepeatType.oneTime) {
      lastConsideredPeriodStart = mostRecentCompletion;
    } else if (repeatType == RepeatType.weekly) {
      lastConsideredPeriodStart = my_date_utils.DateUtils.startOfWeek(
        mostRecentCompletion,
      );
    } else if (repeatType == RepeatType.monthly) {
      lastConsideredPeriodStart = DateTime(
        mostRecentCompletion.year,
        mostRecentCompletion.month,
        1,
      );
    }

    // Iterate backwards from the most recent completion period
    while (true) {
      bool completedInCurrentPeriod = false;

      if (repeatType == RepeatType.daily || repeatType == RepeatType.oneTime) {
        // For daily/one-time, check if the habit was completed on lastConsideredPeriodStart
        completedInCurrentPeriod = isCompletedOn(lastConsideredPeriodStart!);
      } else if (repeatType == RepeatType.weekly) {
        // For weekly, check if the habit was completed in the week starting lastConsideredPeriodStart
        completedInCurrentPeriod = _wasCompletedInWeek(
          lastConsideredPeriodStart!,
        );
      } else if (repeatType == RepeatType.monthly) {
        // For monthly, check if the habit was completed in the month starting lastConsideredPeriodStart
        completedInCurrentPeriod = _wasCompletedInMonth(
          lastConsideredPeriodStart!,
        );
      }

      if (completedInCurrentPeriod) {
        currentStreak++;
        // Move to the previous period
        if (repeatType == RepeatType.daily ||
            repeatType == RepeatType.oneTime) {
          lastConsideredPeriodStart = lastConsideredPeriodStart!.subtract(
            const Duration(days: 1),
          );
        } else if (repeatType == RepeatType.weekly) {
          lastConsideredPeriodStart = lastConsideredPeriodStart!.subtract(
            const Duration(days: 7),
          );
        } else if (repeatType == RepeatType.monthly) {
          lastConsideredPeriodStart = DateTime(
            lastConsideredPeriodStart!.year,
            lastConsideredPeriodStart.month - 1,
            1,
          );
        }
      } else {
        // Check for streak freeze opportunity (only applicable for daily habits for now)
        if (repeatType == RepeatType.daily && streakFreezesUsed < 3) {
          // If the previous day was missed, use a freeze
          final DateTime expectedPreviousDay = lastConsideredPeriodStart!
              .subtract(const Duration(days: 1));
          if (isCompletedOn(
            expectedPreviousDay.subtract(const Duration(days: 1)),
          )) {
            // Check if day before missed day was completed
            streakFreezesUsed++;
            lastFreezeDate = expectedPreviousDay; // The day that was frozen
            currentStreak++; // The frozen day still counts towards the streak conceptually
            lastConsideredPeriodStart = expectedPreviousDay.subtract(
              const Duration(days: 1),
            );
            continue; // Continue checking from the day before the freeze
          }
        }
        // Streak broken
        break;
      }

      // Stop if we go before the habit's start date
      if (lastConsideredPeriodStart!.isBefore(
        my_date_utils.DateUtils.normalizeDateTime(startDate),
      )) {
        break;
      }
    }
    streak = currentStreak;
    updateLongestStreak(); // Update longest streak after calculating current streak
  }

  // Factory constructor to create a Habit from a JSON map
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      icon: CustomIcon.fromSavableString(
        json['icon'],
      ), // Parse icon string to CustomIcon
      goalEnabled: json['goalEnabled'] ?? false,
      goalValue: json['goalValue'],
      unit: json['unit'], // Deserialize unit
      completionDates: (json['completionDates'] as List<dynamic>)
          .map(
            (dateString) =>
                my_date_utils.DateUtils.parseNormalizedDate(dateString),
          )
          .toList(),
      streak: json['streak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0, // Deserialize longest streak
      repeatType: RepeatType.values.firstWhere(
        (e) => e.toString() == 'RepeatType.${json['repeatType']}',
        orElse: () => RepeatType.daily,
      ),
      repeatDays:
          (json['repeatDays'] as List<dynamic>?)
              ?.map((day) => day as int)
              .toList() ??
          const [],
      repeatDateOfMonth: json['repeatDateOfMonth'] ?? 1,
      targetDate: json['targetDate'] != null
          ? my_date_utils.DateUtils.parseNormalizedDate(json['targetDate'])
          : null,
      timeOfDayType: TimeOfDayType.values.firstWhere(
        (e) => e.toString() == 'TimeOfDayType.${json['timeOfDayType']}',
        orElse: () => TimeOfDayType.all,
      ),
      startDate: my_date_utils.DateUtils.parseNormalizedDate(json['startDate']),
      reminderTimes:
          (json['reminderTimes'] as List<dynamic>?)
              ?.map(
                (timeMap) =>
                    TimeOfDay(hour: timeMap['hour'], minute: timeMap['minute']),
              )
              .toList() ??
          const [],
      streakFreezesUsed: json['streakFreezesUsed'] ?? 0,
      lastFreezeDate: json['lastFreezeDate'] != null
          ? my_date_utils.DateUtils.parseNormalizedDate(json['lastFreezeDate'])
          : null,
    );
  }

  // Method to convert a Habit to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon.toSavableString(), // Convert CustomIcon to savable string
      'goalEnabled': goalEnabled,
      'goalValue': goalValue,
      'unit': unit, // Serialize unit
      'completionDates': completionDates
          .map((date) => my_date_utils.DateUtils.normalizeDate(date))
          .toList(),
      'streak': streak,
      'longestStreak': longestStreak, // Serialize longest streak
      'repeatType': repeatType.toString().split('.').last,
      'repeatDays': repeatDays,
      'repeatDateOfMonth': repeatDateOfMonth,
      'targetDate': targetDate != null
          ? my_date_utils.DateUtils.normalizeDate(targetDate!)
          : null,
      'timeOfDayType': timeOfDayType.toString().split('.').last,
      'startDate': my_date_utils.DateUtils.normalizeDate(startDate),
      'reminderTimes': reminderTimes
          .map((time) => {'hour': time.hour, 'minute': time.minute})
          .toList(),
      'streakFreezesUsed': streakFreezesUsed,
      'lastFreezeDate': lastFreezeDate != null
          ? my_date_utils.DateUtils.normalizeDate(lastFreezeDate!)
          : null,
    };
  }

  // Method to create a copy of the Habit with updated fields
  Habit copyWith({
    String? id,
    String? name,
    String? color,
    CustomIcon? icon,
    bool? goalEnabled,
    int? goalValue,
    String? unit, // Add unit to copyWith
    List<DateTime>? completionDates,
    int? streak,
    int? longestStreak, // Add longestStreak to copyWith
    RepeatType? repeatType,
    List<int>? repeatDays,
    int? repeatDateOfMonth,
    DateTime? targetDate,
    TimeOfDayType? timeOfDayType,
    DateTime? startDate,
    List<TimeOfDay>? reminderTimes,
    int? streakFreezesUsed,
    DateTime? lastFreezeDate,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      goalEnabled: goalEnabled ?? this.goalEnabled,
      goalValue: goalValue ?? this.goalValue,
      unit: unit ?? this.unit, // Copy unit
      completionDates: completionDates ?? this.completionDates,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak, // Copy longest streak
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      repeatDateOfMonth: repeatDateOfMonth ?? this.repeatDateOfMonth,
      targetDate: targetDate ?? this.targetDate,
      timeOfDayType: timeOfDayType ?? this.timeOfDayType,
      startDate: startDate ?? this.startDate,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      streakFreezesUsed: streakFreezesUsed ?? this.streakFreezesUsed,
      lastFreezeDate: lastFreezeDate ?? this.lastFreezeDate,
    );
  }
}
