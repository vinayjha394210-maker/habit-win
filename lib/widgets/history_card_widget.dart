import 'package:flutter/material.dart';
import 'package:habit_win/utils/custom_icons.dart'; // Import CustomIcon

class HistoryCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final CustomIcon icon; // Changed from IconData to CustomIcon
  final Color color;

  const HistoryCardWidget({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Determine text color based on the luminance of the card's background color
    final textColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.4);

    return Card(
      color: color,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: shadowColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                ),
                icon.toWidget(
                  size: 24,
                  defaultColor: textColor.withOpacity(0.8),
                ), // Use toWidget to render CustomIcon
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor.withOpacity(0.8),
                      overflow: TextOverflow.ellipsis,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
