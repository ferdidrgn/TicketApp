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

    final cardColor = backgroundColor ?? colorScheme.surface;
    final primaryTextColor = textColor ?? colorScheme.onSurface;
    final secondaryTextColor =
        textColor?.withOpacity(0.7) ?? colorScheme.onSurface.withOpacity(0.7);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      padding: const EdgeInsets.all(24.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: showDecoration
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
        border: showDecoration
            ? Border.all(
                color: primaryTextColor.withOpacity(0.1),
                width: 1,
              )
            : null,
        gradient: showDecoration
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardColor,
                  cardColor.withOpacity(0.9),
                ],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Dekoratif ikon (isteğe bağlı)
          if (showDecoration)
            Icon(
              Icons.format_quote_rounded,
              color: primaryTextColor.withOpacity(0.3),
              size: 32,
            ),

          if (showDecoration) const SizedBox(height: 16),

          // Ana söz
          Text(
            '"$word"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: primaryTextColor,
              fontWeight: FontWeight.w300,
              height: 1.4,
              fontFamily: 'Serif', // Daha sanatsal font
            ),
          ),

          const SizedBox(height: 20),

          // Yazar çizgisi
          Container(
            height: 1,
            width: 60,
            color: secondaryTextColor.withOpacity(0.3),
          ),

          const SizedBox(height: 12),

          // Yazar ismi
          Text(
            author,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
