import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'craft.dart';
import 'optimized_cached_image.dart';

/// Ferah listing dili — referans: selamlama, hap çipler, fotoğraf üstü
/// konum, daire metrikler, cam galeri çubuğu. Renkler temadan; sage yeşil
/// gömülmez. Wipe / Ken Burns yok. Hareket yalnızca dokunuşa cevap.

TextStyle listingUi({
  required final Color color,
  final double size = 15,
  final FontWeight weight = FontWeight.w600,
  final double height = 1.25,
}) =>
    GoogleFonts.manrope(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: height,
    );

class ListingGreeting extends StatelessWidget {
  final String name;
  final String prompt;
  final VoidCallback? onSearch;

  const ListingGreeting({
    super.key,
    required this.name,
    required this.prompt,
    this.onSearch,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String title = name.isEmpty ? 'Merhaba' : 'Merhaba\n$name!';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: listingUi(
            color: cs.onSurface,
            size: 34,
            weight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          prompt,
          style: listingUi(
            color: cs.onSurfaceVariant,
            size: 15,
            weight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        if (onSearch != null) ...[
          const SizedBox(height: AppSpacing.xl),
          ListingSearchHit(onTap: onSearch!),
        ],
      ],
    );
  }
}

class ListingSearchHit extends StatelessWidget {
  final VoidCallback onTap;
  const ListingSearchHit({super.key, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Ara',
      excludeSemantics: true,
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Oyun, oyuncu, sahne ara',
                    style: listingUi(
                      color: cs.onSurfaceVariant,
                      size: 15,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ListingLabel extends StatelessWidget {
  final String text;
  const ListingLabel(this.text, {super.key});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          text,
          style: listingUi(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 13,
            weight: FontWeight.w700,
          ),
        ),
      );
}

class ListingChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const ListingChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return PressScale(
      label: label,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.spring,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              label,
              style: listingUi(
                color: selected ? cs.onPrimaryContainer : cs.onSurface,
                size: 14,
                weight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListingChipRow extends StatelessWidget {
  final List<Widget> children;
  const ListingChipRow({super.key, required this.children});

  @override
  Widget build(final BuildContext context) => SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: children.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(width: AppSpacing.sm),
          itemBuilder: (final context, final i) => children[i],
        ),
      );
}

class ListingMetricOrb extends StatelessWidget {
  final String value;
  final String unit;
  final bool emphasized;

  const ListingMetricOrb({
    super.key,
    required this.value,
    required this.unit,
    this.emphasized = false,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fill = emphasized ? cs.primary : cs.surfaceContainerLow;
    final Color ink = emphasized ? cs.onPrimary : cs.onSurface;
    final Color mute = emphasized
        ? cs.onPrimary.withValues(alpha: 0.8)
        : cs.onSurfaceVariant;
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: listingUi(color: ink, size: 16, weight: FontWeight.w800),
          ),
          Text(
            unit,
            maxLines: 1,
            style: listingUi(color: mute, size: 11, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class ListingPhotoFrame extends StatelessWidget {
  final String imageUrl;
  final String? overlay;
  final double height;
  final Widget? child;
  final VoidCallback? onTap;

  const ListingPhotoFrame({
    super.key,
    required this.imageUrl,
    this.overlay,
    this.height = 220,
    this.child,
    this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget image = OptimizedCachedImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      borderRadius: 0,
    );
    final Widget frame = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (overlay != null && overlay!.trim().isNotEmpty)
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.place_rounded, size: 16, color: cs.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            overlay!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: listingUi(
                              color: cs.onSurface,
                              size: 12,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (child != null) child!,
          ],
        ),
      ),
    );
    if (onTap == null) return frame;
    return PressScale(onTap: onTap, child: frame);
  }
}

class ListingGlassBar extends StatelessWidget {
  final String left;
  final String right;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;

  const ListingGlassBar({
    super.key,
    required this.left,
    required this.right,
    this.onLeft,
    this.onRight,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.level2(cs.shadow),
      ),
      child: Row(
        children: [
          _nav(left, Icons.chevron_left_rounded, onLeft, cs),
          const Spacer(),
          Icon(Icons.circle_outlined, size: 18, color: cs.primary),
          const Spacer(),
          _nav(right, Icons.chevron_right_rounded, onRight, cs, trailing: true),
        ],
      ),
    );
  }

  Widget _nav(
    final String label,
    final IconData icon,
    final VoidCallback? onTap,
    final ColorScheme cs, {
    final bool trailing = false,
  }) {
    final Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!trailing) Icon(icon, color: cs.onSurface),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: listingUi(color: cs.onSurface, size: 13, weight: FontWeight.w700),
          ),
        ),
        if (trailing) Icon(icon, color: cs.onSurface),
      ],
    );
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      child: row,
    );
  }
}

