import 'package:flutter/material.dart';
import 'package:habit_win/utils/app_colors.dart'; // Import the categorized colors

class ColorPickerWidget extends StatefulWidget {
  final String initialColor;

  const ColorPickerWidget({super.key, required this.initialColor});

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    // Flatten all categorized colors into a single list for a unified grid
    final List<String> allColors = AppColors.categorizedColors.values.expand((list) => list).toList();

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Select a Color',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      content: SingleChildScrollView(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, // 5 colors per row for better spacing
            childAspectRatio: 1,
            crossAxisSpacing: 10, // Increased spacing
            mainAxisSpacing: 10, // Increased spacing
          ),
          itemCount: allColors.length,
          itemBuilder: (context, index) {
            final colorHex = allColors[index];
            final color = hexToColor(colorHex);
            final isSelected = _selectedColor == colorHex;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = colorHex;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12), // Rounded rectangle shape
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary // Primary color border
                        : (colorHex == 'FFFFFFFF' ? Colors.grey.shade400 : Colors.transparent), // Border for white color
                    width: isSelected ? 3.0 : 1.0, // Thicker border for selected
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 3,
                          ),
                        ]
                      : [],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      )
                    : null,
              ),
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            'Cancel',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            Navigator.of(context).pop(_selectedColor);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
