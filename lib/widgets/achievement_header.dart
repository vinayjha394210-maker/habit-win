import 'package:flutter/material.dart';

class AchievementHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int achievementCount;
  final Color backgroundColor;
  final Color textColor;
  final Color countBackgroundColor;
  final Color countTextColor;

  const AchievementHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.achievementCount,
    required this.backgroundColor,
    required this.textColor,
    required this.countBackgroundColor,
    required this.countTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: textColor.withAlpha((textColor.alpha * 0.8).round()),
                ),
              ),
            ],
          ),
          CircleAvatar(
            backgroundColor: countBackgroundColor,
            child: Text(
              '$achievementCount',
              style: textTheme.titleMedium?.copyWith(
                color: countTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
