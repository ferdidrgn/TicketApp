import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/audio/audio_highlight_card.dart';
import '../../../../shared/widgets/bento/bento_primitives.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../domain/entities/audio_highlight.dart';
import '../providers/audio_highlight_provider.dart';
import '../widgets/web/landing/landing_cast_section.dart';
import '../widgets/web/landing/landing_mystery_section.dart';
import '../widgets/web/landing/landing_trailers_section.dart';
import '../widgets/web/theater_section_divider.dart';

/// 🎭 GERÇEK TANITIM (LANDING) SAYFASI — Web'in `/` adresi.
///
/// Marka/atmosfer ağırlıklı, çok bölümlü bir "büyüleyici deneyim" sayfası:
/// hero, değer önerileri, öne çıkan oyunlar (3D hover), fragmanlar
/// (YouTube), perde arkası sürpriz kartları, oyuncu kadrosu, sesli deneyim
/// (monolog/tirat kayıtları), gerçek oyuncu alıntısı ve istatistikler.
/// Her bölüm GERÇEK Firestore verisine bağlıdır — veri yoksa bölüm
/// sessizce gizlenir, asla uydurma içerik gösterilmez. Uygulamanın kendisine
/// (mobil dahil) hiçbir şekilde dokunmuyor; gerçek deneyim "Uygulamaya Gir"
/// CTA'sının arkasında (`/app`).
class WebLandingPage extends ConsumerWidget {
  const WebLandingPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final showsAsync = ref.watch(showsProvider(isLimit: true));
    final stagesAsync = ref.watch(stagesProvider(isLimit: true));
    final audioAsync = ref.watch(audioHighlightsProvider);
    final width = MediaQuery.of(context).size.width;
    final bool isLarge = width > 900;
    final double hPad = width > 1400 ? 100 : (width > 900 ? 60 : 24);
    final shows = showsAsync.value ?? const <Show>[];
    final audioHighlights = audioAsync.value ?? const <AudioHighlight>[];

