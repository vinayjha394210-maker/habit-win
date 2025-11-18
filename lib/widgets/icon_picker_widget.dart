import 'package:flutter/material.dart';
import 'package:habit_win/utils/custom_icons.dart'; // Import availableMaterialIcons

class IconPickerWidget extends StatefulWidget {
  final CustomIcon? initialIcon;
  final Color initialColor; // Initial color is now required

  const IconPickerWidget({super.key, this.initialIcon, required this.initialColor});

  @override
  State<IconPickerWidget> createState() => _IconPickerWidgetState();
}

class _IconPickerWidgetState extends State<IconPickerWidget> {
  late CustomIcon _selectedIcon;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon ?? const CustomIcon.material(Icons.directions_run); // Default icon
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select an Icon'),
      contentPadding: const EdgeInsets.all(16.0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 icons per row
                  crossAxisSpacing: 10, // Consistent spacing
                  mainAxisSpacing: 10, // Consistent spacing
                ),
                itemCount: availableMaterialIcons.length, // Use new list
                itemBuilder: (context, index) {
                  final icon = availableMaterialIcons[index]; // Use new list
                  final isSelected = _selectedIcon.materialIconData == icon.materialIconData;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withAlpha((255 * 0.2).round()) // Highlight background
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary // Highlight border
                              : Theme.of(context).colorScheme.outline.withAlpha((255 * 0.5).round()),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.3).round()),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: icon.toWidget(
                          size: 32,
                          defaultColor: isSelected
                              ? Theme.of(context).colorScheme.primary // Highlight icon color
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop(_selectedIcon.copyWith(color: widget.initialColor));
              },
              child: const Text('Select Icon'),
            ),
          ],
        ),
      ),
    );
  }
}
