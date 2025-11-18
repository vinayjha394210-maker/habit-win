import 'dart:async'; // Import for Timer and Completer
import 'package:flutter/foundation.dart'; // Import for ChangeNotifier
import 'package:connectivity_plus/connectivity_plus.dart'; // Import for network connectivity
import '../models/habit.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:flutter/material.dart'; // For TimeOfDay
import 'package:habit_win/services/local_storage_service.dart'; // Import LocalStorageService
import 'package:habit_win/utils/date_utils.dart' as MyDateUtils; // Import DateUtils
import 'package:habit_win/services/notification_service.dart'; // Import NotificationService
import 'package:habit_win/utils/custom_icons.dart'; // Import CustomIcon
class HabitService extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  final Uuid _uuid = Uuid();
  List<Habit> _habits = [];
  int _streakFreezesAvailable = 0;
  int _totalPerfectDays = 0; // New field for total perfect days
  int _totalHabitsCreated = 0; // New field for total habits created
  bool _isFetchingData = false;
  String? _errorMessage;
  Timer? _debounceTimer;
  Completer<void>? _currentFetchCompleter; // To cancel previous fetches
  static const Duration _fetchTimeout = Duration(seconds: 10);
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  final NotificationService _notificationService; // Add NotificationService

  NotificationService get notificationService => _notificationService; // Public getter for NotificationService

  HabitService(this._localStorageService, this._notificationService) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await loadHabitsFromCache();
    _streakFreezesAvailable = _localStorageService.getStreakFreezesAvailable();
    _totalHabitsCreated = _localStorageService.getTotalHabitsCreated(); // Load total habits created
    // Calculate total perfect days after habits are loaded
    _totalPerfectDays = _calculateTotalPerfectDays();
    // Fetch updated data in the background after initial load
    fetchAndCacheHabits(showLoading: false); // Don't show loading spinner on initial background fetch
  }

  List<Habit> get habits => _habits;
  int get streakFreezesAvailable => _streakFreezesAvailable;
  int get totalPerfectDays => _totalPerfectDays; // Getter for total perfect days
  int get totalHabitsCreated => _totalHabitsCreated; // Getter for total habits created
  bool get isFetchingData => _isFetchingData;
  String? get errorMessage => _errorMessage;

  List<Habit> getFilteredHabits(TimeOfDayType filter, DateTime selectedDate) {
    final normalizedSelectedDate = MyDateUtils.DateUtils.parseNormalizedDate(MyDateUtils.DateUtils.normalizeDate(selectedDate));

    List<Habit> filteredByTimeOfDay = [];
    if (filter == TimeOfDayType.all) {
      // If filter is 'all', include all habits that are due on the selected date
      filteredByTimeOfDay = _habits;
    } else {
      // Otherwise, filter by the specific time of day
      filteredByTimeOfDay = _habits.where((habit) => habit.timeOfDayType == filter).toList();
    }

    // Further filter by repeat type and if the habit is due on the selected date
    return filteredByTimeOfDay.where((habit) => habit.isHabitDueOnDate(normalizedSelectedDate)).toList();
  }

  Future<bool> _hasInternetConnection() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> loadHabits() async { // Public method to load habits
    await loadHabitsFromCache();
  }

  Future<void> loadHabitsFromCache() async {
    try {
      _habits = _localStorageService.getHabits();
      _totalPerfectDays = _localStorageService.getTotalPerfectDays(); // Load total perfect days
      _totalHabitsCreated = _localStorageService.getTotalHabitsCreated(); // Load total habits created
      _errorMessage = null; // Clear any previous error messages
    } catch (e) {
      debugPrint('Error loading data from cache: $e');
      _habits = [];
      _totalPerfectDays = 0; // Reset on error
      _totalHabitsCreated = 0; // Reset on error
      _errorMessage = 'Failed to load cached data.';
    } finally {
      notifyListeners(); // Notify listeners after loading data, even if an error occurred
    }
  }

  Future<void> fetchAndCacheHabits({bool showLoading = true}) async {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDuration, () async {
        // Cancel previous fetch if it's still running and not yet completed
        if (_currentFetchCompleter != null && !_currentFetchCompleter!.isCompleted) {
          _currentFetchCompleter?.completeError('Cancelled by new fetch');
        }
        _currentFetchCompleter = Completer<void>();

        if (showLoading) {
          _isFetchingData = true;
          notifyListeners();
        }

      try {
        final connected = await _hasInternetConnection();
        if (!connected) {
          _errorMessage = 'No internet connection. Displaying cached data.';
          debugPrint(_errorMessage);
          return;
        }

        // Simulate a network fetch with a timeout
        await Future.wait([
          _saveData(), // Save merged data to local storage
          Future.delayed(const Duration(milliseconds: 100)), // Simulate network delay
        ]).timeout(_fetchTimeout);

        _errorMessage = null; // Clear error on successful fetch
      } on TimeoutException catch (e) {
        debugPrint('Fetch timeout: $e');
        _errorMessage = 'Fetching data timed out. Displaying cached data.';
      } catch (e) {
        debugPrint('Error fetching data: $e');
        _errorMessage = 'Failed to fetch updated data. Displaying cached data.';
      } finally {
        _isFetchingData = false;
        notifyListeners();
        if (_currentFetchCompleter != null && !_currentFetchCompleter!.isCompleted) {
          _currentFetchCompleter?.complete();
        }
      }
    });
  }

  Future<void> _saveData() async {
    await _localStorageService.saveHabits(_habits);
    await _localStorageService.saveTotalPerfectDays(_totalPerfectDays); // Save total perfect days
    await _localStorageService.saveTotalHabitsCreated(_totalHabitsCreated); // Save total habits created
  }

  Future<void> addHabit(
    String name,
    String color,
    String iconString, // Renamed to iconString to avoid confusion
    bool goalEnabled,
    int? goalValue,
    String? unit, // New parameter for unit
    RepeatType repeatType,
    List<int> repeatDays,
    int repeatDateOfMonth,
    DateTime? targetDate, // Changed from oneTimeDate to targetDate
    TimeOfDayType timeOfDayType,
    DateTime startDate,
    List<TimeOfDay> reminderTimes,
  ) async {
    final newHabit = Habit(
      id: _uuid.v4(),
      name: name,
      color: color,
      icon: CustomIcon.fromSavableString(iconString), // Convert string to CustomIcon
      goalEnabled: goalEnabled,
      goalValue: goalValue,
      unit: unit, // Pass the new unit parameter
      repeatType: repeatType,
      repeatDays: repeatDays,
      repeatDateOfMonth: repeatDateOfMonth,
      targetDate: targetDate, // Use the new targetDate field
      timeOfDayType: timeOfDayType,
      startDate: startDate,
      reminderTimes: reminderTimes,
      completionDates: [], // Completion dates are empty initially
    );
    _habits.add(newHabit);
    _totalHabitsCreated++; // Increment total habits created
    await _saveData();
    try {
      await _notificationService.scheduleHabitReminders(newHabit); // Schedule reminders
    } catch (e) {
      debugPrint('Error scheduling reminders for new habit ${newHabit.id}: $e');
      // Optionally, you could log this error to a crash reporting service
      // or show a non-blocking message to the user.
    }
    notifyListeners(); // Notify listeners about the change
    fetchAndCacheHabits(showLoading: false); // Trigger background sync
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final index = _habits.indexWhere((habit) => habit.id == updatedHabit.id);
    if (index != -1) {
      final oldHabit = _habits[index];
      _habits[index] = updatedHabit;
      await _saveData();
      // Cancel old notifications and schedule new ones if reminder times changed
      if (!listEquals(oldHabit.reminderTimes, updatedHabit.reminderTimes) ||
          oldHabit.startDate != updatedHabit.startDate ||
          oldHabit.repeatType != updatedHabit.repeatType ||
          !listEquals(oldHabit.repeatDays, updatedHabit.repeatDays) ||
          oldHabit.targetDate != updatedHabit.targetDate) { // Check targetDate for changes
        try {
          await _notificationService.cancelHabitReminders(oldHabit.id);
          await _notificationService.scheduleHabitReminders(updatedHabit);
        } catch (e) {
          debugPrint('Error updating reminders for habit ${updatedHabit.id}: $e');
          // Optionally, log this error or show a non-blocking message.
        }
      }
      notifyListeners(); // Notify listeners about the change
      fetchAndCacheHabits(showLoading: false); // Trigger background sync
    }
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((habit) => habit.id == id);
    _totalHabitsCreated--; // Decrement total habits created
    await _saveData();
    try {
      await _notificationService.cancelHabitReminders(id); // Cancel all notifications for this habit
    } catch (e) {
      debugPrint('Error cancelling reminders for habit $id: $e');
      // Optionally, log this error or show a non-blocking message.
    }
    notifyListeners(); // Notify listeners about the change
    fetchAndCacheHabits(showLoading: false); // Trigger background sync
  }

  Future<void> toggleHabitCompletion(Habit habit, DateTime date) async {
    final normalizedDate = MyDateUtils.DateUtils.normalizeDateTime(date); // Normalize the provided date

    // Update habit's completionDates
    // Create a mutable copy of the list to modify
    List<DateTime> updatedCompletionDates = List.from(habit.completionDates);

    final existingCompletionIndex = updatedCompletionDates.indexWhere((d) =>
        MyDateUtils.DateUtils.isSameDay(d, normalizedDate));

    if (existingCompletionIndex != -1) {
      updatedCompletionDates.removeAt(existingCompletionIndex);
    } else {
      updatedCompletionDates.add(normalizedDate);
      updatedCompletionDates.sort((a, b) => a.compareTo(b));
    }
    habit.completionDates = updatedCompletionDates; // Assign the updated list back

    // Update perfect day count
    final bool wasPerfectDay = _isPerfectDay(normalizedDate);
    habit.updateStreak(); // This also updates longestStreak internally
    final bool isNowPerfectDay = _isPerfectDay(normalizedDate);

    if (!wasPerfectDay && isNowPerfectDay) {
      _totalPerfectDays++;
    } else if (wasPerfectDay && !isNowPerfectDay) {
      _totalPerfectDays--;
    }

    // Check for streak freeze usage
    final oldStreak = habit.streak;
    // habit.updateStreak(); // Already called above
    if (habit.streak == oldStreak && habit.lastFreezeDate != null) {
      final daysSinceLastFreeze = DateTime.now().difference(habit.lastFreezeDate!).inDays;
      if (daysSinceLastFreeze <= 1) { // a freeze was just used
        _streakFreezesAvailable--;
        _localStorageService.saveStreakFreezesAvailable(_streakFreezesAvailable);
        // notifyListeners(); // Consider if a specific notification is needed for UI update
      }
    }
    // Recalculate total perfect days after any habit completion change
    _totalPerfectDays = _calculateTotalPerfectDays();

    await _saveData();
    notifyListeners(); // Notify listeners about the change
    fetchAndCacheHabits(showLoading: false); // Trigger background sync
  }

  // Helper to check if a specific habit was completed on a given date
  bool isHabitCompletedOnDate(Habit habit, DateTime date) {
    return habit.isCompletedOn(date);
  }

  // Helper to check if all due habits were completed on a specific date
  bool _isPerfectDay(DateTime date) {
    final normalizedDate = MyDateUtils.DateUtils.normalizeDateTime(date);
    final habitsDueOnDate = _habits.where((habit) => habit.isHabitDueOnDate(normalizedDate)).toList();

    // If there are no habits due on this date, it's considered a perfect day
    // as "all habits in a day are completed" is vacuously true.
    if (habitsDueOnDate.isEmpty) {
      return true;
    }

    for (final habit in habitsDueOnDate) {
      if (!habit.isCompletedOn(normalizedDate)) {
        return false; // At least one due habit was not completed
      }
    }
    return true; // All due habits were completed
  }

  // Calculate the current streak of "perfect days"
  int calculatePerfectDayStreak() {
    if (_habits.isEmpty) {
      return 0;
    }

    int streak = 0;
    DateTime currentDate = MyDateUtils.DateUtils.startOfDay;
    // Find the earliest start date among all habits to optimize the loop
    DateTime earliestHabitStartDate = _habits.map((h) => h.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
    earliestHabitStartDate = MyDateUtils.DateUtils.normalizeDateTime(earliestHabitStartDate);

    while (true) {
      // Stop if we go too far back before any habit started
      if (currentDate.isBefore(earliestHabitStartDate)) {
        break;
      }

      final habitsDueOnDate = _habits.where((habit) => habit.isHabitDueOnDate(currentDate)).toList();

      if (habitsDueOnDate.isEmpty) {
        // If no habits are due on this date, it doesn't break the streak.
        // We simply move to the previous day.
        currentDate = currentDate.subtract(const Duration(days: 1));
        continue;
      }

      if (_isPerfectDay(currentDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        // Streak broken if there were due habits and not all were completed
        break;
      }
    }
    return streak;
  }

  // Calculate total perfect days by iterating through all past days
  int _calculateTotalPerfectDays() {
    if (_habits.isEmpty) {
      return 0;
    }

    int perfectDaysCount = 0;
    // Find the earliest start date among all habits
    DateTime earliestHabitStartDate = _habits.map((h) => h.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
    earliestHabitStartDate = MyDateUtils.DateUtils.normalizeDateTime(earliestHabitStartDate);

    DateTime currentDate = earliestHabitStartDate;
    final DateTime today = MyDateUtils.DateUtils.startOfDay;

    while (currentDate.isBefore(today.add(const Duration(days: 1)))) {
      if (_isPerfectDay(currentDate)) {
        perfectDaysCount++;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    return perfectDaysCount;
  }

  // Calculate the longest perfect day streak
  int calculateLongestPerfectDayStreak() {
    if (_habits.isEmpty) {
      return 0;
    }

    int longestStreak = 0;
    int currentStreak = 0;
    DateTime currentDate = MyDateUtils.DateUtils.startOfDay;
    DateTime earliestHabitStartDate = _habits.map((h) => h.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
    earliestHabitStartDate = MyDateUtils.DateUtils.normalizeDateTime(earliestHabitStartDate);

    while (true) {
      if (currentDate.isBefore(earliestHabitStartDate)) {
        break;
      }

      final habitsDueOnDate = _habits.where((habit) => habit.isHabitDueOnDate(currentDate)).toList();

      if (habitsDueOnDate.isEmpty) {
        // If no habits are due on this date, it doesn't break the streak.
        // We simply move to the previous day and reset currentStreak if it was active.
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
        currentStreak = 0; // Reset streak if there's a gap with no habits
        currentDate = currentDate.subtract(const Duration(days: 1));
        continue;
      }

      if (_isPerfectDay(currentDate)) {
        currentStreak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        // Streak broken
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
        currentStreak = 0;
        currentDate = currentDate.subtract(const Duration(days: 1));
      }
    }
    // After the loop, check if the final currentStreak is the longest
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }
    return longestStreak;
  }

  // Calculate total habits finished this week
  int calculateHabitsFinishedThisWeek(DateTime weekStartDate) {
    final normalizedWeekStartDate = MyDateUtils.DateUtils.normalizeDateTime(weekStartDate);
    int totalCompleted = 0;
    for (final habit in _habits) {
      for (final completionDate in habit.completionDates) {
        final normalizedCompletionDate = MyDateUtils.DateUtils.normalizeDateTime(completionDate);
        if (normalizedCompletionDate.isAfter(normalizedWeekStartDate.subtract(const Duration(days: 1))) &&
            normalizedCompletionDate.isBefore(normalizedWeekStartDate.add(const Duration(days: 7)))) {
          totalCompleted++;
        }
      }
    }
    return totalCompleted;
  }

  // Calculate completion rate for the current week
  double calculateCompletionRate(DateTime weekStartDate) {
    final normalizedWeekStartDate = MyDateUtils.DateUtils.normalizeDateTime(weekStartDate);
    int totalAssigned = 0;
    int totalCompleted = 0;

    for (int i = 0; i < 7; i++) {
      final currentDate = normalizedWeekStartDate.add(Duration(days: i));
      final habitsDueOnDate = _habits.where((habit) => habit.isHabitDueOnDate(currentDate)).toList();
      totalAssigned += habitsDueOnDate.length;

      for (final habit in habitsDueOnDate) {
        if (habit.isCompletedOn(currentDate)) {
          totalCompleted++;
        }
      }
    }

    if (totalAssigned == 0) {
      return 0.0; // Avoid division by zero
    }
    return (totalCompleted / totalAssigned) * 100;
  }

  // Calculate the number of missed habit days in the last 'days'
  int calculateMissedDays(int days) {
    int missedCount = 0;
    final DateTime today = MyDateUtils.DateUtils.startOfDay;

    for (int i = 0; i < days; i++) {
      final currentDate = today.subtract(Duration(days: i));
      final habitsDueOnDate = _habits.where((habit) => habit.isHabitDueOnDate(currentDate)).toList();

      if (habitsDueOnDate.isNotEmpty) {
        final bool allCompleted = habitsDueOnDate.every((habit) => habit.isCompletedOn(currentDate));
        if (!allCompleted) {
          missedCount++;
        }
      }
    }
    return missedCount;
  }

  // Calculate perfect days this week
  int calculatePerfectDaysThisWeek(DateTime weekStartDate) {
    final normalizedWeekStartDate = MyDateUtils.DateUtils.normalizeDateTime(weekStartDate);
    int perfectDays = 0;

    for (int i = 0; i < 7; i++) {
      final currentDate = normalizedWeekStartDate.add(Duration(days: i));
      if (_isPerfectDay(currentDate)) {
        perfectDays++;
      }
    }
    return perfectDays;
  }

  // Calculate total habits completed for a specific day
  int calculateHabitsCompletedToday(DateTime date) {
    final normalizedDate = MyDateUtils.DateUtils.normalizeDateTime(date);
    int completedCount = 0;
    for (final habit in _habits) {
      if (habit.isHabitDueOnDate(normalizedDate) && habit.isCompletedOn(normalizedDate)) {
        completedCount++;
      }
    }
    return completedCount;
  }

  // Calculate monthly completion rate
  double calculateMonthlyCompletionRate(DateTime monthStartDate) {
    final normalizedMonthStartDate = MyDateUtils.DateUtils.normalizeDateTime(monthStartDate);
    int totalAssigned = 0;
    int totalCompleted = 0;

    // Iterate through all days of the month
    for (int i = 0; i < MyDateUtils.DateUtils.daysInMonth(normalizedMonthStartDate); i++) {
      final currentDate = normalizedMonthStartDate.add(Duration(days: i));
      final habitsDueOnDate = _habits.where((habit) => habit.isHabitDueOnDate(currentDate)).toList();
      totalAssigned += habitsDueOnDate.length;

      for (final habit in habitsDueOnDate) {
        if (habit.isCompletedOn(currentDate)) {
          totalCompleted++;
        }
        }
    }

    if (totalAssigned == 0) {
      return 0.0; // Avoid division by zero
    }
    return (totalCompleted / totalAssigned) * 100;
  }

  // Calculate overall completion rate
  double calculateOverallCompletionRate() {
    int totalAssigned = 0;
    int totalCompleted = 0;

    for (final habit in _habits) {
      // Iterate from habit's start date up to today
      for (DateTime d = MyDateUtils.DateUtils.normalizeDateTime(habit.startDate);
          d.isBefore(MyDateUtils.DateUtils.startOfDay.add(const Duration(days: 1)));
          d = d.add(const Duration(days: 1))) {
        if (habit.isHabitDueOnDate(d)) {
          totalAssigned++;
          if (habit.isCompletedOn(d)) {
            totalCompleted++;
          }
        }
      }
    }

    if (totalAssigned == 0) {
      return 0.0; // Avoid division by zero
    }
    return (totalCompleted / totalAssigned) * 100;
  }

  // Helper to calculate total days with at least one due habit
  int _calculateTotalDaysWithDueHabits() {
    if (_habits.isEmpty) {
      return 0;
    }

    final Set<DateTime> daysWithDueHabits = {};
    DateTime earliestHabitStartDate = _habits.map((h) => h.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
    earliestHabitStartDate = MyDateUtils.DateUtils.normalizeDateTime(earliestHabitStartDate);
    final DateTime today = MyDateUtils.DateUtils.startOfDay;

    for (DateTime d = earliestHabitStartDate;
        d.isBefore(today.add(const Duration(days: 1)));
        d = d.add(const Duration(days: 1))) {
      final habitsDueOnDate = _habits.where((habit) => habit.isHabitDueOnDate(d)).toList();
      if (habitsDueOnDate.isNotEmpty) {
        daysWithDueHabits.add(d);
      }
    }
    return daysWithDueHabits.length;
  }

  // Calculate consistency percentage = (days completed ÷ total days tracked) × 100
  double calculateConsistencyScore() {
    final int totalPerfectDays = _calculateTotalPerfectDays();
    final int totalDaysWithDueHabits = _calculateTotalDaysWithDueHabits();

    if (totalDaysWithDueHabits == 0) {
      return 0.0; // Avoid division by zero
    }
    return (totalPerfectDays / totalDaysWithDueHabits) * 100;
  }

  // --- Habit-specific History Methods ---

  // Calculate the current streak for a specific habit
  int calculateHabitStreak(String habitId) {
    final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => throw Exception('Habit not found'));
    return habit.streak; // Habit model already calculates and stores its streak
  }

  // Calculate total times a specific habit was finished this week
  int calculateHabitFinishedThisWeek(String habitId, DateTime weekStartDate) {
    final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => throw Exception('Habit not found'));
    final normalizedWeekStartDate = MyDateUtils.DateUtils.normalizeDateTime(weekStartDate);
    int completedCount = 0;
    for (final completionDate in habit.completionDates) {
      final normalizedCompletionDate = MyDateUtils.DateUtils.normalizeDateTime(completionDate);
      if (normalizedCompletionDate.isAfter(normalizedWeekStartDate.subtract(const Duration(days: 1))) &&
          normalizedCompletionDate.isBefore(normalizedWeekStartDate.add(const Duration(days: 7)))) {
        completedCount++;
      }
    }
    return completedCount;
  }

  // Calculate completion rate for a specific habit for the current week
  double calculateCompletionRateForHabit(String habitId, DateTime weekStartDate) {
    final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => throw Exception('Habit not found'));
    final normalizedWeekStartDate = MyDateUtils.DateUtils.normalizeDateTime(weekStartDate);
    int totalAssigned = 0;
    int totalCompleted = 0;

    for (int i = 0; i < 7; i++) {
      final currentDate = normalizedWeekStartDate.add(Duration(days: i));
      if (habit.isHabitDueOnDate(currentDate)) {
        totalAssigned++;
        if (habit.isCompletedOn(currentDate)) {
          totalCompleted++;
        }
      }
    }

    if (totalAssigned == 0) {
      return 0.0;
    }
    return (totalCompleted / totalAssigned) * 100;
  }

  // Calculate perfect days for a specific habit this week (i.e., days the habit was due and completed)
  int calculatePerfectDaysForHabitThisWeek(String habitId, DateTime weekStartDate) {
    final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => throw Exception('Habit not found'));
    final normalizedWeekStartDate = MyDateUtils.DateUtils.normalizeDateTime(weekStartDate);
    int perfectDays = 0;

    for (int i = 0; i < 7; i++) {
      final currentDate = normalizedWeekStartDate.add(Duration(days: i));
      if (habit.isHabitDueOnDate(currentDate) && habit.isCompletedOn(currentDate)) {
        perfectDays++;
      }
    }
    return perfectDays;
  }

  // Calculate monthly completion rate for a specific habit
  double calculateMonthlyCompletionRateForHabit(String habitId, DateTime monthStartDate) {
    final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => throw Exception('Habit not found'));
    final normalizedMonthStartDate = MyDateUtils.DateUtils.normalizeDateTime(monthStartDate);
    int totalAssigned = 0;
    int totalCompleted = 0;

    for (int i = 0; i < MyDateUtils.DateUtils.daysInMonth(normalizedMonthStartDate); i++) {
      final currentDate = normalizedMonthStartDate.add(Duration(days: i));
      if (habit.isHabitDueOnDate(currentDate)) {
        totalAssigned++;
        if (habit.isCompletedOn(currentDate)) {
          totalCompleted++;
        }
      }
    }

    if (totalAssigned == 0) {
      return 0.0;
    }
    return (totalCompleted / totalAssigned) * 100;
  }

  // Calculate overall completion rate for a specific habit
  double calculateOverallCompletionRateForHabit(String habitId) {
    final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => throw Exception('Habit not found'));
    int totalAssigned = 0;
    int totalCompleted = 0;

    for (DateTime d = MyDateUtils.DateUtils.normalizeDateTime(habit.startDate);
        d.isBefore(MyDateUtils.DateUtils.startOfDay.add(const Duration(days: 1)));
        d = d.add(const Duration(days: 1))) {
      if (habit.isHabitDueOnDate(d)) {
        totalAssigned++;
        if (habit.isCompletedOn(d)) {
          totalCompleted++;
        }
      }
    }

    if (totalAssigned == 0) {
      return 0.0;
    }
    return (totalCompleted / totalAssigned) * 100;
  }

  // Calculate perfect day streak for a specific month
  int calculatePerfectDayStreakForMonth(DateTime month) {
    int streak = 0;
    DateTime currentDate = MyDateUtils.DateUtils.normalizeDateTime(month);
    // Go to the last day of the month
    currentDate = DateTime(currentDate.year, currentDate.month, MyDateUtils.DateUtils.daysInMonth(currentDate));

    // Find the earliest start date among all habits to optimize the loop
    DateTime? earliestHabitStartDate;
    if (_habits.isNotEmpty) {
      earliestHabitStartDate = _habits.map((h) => h.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
      earliestHabitStartDate = MyDateUtils.DateUtils.normalizeDateTime(earliestHabitStartDate);
    }


    while (MyDateUtils.DateUtils.isSameMonth(currentDate, month)) {
      // Stop if we go too far back before any habit started
      if (earliestHabitStartDate != null && currentDate.isBefore(earliestHabitStartDate)) {
        break;
      }

      final habitsDueOnDate = _habits.where((habit) => habit.isHabitDueOnDate(currentDate)).toList();

      if (habitsDueOnDate.isEmpty) {
        // If no habits are due on this date, it doesn't break the streak.
        // We simply move to the previous day.
        currentDate = currentDate.subtract(const Duration(days: 1));
        continue;
      }

      if (_isPerfectDay(currentDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        // Streak broken if there were due habits and not all were completed
        break;
      }
    }
    return streak;
  }

  // Calculate total number of times habits were completed
  int calculateTotalCompletedHabits() {
    int totalCompleted = 0;
    for (final habit in _habits) {
      totalCompleted += habit.completionDates.length;
    }
    return totalCompleted;
  }

  // Calculate total number of times habits were skipped (due but not completed)
  int calculateTotalSkippedHabits() {
    int totalSkipped = 0;
    final DateTime today = MyDateUtils.DateUtils.startOfDay;

    for (final habit in _habits) {
      // Iterate from habit's start date up to yesterday
      for (DateTime d = MyDateUtils.DateUtils.normalizeDateTime(habit.startDate);
          d.isBefore(today);
          d = d.add(const Duration(days: 1))) {
        if (habit.isHabitDueOnDate(d) && !habit.isCompletedOn(d)) {
          totalSkipped++;
        }
      }
    }
    return totalSkipped;
  }

  // Calculate total number of habits currently in progress (due today but not completed)
  int calculateTotalInProgressHabits() {
    int inProgressCount = 0;
    final DateTime today = MyDateUtils.DateUtils.startOfDay;

    for (final habit in _habits) {
      if (habit.isHabitDueOnDate(today) && !habit.isCompletedOn(today)) {
        inProgressCount++;
      }
    }
    return inProgressCount;
  }

  // Calculate total number of times a specific habit was completed
  int calculateHabitTotalCompletionCount(String habitId) {
    final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => throw Exception('Habit not found'));
    return habit.completionDates.length;
  }

  // Determine the overall habit status for the "light/active" box
  String getOverallHabitStatus() {
    final DateTime today = MyDateUtils.DateUtils.startOfDay;
    final List<Habit> habitsDueToday = _habits.where((habit) => habit.isHabitDueOnDate(today)).toList();

    if (habitsDueToday.isEmpty) {
      return 'No Habits Due'; // No habits due today
    }

    final bool allCompleted = habitsDueToday.every((habit) => habit.isCompletedOn(today));

    if (allCompleted) {
      return 'Light'; // All due habits completed
    } else {
      return 'Active'; // At least one due habit not completed
    }
  }
  // Group habits by completion date for calendar view
  Map<DateTime, List<Habit>> getGroupedHabitsByCompletionDate() {
    final Map<DateTime, List<Habit>> grouped = {};
    for (final habit in _habits) {
      for (final completionDate in habit.completionDates) {
        final normalizedDate = MyDateUtils.DateUtils.normalizeDateTime(completionDate);
        grouped.putIfAbsent(normalizedDate, () => []).add(habit);
      }
    }
    return grouped;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _currentFetchCompleter?.completeError('Service disposed');
    super.dispose();
  }
}
