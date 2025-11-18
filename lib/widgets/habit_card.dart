import 'package:flutter/material.dart';
import 'package:habit_win/models/habit.dart';
import 'package:habit_win/utils/app_colors.dart'; // Import AppColors for hexToColor
// For date formatting
// Import StringExtension
// Import provider
// Import HabitService
// Import DateUtils
// Import CustomIcon
import 'package:habit_win/utils/debounce_utils.dart'; // Import Debouncer
import 'package:habit_win/utils/date_utils.dart' as my_date_utils;

class HabitCard extends StatefulWidget {
  final Habit habit;
  final Function(Habit, DateTime)
  onToggleCompletion; // Modified to pass selectedDate
  final Function(Habit) onEdit;
  final Function(Habit) onDelete;
  final Function(Habit) onTap; // New parameter for card tap
  final DateTime selectedDate; // New parameter for the selected date

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggleCompletion,
    required this.onEdit,
    required this.onDelete,
    required this.onTap, // Require onTap
    required this.selectedDate, // Require selectedDate
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 300),
  );
  double _previousProgress = 0.0; // Store the previous progress

  @override
  void initState() {
    super.initState();
    // Initialize _previousProgress to 0.0 to always animate from uncompleted state
    // when the card is first displayed for a given selectedDate.
    _previousProgress = 0.0;
  }

  @override
  void didUpdateWidget(covariant HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the habit object changes (e.g., completion status updated),
    // we want to animate from the old habit's progress to the new habit's progress.
    // Also, if the selectedDate changes, we should reset _previousProgress to 0.0
    // to ensure the animation plays from an uncompleted state for the new day.
    if (widget.habit != oldWidget.habit || !my_date_utils.DateUtils.isSameDay(widget.selectedDate, oldWidget.selectedDate)) {
      _previousProgress = _calculateProgress(oldWidget.habit, oldWidget.selectedDate);
      // If the selectedDate changed, we want to animate from 0.0 for the new day's initial display.
      if (!my_date_utils.DateUtils.isSameDay(widget.selectedDate, oldWidget.selectedDate)) {
        _previousProgress = 0.0; // Reset for new day to always show animation from start
      }
    }
  }

  // Helper method to calculate progress
  double _calculateProgress(Habit habit, DateTime selectedDate) {
    final bool isCompletedOnSelectedDate = habit.isCompletedOn(selectedDate);
    final int currentCompletions = habit.completionDates
        .where((date) => my_date_utils.DateUtils.isSameDay(date, selectedDate))
        .length;
    return habit.goalEnabled && habit.goalValue != null
        ? (currentCompletions / habit.goalValue!).clamp(0.0, 1.0)
        : (isCompletedOnSelectedDate ? 1.0 : 0.0);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompletedOnSelectedDate = widget.habit.isCompletedOn(
      widget.selectedDate,
    );
    final bool isHabitDue = widget.habit.isHabitDueOnDate(widget.selectedDate);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color baseColor = hexToColor(widget.habit.color);
    final Color darkerColor = Color.lerp(baseColor, Colors.black, 0.2)!; // 20% darker
    final Color textColor = Colors.white; // Assuming white text for colored cards
    final Color iconColor = Colors.white; // Assuming white icon for colored cards

    // Calculate progress for the circular indicator
    final double progress = _calculateProgress(widget.habit, widget.selectedDate);

    return AnimatedOpacity(
      key: ValueKey('habit-card-opacity-${widget.habit.id}-$isCompletedOnSelectedDate'),
      opacity: isCompletedOnSelectedDate
          ? 0.6
          : 1.0, // Slightly faded for completed habits
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container( // Changed from AnimatedContainer to Container for custom animation control
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _debouncer.call(() => widget.onTap(widget.habit)),
            borderRadius: BorderRadius.circular(20.0), // Rounded corners (20-24px)
            child: AnimatedContainer( // Inner AnimatedContainer for color/shadow animation
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isCompletedOnSelectedDate
                      ? [baseColor.withAlpha((255 * 0.7).round()), darkerColor.withAlpha((255 * 0.7).round())]
                      : [baseColor, darkerColor],
                ),
                boxShadow: [
                  // Outer drop shadow
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.2).round()),
                    blurRadius: 15.0,
                    offset: const Offset(0, 8),
                  ),
                  // Soft inner shadow (top-left)
                  BoxShadow(
                    color: Colors.white.withAlpha((255 * 0.15).round()),
                    blurRadius: 8.0,
                    offset: const Offset(-3, -3),
                    spreadRadius: -2.0,
                  ),
                  // Soft inner shadow (bottom-right)
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.2).round()),
                    blurRadius: 8.0,
                    offset: const Offset(3, 3),
                    spreadRadius: -2.0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Consistent padding
                child: Row(
                  children: [
                    // Animated Progress Circle/Bar
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 40.0,
                          height: 40.0,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: _previousProgress, end: progress),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return CircularProgressIndicator(
                                value: value,
                                strokeWidth: 4.0,
                                backgroundColor: Colors.white.withAlpha((255 * 0.3).round()), // Lighter shade of primary
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  textColor, // Use white for progress indicator
                                ),
                              );
                            },
                          ),
                        ),
                        // Check/Uncheck Animation
                        InkWell(
                          onTap: isHabitDue
                              ? () => _debouncer.call(
                                    () => widget.onToggleCompletion(
                                      widget.habit,
                                      widget.selectedDate,
                                    ),
                                  )
                              : null,
                          borderRadius: BorderRadius.circular(20.0),
                          child: AnimatedContainer(
                            key: ValueKey('habit-checkmark-${widget.habit.id}-$isCompletedOnSelectedDate'),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: 30.0,
                            height: 30.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompletedOnSelectedDate
                                  ? textColor // Filled when completed
                                  : Colors.transparent, // Background color
                              border: Border.all(
                                color: isCompletedOnSelectedDate
                                    ? textColor
                                    : Colors.white.withAlpha((255 * 0.7).round()), // Border color
                                width: 2.0,
                              ),
                              boxShadow: [
                                if (isCompletedOnSelectedDate)
                                  BoxShadow(
                                    color: textColor.withAlpha((255 * 0.4).round()),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: isCompletedOnSelectedDate
                                ? Icon(
                                    Icons.check,
                                    color: baseColor, // Checkmark color should be the base color
                                    size: 20.0,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16.0),
                    // Habit Icon
                    IconTheme(
                      data: IconThemeData(
                        size: 32.0, // Slightly larger icon
                        color: iconColor,
                      ),
                      child: Hero(
                        tag: 'habit-icon-${widget.habit.id}',
                        child: widget.habit.icon.toWidget(),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'habit-name-${widget.habit.id}',
                            child: Text(
                              widget.habit.name,
                              style: theme.textTheme.titleMedium!.copyWith(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (widget.habit.goalEnabled &&
                              widget.habit.goalValue != null)
                            Text(
                              'Goal: ${widget.habit.goalValue} ${widget.habit.unit ?? ''}',
                              style: theme.textTheme.bodySmall!.copyWith(
                                color: textColor.withAlpha((255 * 0.7).round()),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          // Streak Counter
                          if (widget.habit.streak > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0), // Increased top padding
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha((255 * 0.2).round()), // Use a secondary container color
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      color: textColor,
                                      size: 16,
                                    ), // 🔥 icon
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.habit.streak} days',
                                      style: theme.textTheme.bodySmall!.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: iconColor.withAlpha((255 * 0.7).round()),
                      ),
                      onSelected: (value) {
                        _debouncer.call(() {
                          if (value == 'edit') {
                            widget.onEdit(widget.habit);
                          } else if (value == 'delete') {
                            widget.onDelete(widget.habit);
                          }
                        });
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Text(
                                'Edit',
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
