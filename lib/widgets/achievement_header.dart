import 'package:flutter/material.dart';

class AchievementHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int achievementCount;
  final Color countBackgroundColor;
  final Color countTextColor;

  const AchievementHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.achievementCount,
    required this.countBackgroundColor,
    required this.countTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7D3CFF),
            Color(0xFFA566FF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500, // Medium
                    fontSize: 14.0,
                    color: Colors.white.withOpacity(0.8), // #FFFFFFCC
                  ),
                ),
              ],
            ),
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
