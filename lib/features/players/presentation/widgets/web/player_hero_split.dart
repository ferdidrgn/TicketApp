import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/features/players/domain/entities/player.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import 'scroll_reveal.dart';

/// 🎭 EDITORIAL HERO SPLIT
///
/// Masaüstünde sanatçı sayfasının en üstü: solda büyük bir portre fotoğrafı
/// (hover'da hafif yakınlaşan), sağda isim / alıntı / biyografi / işbirlikleri
/// dikey akışı — landing sitesindeki "büyük görsel + kısa çarpıcı başlık"
/// hissini masaüstü genişliğinde yeniden kuruyor.
class PlayerHeroSplit extends StatelessWidget {
  final Player player;
  final int activeShowCount;
  final int pastShowCount;

  const PlayerHeroSplit({
    super.key,
    required this.player,
    required this.activeShowCount,
    required this.pastShowCount,
  });

  @override
  Widget build(final BuildContext context) {
    final String fullName = '${player.firstName} ${player.lastName}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: ScrollReveal(
            beginOffset: const Offset(-0.06, 0),
            child: _PortraitImage(imageUrl: player.imageUrl, name: fullName),
          ),
        ),
        const SizedBox(width: 72),
        Expanded(
          flex: 6,
          child: ScrollReveal(
            delay: const Duration(milliseconds: 150),
            beginOffset: const Offset(0.04, 0),
            child: _HeroCopy(
              player: player,
              fullName: fullName,
              activeShowCount: activeShowCount,
              pastShowCount: pastShowCount,
            ),
          ),
        ),
      ],
    );
  }
}

class _PortraitImage extends StatefulWidget {
  final String imageUrl;
  final String name;

  const _PortraitImage({required this.imageUrl, required this.name});

  @override
  State<_PortraitImage> createState() => _PortraitImageState();
}

class _PortraitImageState extends State<_PortraitImage> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    return MouseRegion(
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.basic,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: WebColors.primaryGold.withOpacity(_hovered ? 0.35 : 0.22),
              blurRadius: _hovered ? 60 : 40,
              spreadRadius: 2,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  scale: _hovered ? 1.05 : 1.0,
                  child: OptimizedCachedImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Alt taraftaki hafif gradyan; portre çerçevesine "sahne" hissi verir
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        WebColors.veryDarkBlue.withOpacity(0.55),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 22,
                right: 22,
                bottom: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: WebColors.whiteText.withOpacity(0.35)),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'U S T A   S A N A T Ç I',
                    style: TextStyle(
                      color: WebColors.whiteText,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final Player player;
  final String fullName;
  final int activeShowCount;
  final int pastShowCount;

  const _HeroCopy({
    required this.player,
    required this.fullName,
    required this.activeShowCount,
    required this.pastShowCount,
  });

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: WebColors.primaryGold.withOpacity(0.35),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Text(
              'SANATÇI PROFİLİ',
              style: TextStyle(
                color: WebColors.veryDarkBlue,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            fullName.toUpperCase(),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: WebColors.whiteText,
              height: 0.98,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _StatPill(label: 'AKTİF', value: activeShowCount),
              const SizedBox(width: 16),
              _StatPill(label: 'ARŞİV', value: pastShowCount),
              const SizedBox(width: 16),
              _StatPill(label: 'ÖDÜL', value: player.achievements.length),
            ],
          ),
          if (player.quote.trim().isNotEmpty) ...[
            const SizedBox(height: 36),
            _QuoteBlock(quote: player.quote),
          ],
          if (player.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 36),
            Text(
              player.bio,
              style: const TextStyle(
                fontSize: 17,
                height: 1.9,
                color: WebColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
          if (player.collaborations.isNotEmpty) ...[
            const SizedBox(height: 40),
            const Text(
              'GÜÇLÜ İŞBİRLİKLERİ',
              style: TextStyle(
                color: WebColors.secondaryAccentLight,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: player.collaborations
                  .map((final c) => _CollabChip(label: c))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: WebColors.primaryGoldLight,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: WebColors.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  final String quote;

  const _QuoteBlock({required this.quote});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: WebColors.primaryGold, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded,
              color: WebColors.primaryGold, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              quote,
              style: const TextStyle(
                fontSize: 19,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: WebColors.lightWhite,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollabChip extends StatelessWidget {
  final String label;

  const _CollabChip({required this.label});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: WebColors.darkBlueAccent.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WebColors.secondaryAccent.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: WebColors.whiteText,
        ),
      ),
    );
  }
}
