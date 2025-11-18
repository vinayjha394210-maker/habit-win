import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_win/services/habit_service.dart';
import 'package:habit_win/utils/app_colors.dart';
import 'package:habit_win/utils/custom_icons.dart';

class StreakHistoryCard extends StatefulWidget {
  final int initialDelay;

  const StreakHistoryCard({super.key, this.initialDelay = 0});

  @override
  State<StreakHistoryCard> createState() => _StreakHistoryCardState();
}

class _StreakHistoryCardState extends State<StreakHistoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Standardized duration
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInQuad, // Standardized easing
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInQuad, // Standardized easing
      ),
    );

    Future.delayed(Duration(milliseconds: widget.initialDelay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<HabitService>(
      builder: (context, habitService, child) {
        final currentStreak = habitService.calculatePerfectDayStreak();
        final longestStreak = habitService.calculateLongestPerfectDayStreak();

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              color: colorScheme.surface, // Standardized background color
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak History',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CustomIcon.material(Icons.local_fire_department)
                            .toWidget(size: 24, defaultColor: AppColors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Current Streak: $currentStreak days',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CustomIcon.material(Icons.military_tech)
                            .toWidget(size: 24, defaultColor: AppColors.gold),
                        const SizedBox(width: 8),
                        Text(
                          'Longest Streak: $longestStreak days',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
