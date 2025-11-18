import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_win/services/habit_service.dart';
import 'package:habit_win/utils/export_utils.dart';
import 'package:flutter_svg/flutter_svg.dart'; // For SVG logo

class ProgressExportWidget extends StatelessWidget {
  const ProgressExportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final habitService = Provider.of<HabitService>(context);
    final progressData = ExportUtils.getOverallHabitProgress(habitService);

    final int totalHabits = progressData['totalHabits'];
    final int completedHabits = progressData['completedHabits'];
    final double overallConsistency = progressData['overallConsistency'];
    final int longestStreak = progressData['longestStreak'];
    final int currentStreak = progressData['currentStreak'];

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'My Habit Progress',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 20),
          _buildProgressRow(
            context,
            'Total Habits',
            totalHabits.toString(),
            Icons.checklist,
          ),
          _buildProgressRow(
            context,
            'Completed Habits',
            completedHabits.toString(),
            Icons.check_circle_outline,
          ),
          _buildProgressRow(
            context,
            'Overall Consistency',
            '${overallConsistency.toStringAsFixed(1)}%',
            Icons.show_chart,
          ),
          _buildProgressRow(
            context,
            'Longest Streak',
            '$longestStreak days',
            Icons.local_fire_department,
          ),
          _buildProgressRow(
            context,
            'Current Perfect Day Streak',
            '$currentStreak days',
            Icons.star_border,
          ),
          const SizedBox(height: 30),
          // App Logo Watermark
          Align(
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: 0.3,
              child: SvgPicture.asset(
                'assets/icons/app_logo.svg', // Placeholder for app logo
                height: 50,
                colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.srcIn),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(BuildContext context, String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
