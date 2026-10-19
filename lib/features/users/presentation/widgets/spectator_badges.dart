import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../reviews/data/review_repository.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/presentation/widgets/review_widgets.dart';

class _Badge {
  final String id;
  final String title;
  final String hint;
  final IconData icon;
  final bool earned;
  const _Badge(this.id, this.title, this.hint, this.icon, this.earned);
}

/// Seyirci karnesinin ikinci katmanı: gerçek bilet + yorum verisinden
/// sayılar ve rozetler. Yeni kazanılan rozet konfeti ve damga animasyonuyla
/// kutlanır (yalnızca bu cihazda daha önce görülmemişse).
class SpectatorBadges extends ConsumerStatefulWidget {
  final String userId;
  final int seenShows; // izlenen farklı oyun
  final int seenStages; // izlenen farklı sahne

  const SpectatorBadges({
    super.key,
    required this.userId,
    required this.seenShows,
    required this.seenStages,
  });

  @override
  ConsumerState<SpectatorBadges> createState() => _SpectatorBadgesState();
}

class _SpectatorBadgesState extends ConsumerState<SpectatorBadges> {
  final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));
  Set<String> _fresh = {};
  String _celebratedKey = '';

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  List<_Badge> _badges(final List<Review> mine) {
    final int n = mine.length;
    return [
      _Badge('first_seen', 'İlk perde', 'İlk oyununu izle', Icons.theater_comedy_rounded,
          widget.seenShows >= 1),
      _Badge('five_shows', 'Müdavim', '5 farklı oyun izle',
          Icons.local_activity_rounded, widget.seenShows >= 5),
      _Badge('ten_shows', 'Tiyatro kurdu', '10 farklı oyun izle',
          Icons.auto_stories_rounded, widget.seenShows >= 10),
      _Badge('stages_5', 'Sahne gezgini', '5 farklı sahnede oyun izle',
          Icons.place_rounded, widget.seenStages >= 5),
      _Badge('first_review', 'İlk söz', 'İlk yorumunu yaz', Icons.rate_review_rounded,
          n >= 1),
      _Badge('critic', 'Eleştirmen', '5 yorum yaz', Icons.edit_note_rounded, n >= 5),
    ];
  }

  /// Kazanılan rozetleri cihazdaki kayıtla karşılaştırır; ilk çalıştırmada
  /// sessizce kaydeder, sonraki yeni rozetler için kutlama başlatır.
  Future<void> _celebrateNew(final List<_Badge> badges) async {
    final Set<String> earned = {
      for (final _Badge b in badges)
        if (b.earned) b.id,
    };
    final String key = (earned.toList()..sort()).join(',');
    if (key == _celebratedKey) return;
    _celebratedKey = key;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String prefKey = 'earned_badges_${widget.userId}';
      final List<String>? stored = p.getStringList(prefKey);
      await p.setStringList(prefKey, earned.toList());
      if (stored == null) return; // ilk kez: sessizce kaydet
      final Set<String> fresh = earned.difference(stored.toSet());
      if (fresh.isEmpty || !mounted) return;
      setState(() => _fresh = fresh);
      HapticFeedback.mediumImpact();
      if (!Sk.reduceMotion(context)) _confetti.play();
    } catch (_) {}
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Review> mine =
        ref.watch(reviewsByUserProvider(widget.userId)).value ?? const [];
    final List<_Badge> badges = _badges(mine);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _celebrateNew(badges);
    });

    final double avg = mine.isEmpty
        ? 0
        : mine.fold<int>(0, (a, r) => a + r.rating) / mine.length;

    Widget stat(final String value, final String label, final IconData icon) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(height: 4),
              Text(value, style: Sk.display(context, size: 24, height: 1.0)),
              const SizedBox(height: 2),
              Text(label,
                  style: Sk.ui(context,
                      size: 11.5,
                      color: cs.onSurfaceVariant,
                      weight: FontWeight.w700)),
            ]),
          ),
        );

    final int earnedCount = badges.where((b) => b.earned).length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              stat('${widget.seenShows}', 'İzlenen oyun',
                  Icons.theater_comedy_rounded),
              const SizedBox(width: AppSpacing.sm + 2),
              stat('${mine.length}', 'Yorum', Icons.rate_review_rounded),
              const SizedBox(width: AppSpacing.sm + 2),
              stat(mine.isEmpty ? '—' : avg.toStringAsFixed(1), 'Ort. puanın',
                  Icons.star_rounded),
            ]),
            if (mine.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(child: StarRow(rating: avg, size: 18)),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text('Rozetler · $earnedCount/${badges.length}',
                style: Sk.ui(context, size: 15, weight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm + 2,
              crossAxisSpacing: AppSpacing.sm + 2,
              childAspectRatio: 0.92,
              children: [
                for (int i = 0; i < badges.length; i++)
                  _BadgeTile(badge: badges[i], fresh: _fresh.contains(badges[i].id)),
              ],
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: math.pi / 2,
              emissionFrequency: 0.06,
              numberOfParticles: 18,
              maxBlastForce: 22,
              minBlastForce: 8,
              gravity: 0.25,
              shouldLoop: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final _Badge badge;
  final bool fresh;
  const _BadgeTile({required this.badge, required this.fresh});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fg = badge.earned ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    final Widget tile = Semantics(
      label: badge.earned
          ? '${badge.title} rozeti kazanıldı'
          : '${badge.title} rozeti kilitli: ${badge.hint}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: badge.earned
              ? cs.primaryContainer
              : cs.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: badge.earned
                ? cs.primary.withValues(alpha: 0.6)
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(badge.earned ? badge.icon : Icons.lock_outline_rounded,
                size: 28, color: fg),
            const SizedBox(height: 6),
            Text(badge.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Sk.ui(context, size: 12, color: fg, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(badge.earned ? 'Kazanıldı' : badge.hint,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Sk.ui(context,
                    size: 10.5,
                    color: fg.withValues(alpha: 0.8),
                    weight: FontWeight.w600,
                    height: 1.2)),
          ],
        ),
      ),
    );
    if (!fresh) return tile;
    // Yeni kazanılan: damga gibi büyüyüp oturur.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.6, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (_, final v, final child) =>
          Transform.scale(scale: v, child: child),
      child: tile,
    );
  }
}
