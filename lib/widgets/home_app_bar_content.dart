import 'package:flutter/material.dart';
import 'package:habit_win/models/habit.dart';
import 'package:habit_win/utils/string_extensions.dart';
import 'package:habit_win/utils/debounce_utils.dart';
import 'package:habit_win/widgets/day_navigation_bar.dart';

class HomeAppBarContent extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final TimeOfDayType timeOfDayFilter;
  final Function(TimeOfDayType) onTimeOfDayFilterTapped;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isToday;
  final String dayLabel;
  final String formattedDate;
  final Debouncer debouncer;
  final Function() onGoToToday; // New callback for the "Today" button

  const HomeAppBarContent({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.timeOfDayFilter,
    required this.onTimeOfDayFilterTapped,
    required this.colorScheme,
    required this.textTheme,
    required this.isToday,
    required this.dayLabel,
    required this.formattedDate,
    required this.debouncer,
    required this.onGoToToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withAlpha((255 * 0.8).round()),
            colorScheme.primaryContainer.withAlpha((255 * 0.8).round()),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12.0)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha((255 * 0.1).round()),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Reverted to start for left alignment
                    children: [
                      Text(
                        dayLabel,
                        style: textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          formattedDate,
                          style: textTheme.bodyMedium!.copyWith(
                            fontSize: 16,
                            color: colorScheme.onPrimary.withAlpha((255 * 0.7).round()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: isToday ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Visibility(
                    visible: !isToday,
                    child: Center( // Center the TextButton
                      child: TextButton(
                        onPressed: () => debouncer.call(onGoToToday),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.onPrimary,
                          backgroundColor: colorScheme.onPrimary.withAlpha((255 * 0.2).round()),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Today',
                          style: textTheme.labelLarge!.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withAlpha((255 * 0.8).round()),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withAlpha((255 * 0.08).round()),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: TimeOfDayType.values.map((type) {
                    final isSelected = timeOfDayFilter == type;
                    return GestureDetector(
                      onTap: () {
                        debouncer.call(() => onTimeOfDayFilterTapped(type));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withAlpha((255 * (isSelected ? 0.2 : 0.08)).round()),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type == TimeOfDayType.all
                                  ? Icons.access_time
                                  : type == TimeOfDayType.morning
                                      ? Icons.wb_sunny_outlined
                                      : type == TimeOfDayType.afternoon
                                          ? Icons.brightness_5_outlined
                                          : Icons.nights_stay_outlined,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              type == TimeOfDayType.all ? 'All' : type.toString().split('.').last.capitalize(),
                              style: textTheme.bodyMedium!.copyWith(
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          DayNavigationBar(
            selectedDate: selectedDate,
            onDateSelected: onDateSelected,
          ),
        ],
      ),
    );
  }
}
