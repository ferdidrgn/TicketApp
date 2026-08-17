import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

/// ══════════════════════════════════════════════════════════════════════
/// TASARIM SİSTEMİ 2.0 — Yeniden kullanılabilir Bento/Glassmorphism
/// bileşenleri. Her yeni ekran bu birincil parçalardan kurulur, böylece
/// tüm uygulamada tutarlı bir "Linear/Vercel" hissi elde edilir.
/// ══════════════════════════════════════════════════════════════════════

/// Düz zemin + mikro kenarlık ile standart Bento kartı.
class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color borderColor;

  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.color,
    this.onTap,
    this.gradient,
    this.borderColor = BentoColors.microBorder,
  });

  @override
  Widget build(final BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? BentoColors.card) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Buzlu cam efektli kart — genelde bir görselin/hero'nun üzerine
/// bindirilen içerikler için (BackdropFilter ile gerçek blur).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color tint;
  final Color borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.blur = 20,
    this.tint = const Color(0x66101012),
    this.borderColor = BentoColors.microBorderStrong,
  });

  @override
  Widget build(final BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor),
            ),
            child: child,
          ),
        ),
      );
}

/// Küçük pill-şeklinde rozet — kategori/durum etiketleri için.
class BentoBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color? backgroundColor;

  const BentoBadge({
    super.key,
    required this.label,
    this.icon,
    this.color = BentoColors.indigo,
    this.backgroundColor,
  });

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor ?? color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
}

/// Bento bölüm başlığı: ikon rozeti + başlık + opsiyonel alt başlık/aksiyon.
class BentoSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onActionTap;
  final String? actionLabel;

  const BentoSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onActionTap,
    this.actionLabel,
  });

  @override
  Widget build(final BuildContext context) => Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BentoColors.indigo.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: BentoColors.indigoLight),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!,
                        style: const TextStyle(
                            color: Color(0xFFA1A1AA), fontSize: 12.5)),
                  ),
              ],
            ),
          ),
          if (onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                foregroundColor: BentoColors.indigoLight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel ?? 'Tümü',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 14),
                ],
              ),
            ),
        ],
      );
}

/// Tutarlı giriş animasyonu: hafif aşağıdan kayarak belirir.
/// Listelerde `delay: Duration(milliseconds: 60 * index)` ile kademeli
/// (staggered) bir açılış elde edilir.
class FadeInUp extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  const FadeInUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = 0.06,
  });

  @override
  Widget build(final BuildContext context) => child
      .animate(delay: delay)
      .fadeIn(duration: duration, curve: Curves.easeOutCubic)
      .slideY(
          begin: offset,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic);
}

/// Bento boş-durum (empty state) kartı.
class BentoEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const BentoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(final BuildContext context) => BentoCard(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BentoColors.highlight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 26, color: const Color(0xFF71717A)),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      );
}

/// Bento hata durumu kartı (tekrar dene aksiyonlu).
class BentoErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const BentoErrorState(
      {super.key, required this.message, required this.onRetry});

  @override
  Widget build(final BuildContext context) => BentoCard(
        borderColor: const Color(0x33EF4444),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 26, color: Color(0xFFF87171)),
            ),
            const SizedBox(height: 20),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: BentoColors.indigo,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
}
