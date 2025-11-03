import 'package:flutter/material.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomFloatingActionButton({super.key, required this.onPressed});

  @override
  Widget build(final BuildContext context) => Container(
      margin: EdgeInsets.symmetric(vertical: 40),
      child: FloatingActionButton(
        onPressed: onPressed,
        child: const Icon(Icons.refresh),
      ));
}
