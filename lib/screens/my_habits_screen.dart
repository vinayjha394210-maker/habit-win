import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../widgets/habit_card.dart'; // Assuming a reusable habit card widget
import 'habit_detail_screen.dart'; // Import HabitDetailScreen
import 'add_habit_screen.dart'; // Import AddHabitScreen
import 'package:habit_win/utils/debounce_utils.dart'; // Import Debouncer

class MyHabitsScreen extends StatefulWidget {
  const MyHabitsScreen({super.key});

  @override
  State<MyHabitsScreen> createState() => _MyHabitsScreenState();
}

class _MyHabitsScreenState extends State<MyHabitsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Habits',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<HabitService>(
        builder: (context, habitService, child) {
          final habits = habitService.habits;

          if (habits.isEmpty) {
            return const Center(
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: HabitCard(
                  habit: habit,
                  onTap: (habit) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HabitDetailScreen(habitId: habit.id),
                      ),
                    );
                  },
                  onEdit: (habit) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddHabitScreen(habit: habit),
                      ),
                    );
                  },
                  onToggleCompletion: (habit, date) {
                    // Not relevant for this screen, but required by HabitCard
                  },
                  onDelete: (habit) => _confirmDeleteHabit(context, habit),
                  selectedDate: DateTime.now(), // Pass current date as a placeholder, as completion is not toggled here
                ),
              );
            },
          );
        },
      ),
    );
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
              content: Text('Are you sure you want to permanently delete "${habit.name}"? This cannot be undone.'),
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
}
