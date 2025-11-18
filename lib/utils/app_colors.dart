import 'package:flutter/material.dart';

// Helper function to convert hex string to Color object
Color hexToColor(String hexString) {
  final hexCode = hexString.replaceAll('FF', ''); // Remove FF if present
  return Color(int.parse('FF$hexCode', radix: 16));
}

// Define a class for common application colors
class AppColors {
  // Primary Purple Color
  static const Color primaryPurple = Color(0xFF7E57C2); // Main purple color

  // Accent Colors
  static const Color lightPurple = Color(0xFFB39DDB); // Lighter shade of purple
  static const Color softGray = Color(0xFFEEEEEE); // Soft gray for backgrounds/text
  static const Color darkGray = Color(0xFF424242); // Dark gray for text/icons
  static const Color white = Color(0xFFFFFFFF); // White for text/backgrounds
  static const Color black = Color(0xFF000000); // Black for text/icons

  // Semantic Colors
  static const Color greenSuccess = Color(0xFF4CAF50); // Green for success
  static const Color redError = Color(0xFFF44336); // Red for errors
  static const Color yellowWarning = Color(0xFFFFC107); // Yellow for warnings
  static const Color blueInfo = Color(0xFF2196F3); // Blue for informational messages
  static const Color orange = Color(0xFFFF9800); // Orange for streaks
  static const Color gold = Color(0xFFD4AF37); // Gold for longest streaks

  // Backgrounds and Cards
  static const Color lightBackground = Color(0xFFF5F5F5); // Light background
  static const Color darkBackground = Color(0xFF121212); // Dark background
  static const Color cardLight = Color(0xFFFFFFFF); // White card background
  static const Color cardDark = Color(0xFF1E1E1E); // Dark card background

  // Shadow Color
  static const Color shadowColor = Color(0x33000000); // Soft black for shadows

  // Categorized colors (simplified to align with new theme)
  static const Map<String, List<String>> categorizedColors = {
    'Purple': [
      'FF7E57C2', // Primary Purple
      'FFB39DDB', // Light Purple
      'FFAB47BC', // Original Purple Accent
      'FF6A1B9A', // Deep Purple
      'FF9C27B0', // Purple 500
      'FFBA68C8', // Purple 300
      'FFD1C4E9', // Purple 100
      'FFEDE7F6', // Purple 50
    ],
    'Blue': [
      'FF2196F3', // Blue Info
      'FF42A5F5', // Blue 400
      'FF90CAF9', // Blue 200
      'FF1976D2', // Blue 700
      'FF0D47A1', // Blue 900
      'FFBBDEFB', // Blue 100
      'FFE3F2FD', // Blue 50
      'FF00BCD4', // Cyan 500
      'FF4DD0E1', // Cyan 300
      'FF0097A7', // Cyan 700
    ],
    'Green': [
      'FF4CAF50', // Green Success
      'FF81C784', // Green 300
      'FF388E3C', // Green 700
      'FF1B5E20', // Green 900
      'FF00BFA5', // Teal Accent
      'FF64FFDA', // Teal Accent 200
      'FF1DE9B6', // Teal Accent 400
      'FFB9F6CA', // Green Accent 100
      'FF69F0AE', // Green Accent 200
    ],
    'Red & Orange': [
      'FFF44336', // Red Error
      'FFE57373', // Red 300
      'FFD32F2F', // Red 700
      'FFB71C1C', // Red 900
      'FFFF9800', // Orange
      'FFFFB74D', // Orange 300
      'FFF57C00', // Orange 700
      'FFFFCCBC', // Deep Orange 100
      'FFFFE0B2', // Orange 100
    ],
    'Yellow & Amber': [
      'FFFFC107', // Yellow Warning
      'FFFFEB3B', // Yellow 500
      'FFFBC02D', // Amber 700
      'FFFFD54F', // Amber 300
      'FFFFF9C4', // Yellow 100
      'FFFFFDE7', // Yellow 50
    ],
    'Grayscale': [
      'FFEEEEEE', // Soft Gray
      'FFB0BEC5', // Blue Grey 200
      'FF90A4AE', // Blue Grey 300
      'FF424242', // Dark Gray
      'FF212121', // Grey 900
      'FF000000', // Black
      'FFFFFFFF', // White
      'FFCFD8DC', // Blue Grey 100
      'FFECEFF1', // Blue Grey 50
    ],
  };
}
