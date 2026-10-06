import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/shows/domain/entities/show.dart';
import 'optimized_cached_image.dart';
import 'ticket/stage_entrance.dart';
import 'ticket/ticket_kit.dart';

/// Paylaşılan oyun kartı — "bilet dili": kart, koçanı delik çizgisiyle
/// ayrılmış bir tiyatro biletidir.
///
/// Gövde: afiş (gerçek, kırpılmadan üstte) + oyun adı. Koçan: türü ya da
/// "Başka platformda" + süre, ve oyuna özgü barkod. Yeni eklenen oyunlarda
/// afişin köşesine küçük bir "YENİ" mürekkep damgası basılır; başka rozet
/// yığını yok.
///
/// Hover/klavye odağında (web) kart hafifçe kalkar ve `show.photosShowId`
/// doluysa bir kez rastgele seçilen gerçek galeri fotoğrafı afişin üstüne
/// ortadan açılır. Galeri yoksa sadece kalkma olur, görsel uydurulmaz.
class TheatreShowCard extends StatefulWidget {
  final Show show;
  final VoidCallback onTap;

  const TheatreShowCard({
    super.key,
    required this.show,
    required this.onTap,
  });

  @override
  State<TheatreShowCard> createState() => _TheatreShowCardState();
}

class _TheatreShowCardState extends State<TheatreShowCard> {
  bool _active = false;

  /// Kart bağlı kaldığı sürece sabit, bir kez seçilmiş galeri fotoğrafı.
  String? _revealImageUrl;

  @override
  void initState() {
    super.initState();
    final photos = widget.show.photosShowId;
    if (photos.isNotEmpty) {
      _revealImageUrl = photos[Random().nextInt(photos.length)];
    }
  }

  void _setActive(final bool value) {
    if (_active != value) setState(() => _active = value);
  }

  @override
  Widget build(final BuildContext context) {
    final show = widget.show;
    final bool hasReveal =
        _revealImageUrl != null && _revealImageUrl != show.imageUrl;
    final Color tint = Theme.of(context).colorScheme.shadow;
    final List<BoxShadow> shadows = _active
        ? AppShadows.level4(tint)
        : AppShadows.level2(tint);

    return Semantics(
      button: true,
      label: [
        show.name,
        if (show.category.trim().isNotEmpty) show.category,
        if (show.hasExternalTicketing) 'biletler başka platformda',
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHover: _setActive,
          onFocusChange: _setActive,
          mouseCursor: SystemMouseCursors.click,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: AnimatedSlide(
            offset: _active ? const Offset(0, -0.015) : Offset.zero,
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            child: LayoutBuilder(
              builder: (final context, final constraints) {
                final bool compact = constraints.maxWidth < 200;
                final double notch = compact ? 8 : 11;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TicketPiece(
                        perforated: TicketEdge.bottom,
                        notch: notch,
                        corner: AppRadius.sm,
                        shadows: shadows,
                        child: _Body(
                          show: show,
                          compact: compact,
                          revealUrl: hasReveal ? _revealImageUrl : null,
                          revealed: _active,
                        ),
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.passthrough,
                      children: [
                        TicketPiece(
                          perforated: TicketEdge.top,
                          notch: notch,
                          corner: AppRadius.sm,
                          shadows: shadows,
                          child: _Stub(show: show, compact: compact),
                        ),
                        const Positioned(
                          top: -1,
                          left: 0,
                          right: 0,
                          height: 2,
                          child: TicketPerforation(),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Show show;
  final bool compact;
  final String? revealUrl;
  final bool revealed;

  const _Body({
    required this.show,
    required this.compact,
    required this.revealUrl,
    required this.revealed,
  });

  @override
  Widget build(final BuildContext context) {
    final double inset = compact ? AppSpacing.sm - 2 : AppSpacing.sm;
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, inset, inset, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: TicketInk.inkSoft(0.08),
                    child: StageHero(
                      tag: 'show_${show.id}',
                      child: OptimizedCachedImage(
                        imageUrl: show.imageUrl,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                  if (revealUrl != null)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: revealed ? 1 : 0),
                      duration: AppMotion.normal,
                      curve: AppMotion.dramatic,
                      builder: (final context, final t, final child) {
                        if (t <= 0) return const SizedBox.shrink();
                        return ClipRect(
                          child: Align(
                            widthFactor: t,
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox.expand(
                        child: OptimizedCachedImage(
                          imageUrl: revealUrl!,
                          fit: BoxFit.cover,
                          borderRadius: 0,
                        ),
                      ),
                    ),
                  if (show.isRecentlyAdded)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: _NewStamp(compact: compact),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                vertical: compact ? AppSpacing.sm : AppSpacing.md),
            child: Text(
              show.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                color: TicketInk.ink,
                fontSize: compact ? 14 : 17,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stub extends StatelessWidget {
  final Show show;
  final bool compact;

  const _Stub({required this.show, required this.compact});

  @override
  Widget build(final BuildContext context) {
    final String kind = show.hasExternalTicketing
        ? 'BAŞKA PLATFORMDA'
        : (show.category.trim().isEmpty
            ? 'OYUN'
            : show.category.trim().toUpperCase());
    final String detail = show.duration.trim().isNotEmpty
        ? show.duration.trim()
        : show.ageLimit.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          compact ? AppSpacing.sm + 2 : AppSpacing.md,
          compact ? AppSpacing.sm : AppSpacing.md,
          compact ? AppSpacing.sm + 2 : AppSpacing.md,
          compact ? AppSpacing.sm : AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (show.hasExternalTicketing) ...[
                      Icon(Icons.open_in_new_rounded,
                          size: 10, color: TicketInk.accentOf(context)),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(
                        kind,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TicketInk.label(
                          color: show.hasExternalTicketing
                              ? TicketInk.accentOf(context)
                              : null,
                        ).copyWith(fontSize: compact ? 8.5 : 9.5),
                      ),
                    ),
                  ],
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TicketInk.value(size: compact ? 11.5 : 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: compact ? 30 : 44,
            child: TicketBarcode(seed: show.id, height: compact ? 22 : 28),
          ),
        ],
      ),
    );
  }
}

/// Afişin köşesine basılan küçük "YENİ" damgası (son 21 gün — gerçek
/// `createdAt`'tan).
class _NewStamp extends StatelessWidget {
  final bool compact;
  const _NewStamp({required this.compact});

  @override
  Widget build(final BuildContext context) {
    final Color accent = TicketInk.accentOf(context);
    return Transform.rotate(
      angle: -0.12,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TicketInk.paper.withOpacity(0.92),
          border: Border.all(color: accent, width: 1.6),
          borderRadius: BorderRadius.circular(AppRadius.xs / 2),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : AppSpacing.sm - 1, vertical: 2),
          child: Text(
            'YENİ',
            style: TextStyle(
              color: accent,
              fontSize: compact ? 9 : 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}
