import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_win/models/habit.dart';
import 'package:habit_win/services/habit_service.dart';
import 'package:habit_win/screens/add_habit_screen.dart';
import 'package:habit_win/utils/string_extensions.dart';
import 'package:intl/intl.dart';
import 'package:habit_win/utils/custom_icons.dart'; // Import CustomIcon
import 'package:habit_win/utils/debounce_utils.dart'; // Import Debouncer
import 'package:habit_win/widgets/top_gradient_background.dart'; // Import TopGradientBackground

class HabitDetailScreen extends StatefulWidget {
  final String habitId;
  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _navigateToEditHabit(BuildContext context, Habit habit) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddHabitScreen(habit: habit)),
    );
  }

  void _confirmDeleteHabit(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isDeleting = false; // Local state for the dialog
        final Debouncer dialogDebouncer = Debouncer(delay: const Duration(milliseconds: 300)); // Debouncer for dialog buttons

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
    return Consumer<HabitService>(
      builder: (context, habitService, child) {
        final habit = habitService.habits.firstWhere((h) => h.id == widget.habitId);

        return Stack(
          children: [
            TopGradientBackground(),
            Scaffold(
              appBar: AppBar(
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    habit.name,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: CustomIcon.material(Icons.edit).toWidget(),
                    onPressed: () {
                      _debouncer.call(() => _navigateToEditHabit(context, habit));
                    },
                  ),
                  IconButton(
                    icon: CustomIcon.material(Icons.delete).toWidget(),
                    onPressed: () {
                      _debouncer.call(() => _confirmDeleteHabit(context, habit));
                    },
                  ),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    Card(
                      color: Color(int.parse(habit.color, radix: 16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Hero(
                                  tag: 'habit-icon-${habit.id}',
                                  child: habit.icon.toWidget(
                                    size: 40,
                                    defaultColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Hero(
                                      tag: 'habit-name-${habit.id}',
                                      child: Text(
                                        habit.name,
                                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        )),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Repeat: ${habit.repeatType.toString().split('.').last.capitalize()}',
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),
                            ),
                            if (habit.repeatType == RepeatType.weekly && habit.repeatDays.isNotEmpty)
                              Text(
                                'On: ${habit.repeatDays.map((day) => DateFormat('EEE').format(DateTime(2025, 1, day))).join(', ')}',
                                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),
                              ),
                            if (habit.goalEnabled)
                              Text(
                                'Goal: ${habit.goalValue} times a day',
                                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),
                              ),
                            Text(
                              'Time of Day: ${habit.timeOfDayType.toString().split('.').last.capitalize()}',
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),
                            ),
                            Text(
                              'Start Date: ${DateFormat('MMM d, yyyy').format(habit.startDate)}',
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),
                            ),
                            if (habit.reminderTimes.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'Reminders: ${habit.reminderTimes.map((time) => time.format(context)).join(', ')}',
                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            Text(
                              'Current Streak: ${habit.streak} days',
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // You can add more details here, e.g., a completion calendar or history
                    // For now, just a placeholder
                    const Text(
                      'Habit Progress (Coming Soon)',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
