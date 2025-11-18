import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:habit_win/utils/custom_icons.dart'; // Import CustomIcon
import 'package:provider/provider.dart';
import '../services/habit_service.dart';
import '../models/habit.dart';
import '../utils/date_utils.dart' as my_date_utils;
class HabitCalendarWidget extends StatefulWidget {
  const HabitCalendarWidget({super.key});

  @override
  State<HabitCalendarWidget> createState() => _HabitCalendarWidgetState();
}

class _HabitCalendarWidgetState extends State<HabitCalendarWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  // Track the current month's perfect day streak
  int _currentMonthPerfectDayStreak = 0;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _updateMonthStreak();
  }

  @override
  void didUpdateWidget(covariant HabitCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate streak if focused day changes to a new month
    // The comparison should be done with the current _focusedDay and the previous _focusedDay value
    // However, _focusedDay is a state variable, so we can't directly access oldWidget._focusedDay.
    // The onPageChanged callback already updates _focusedDay, so we can rely on that.
    // For now, I'll remove this check and rely on onPageChanged to trigger updates if needed.
    // A more robust solution might involve passing a callback to onPageChanged to trigger streak updates.
  }

  void _updateMonthStreak() {
    // This will be called when the month changes or on initial load
    final habitService = Provider.of<HabitService>(context, listen: false);
    setState(() {
      _currentMonthPerfectDayStreak = habitService.calculatePerfectDayStreakForMonth(_focusedDay);
    });
  }

  // Helper function to get habits due on a given day
  List<Habit> _getHabitsDueOnDay(DateTime day, List<Habit> allHabits) {
    return allHabits.where((habit) => habit.isHabitDueOnDate(day)).toList();
  }

  // Determine the status of a given day: completed, missed, or not scheduled
  String _getDayStatus(DateTime day, List<Habit> allHabits, HabitService habitService) {
    final normalizedDay = my_date_utils.DateUtils.normalizeDateTime(day);
    final habitsDue = _getHabitsDueOnDay(normalizedDay, allHabits);

    if (habitsDue.isEmpty) {
      // If it's a future date and no habits are scheduled, it's empty
      if (normalizedDay.isAfter(my_date_utils.DateUtils.startOfDay)) {
        return ''; // Not scheduled for future dates
      }
      return '–'; // Not scheduled for past/current dates
    }

    bool allCompleted = true;
    for (final habit in habitsDue) {
      if (!habitService.isHabitCompletedOnDate(habit, normalizedDay)) {
        allCompleted = false;
        break;
      }
    }

    if (allCompleted) {
      return '✔'; // All scheduled habits completed
    } else {
      return '✘'; // At least one scheduled habit missed
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<HabitService>(
      builder: (context, habitService, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await habitService.fetchAndCacheHabits();
          },
          child: Column(
            children: [
              if (habitService.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    habitService.errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (habitService.isFetchingData)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                ),
              TableCalendar(
                firstDay: DateTime.utc(DateTime.now().year - 10, 1, 1),
                lastDay: DateTime.utc(DateTime.now().year + 10, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (mounted) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    if (mounted) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _updateMonthStreak();
                },
                daysOfWeekHeight: 25.0, // Increased height for day labels
                eventLoader: (day) => _getHabitsDueOnDay(day, habitService.habits),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final dayStatus = _getDayStatus(day, habitService.habits, habitService);
                    Color textColor = colorScheme.onSurface;
                    Color? backgroundColor;
                    BoxBorder? border;

                    if (dayStatus == '✔') {
                      textColor = colorScheme.primary;
                    } else if (dayStatus == '✘') {
                      textColor = colorScheme.error;
                    } else if (dayStatus == '–') {
                      textColor = colorScheme.onSurface.withAlpha((255 * 0.5).round());
                    } else if (dayStatus == '') {
                      textColor = colorScheme.onSurface.withAlpha((255 * 0.3).round());
                    }

                    if (dayStatus == '✔' && day.isBefore(my_date_utils.DateUtils.startOfDay.add(const Duration(days: 1)))) {
                      backgroundColor = colorScheme.primary.withAlpha((255 * 0.1).round());
                    }

                    if (isSameDay(day, _selectedDay)) {
                      backgroundColor = colorScheme.primary;
                      textColor = colorScheme.onPrimary;
                    } else if (isSameDay(day, my_date_utils.DateUtils.normalizeDateTime(DateTime.now()))) {
                      border = Border.all(color: colorScheme.primary, width: 1.5);
                    }

                    return Container(
                      margin: const EdgeInsets.all(4.0), // Reduced margin
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                        border: border,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: textTheme.bodyLarge?.copyWith(
                              color: textColor,
                              fontWeight: isSameDay(day, _selectedDay) ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (dayStatus != '' && dayStatus != '–' && !isSameDay(day, _selectedDay)) // Only show marker for scheduled days, not selected
                            Text(
                              dayStatus,
                              style: textTheme.bodySmall?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final dayStatus = _getDayStatus(day, habitService.habits, habitService);
                    Color textColor = colorScheme.onSurface;
                    Color? backgroundColor;
                    BoxBorder? border = Border.all(color: colorScheme.primary, width: 1.5);

                    if (dayStatus == '✔') {
                      textColor = colorScheme.primary;
                    } else if (dayStatus == '✘') {
                      textColor = colorScheme.error;
                    } else if (dayStatus == '–') {
                      textColor = colorScheme.onSurface.withAlpha((255 * 0.5).round());
                    } else if (dayStatus == '') {
                      textColor = colorScheme.onSurface.withAlpha((255 * 0.3).round());
                    }

                    if (isSameDay(day, _selectedDay)) {
                      backgroundColor = colorScheme.primary;
                      textColor = colorScheme.onPrimary;
                      border = null; // No border if selected
                    } else {
                      backgroundColor = colorScheme.primaryContainer; // Softer background for today
                    }

                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                        border: border,
                      ),
                      child: Text(
                        '${day.day}',
                        style: textTheme.bodyLarge?.copyWith(
                          color: textColor,
                          fontWeight: isSameDay(day, _selectedDay) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                  markerBuilder: (context, day, events) {
                    final habitsDueOnDay = _getHabitsDueOnDay(day, Provider.of<HabitService>(context, listen: false).habits);
                    if (habitsDueOnDay.isNotEmpty && !isSameDay(day, _selectedDay)) { // Only show markers if not selected day
                      return Positioned(
                        left: 1,
                        right: 1,
                        bottom: 1,
                        child: _buildHabitMarkers(context, day, habitsDueOnDay),
                      );
                    }
                    return null;
                  },
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleTextFormatter: (date, locale) {
                    final monthYear = my_date_utils.DateUtils.formatMonthYear(date);
                    return '$monthYear (Streak: $_currentMonthPerfectDayStreak days)';
                  },
                  titleCentered: true,
                  titleTextStyle: textTheme.titleLarge!.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                  leftChevronIcon: CustomIcon.material(Icons.chevron_left).toWidget(defaultColor: colorScheme.onSurface),
                  rightChevronIcon: CustomIcon.material(Icons.chevron_right).toWidget(defaultColor: colorScheme.onSurface),
                  decoration: BoxDecoration(
                    color: colorScheme.surface, // Header background
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withAlpha((255 * 0.05).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  headerPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: textTheme.bodyLarge!.copyWith(color: colorScheme.onSurface.withAlpha((255 * 0.6).round())),
                  defaultTextStyle: textTheme.bodyLarge!.copyWith(color: colorScheme.onSurface),
                  todayTextStyle: textTheme.bodyLarge!.copyWith(color: colorScheme.onSurface),
                  selectedTextStyle: textTheme.bodyLarge!.copyWith(color: colorScheme.onPrimary),
                  tableBorder: TableBorder.symmetric(
                    inside: BorderSide(color: colorScheme.outline.withAlpha((255 * 0.3).round()), width: 0.5),
                  ),
                  cellMargin: const EdgeInsets.all(2.0),
                ),
              ),
              const SizedBox(height: 16.0), // Increased spacing
              // Display habits for the selected day
              _selectedDay != null
                  ? Expanded(
                      child: Builder(
                        builder: (context) {
                          final habitsForSelectedDay = _getHabitsDueOnDay(_selectedDay!, habitService.habits);
                          if (habitsForSelectedDay.isEmpty) {
                            return Center(
                              child: Text(
                                'No habits scheduled for this day.',
                                style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withAlpha((255 * 0.7).round())),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: habitsForSelectedDay.length,
                            itemBuilder: (context, index) {
                              final habit = habitsForSelectedDay[index];
                              final isCompleted = habit.isCompletedOn(_selectedDay!);
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Consistent margin
                                elevation: 4,
                                shadowColor: colorScheme.shadow.withAlpha((255 * 0.08).round()),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                                child: ListTile(
                                  title: Text(
                                    habit.name,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isCompleted ? 'Completed' : 'Missed',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: isCompleted ? colorScheme.primary : colorScheme.error,
                                    ),
                                  ),
                                  trailing: Checkbox(
                                    value: isCompleted,
                                    onChanged: (value) {
                                      habitService.toggleHabitCompletion(habit, _selectedDay!);
                                    },
                                    activeColor: colorScheme.primary,
                                    checkColor: colorScheme.onPrimary,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHabitMarkers(BuildContext context, DateTime date, List<Habit> habitsDueOnDay) {
    final colorScheme = Theme.of(context).colorScheme;
    final habitService = Provider.of<HabitService>(context, listen: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: habitsDueOnDay.map((habit) {
        final isCompleted = habitService.isHabitCompletedOnDate(habit, date);
        return Container(
          width: 7.0,
          height: 7.0,
          margin: const EdgeInsets.symmetric(horizontal: 1.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? colorScheme.primary : Colors.transparent,
            border: Border.all(
              color: isCompleted ? colorScheme.primary : colorScheme.onSurface.withAlpha((255 * 0.5).round()),
              width: 1.0,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Helper to check if two lists are equal (for reminderTimes comparison)
  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
