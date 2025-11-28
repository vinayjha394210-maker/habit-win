import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_win/services/habit_service.dart';
import 'package:habit_win/models/habit.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:habit_win/utils/date_utils.dart' as my_date_utils;
import 'package:habit_win/utils/app_colors.dart';

class HabitHistoryTab extends StatefulWidget {
  final DateTime initialSelectedDate;

  const HabitHistoryTab({super.key, required this.initialSelectedDate});

  @override
  State<HabitHistoryTab> createState() => _HabitHistoryTabState();
}

class _HabitHistoryTabState extends State<HabitHistoryTab>
    with AutomaticKeepAliveClientMixin {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late final PageController _pageController; // Declare PageController

  @override
  void initState() {
    super.initState();
    _selectedDay = my_date_utils.DateUtils.normalizeDateTime(widget.initialSelectedDate);
    _focusedDay = _selectedDay;
  }

  @override
  void dispose() {
    // _pageController.dispose(); // Dispose only if initialized
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  my_date_utils.DayCompletionStatus _getDayCompletionStatus(
    DateTime day,
    List<Habit> habits,
  ) {
    final normalizedDay = my_date_utils.DateUtils.normalizeDateTime(day);
    int completedHabitsCount = 0;
    int dueHabitsCount = 0;

    for (final habit in habits) {
      if (habit.isHabitDueOnDate(normalizedDay)) {
        dueHabitsCount++;
        if (habit.isCompletedOn(normalizedDay)) {
          completedHabitsCount++;
        }
      }
    }

    if (dueHabitsCount == 0) {
      return my_date_utils.DayCompletionStatus.none;
    } else if (completedHabitsCount == dueHabitsCount) {
      return my_date_utils.DayCompletionStatus.perfect;
    } else if (completedHabitsCount > 0) {
      return my_date_utils.DayCompletionStatus.partial;
    } else {
      return my_date_utils.DayCompletionStatus.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<HabitService>(
      builder: (context, habitService, child) {
        final List<Habit> habits = habitService.habits;

        return SingleChildScrollView(
          key: const PageStorageKey<String>('HabitHistoryTabScroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMM().format(_focusedDay),
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Visibility(
                      visible: !my_date_utils.DateUtils.isSameMonth(
                              _focusedDay, DateTime.now()) ||
                          !my_date_utils.DateUtils.isSameDay(
                              _selectedDay, DateTime.now()),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _focusedDay = my_date_utils.DateUtils.normalizeDateTime(DateTime.now());
                            _selectedDay = _focusedDay;
                          });
                          if (mounted && _pageController.hasClients) {
                            _pageController.jumpToPage(
                                (_pageController.page!).toInt() +
                                    my_date_utils.DateUtils.getMonthsDifference(
                                        _focusedDay, DateTime.now()));
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          alignment: Alignment.centerRight,
                        ),
                        child: Text(
                          'Today',
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return my_date_utils.DateUtils.isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = my_date_utils.DateUtils.normalizeDateTime(selectedDay);
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final status = _getDayCompletionStatus(day, habits);
                    Color? dotColor;
                    switch (status) {
                      case my_date_utils.DayCompletionStatus.perfect:
                        dotColor = AppColors.greenSuccess;
                        break;
                      case my_date_utils.DayCompletionStatus.partial:
                        dotColor = AppColors.yellowWarning;
                        break;
                      case my_date_utils.DayCompletionStatus.none:
                        dotColor = null;
                        break;
                    }
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${day.day}', style: textTheme.bodyMedium),
                          if (dotColor != null)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              height: 6,
                              width: 6,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
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
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '${day.day}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.primary),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '${day.day}',
                        style: textTheme.bodyMedium,
                      ),
                    );
                  },
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: textTheme.bodyMedium!.copyWith(
                    color: Colors.grey,
                  ),
                  defaultTextStyle: textTheme.bodyMedium!,
                  todayDecoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  selectedDecoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onCalendarCreated: (controller) => _pageController = controller, // Initialize _pageController
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
