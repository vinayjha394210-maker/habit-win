import 'package:flutter/material.dart';

class CustomRadioGroup<T> extends StatelessWidget {
  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final List<CustomRadioOption<T>> options;
  final MainAxisAlignment mainAxisAlignment;

  const CustomRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.options,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: options.map((option) {
        return Expanded(
          child: RadioListTile<T>(
            title: Text(
              option.label,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            value: option.value,
            groupValue: groupValue,
            onChanged: onChanged,
          ),
        );
      }).toList(),
    );
  }
}

class CustomRadioOption<T> {
  final T value;
  final String label;

  CustomRadioOption({required this.value, required this.label});
}
