import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/common/extentions/app_context_ui_extension.dart';

/// Büyük sayfa başlığı. Adı tarihsel (eskiden gradyanla boyanıyordu);
/// artık bilet dilindeki başlıklarla aynı: Playfair Display, temanın metin
/// renginde.
class TopGradientHeader extends StatelessWidget {
  final String title;

  const TopGradientHeader({super.key, required this.title});

  @override
  Widget build(final BuildContext context) => Semantics(
        header: true,
        child: Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.05,
            color: context.colors.onSurface,
          ),
        ),
      );
}
