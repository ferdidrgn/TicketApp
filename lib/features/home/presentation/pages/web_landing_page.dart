import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../widgets/web/theater_section_divider.dart';

/// 🎭 GERÇEK TANITIM (LANDING) SAYFASI — Web'in `/` adresi.
///
/// Öncesinde `/` adresi doğrudan uygulamanın kendisini (HomePage) gösteriyordu
/// — yeni ziyaretçi için "TiyatRol nedir" diye anlatan hiçbir şey yoktu.
/// Bu sayfa TAMAMEN AYRI: marka/atmosfer ağırlıklı bir tanıtım sayfası,
/// gerçek uygulama deneyimi "Uygulamaya Gir" CTA'sının arkasında (`/app`).
/// Uygulamanın kendisine (mobil dahil) HİÇBİR ŞEKİLDE dokunmuyor.
class WebLandingPage extends ConsumerWidget {
  const WebLandingPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final showsAsync = ref.watch(showsProvider(isLimit: true));
    final stagesAsync = ref.watch(stagesProvider(isLimit: true));
    final width = MediaQuery.of(context).size.width;
    final bool isLarge = width > 900;
    final double hPad = width > 1400 ? 100 : (width > 900 ? 60 : 24);
    final shows = showsAsync.value ?? const <Show>[];

    return Scaffold(
      backgroundColor: WebColors.darkBlueBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LandingNavBar(hPad: hPad),
            _LandingHero(hPad: hPad, isLarge: isLarge, heroShow: shows.isNotEmpty ? shows.first : null),
            const TheaterSectionDivider(style: DividerStyle.iconCenter, height: 90),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _ValueProps(isLarge: isLarge),
            ),
            const SizedBox(height: 72),
            if (shows.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _FeaturedShows(shows: shows),
              ),
            const SizedBox(height: 72),
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
// HERO
// ══════════════════════════════════════════════════════════════
class _LandingHero extends StatelessWidget {
  final double hPad;
  final bool isLarge;
  final Show? heroShow;

  const _LandingHero(
      {required this.hPad, required this.isLarge, required this.heroShow});

  @override
  Widget build(final BuildContext context) => Stack(
        children: [
          if (heroShow != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.22,
                child: CachedNetworkImage(
                    imageUrl: heroShow!.imageUrl, fit: BoxFit.cover),
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
            padding: EdgeInsets.fromLTRB(hPad, 64, hPad, 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: WebColors.primaryGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: WebColors.primaryGold.withOpacity(0.35)),
                  ),
                  child: const Text('TÜRKİYE\'NİN SAHNE PLATFORMU',
                      style: TextStyle(
                          color: WebColors.primaryGoldLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2)),
                ),
                const SizedBox(height: 28),
                Text(
                  'Sanat Seni Bekliyor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isLarge ? 64 : 40,
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
                    'biletini saniyeler içinde al. Türkiye\'nin en kapsamlı '
                    'sahne sanatları platformu TiyatRol\'de.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: isLarge ? 17 : 15,
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
              ],
            ),
          ),
        ],
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
// ÖNE ÇIKAN OYUNLAR
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
          height: 300,
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

class _FeaturedShowTile extends StatelessWidget {
  final Show show;
  const _FeaturedShowTile({required this.show});

  @override
  Widget build(final BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => NavigationHandler.goToApp(context),
        child: Container(
          width: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(imageUrl: show.imageUrl, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(show.category.toUpperCase(),
                          style: const TextStyle(
                              color: WebColors.primaryGoldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(show.name,
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
      );
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
