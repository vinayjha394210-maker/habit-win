import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_win/services/habit_service.dart';
import 'package:habit_win/models/habit.dart';
import 'package:habit_win/models/badge.dart' as my_badge;
import 'package:habit_win/widgets/badge_grid_widget.dart';
import 'package:habit_win/widgets/achievement_header.dart';
import 'dart:math';
import 'package:habit_win/utils/app_colors.dart'; // Import AppColors

class BadgesTabContent extends StatefulWidget {
  const BadgesTabContent({super.key});

  @override
  State<BadgesTabContent> createState() => _BadgesTabContentState();
}

class _BadgesTabContentState extends State<BadgesTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int getArchivedCount(List<my_badge.Badge> badgeList, int progress) {
    return badgeList
        .where((badge) => progress >= badge.milestoneDays)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<HabitService>(
      builder: (context, habitService, child) {
        final List<Habit> habits = habitService.habits;

        final int totalPerfectDays = habitService.totalPerfectDays;
        final int totalHabitsFinished = habitService.calculateTotalCompletedHabits();
        final double overallCompletionRate = habitService.calculateOverallCompletionRate();

        final List<my_badge.Badge> dayStreakBadges = [
          my_badge.Badge(
            id: 'ds_3',
            name: '3-Day Streak',
            description: 'Achieve a 3-day streak',
            icon: Icons.star,
            milestoneDays: 3,
          ),
          my_badge.Badge(
            id: 'ds_5',
            name: '5-Day Streak',
            description: 'Achieve a 5-day streak',
            icon: Icons.star,
            milestoneDays: 5,
          ),
          my_badge.Badge(
            id: 'ds_7',
            name: '7-Day Streak',
            description: 'Achieve a 7-day streak',
            icon: Icons.star,
            milestoneDays: 7,
          ),
          my_badge.Badge(
            id: 'ds_10',
            name: '10-Day Streak',
            description: 'Achieve a 10-day streak',
            icon: Icons.local_fire_department,
            milestoneDays: 10,
          ),
          my_badge.Badge(
            id: 'ds_15',
            name: '15-Day Streak',
            description: 'Achieve a 15-day streak',
            icon: Icons.local_fire_department,
            milestoneDays: 15,
          ),
          my_badge.Badge(
            id: 'ds_21',
            name: '21-Day Streak',
            description: 'Achieve a 21-day streak',
            icon: Icons.emoji_events,
            milestoneDays: 21,
          ),
          my_badge.Badge(
            id: 'ds_30',
            name: '30-Day Streak',
            description: 'Achieve a 30-day streak',
            icon: Icons.emoji_events,
            milestoneDays: 30,
          ),
          my_badge.Badge(
            id: 'ds_50',
            name: '50-Day Streak',
            description: 'Achieve a 50-day streak',
            icon: Icons.military_tech,
            milestoneDays: 50,
          ),
          my_badge.Badge(
            id: 'ds_100',
            name: '100-Day Streak',
            description: 'Achieve a 100-day streak',
            icon: Icons.workspace_premium,
            milestoneDays: 100,
          ),
        ];

        final List<my_badge.Badge> perfectDayBadges = [
          my_badge.Badge(
            id: 'pd_3',
            name: '3 Perfect Days',
            description: 'Complete all habits for 3 days',
            icon: Icons.check_circle,
            milestoneDays: 3,
          ),
          my_badge.Badge(
            id: 'pd_10',
            name: '10 Perfect Days',
            description: 'Complete all habits for 10 days',
            icon: Icons.check_circle,
            milestoneDays: 10,
          ),
          my_badge.Badge(
            id: 'pd_20',
            name: '20 Perfect Days',
            description: 'Complete all habits for 20 days',
            icon: Icons.check_circle,
            milestoneDays: 20,
          ),
          my_badge.Badge(
            id: 'pd_30',
            name: '30 Perfect Days',
            description: 'Complete all habits for 30 days',
            icon: Icons.check_circle,
            milestoneDays: 30,
          ),
          my_badge.Badge(
            id: 'pd_50',
            name: '50 Perfect Days',
            description: 'Complete all habits for 50 days',
            icon: Icons.check_circle,
            milestoneDays: 50,
          ),
          my_badge.Badge(
            id: 'pd_100',
            name: '100 Perfect Days',
            description: 'Complete all habits for 100 days',
            icon: Icons.check_circle,
            milestoneDays: 100,
          ),
        ];

        final List<my_badge.Badge> habitFinishBadges = [
          my_badge.Badge(
            id: 'hf_1',
            name: 'Finish Habit for The First Time',
            description: 'Complete your first habit',
            icon: Icons.flag,
            milestoneDays: 1,
          ),
          my_badge.Badge(
            id: 'hf_10',
            name: 'Finish Habit 10 Times',
            description: 'Complete habits 10 times',
            icon: Icons.flag,
            milestoneDays: 10,
          ),
          my_badge.Badge(
            id: 'hf_20',
            name: 'Finish Habit 20 Times',
            description: 'Complete habits 20 times',
            icon: Icons.flag,
            milestoneDays: 20,
          ),
          my_badge.Badge(
            id: 'hf_50',
            name: 'Finish Habit 50 Times',
            description: 'Complete habits 50 times',
            icon: Icons.flag,
            milestoneDays: 50,
          ),
          my_badge.Badge(
            id: 'hf_100',
            name: 'Finish Habit 100 Times',
            description: 'Complete habits 100 times',
            icon: Icons.flag,
            milestoneDays: 100,
          ),
          my_badge.Badge(
            id: 'hf_300',
            name: 'Finish Habit 300 Times',
            description: 'Complete habits 300 times',
            icon: Icons.flag,
            milestoneDays: 300,
          ),
        ];

        return SingleChildScrollView(
          key: const PageStorageKey<String>('BadgesTabContentScroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AchievementHeader(
                title: 'My achievements',
                subtitle:
                    'You\'ve earned ${overallCompletionRate.round()}% of all achievements',
                achievementCount: getArchivedCount(
                      dayStreakBadges,
                      habits.isNotEmpty
                          ? habits.map((h) => h.longestStreak).reduce(max)
                          : 0,
                    ) +
                    getArchivedCount(perfectDayBadges, totalPerfectDays) +
                    getArchivedCount(habitFinishBadges, totalHabitsFinished),
                countBackgroundColor: AppColors.darkGray, // Use specific color
                countTextColor: AppColors.primaryPurple, // Use specific color
              ),
              const SizedBox(height: 16),
              BadgeGridWidget(
                title: 'Best Streak',
                archivedCount: getArchivedCount(
                  dayStreakBadges,
                  habits.isNotEmpty
                      ? habits.map((h) => h.longestStreak).reduce(max)
                      : 0,
                ),
                totalBadges: dayStreakBadges.length,
                badges: dayStreakBadges,
                currentProgress: habits.isNotEmpty
                    ? habits.map((h) => h.longestStreak).reduce(max)
                    : 0,
                progressType: 'streak',
              ),
              const SizedBox(height: 24),
              BadgeGridWidget(
                title: 'Perfect Days',
                archivedCount: getArchivedCount(
                  perfectDayBadges,
                  totalPerfectDays,
                ),
                totalBadges: perfectDayBadges.length,
                badges: perfectDayBadges,
                currentProgress: totalPerfectDays,
                progressType: 'perfect_days',
              ),
              const SizedBox(height: 24),
              BadgeGridWidget(
                title: 'Habits Finished',
                archivedCount: getArchivedCount(
                  habitFinishBadges,
                  totalHabitsFinished,
                ),
                totalBadges: habitFinishBadges.length,
                badges: habitFinishBadges,
                currentProgress: totalHabitsFinished,
                progressType: 'habits_finished',
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
