import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_win/services/habit_service.dart';

class MissedDaysChart extends StatefulWidget {
  final int initialDelay;

  const MissedDaysChart({super.key, this.initialDelay = 0});

  @override
  State<MissedDaysChart> createState() => _MissedDaysChartState();
}

class _MissedDaysChartState extends State<MissedDaysChart>
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
        final missedDays7 = habitService.calculateMissedDays(7);
        final missedDays30 = habitService.calculateMissedDays(30);

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
                padding: const EdgeInsets.all(12), // Standardized padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Missed Days',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMissedDaysItem(
                          context,
                          'Last 7 Days',
                          missedDays7,
                          colorScheme.error,
                        ),
                        _buildMissedDaysItem(
                          context,
                          'Last 30 Days',
                          missedDays30,
                          colorScheme.error.withAlpha((255 * 0.7).round()),
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

  Widget _buildMissedDaysItem(
      BuildContext context, String label, int count, Color color) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withAlpha((255 * 0.2).round()),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.8).round()),
          ),
        ),
      ],
    );
  }
}