    return Scaffold(
      backgroundColor: WebColors.darkBlueBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LandingNavBar(hPad: hPad),
            _LandingHero(
                hPad: hPad,
                isLarge: isLarge,
                heroShow: shows.isNotEmpty ? shows.first : null),
            const TheaterSectionDivider(style: DividerStyle.iconCenter, height: 90),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _ValueProps(isLarge: isLarge),
            ),
            const SizedBox(height: 80),
            if (shows.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _FeaturedShows(shows: shows),
              ),
            const SizedBox(height: 80),
            if (shows.any((final s) =>
                s.trailerYoutubeId != null && s.trailerYoutubeId!.trim().isNotEmpty)) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: LandingTrailersSection(shows: shows),
              ),
              const SizedBox(height: 80),
            ],
            if (shows.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: LandingMysterySection(shows: shows),
              ),
              const SizedBox(height: 80),
            ],
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: const LandingCastSection(),
            ),
            const SizedBox(height: 80),
            if (audioHighlights.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _AudioHighlightsSection(highlights: audioHighlights),
              ),
              const SizedBox(height: 80),
            ],
            const _PullQuoteSection(),
            const SizedBox(height: 80),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _StatsBar(
                showCount: shows.length,
                stageCount: (stagesAsync.value ?? const []).length,
              ),
            ),
            const SizedBox(height: 80),
            const Footer(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ÜST BAR
// ══════════════════════════════════════════════════════════════
class _LandingNavBar extends StatelessWidget {
  final double hPad;
  const _LandingNavBar({required this.hPad});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
        child: Row(
          children: [
            const Icon(Icons.theater_comedy_rounded,
                color: WebColors.primaryGold, size: 26),
            const SizedBox(width: 10),
            const Text('TiyatRol',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
            const Spacer(),
            TextButton(
              onPressed: () => NavigationHandler.goToLogin(context),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Giriş Yap'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => NavigationHandler.goToApp(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: WebColors.primaryGold,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Uygulamaya Gir',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// HERO — hafif imleç-parallax + yüzen bilgi rozetleri
// ══════════════════════════════════════════════════════════════
class _LandingHero extends StatefulWidget {
  final double hPad;
  final bool isLarge;
  final Show? heroShow;

  const _LandingHero(
      {required this.hPad, required this.isLarge, required this.heroShow});

  @override
  State<_LandingHero> createState() => _LandingHeroState();
}

class _LandingHeroState extends State<_LandingHero> {
  Offset _parallax = Offset.zero;

  // Sabit referans boyutlar kullanılıyor: hero'nun yüksekliği bir
  // ScrollView içinde sınırsız (infinity) olabildiğinden gerçek widget
  // boyutuna değil, tipik bir hero alanına göre normalize ediyoruz — efekt
  // zaten çok hafif/kozmetik olduğu için bu yeterli.
  void _onHover(final PointerEvent event, final double width) {
    if (!widget.isLarge) return;
    final dx = (event.localPosition.dx / width - 0.5) * 2;
    final dy =
        ((event.localPosition.dy / 640 - 0.5) * 2).clamp(-1.0, 1.0).toDouble();
    setState(() => _parallax = Offset(dx * 14, dy * 10));
  }

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final constraints) => MouseRegion(
          onHover: (final e) => _onHover(e, constraints.maxWidth),
          onExit: (final _) => setState(() => _parallax = Offset.zero),
          child: Stack(
            children: [
              if (widget.heroShow != null)
                Positioned.fill(
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    offset: Offset(_parallax.dx / 400, _parallax.dy / 400),
                    child: Opacity(
                      opacity: 0.22,
                      child: CachedNetworkImage(
                          imageUrl: widget.heroShow!.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        WebColors.darkBlueBackground.withOpacity(0.3),
                        WebColors.darkBlueBackground,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(widget.hPad, 64, widget.hPad, 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: WebColors.primaryGold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: WebColors.primaryGold.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LivePulseDot(),
                          const SizedBox(width: 8),
                          const Text('TÜRKİYE\'NİN SAHNE PLATFORMU',
                              style: TextStyle(
                                  color: WebColors.primaryGoldLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Sanat Seni Bekliyor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.isLarge ? 64 : 40,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Text(
                        'Tiyatro, konser ve etkinlikleri keşfet; koltuğunu seç, '
                        'biletini saniyeler içinde al. Fragmanları izle, sahne '
                        'kadrosuyla tanış, perde arkasındaki sürprizleri keşfet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: widget.isLarge ? 17 : 15,
                            height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        ElevatedButton(
                          onPressed: () => NavigationHandler.goToApp(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WebColors.primaryGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('ETKİNLİKLERİ KEŞFET',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        OutlinedButton(
                          onPressed: () => NavigationHandler.goToApp(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('NASIL ÇALIŞIR?',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                    if (widget.heroShow != null) ...[
                      const SizedBox(height: 48),
                      _HeroFloatingBadge(show: widget.heroShow!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _LivePulseDot extends StatefulWidget {
  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
              color: WebColors.accentEmerald, shape: BoxShape.circle),
        ),
      );
}

class _HeroFloatingBadge extends StatelessWidget {
  final Show show;
  const _HeroFloatingBadge({required this.show});

  @override
  Widget build(final BuildContext context) => GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        radius: 18,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 40,
                height: 40,
                child: CachedNetworkImage(
                    imageUrl: show.imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ŞU AN SAHNEDE',
                    style: TextStyle(
                        color: WebColors.primaryGoldLight,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(show.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// DEĞER ÖNERİLERİ
// ══════════════════════════════════════════════════════════════
class _ValueProps extends StatelessWidget {
  final bool isLarge;
  const _ValueProps({required this.isLarge});

  static const _items = [
    (
      Icons.explore_rounded,
      'Binlerce Etkinlik',
      'Tiyatrodan konsere, stand-up\'tan müzeye — şehrindeki tüm sahneler tek yerde.'
    ),
    (
      Icons.event_seat_rounded,
      'Koltuğunu Sen Seç',
      'Gerçek zamanlı koltuk haritasından yerini gör, saniyeler içinde rezerve et.'
    ),
    (
      Icons.verified_user_rounded,
      'Güvenli Ödeme',
      'Türkiye\'nin güvenilir ödeme altyapılarıyla korumalı, anında bilet teslimi.'
    ),
  ];

  @override
  Widget build(final BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 24,
        runSpacing: 24,
        children: _items
            .map((final item) => SizedBox(
                  width: isLarge ? 340 : double.infinity,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: WebColors.darkBlueSurface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: WebColors.microBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: WebColors.primaryGold.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(item.$1,
                              color: WebColors.primaryGoldLight, size: 26),
                        ),
                        const SizedBox(height: 18),
                        Text(item.$2,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(item.$3,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13.5,
                                height: 1.5)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      );
}

// ══════════════════════════════════════════════════════════════
// ÖNE ÇIKAN OYUNLAR — 3D imleç-tilt kartlar
// ══════════════════════════════════════════════════════════════
class _FeaturedShows extends StatelessWidget {
  final List<Show> shows;
  const _FeaturedShows({required this.shows});

  @override
  Widget build(final BuildContext context) {
    final preview = shows.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Öne Çıkan Oyunlar',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
            TextButton(
              onPressed: () => NavigationHandler.goToApp(context),
              style: TextButton.styleFrom(
                  foregroundColor: WebColors.primaryGoldLight),
              child: const Text('Tümünü Keşfet →'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 320,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: preview.length,
            separatorBuilder: (final _, final __) => const SizedBox(width: 20),
            itemBuilder: (final context, final index) =>
                _FeaturedShowTile(show: preview[index]),
          ),
        ),
      ],
    );
  }
}

class _FeaturedShowTile extends StatefulWidget {
  final Show show;
  const _FeaturedShowTile({required this.show});

  @override
  State<_FeaturedShowTile> createState() => _FeaturedShowTileState();
}

class _FeaturedShowTileState extends State<_FeaturedShowTile> {
  static const double _w = 220, _h = 300;
  double _rotX = 0, _rotY = 0;
  bool _hovering = false;

  void _onHover(final PointerEvent e) {
    final dx = (e.localPosition.dx / _w - 0.5) * 2;
    final dy = (e.localPosition.dy / _h - 0.5) * 2;
    setState(() {
      _rotY = dx * 0.12;
      _rotX = -dy * 0.12;
    });
  }

  void _reset() => setState(() {
        _hovering = false;
        _rotX = 0;
        _rotY = 0;
      });

  @override
  Widget build(final BuildContext context) => MouseRegion(
        onEnter: (final _) => setState(() => _hovering = true),
        onExit: (final _) => _reset(),
        onHover: _onHover,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => NavigationHandler.goToApp(context),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateX(_rotX)
              ..rotateY(_rotY)
              ..scale(_hovering ? 1.05 : 1.0),
            child: Container(
              width: _w,
              height: _h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _hovering
                        ? WebColors.primaryGold.withOpacity(0.35)
                        : Colors.black.withOpacity(0.35),
                    blurRadius: _hovering ? 28 : 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                        imageUrl: widget.show.imageUrl, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.9)
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                    if (widget.show.trailerYoutubeId != null &&
                        widget.show.trailerYoutubeId!.trim().isNotEmpty)
                      const Positioned(
                        top: 14,
                        right: 14,
                        child: Icon(Icons.play_circle_fill_rounded,
                            color: Colors.white, size: 22),
                      ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.show.category.toUpperCase(),
                              style: const TextStyle(
                                  color: WebColors.primaryGoldLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Text(widget.show.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// SESLİ DENEYİM — monolog/tirat kayıtları
// ══════════════════════════════════════════════════════════════
class _AudioHighlightsSection extends StatelessWidget {
  final List<AudioHighlight> highlights;
  const _AudioHighlightsSection({required this.highlights});

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WebColors.primaryGold.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.graphic_eq_rounded,
                    color: WebColors.primaryGoldLight, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Sesli Deneyim',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Sahneye çıkmadan bir monoloğa kulak ver.',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13.5)),
          const SizedBox(height: 24),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: highlights.length,
              separatorBuilder: (final _, final __) => const SizedBox(width: 18),
              itemBuilder: (final context, final i) =>
                  AudioHighlightCard(highlight: highlights[i]),
            ),
          ),
        ],
      );
}

// ══════════════════════════════════════════════════════════════
// GERÇEK OYUNCU ALINTISI
// ══════════════════════════════════════════════════════════════
class _PullQuoteSection extends ConsumerWidget {
  const _PullQuoteSection();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final playersAsync = ref.watch(playersProvider(isLimit: true));
    final players = playersAsync.value ?? const <Player>[];
    final withQuote =
        players.where((final p) => p.quote.trim().isNotEmpty).toList();
    if (withQuote.isEmpty) return const SizedBox.shrink();

    final player = withQuote.first;
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: WebColors.darkBlueSurface,
      padding: EdgeInsets.symmetric(
          vertical: 64, horizontal: width > 900 ? 100 : 24),
      child: Column(
        children: [
          const Icon(Icons.format_quote_rounded,
              color: WebColors.primaryGold, size: 36),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              '"${player.quote.trim()}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text('${player.firstName} ${player.lastName}',
              style: const TextStyle(
                  color: WebColors.primaryGoldLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// İSTATİSTİK ŞERİDİ — sadece GERÇEK sayılar, uydurma pazarlama
// rakamı yok.
// ══════════════════════════════════════════════════════════════
class _StatsBar extends StatelessWidget {
  final int showCount;
  final int stageCount;
  const _StatsBar({required this.showCount, required this.stageCount});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: WebColors.microBorder),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          runSpacing: 20,
          children: [
            _stat('$showCount+', 'Aktif Etkinlik'),
            _stat('$stageCount+', 'Sahne / Mekan'),
            _stat('7/24', 'Anında Bilet'),
          ],
        ),
      );

  Widget _stat(final String value, final String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ],
      );
}
