import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_win/services/habit_service.dart';
import 'package:habit_win/models/habit.dart';
import 'package:habit_win/widgets/history_card_widget.dart';
import 'package:habit_win/utils/custom_icons.dart';
import 'dart:math';
import 'package:habit_win/utils/app_colors.dart'; // Import AppColors
import 'package:habit_win/widgets/habit_history_tab.dart'; // Import HabitHistoryTab
import 'package:habit_win/widgets/streak_history_card.dart'; // Import StreakHistoryCard
import 'package:habit_win/widgets/missed_days_chart.dart'; // Import MissedDaysChart
import 'package:habit_win/widgets/consistency_score_card.dart'; // Import ConsistencyScoreCard

class HistoryTabContent extends StatefulWidget {
  const HistoryTabContent({super.key});

  @override
  State<HistoryTabContent> createState() => _HistoryTabContentState();
}

class _HistoryTabContentState extends State<HistoryTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<HabitService>(
      builder: (context, habitService, child) {
        final List<Habit> habits = habitService.habits;

        final int totalHabitsFinished = habitService.calculateTotalCompletedHabits();
        final double overallCompletionRate = habitService.calculateOverallCompletionRate();

        return SingleChildScrollView(
          key: const PageStorageKey<String>('HistoryTabContentScroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HabitHistoryTab(initialSelectedDate: DateTime.now()), // Add Calendar at the top
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall History',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    HistoryCardWidget(
                      title: 'Current Streak',
                      value:
                          '${habits.isNotEmpty ? habits.map((h) => h.streak).reduce(max) : 0} days',
                      icon: const CustomIcon.material(Icons.history),
                      color: AppColors.primaryPurple, // Use specific color
                    ),
                    const SizedBox(height: 12),
                    HistoryCardWidget(
                      title: 'Habit Finish',
                      value: '$totalHabitsFinished times',
                      icon: CustomIcon.material(Icons.task_alt),
                      color: AppColors.lightPurple, // Use specific color
                    ),
                    const SizedBox(height: 12),
                    HistoryCardWidget(
                      title: 'Completion Rate',
                      value: '${overallCompletionRate.round()}%',
                      icon: CustomIcon.material(Icons.percent),
                      color: AppColors.primaryPurple, // Use specific color
                    ),
                    const SizedBox(height: 20),
                    const StreakHistoryCard(initialDelay: 0),
                    const SizedBox(height: 12),
                    const MissedDaysChart(initialDelay: 100),
                    const SizedBox(height: 12),
                    const ConsistencyScoreCard(initialDelay: 200),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
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
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
