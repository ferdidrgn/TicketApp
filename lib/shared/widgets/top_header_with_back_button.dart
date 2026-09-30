import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/common/extentions/app_context_ui_extension.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../navigation/widgets/nav_handler.dart';

/// Geri butonlu ortak sayfa başlığı (`BasePageWrapper` ve birkaç detay
/// sayfası kullanıyor). Bilet dilindeki başlıklarla aynı: Playfair Display,
/// temanın metin renginde — eski gradyan boyalı (ShaderMask) yazı ve buzlu
/// cam geri butonu kaldırıldı. Genel API (title/subtitle/rightIcon/
/// showBackButton) aynı.
class TopHeaderWithBackButton extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? rightIcon;
  final bool showBackButton;

  const TopHeaderWithBackButton({
    super.key,
    this.title,
    this.subtitle,
    this.rightIcon,
    this.showBackButton = true,
  });

  @override
  Widget build(final BuildContext context) {
    final bool hasTitle = title != null && title!.isNotEmpty;
    final bool hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    if (!hasTitle && !hasSubtitle && !showBackButton)
      return const SizedBox.shrink();

    final cs = context.colors;
    // Akışkan başlık: 360px telefonda 28, geniş ekranda 34.
    final double w = MediaQuery.sizeOf(context).width;
    final double titleSize =
        28 + 6 * ((w - 360) / (1024 - 360)).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Sol Kısım: Geri Butonu
              if (showBackButton)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.md),
                  child: _HeaderBackButton(),
                ),

              // 2. Orta Kısım: Başlık
              if (hasTitle)
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.5,
                        height: 1.08,
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),

              // 3. Sağ Kısım: İkon (bilgi amaçlı, soluk)
              if (rightIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: ExcludeSemantics(
                    child: Icon(rightIcon,
                        color: cs.onSurfaceVariant, size: 24),
                  ),
                ),
            ],
          ),

          // Alt Başlık (Subtitle)
          if (hasSubtitle) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              // Geri butonu (48) + aralık (12) hizasında başlar.
              padding: EdgeInsets.only(
                  left: showBackButton ? 48 + AppSpacing.md : 0),
              child: Text(
                subtitle!,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 48×48 geri butonu: temanın çizgi rengiyle ince çerçeve, hover'da hafif
/// zemin, klavye odağında vurgu tonu.
class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton();

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    return Semantics(
      button: true,
      label: 'Geri',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Geri',
        child: SizedBox(
          width: 48,
          height: 48,
          child: Material(
            type: MaterialType.transparency,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              side: BorderSide(color: cs.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => NavigationHandler.smartGoBack(context),
              focusColor: cs.primary.withOpacity(0.16),
              hoverColor: cs.onSurface.withOpacity(0.05),
              child: Icon(Icons.arrow_back_rounded,
                  size: 22, color: cs.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
