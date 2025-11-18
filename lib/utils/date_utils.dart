import 'package:intl/intl.dart';

enum DayCompletionStatus {
  perfect,
  partial,
  none,
}

class DateUtils {
  static String normalizeDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static DateTime parseNormalizedDate(String dateString) {
    return DateFormat('yyyy-MM-dd').parse(dateString);
  }

  static DateTime get startOfDay {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime get yesterday {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return DateTime(yesterday.year, yesterday.month, yesterday.day);
  }

  /// Returns the start of the week (Sunday) for a given date.
  static DateTime startOfWeek(DateTime date) {
    // Dart's weekday property returns 1 for Monday, 7 for Sunday.
    // We want Sunday to be the start of the week (index 0).
    // So, if it's Sunday (7), subtract 0 days. If it's Monday (1), subtract 1 day, etc.
    // (date.weekday % 7) gives 0 for Sunday, 1 for Monday, ..., 6 for Saturday.
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday % 7));
  }

  /// Returns the end of the week (Saturday) for a given date.
  static DateTime endOfWeek(DateTime date) {
    final start = startOfWeek(date);
    return start.add(const Duration(days: 6));
  }

  /// Returns a list of 7 DateTimes representing the days of the week
  /// starting from Sunday for the week of the given date.
  static List<DateTime> daysInWeek(DateTime date) {
    final start = startOfWeek(date);
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  /// Checks if two DateTimes represent the same day (ignoring time).
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static DateTime normalizeDateTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Returns the number of days in a given month.
  static int daysInMonth(DateTime date) {
    final firstDayOfNextMonth = DateTime(date.year, date.month + 1, 1);
    final lastDayOfMonth = firstDayOfNextMonth.subtract(const Duration(days: 1));
    return lastDayOfMonth.day;
  }

  /// Checks if two DateTimes represent the same month and year (ignoring day and time).
  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  /// Formats a DateTime to display only the month and year (e.g., "September 2025").
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Calculates the difference in months between two DateTime objects.
  /// Returns a positive integer if date2 is after date1, negative if before, and 0 if same month/year.
  static int getMonthsDifference(DateTime date1, DateTime date2) {
    return (date2.year - date1.year) * 12 + (date2.month - date1.month);
  }
}
