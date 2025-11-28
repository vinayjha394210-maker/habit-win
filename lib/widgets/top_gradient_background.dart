import 'package:flutter/material.dart';

class TopGradientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.85),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.55)
          ],
        ),
      ),
    );
  }
}
