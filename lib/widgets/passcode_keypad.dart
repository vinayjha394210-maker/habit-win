import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback

class PasscodeKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final Color buttonColor;
  final Color textColor;
  final Color highlightColor;

  const PasscodeKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.buttonColor,
    required this.textColor,
    required this.highlightColor,
  });

  Widget _buildKeypadButton(
    BuildContext context,
    String text, {
    IconData? icon,
    VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact(); // Haptic feedback on tap
          onPressed?.call();
        },
        borderRadius: BorderRadius.circular(64),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: 72, // Slightly larger for modern look
          height: 72,
          decoration: BoxDecoration(
            color: buttonColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.1).round()),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 32, color: textColor)
                : Text(
                    text,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (j) {
              final digit = (i * 3 + j + 1).toString();
              return _buildKeypadButton(
                context,
                digit,
                onPressed: () => onDigitPressed(digit),
              );
            }),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72), // Placeholder for alignment
            _buildKeypadButton(
              context,
              '0',
              onPressed: () => onDigitPressed('0'),
            ),
            _buildKeypadButton(
              context,
              'backspace',
              icon: Icons.backspace_outlined,
              onPressed: onBackspacePressed,
            ),
          ],
        ),
      ],
    );
  }
}
