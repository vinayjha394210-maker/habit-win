import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_win/models/habit.dart';
import 'package:habit_win/services/habit_service.dart';
import 'package:habit_win/widgets/habit_card.dart';
import 'package:habit_win/screens/add_habit_screen.dart';
import 'package:habit_win/utils/string_extensions.dart'; // Import StringExtension
import 'package:habit_win/screens/habit_history_screen.dart'; // Import HabitHistoryScreen
import 'package:intl/intl.dart'; // Import for DateFormat

import 'package:habit_win/utils/debounce_utils.dart'; // Import Debouncer
import 'package:habit_win/widgets/top_gradient_background.dart'; // Import TopGradientBackground

class HabitListScreen extends StatefulWidget {
  final TimeOfDayType timeOfDayFilter;
  final DateTime selectedDate;

  const HabitListScreen({
    super.key,
    this.timeOfDayFilter = TimeOfDayType.all,
    required this.selectedDate,
  });

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<Habit> _currentHabits = []; // This will hold the habits currently displayed in the AnimatedList

  @override
  void initState() {
    super.initState();
    // Initialize _currentHabits with the initial filtered habits
    // This will be updated in the Consumer builder when the HabitService provides data.
    // We don't need to fetch here as the Consumer will handle it.
  }

  @override
  void didUpdateWidget(covariant HabitListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When selectedDate or timeOfDayFilter changes, the entire list might change,
    // so we need to rebuild the AnimatedList from scratch.
    // The Consumer will handle updating _currentHabits and triggering animations.
  }

  @override
  void dispose() {
    super.dispose();
  }


  void _navigateToHabitHistory(BuildContext context, Habit habit, DateTime selectedDate) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HabitHistoryScreen(
          habit: habit,
          selectedDate: selectedDate,
        ),
      ),
    );
  }

  void _navigateToEditHabit(BuildContext context, Habit habit) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddHabitScreen(habit: habit)),
    );
  }

  void _toggleHabitCompletion(BuildContext context, Habit habit, DateTime date) async {
    final habitService = Provider.of<HabitService>(context, listen: false);
    await habitService.toggleHabitCompletion(habit, date); // Use the provided date
  }

  void _confirmDeleteHabit(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isDeleting = false; // Local state for the dialog
        final Debouncer dialogDebouncer = Debouncer(); // Debouncer for dialog buttons

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Delete Habit',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              content: Text('Are you sure you want to delete "${habit.name}"? This action cannot be undone.'),
              actions: <Widget>[
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () {
                          dialogDebouncer.call(() { // Debounce cancel button
                            Navigator.of(dialogContext).pop(); // Dismiss dialog
                          });
                        },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () {
                          dialogDebouncer.call(() async { // Debounce delete button
                            setState(() {
                              isDeleting = true;
                            });
                            try {
                              final habitService = Provider.of<HabitService>(context, listen: false);
                              await habitService.deleteHabit(habit.id);
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(content: Text('Habit "${habit.name}" deleted successfully!')),
                                );
                                Navigator.of(dialogContext).pop(); // Dismiss dialog
                              }
                            } catch (e) {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(content: Text('Failed to delete habit: $e')),
                                );
                                setState(() {
                                  isDeleting = false; // Reset loading state on error
                                });
                              }
                            } finally {
                              dialogDebouncer.dispose(); // Dispose debouncer
                            }
                          });
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TopGradientBackground(),
        Consumer<HabitService>(
          builder: (context, habitService, child) {
            final List<Habit> habits = habitService.getFilteredHabits(widget.timeOfDayFilter, widget.selectedDate);

            // This logic handles updating the AnimatedList when the underlying habit data changes.
            // It compares the new list of habits with the currently displayed habits (_currentHabits)
            // and performs animated insertions or removals.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateAnimatedList(habits);
            });

            if (habits.isEmpty) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _currentHabits.isEmpty // Only show "No habits" message if _currentHabits is also empty
                    ? Column(
                        key: const ValueKey('noHabitsMessage'), // Key for AnimatedSwitcher
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_box_outline_blank, // Or a more suitable icon
                            size: 80,
                            color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.4).round()),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No habits scheduled for ${widget.timeOfDayFilter == TimeOfDayType.all ? 'this day' : widget.timeOfDayFilter.toString().split('.').last.capitalize()} on ${DateFormat('MMM d').format(widget.selectedDate)}!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap the + button to add a new habit.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.5).round()),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(), // Show nothing if habits are being animated out
              );
            } else {
              return AnimatedList(
                key: _listKey,
                padding: const EdgeInsets.all(8.0),
                initialItemCount: _currentHabits.length,
                itemBuilder: (context, index, animation) {
                  final habit = _currentHabits[index];
                  return _buildItem(context, habit, animation);
                },
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, Habit habit, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      axis: Axis.vertical,
          child: FadeTransition(
            opacity: animation,
            child: HabitCard(
              key: ValueKey('${habit.id}-${widget.selectedDate.toIso8601String()}'), // Add a unique key
              habit: habit,
              onToggleCompletion: (habitToToggle, date) => _toggleHabitCompletion(context, habitToToggle, date),
              onEdit: (habitToEdit) => _navigateToEditHabit(context, habitToEdit),
              onDelete: (habitToDelete) => _confirmDeleteHabit(context, habitToDelete),
              onTap: (habitToDetail) => _navigateToHabitHistory(context, habitToDetail, widget.selectedDate),
              selectedDate: widget.selectedDate,
            ),
          ),
    );
  }

  void _updateAnimatedList(List<Habit> newHabits) {
    // Identify habits to be removed
    List<Habit> habitsToRemove = _currentHabits.where((habit) => !newHabits.contains(habit)).toList();
    for (Habit habit in habitsToRemove) {
      final int index = _currentHabits.indexOf(habit);
      if (index != -1) {
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => _buildItem(context, habit, animation),
          duration: const Duration(milliseconds: 300),
        );
        _currentHabits.removeAt(index);
      }
    }

    // Identify habits to be added or updated
    for (int i = 0; i < newHabits.length; i++) {
      final Habit newHabit = newHabits[i];
      final int oldIndex = _currentHabits.indexOf(newHabit);

      if (oldIndex == -1) {
        // Habit is new, insert it
        _currentHabits.insert(i, newHabit);
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 300));
      } else if (oldIndex != i) {
        // Habit moved, animate its movement
        final Habit habitToMove = _currentHabits.removeAt(oldIndex);
        _currentHabits.insert(i, habitToMove);
        _listKey.currentState?.removeItem(
          oldIndex,
          (context, animation) => _buildItem(context, habitToMove, animation),
          duration: const Duration(milliseconds: 0), // No animation for removal, just re-insert
        );
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 300));
      } else {
        // Habit exists at the same position, just update its content if necessary
        // (HabitCard itself should handle internal updates if the habit object changes)
        _currentHabits[i] = newHabit;
      }
    }
  }
}
