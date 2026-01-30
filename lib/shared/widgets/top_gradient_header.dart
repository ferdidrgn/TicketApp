import 'package:flutter/material.dart';
import '../../core/common/extentions/app_context_ui_extension.dart';

class TopGradientHeader extends StatelessWidget {
  final String title;

  const TopGradientHeader({super.key, required this.title});

  @override
  Widget build(final BuildContext context) => ShaderMask(
        shaderCallback: (final Rect bounds) => LinearGradient(
          colors: context.appGradient(isActive: true),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            fontFamily: 'Serif',
            letterSpacing: -1.5,
            color: Colors.white,
          ),
        ),
      );
}
