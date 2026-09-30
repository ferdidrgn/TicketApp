import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/common/extentions/app_context_ui_extension.dart';
import '../../core/theme/app_spacing.dart';
import '../navigation/widgets/navigation_button.dart';

/// Bölüm başlığı: (varsa) küçük bilet etiketi + Playfair Display başlık +
/// (varsa) "tümünü gör" düğmesi. Eski dikey vurgu çubuğu kaldırıldı;
/// renkler temadan. Genel API aynı.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double? fontSize;
  final Alignment? alignment;
  final FontWeight? fontWeight;
  final Color backgroundColor;
  final Color? textColor;

  /// Ana başlığın rengi. null ise temanın `onSurface` rengi.
  final Color? titleColor;

  /// Üst etiketin (subtitle) rengi. null ise `textColor`, o da yoksa
  /// temanın `primary` rengi.
  final Color? accentColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.fontSize = 10,
    this.alignment,
    this.fontWeight = FontWeight.bold,
    this.backgroundColor = Colors.transparent,
    this.textColor,
    this.titleColor,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final Color labelColor = textColor ?? accentColor ?? cs.primary;
    final Color effectiveTitleColor = titleColor ?? cs.onSurface;

    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xxxl, AppSpacing.lg, AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle != null) ...[
                    Text(
                      subtitle!.toUpperCase(),
                      style: TextStyle(
                        color: labelColor,
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: effectiveTitleColor,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.md),
              NavigationButton(onTap: onTap),
            ],
          ],
        ),
      ),
    );
  }
}
