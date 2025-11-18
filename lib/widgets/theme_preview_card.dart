import 'package:flutter/material.dart';
import 'dart:math'; // Import for Random and pi
import 'package:habit_win/utils/app_themes.dart';

class ThemePreviewCard extends StatelessWidget {
  final AppTheme theme;
  final AppTheme currentTheme;
  final ValueChanged<AppTheme?> onChanged;

  const ThemePreviewCard({
    super.key,
    required this.theme,
    required this.currentTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = theme.themeData;
    final bool isSelected = theme == currentTheme;

    return GestureDetector(
      onTap: () => onChanged(theme),
      child: AnimatedContainer( // Wrap Card in AnimatedContainer for smooth transitions
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected // Changed to Border.all
              ? Border.all(color: themeData.colorScheme.primary, width: 3)
              : null, // Use null for no border
          boxShadow: [
            BoxShadow(
              color: themeData.colorScheme.shadow.withAlpha((255 * (isSelected ? 0.2 : 0.05)).round()), // Dynamic shadow
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Card(
          elevation: 0, // Elevation handled by AnimatedContainer's boxShadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide.none, // Border handled by AnimatedContainer
          ),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeData.colorScheme.surface,
                  themeData.colorScheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Placeholder for animations/patterns
                if (theme == AppTheme.oceanBlue)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.3,
                      child: CustomPaint(
                        painter: WavePatternPainter(themeData.colorScheme.primary),
                      ),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.color_lens,
                        color: themeData.colorScheme.onSurface,
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        theme.name.split(' ')[0], // Display first word of theme name
                        style: TextStyle(
                          color: themeData.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AnimatedOpacity( // Added AnimatedOpacity for checkmark icon
                        opacity: isSelected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Icon(
                            Icons.check_circle,
                            color: themeData.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Painters for subtle background patterns
class WavePatternPainter extends CustomPainter {
  final Color color;
  WavePatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color.withAlpha((255 * 0.2).round());
    final Path path = Path();

    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.25, size.height * 0.6, size.width * 0.5, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.8, size.width * 1.0, size.height * 0.7);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class StarPatternPainter extends CustomPainter {
  final Color color;
  StarPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color.withAlpha((255 * 0.3).round());
    final Random random = Random();

    for (int i = 0; i < 50; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double radius = random.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConfettiPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Random random = Random();
    final List<Color> colors = [
      Colors.red, Colors.yellow, Colors.pink, Colors.orange,
    ];

    for (int i = 0; i < 30; i++) {
      final Paint paint = Paint()..color = colors[random.nextInt(colors.length)].withAlpha((255 * 0.6).round());
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double width = random.nextDouble() * 8 + 4;
      final double height = random.nextDouble() * 8 + 4;
      final double angle = random.nextDouble() * 2 * pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: width, height: height), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
