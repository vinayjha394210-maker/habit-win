import 'package:flutter/material.dart';
import 'package:habit_win/models/badge.dart' as my_badge;
import 'package:habit_win/utils/app_colors.dart';
import 'package:vector_math/vector_math_64.dart' as vector; // For 3D effects

class BadgeGridWidget extends StatefulWidget {
  final String title;
  final int archivedCount;
  final int totalBadges;
  final List<my_badge.Badge> badges;
  final int currentProgress; // e.g., current streak, total perfect days, total habits finished
  final String progressType; // e.g., 'streak', 'perfect_days', 'habits_finished'

  const BadgeGridWidget({
    super.key,
    required this.title,
    required this.archivedCount,
    required this.totalBadges,
    required this.badges,
    required this.currentProgress,
    required this.progressType,
  });

  @override
  State<BadgeGridWidget> createState() => _BadgeGridWidgetState();
}

class _BadgeGridWidgetState extends State<BadgeGridWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final Map<String, bool> _unlockedStatus = {}; // To track previous unlocked status

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    // Initialize unlocked status for existing badges
    for (var badge in widget.badges) {
      _unlockedStatus[badge.id] = _isBadgeUnlocked(badge, widget.currentProgress, widget.progressType);
    }
  }

  @override
  void didUpdateWidget(covariant BadgeGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentProgress != oldWidget.currentProgress) {
      for (var badge in widget.badges) {
        final bool wasUnlocked = _unlockedStatus[badge.id] ?? false;
        final bool isNowUnlocked = _isBadgeUnlocked(badge, widget.currentProgress, widget.progressType);

        if (!wasUnlocked && isNowUnlocked) {
          _controller.forward(from: 0.0); // Trigger animation
        }
        _unlockedStatus[badge.id] = isNowUnlocked; // Update status
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isBadgeUnlocked(my_badge.Badge badge, int progress, String type) {
    if (type == 'streak' || type == 'perfect_days') {
      return progress >= badge.milestoneDays;
    } else if (type == 'habits_finished') {
      return progress >= badge.milestoneDays;
    }
    return false;
  }

  Widget _buildBadgeIcon(my_badge.Badge badge, bool isUnlocked, ColorScheme colorScheme) {
    Color primaryColor = isUnlocked ? colorScheme.primary : colorScheme.onSurface.withAlpha((255 * 0.2).round());
    Color secondaryColor = isUnlocked ? colorScheme.secondary : colorScheme.onSurface.withAlpha((255 * 0.1).round());
    Color textColor = isUnlocked ? colorScheme.onSurface : colorScheme.onSurface.withAlpha((255 * 0.4).round());

    Widget badgeContent;

    if (widget.progressType == 'habits_finished') {
      badgeContent = Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUnlocked ? null : colorScheme.surfaceContainerHighest,
          boxShadow: [
            if (isUnlocked)
              BoxShadow(
                color: primaryColor.withAlpha((255 * 0.3).round()),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: Icon(
            badge.icon,
            size: 32,
            color: isUnlocked ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      );
    } else {
      badgeContent = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateX(vector.radians(isUnlocked ? 5 : 0)) // Slight 3D tilt
          ..rotateY(vector.radians(isUnlocked ? -5 : 0)),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15), // Rounded square for a modern look
            gradient: isUnlocked
                ? LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isUnlocked ? null : colorScheme.surfaceContainerHighest,
            boxShadow: [
              if (isUnlocked)
                BoxShadow(
                  color: primaryColor.withAlpha((255 * 0.3).round()),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Center(
            child: Text(
              badge.milestoneDays.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            badgeContent,
            if (isUnlocked)
              Positioned(
                bottom: 0,
                right: 0,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.greenSuccess,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          badge.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.archivedCount}/${widget.totalBadges} Archived',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha((255 * 0.7).round())),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20.0, // Increased spacing
              mainAxisSpacing: 20.0, // Increased spacing
              childAspectRatio: 0.9, // Adjusted for better visual balance
            ),
            itemCount: widget.badges.length,
            itemBuilder: (context, index) {
              final badge = widget.badges[index];
              bool isUnlocked = _isBadgeUnlocked(badge, widget.currentProgress, widget.progressType);

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Opacity(
                  key: ValueKey('${badge.id}_$isUnlocked'), // Key for AnimatedSwitcher
                  opacity: isUnlocked ? 1.0 : 0.5, // Slightly increased opacity for locked badges
                  child: _buildBadgeIcon(badge, isUnlocked, colorScheme),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
