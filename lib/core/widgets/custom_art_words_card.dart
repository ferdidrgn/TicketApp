import 'package:flutter/material.dart';

class CustomArtWordsCard extends StatelessWidget {
  final String word;
  final String author;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showDecoration;

  const CustomArtWordsCard({
    super.key,
    required this.word,
    required this.author,
    this.backgroundColor,
    this.textColor,
    this.showDecoration = true,
  });

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cardColor = backgroundColor ?? colorScheme.surfaceContainerHighest;
    final primaryTextColor = textColor ?? colorScheme.onSurface;
    final secondaryTextColor =
        textColor?.withOpacity(0.7) ?? colorScheme.onSurface.withOpacity(0.7);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        padding: const EdgeInsets.all(24.0),
        width: double.infinity,
        constraints: const BoxConstraints(
          maxWidth: 600, // Maksimum genişlik, büyük ekranlarda ortalanır
          minWidth: 320, // Minimum genişlik, küçük cihazlarda taşmaz
        ),
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            gradient: showDecoration
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardColor.withOpacity(0.95),
                      cardColor.withOpacity(0.8),
                    ],
                  )
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 6)),
              BoxShadow(
                  color: Colors.white.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2))
            ],
            border: Border.all(
                color: primaryTextColor.withOpacity(0.08), width: 4)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showDecoration)
              Icon(Icons.format_quote_rounded,
                  color: primaryTextColor.withOpacity(0.25), size: 34),

            if (showDecoration) const SizedBox(height: 14),

            // Ana söz
            Text('"$word"',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: primaryTextColor,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                    fontFamily: 'Serif')),

            const SizedBox(height: 22),

            // Alt çizgi
            Container(
                height: 1,
                width: 60,
                color: secondaryTextColor.withOpacity(0.25)),

            const SizedBox(height: 12),

            // Yazar ismi
            Text(author,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                    letterSpacing: 1.1)),
          ],
        ),
      ),
    );
  }
}
