import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_win/services/habit_service.dart';
import 'package:habit_win/models/habit.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:habit_win/utils/date_utils.dart' as date_utils;
import 'package:habit_win/widgets/history_card_widget.dart';
import 'package:habit_win/utils/custom_icons.dart'; // Import CustomIcon

class HabitHistoryScreen extends StatefulWidget {
  final Habit habit;
  final DateTime selectedDate;

  const HabitHistoryScreen({
    super.key,
    required this.habit,
    required this.selectedDate,
  });

  @override
  State<HabitHistoryScreen> createState() => _HabitHistoryScreenState();
}

class _HabitHistoryScreenState extends State<HabitHistoryScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = date_utils.DateUtils.normalizeDateTime(widget.selectedDate);
    _focusedDay = _selectedDay;
  }

  // Helper function to get habits due on a given day
  List<Habit> _getHabitsDueOnDay(DateTime day, List<Habit> allHabits) {
    return allHabits.where((habit) => habit.isHabitDueOnDate(day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.habit.name} History',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: CustomIcon.material(Icons.arrow_back).toWidget(),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<HabitService>(
        builder: (context, habitService, child) {
          // We only care about the specific habit passed to this screen
          final Habit currentHabit = widget.habit;

          // Calculate history data using HabitService, but scoped to currentHabit
          final int currentStreak = habitService.calculateHabitStreak(currentHabit.id);
          final int totalCompletionCount = habitService.calculateHabitTotalCompletionCount(currentHabit.id); // New metric
          final String overallCompletionRate = '${habitService.calculateOverallCompletionRateForHabit(currentHabit.id).round()}%';

          // Function to show detailed daily report for the specific habit
          void showDailyReportDialog(DateTime day) {
            final normalizedDay = date_utils.DateUtils.normalizeDateTime(day);
            final bool isDue = currentHabit.isHabitDueOnDate(normalizedDay);
            final bool isCompleted = currentHabit.isCompletedOn(normalizedDay);

            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    'Habit Status for ${DateFormat.yMMMd().format(day)}',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Habit: ${currentHabit.name}'),
                      const SizedBox(height: 8),
                      Text('Due on this day: ${isDue ? 'Yes' : 'No'}'),
                      if (isDue)
                        Text('Completed: ${isCompleted ? 'Yes' : 'No'}',
                          style: TextStyle(color: isCompleted ? Colors.green : Colors.red),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 420, // Fixed height for the calendar
                    child: AbsorbPointer( // Absorb pointer events to prevent internal calendar scrolling
                      child: TableCalendar(
                        firstDay: DateTime.utc(2000, 1, 1),
                        lastDay: DateTime.utc(2050, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        calendarFormat: _calendarFormat,
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!isSameDay(_selectedDay, selectedDay)) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: textTheme.titleLarge!.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                          leftChevronIcon: CustomIcon.material(Icons.chevron_left).toWidget(defaultColor: colorScheme.onSurface),
                          rightChevronIcon: CustomIcon.material(Icons.chevron_right).toWidget(defaultColor: colorScheme.onSurface),
                          decoration: BoxDecoration(
                            color: colorScheme.surface, // Header background
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withAlpha(13),
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
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            final dayStatus = _getDayCompletionStatus(day, currentHabit);
                            Color textColor = colorScheme.onSurface;
                            Color? backgroundColor;
                            BoxBorder? border;

                            if (dayStatus == date_utils.DayCompletionStatus.perfect) {
                              textColor = colorScheme.primary;
                            } else if (dayStatus == date_utils.DayCompletionStatus.none && currentHabit.isHabitDueOnDate(day) && day.isBefore(date_utils.DateUtils.normalizeDateTime(DateTime.now()))) {
                              textColor = colorScheme.error;
                            } else if (!currentHabit.isHabitDueOnDate(day)) {
                              textColor = colorScheme.onSurface.withAlpha((255 * 0.3).round());
                            }

                            if (dayStatus == date_utils.DayCompletionStatus.perfect && day.isBefore(date_utils.DateUtils.startOfDay.add(const Duration(days: 1)))) {
                              backgroundColor = colorScheme.primary.withOpacity(0.1);
                            }

                            if (isSameDay(day, _selectedDay)) {
                              backgroundColor = colorScheme.primary;
                              textColor = colorScheme.onPrimary;
                            } else if (isSameDay(day, date_utils.DateUtils.normalizeDateTime(DateTime.now()))) {
                              border = Border.all(color: colorScheme.primary, width: 1.5);
                            }

                            return GestureDetector(
                              onLongPress: () => showDailyReportDialog(day),
                              child: Container(
                                margin: const EdgeInsets.all(4.0), // Reduced margin
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
                              ), // Closing parenthesis for Container
                            ); // Closing parenthesis for GestureDetector
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
                            final status = _getDayCompletionStatus(day, currentHabit);
                            Color textColor = colorScheme.onSurface;
                            Color? backgroundColor;
                            BoxBorder? border = Border.all(color: colorScheme.primary, width: 1.5);

                            if (status == date_utils.DayCompletionStatus.perfect) {
                              textColor = colorScheme.primary;
                            } else if (status == date_utils.DayCompletionStatus.none && currentHabit.isHabitDueOnDate(day) && day.isBefore(date_utils.DateUtils.normalizeDateTime(DateTime.now()))) {
                              textColor = colorScheme.error;
                            } else if (!currentHabit.isHabitDueOnDate(day)) {
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
                            final status = _getDayCompletionStatus(day, currentHabit);
                            if ((status == date_utils.DayCompletionStatus.perfect ||
                                (status == date_utils.DayCompletionStatus.none &&
                                    currentHabit.isHabitDueOnDate(day) &&
                                    day.isBefore(date_utils.DateUtils.normalizeDateTime(DateTime.now())))) &&
                                !isSameDay(day, _selectedDay)) {
                              return Positioned(
                                left: 1,
                                right: 1,
                                bottom: 1,
                                child: _buildHabitMarker(context, day, status),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0), // Increased spacing
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10.0, // Horizontal spacing
                  runSpacing: 10.0, // Vertical spacing
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _focusedDay = date_utils.DateUtils.normalizeDateTime(DateTime.now());
                          _selectedDay = _focusedDay;
                        });
                      },
                      child: const Text('Jump to Today'),
                    ),
                    SegmentedButton<CalendarFormat>(
                      segments: const <ButtonSegment<CalendarFormat>>[
                        ButtonSegment<CalendarFormat>(
                          value: CalendarFormat.month,
                          label: Text('Month'),
                        ),
                        ButtonSegment<CalendarFormat>(
                          value: CalendarFormat.week,
                          label: Text('Week'),
                        ),
                      ],
                      selected: <CalendarFormat>{_calendarFormat},
                      onSelectionChanged: (Set<CalendarFormat> newSelection) {
                        setState(() {
                          _calendarFormat = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // History Widgets
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2, // Two cards per row
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      HistoryCardWidget(
                        title: 'CURRENT STREAK',
                        value: currentStreak.toString(),
                        subtitle: 'Perfect Days Streak',
                        icon: CustomIcon.material(Icons.local_fire_department), // Updated to CustomIcon.material
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      HistoryCardWidget(
                        title: 'HABIT FINISH',
                        value: totalCompletionCount.toString(),
                        subtitle: 'Total Completions',
                        icon: CustomIcon.material(Icons.check_circle_outline), // Updated to CustomIcon.material
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      HistoryCardWidget(
                        title: 'COMPLETION RATE',
                        value: overallCompletionRate,
                        subtitle: 'Overall for this habit',
                        icon: CustomIcon.material(Icons.percent), // Updated to CustomIcon.material
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (habitService.isFetchingData)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(),
                  ),
                if (habitService.errorMessage != null)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          habitService.errorMessage!,
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Implement retry logic here, e.g., habitService.fetchData();
                        },
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                Column(
                    children: [
                      const SizedBox(height: 16.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Habits for ${DateFormat.yMMMd().format(_selectedDay)}',
                          style: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _getHabitsDueOnDay(_selectedDay, habitService.habits).length,
                        itemBuilder: (context, index) {
                          final habit = _getHabitsDueOnDay(_selectedDay, habitService.habits)[index];
                          final isCompleted = habit.isCompletedOn(_selectedDay);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                  habitService.toggleHabitCompletion(habit, _selectedDay);
                                },
                                activeColor: colorScheme.primary,
                                checkColor: colorScheme.onPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  date_utils.DayCompletionStatus _getDayCompletionStatus(DateTime day, Habit habit) {
    final normalizedDay = date_utils.DateUtils.normalizeDateTime(day);
    if (habit.isCompletedOn(normalizedDay)) {
      return date_utils.DayCompletionStatus.perfect;
    } else if (habit.isHabitDueOnDate(normalizedDay) && normalizedDay.isBefore(date_utils.DateUtils.normalizeDateTime(DateTime.now()))) {
      return date_utils.DayCompletionStatus.none;
    }
    return date_utils.DayCompletionStatus.none; // Default or other status if needed
  }

  Widget _buildHabitMarker(BuildContext context, DateTime date, date_utils.DayCompletionStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    Color markerColor;
    BoxBorder? markerBorder;

    if (status == date_utils.DayCompletionStatus.perfect) {
      markerColor = colorScheme.primary;
      markerBorder = null;
    } else {
      markerColor = Colors.transparent;
      markerBorder = Border.all(color: colorScheme.error, width: 1.0);
    }

    return Container(
      width: 7.0,
      height: 7.0,
      margin: const EdgeInsets.symmetric(horizontal: 1.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: markerColor,
        border: markerBorder,
      ),
    );
  }
}
