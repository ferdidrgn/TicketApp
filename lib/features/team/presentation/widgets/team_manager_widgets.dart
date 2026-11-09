import 'package:flutter/material.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';

/// Ekip yöneticisi ekranında tekrar eden küçük parçalar. Bu ekran,
/// admin paneli gibi bilinçli olarak "sade iç araç" — bilet
/// dili/perde/spot süsü YOK (bkz. `.claude/skills/tiyatrol-design/
/// references/history.md`), ama renk/`AppSpacing`/`AppRadius`/
/// `AppShadows` token kuralları tam uygulanır. Admin modülünden
/// bağımsız — kendi küçük widget kümesi (bkz. CLAUDE.md: team özelliği
/// admin'den ayrı bir klasör).

/// Bölüm kartı — bir ekran bölümünü (bildirim, özet…) tek bir yüzeyde
/// toplar.
class TeamSectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const TeamSectionCard({
    super.key,
    this.title,
    this.icon,
    required this.child,
    this.padding,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: AppShadows.level1(colors.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: context.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}

/// Hata/uyarı/bilgi satırı — dialog gerektirmeyen kalıcı geri bildirim.
class TeamInlineBanner extends StatelessWidget {
  final String message;
  final TeamBannerTone tone;

  const TeamInlineBanner(
      {super.key, required this.message, this.tone = TeamBannerTone.error});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final color = switch (tone) {
      TeamBannerTone.error => colors.error,
      TeamBannerTone.warning => Colors.orange,
      TeamBannerTone.info => colors.primary,
    };
    final icon = switch (tone) {
      TeamBannerTone.error => Icons.error_outline_rounded,
      TeamBannerTone.warning => Icons.warning_amber_rounded,
      TeamBannerTone.info => Icons.info_outline_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child:
                Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

enum TeamBannerTone { error, warning, info }

/// Basit yükleniyor iskeleti (admin panelindeki `AdminListLoading` ile aynı
/// fikir, bu özellik kendi küçük kopyasını tutar).
class TeamLoadingSkeleton extends StatelessWidget {
  final int rows;
  final double rowHeight;

  const TeamLoadingSkeleton({super.key, this.rows = 3, this.rowHeight = 56});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Column(
      children: List.generate(
        rows,
        (final i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            height: rowHeight,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
      ),
    );
  }
}

/// Boş durum — davet/CTA niteliğinde kısa bir mesaj.
class TeamEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const TeamEmptyState(
      {super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.onSurfaceVariant, size: 36),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Küçük sayı+etiket çifti (önizleme/özet şeritlerinde kullanılır).
class TeamStatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const TeamStatTile(
      {super.key, required this.value, required this.label, this.color});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: color ?? colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
