import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_theme.dart';

class QuoteCard extends StatelessWidget {
  final String quote;
  final String imagePath;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.imagePath,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          quote,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppWebLightColors.whiteText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
