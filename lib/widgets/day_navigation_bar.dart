import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/date_utils.dart' as date_utils;
import 'package:provider/provider.dart'; // Import provider
import '../services/habit_service.dart'; // Import HabitService
import '../utils/debounce_utils.dart'; // Import Debouncer

class DayNavigationBar extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  const DayNavigationBar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<DayNavigationBar> createState() => _DayNavigationBarState();
}

class _DayNavigationBarState extends State<DayNavigationBar> {
  late ScrollController _scrollController;
  late DateTime
  _currentVisibleWeekStart; // Track the start of the week currently visible
  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 300),
  );
  // Define a range of days to display (e.g., 1 year before and 1 year after today)
  static const int _daysToDisplayBefore = 365;
  static const int _daysToDisplayAfter = 365;
  late List<DateTime> _allDates;
  late List<List<DateTime>> _weeks; // Grouped weeks

  @override
  void initState() {
    super.initState();
    _initializeDatesAndWeeks();
    _scrollController = ScrollController();
    _currentVisibleWeekStart = date_utils.DateUtils.startOfWeek(
      widget.selectedDate,
    );

    // Scroll to the selected date after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedWeek(animate: false);
    });
  }

  void _initializeDatesAndWeeks() {
    final today = date_utils.DateUtils.normalizeDateTime(DateTime.now());
    final startDate = today.subtract(
      const Duration(days: _daysToDisplayBefore),
    );
    final endDate = today.add(const Duration(days: _daysToDisplayAfter));

    _allDates = [];
    for (
      DateTime d = startDate;
      d.isBefore(endDate) || date_utils.DateUtils.isSameDay(d, endDate);
      d = d.add(const Duration(days: 1))
    ) {
      _allDates.add(d);
    }

    _weeks = [];
    List<DateTime> currentWeek = [];
    for (int i = 0; i < _allDates.length; i++) {
      final date = _allDates[i];
      if (currentWeek.isEmpty ||
          date_utils.DateUtils.startOfWeek(date) ==
              date_utils.DateUtils.startOfWeek(currentWeek.last)) {
        currentWeek.add(date);
      } else {
        _weeks.add(currentWeek);
        currentWeek = [date];
      }
      if (i == _allDates.length - 1) {
        _weeks.add(currentWeek);
      }
    }
  }

  @override
  void didUpdateWidget(covariant DayNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!date_utils.DateUtils.isSameDay(
      widget.selectedDate,
      oldWidget.selectedDate,
    )) {
      _scrollToSelectedWeek(animate: true);
      setState(() {
        _currentVisibleWeekStart = date_utils.DateUtils.startOfWeek(
          widget.selectedDate,
        );
      });
    }
  }

  void _scrollToSelectedWeek({bool animate = true}) {
    final int selectedWeekIndex = _weeks.indexWhere(
      (week) => week.any(
        (date) => date_utils.DateUtils.isSameDay(date, widget.selectedDate),
      ),
    );

    if (selectedWeekIndex != -1) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double offset =
          selectedWeekIndex * screenWidth; // Each week takes full screen width

      if (animate) {
        _scrollController.animateTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollController.jumpTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = date_utils.DateUtils.normalizeDateTime(DateTime.now());
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dayItemWidth =
        screenWidth / 7; // Each day takes 1/7th of the screen width

    return SizedBox(
      height:
          120, // Increased height to accommodate the upward shift of today's date
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo is ScrollEndNotification) {
                final int currentWeekIndex =
                    (_scrollController.offset / screenWidth).round();
                if (currentWeekIndex >= 0 && currentWeekIndex < _weeks.length) {
                  final newVisibleWeekStart = date_utils.DateUtils.startOfWeek(
                    _weeks[currentWeekIndex].first,
                  );
                  // Only update if the visible week has actually changed to avoid unnecessary rebuilds
                  if (!date_utils.DateUtils.isSameDay(
                    newVisibleWeekStart,
                    _currentVisibleWeekStart,
                  )) {
                    setState(() {
                      _currentVisibleWeekStart = newVisibleWeekStart;
                    });
                  }
                }
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _weeks.length,
              physics: const PageScrollPhysics(), // For snapping to weeks
              itemBuilder: (context, weekIndex) {
                final week = _weeks[weekIndex];
                return SizedBox(
                  width: screenWidth, // Each week takes full screen width
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: week.map((date) {
                      final isSelected = date_utils.DateUtils.isSameDay(
                        date,
                        widget.selectedDate,
                      );
                      final isToday = date_utils.DateUtils.isSameDay(
                        date,
                        today,
                      );

                      // Get habit service to check completion status
                      final habitService = Provider.of<HabitService>(
                        context,
                        listen: false,
                      );
                      final habitsDueOnDay = habitService.habits
                          .where((habit) => habit.isHabitDueOnDate(date))
                          .toList();
                      final completedHabitsOnDay = habitsDueOnDay
                          .where((habit) => habit.isCompletedOn(date))
                          .toList();
                      final bool isPerfectDay =
                          habitsDueOnDay.isNotEmpty &&
                          completedHabitsOnDay.length == habitsDueOnDay.length;
                      final bool isPartialDay =
                          completedHabitsOnDay.isNotEmpty &&
                          completedHabitsOnDay.length < habitsDueOnDay.length;
                      final bool isMissedDay =
                          habitsDueOnDay.isNotEmpty &&
                          completedHabitsOnDay.isEmpty &&
                          date.isBefore(today);

                      return GestureDetector(
                        onTap: () {
                          _debouncer.call(() => widget.onDateSelected(date));
                        },
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            isToday ? -15 : 0,
                          ), // Upward shift for today
                          child: Container(
                            width:
                                dayItemWidth, // Each day takes 1/7th of the screen width
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('EEE').format(date).toUpperCase(),
                                  style: TextStyle(
                                    fontSize:
                                        13, // Slightly smaller font for day of week
                                    fontFamily:
                                        'Nunito', // Ensure Nunito font is used
                                    fontWeight: FontWeight
                                        .normal, // Inactive days are regular
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                                  ),
                                ),
                                const SizedBox(height: 6), // Increased spacing
                                AnimatedContainer(
                                  // Added AnimatedContainer for smooth color transition
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  width: 42, // Slightly larger circle
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : isToday
                                        ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer // Highlight today with a softer background
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: isToday && !isSelected
                                        ? Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            width: 1.5,
                                          ) // Border for today if not selected
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      DateFormat('d').format(date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                            fontFamily:
                                                'Nunito', // Ensure Nunito font is used
                                            fontSize:
                                                17, // Slightly larger font for day number
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                ),
                                // Completion indicator dot
                                if (isPerfectDay)
                                  Container(
                                    margin: const EdgeInsets.only(
                                      top: 6,
                                    ), // Increased top margin
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimary
                                          : Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                else if (isPartialDay)
                                  Container(
                                    margin: const EdgeInsets.only(
                                      top: 6,
                                    ), // Increased top margin
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimary
                                            : Colors.orange,
                                        width: 1.5,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                else if (isMissedDay)
                                  Container(
                                    margin: const EdgeInsets.only(
                                      top: 6,
                                    ), // Increased top margin
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimary
                                            : Colors.red,
                                        width: 1.5,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