class ListingCta extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  const ListingCta({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        onPressed: busy || onPressed == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed!();
              },
        style: FilledButton.styleFrom(
          backgroundColor: cs.onSurface,
          foregroundColor: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: busy
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: cs.surface),
              )
            : Text(
                label,
                style: listingUi(
                    color: cs.surface, size: 16, weight: FontWeight.w800),
              ),
      ),
    );
  }
}

/// Yuvarlak kategori seçici — seçilince hafif büyür (wipe/KenBurns yok).
class ListingCategoryOrb extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ListingCategoryOrb({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool reduce = MediaQuery.disableAnimationsOf(context);
    return PressScale(
      label: label,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: selected && !reduce ? 1.08 : 1,
            duration: AppMotion.fast,
            curve: AppMotion.spring,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.spring,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: selected ? cs.primary : cs.surfaceContainerLow,
                shape: BoxShape.circle,
                boxShadow: selected ? AppShadows.level2(cs.shadow) : null,
              ),
              child: Icon(
                icon,
                color: selected ? cs.onPrimary : cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: listingUi(
              color: selected ? cs.primary : cs.onSurfaceVariant,
              size: 12,
              weight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fotoğrafın altına binen aksiyon kartı (sağlık mock’undaki overlap).
class ListingOverlapCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badge;
  final List<Widget> slots;
  final VoidCallback? onTap;

  const ListingOverlapCard({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.slots = const [],
    this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.level3(cs.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: listingUi(
                    color: cs.onPrimary,
                    size: 18,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              if (badge != null && badge!.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: cs.onSurface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    badge!,
                    style: listingUi(
                      color: cs.surface,
                      size: 12,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: listingUi(
                color: cs.onPrimary.withValues(alpha: 0.85),
                size: 13,
                weight: FontWeight.w600,
              ),
            ),
          ],
          if (slots.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: slots),
          ],
        ],
      ),
    );
    if (onTap == null) return card;
    return PressScale(onTap: onTap, child: card);
  }
}

/// Dalgalı alt kenarlı vurgu kartı — ClipPath, sabit marka rengi yok.
class ListingWaveCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;

  const ListingWaveCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget body = ClipPath(
      clipper: const _WaveBottomClipper(),
      child: Container(
        width: double.infinity,
        color: color ?? cs.primaryContainer,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.huge,
        ),
        child: child,
      ),
    );
    if (onTap == null) return body;
    return PressScale(onTap: onTap, child: body);
  }
}

class _WaveBottomClipper extends CustomClipper<Path> {
  const _WaveBottomClipper();

  @override
  Path getClip(final Size size) {
    final Path p = Path()..lineTo(0, size.height - 28);
    p.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 18,
    );
    p.quadraticBezierTo(
      size.width * 0.75,
      size.height - 36,
      size.width,
      size.height - 14,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant final CustomClipper<Path> oldClipper) => false;
}

/// Koyu yüzen pill aksiyon çubuğu.
class ListingFloatBar extends StatelessWidget {
  final List<Widget> children;

  const ListingFloatBar({super.key, required this.children});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.onSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.level3(cs.shadow),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      ),
    );
  }
}

/// Hap arama kutusu — TicketSearchShell yerine.
class ListingSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final String hint;
  final bool autofocus;
  final Widget? hintOverlay;

  const ListingSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.hint = 'Oyun, oyuncu, sahne ara',
    this.autofocus = false,
    this.hintOverlay,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (controller.text.isEmpty && hintOverlay != null)
                  IgnorePointer(child: hintOverlay!),
                TextField(
                  controller: controller,
                  autofocus: autofocus,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  textInputAction: TextInputAction.search,
                  style: listingUi(
                    color: cs.onSurface,
                    size: 15,
                    weight: FontWeight.w600,
                  ),
                  cursorColor: cs.primary,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    hintText: hintOverlay == null ? hint : null,
                    hintStyle: listingUi(
                      color: cs.onSurfaceVariant,
                      size: 15,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onClear != null && controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Temizle',
              onPressed: onClear,
              icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
