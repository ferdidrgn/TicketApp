import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../events/presentation/widgets/events_card.dart';
import '../providers/nearby_events_provider.dart';

class NearbyEventsPage extends StatelessWidget {
  const NearbyEventsPage({super.key});

  // Statik verilerimiz - Tasarımın şıklığını korumak için
  final List<Map<String, dynamic>> staticEvents = const [
    {
      'name': 'Cimri - Moliere',
      'category': 'Klasik Tiyatro',
      'date': '24 Aralık, 20:30',
      'stage': 'Harbiye Muhsin Ertuğrul Sahnesi',
      'price': 180.0,
      'image':
          'https://www.cumhuriyet.com.tr/Archive/2021/8/27/1863857/kapak_002553.jpg',
    },
    {
      'name': 'Hamlet - Versus Tiyatro',
      'category': 'Shakespeare Dramı',
      'date': '28 Aralık, 20:00',
      'stage': 'Zorlu PSM - Turkcell Sahnesi',
      'price': 250.0,
      'image':
          'https://versustiyatro.com/wp-content/uploads/2016/02/GHT_36101.jpg',
    },
    {
      'name': 'Don Kişot\'um Ben',
      'category': 'Modern Komedi',
      'date': '30 Aralık, 20:30',
      'stage': 'Baba Sahne - Taksim',
      'price': 200.0,
      'image':
          'https://tiyatronline.com/isDosyalar/2019/05/20/crop_gozlerimi-kaparim-vazifemi-yaparim-ank_ilf4LaFHkp.jpg',
    },
    {
      'name': 'Romeo & Juliet',
      'category': 'Klasik Aşk',
      'date': '26 Aralık, 19:30',
      'stage': 'İstanbul Şehir Tiyatrosu',
      'price': 150.0,
      'image':
          'https://i.pinimg.com/originals/cd/f6/58/cdf6583da74eb1838429456c96decdb8.jpg',
    },
    {
      'name': 'Kral Lear',
      'category': 'Tragedy',
      'date': '29 Aralık, 21:00',
      'stage': 'Kadıköy Haldun Taner',
      'price': 220.0,
      'image':
          'https://static.ticimax.cloud/cdn-cgi/image/width=1125,quality=85/43055/uploads/urunresimleri/buyuk/king-lear-17-kasim-21-kasim-2022-55a1c.jpg',
    },
  ];

  @override
  Widget build(final BuildContext context) {
    // Masaüstünde (>=1024px) gerçek Firestore verisiyle çalışan, ayrı bir
    // "premium" web deneyimi kullanılır (bkz. _NearbyEventsDesktopPage).
    // Mobil/tablet gövdesi aşağıda AYNEN kalır — bu görevin kapsamı sadece
    // masaüstü deneyimini eklemek, mobili yeniden yazmak değil.
    if (context.isDesktop) return const _NearbyEventsDesktopPage();

    final bool isLargeScreen = context.isTablet || context.isDesktop;
    final double cardWidth = isLargeScreen ? 400 : context.screenWidth - 48;

    return BasePageWrapper(
      title: 'YAKININIZDAKİ ETKİNLİKLER',
      subtitle: 'Size en yakın sahnelerde bu hafta neler var?',
      showBackButton: false,
      rightIcon: Icons.tune_rounded,
      showFab: true,
      layoutConfig: BasePageLayoutConfig(
          backgroundColor: context.colors.surface, safeAreaTop: true),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HERO BANNER
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _buildDiscoveryBanner(context),
            ),
          ),

          // HIZLI FİLTRELER
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('Tümü', true, context),
                  _buildFilterChip('Tiyatro', false, context),
                  _buildFilterChip('Konser', false, context),
                  _buildFilterChip('Sahne', false, context),
                  _buildFilterChip('Bugün', false, context),
                  _buildFilterChip('Yakında', false, context),
                ],
              ),
            ),
          ),

          // BAŞLIK
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SectionHeader(
                title: 'Sizin İçin Önerilenler',
                subtitle: 'Konumunuza göre en uygun etkinlikler',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // ETKİNLİK LİSTESİ - YATAY KAYDIRMA
          SliverToBoxAdapter(
            child: SizedBox(
              height: 320, // Sabit yükseklik - butonlar için yeterli alan
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                itemCount: staticEvents.length,
                itemBuilder: (final context, final index) {
                  return Container(
                    width: cardWidth * 0.85, // Daha dar kartlar
                    margin: EdgeInsets.only(
                      right: index < staticEvents.length - 1 ? 16 : 0,
                    ),
                    child: EventsCard(
                      width: cardWidth * 0.85,
                      imageUrl: staticEvents[index]['image'],
                      showName: staticEvents[index]['name'],
                      category: staticEvents[index]['category'],
                      fullDateString: staticEvents[index]['date'],
                      timeString: '',
                      stage: staticEvents[index]['stage'],
                      price: staticEvents[index]['price'],
                      onTap: () {
                        // Kart tıklama işlevi
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${staticEvents[index]['name']} - Bilet sayfasına yönlendiriliyorsunuz'),
                            backgroundColor: context.primaryColor,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // POPÜLER MEKANLAR BAŞLIĞI
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: SectionHeader(
                title: 'Popüler Sahne ve Mekanlar',
                subtitle: 'En çok tercih edilen yerler',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // MEKAN LİSTESİ
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLargeScreen ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (final context, final index) => _buildVenueCard(context, index),
                childCount: 6,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryBanner(final BuildContext context) => Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              context.primaryColor,
              context.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // DEKORATİF ELEMENTLER
            Positioned(
              top: -20,
              right: -20,
              child: Icon(
                Icons.star_rounded,
                size: 120,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              bottom: -10,
              left: -10,
              child: Icon(
                Icons.location_on_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Şehrin Ritmini Keşfet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '15+ tiyatro oyunu ve 20+ konser sizi bekliyor.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.explore_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterChip(
      final String text, final bool isActive, final BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive
                ? context.colors.onPrimary
                : context.colors.onSurfaceVariant,
          ),
        ),
        selected: isActive,
        onSelected: (final selected) {},
        backgroundColor: context.colors.surfaceContainerHighest,
        selectedColor: context.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildVenueCard(final BuildContext context, final int index) {
    final venues = [
      {'name': 'Zorlu PSM', 'type': 'Sahne', 'icon': Icons.theater_comedy},
      {'name': 'İKSV Salon', 'type': 'Konser', 'icon': Icons.music_note},
      {'name': 'BKM', 'type': 'Tiyatro', 'icon': Icons.home_max},
      {'name': 'Kadıköy Sahne', 'type': 'Sahne', 'icon': Icons.location_city},
      {'name': 'Bostancı Gösteri', 'type': 'Konser', 'icon': Icons.mic},
      {'name': 'Akasya Kültür', 'type': 'Tiyatro', 'icon': Icons.palette},
    ];

    final venue = venues[index];

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: context.colors.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              venue['icon'] as IconData,
              color: context.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            venue['name'] as String,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            venue['type'] as String,
            style: TextStyle(
              fontSize: 12,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MASAÜSTÜ (WEB) YAKINDAKİLER SAYFASI — GERÇEK VERİ
// =============================================================================
//
// Mobil gövdedeki `staticEvents` tamamen kurgusal (uydurma oyun adları,
// sahte tarihler/fiyatlar, üçüncü parti sitelerden alınmış stok görseller)
// — burada KULLANILMIYOR. Bu sayfa yalnızca `nearbyStagesProvider` /
// `upcomingNearbyEventsProvider` (bkz. ../providers/nearby_events_provider.dart)
// üzerinden Firestore'dan gelen gerçek Show/Event/Stage verisiyle çalışır.
//
// GERÇEK KONUM/MESAFE HAKKINDA: `pubspec.yaml`'da `geolocator` (ya da
// tarayıcının coğrafi konum API'sine erişim sağlayan başka bir paket) HENÜZ
// bağımlılık olarak yok, ve bu sandbox'ta yeni bir paket eklenip
// `flutter pub get` çalıştırılamıyor. Sahte "X km uzakta" etiketleri
// uydurmak yerine — ki bu projede kesinlikle yasak — dürüst bir alternatif
// seçildi: etkinlikler gerçek tarihlerine göre (en yakın tarih en önce)
// sıralanıyor ve gerçek sahne/mekân bilgisine göre açıkça gruplanıyor.
// Sayfa `geolocator` eklendiğinde mesafeye göre sıralamaya kolayca
// genişletilebilir (bkz. `Stage.locationLat`/`locationLng` — bu alanlar
// zaten gerçek ve kullanılabilir durumda).
class _NearbyEventsDesktopPage extends StatelessWidget {
  const _NearbyEventsDesktopPage();

  @override
  Widget build(final BuildContext context) => BasePageWrapper(
        title: 'Yakınızdaki Etkinlikler',
        subtitle: 'Sahnede olan tüm oyunlar, en yakın tarihe göre sıralı',
        showBackButton: false,
        showFab: true,
        layoutConfig: BasePageLayoutConfig(
          backgroundColor: WebColors.darkBlueBackground,
          ambientColor: WebColors.primaryGold.withOpacity(0.05),
          safeAreaTop: true,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: context.isLargeDesktop ? 1360 : 1180),
            child: const _NearbyEventsDesktopBody(),
          ),
        ),
      );
}

class _NearbyEventsDesktopBody extends ConsumerWidget {
  const _NearbyEventsDesktopBody();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final eventsState = ref.watch(upcomingNearbyEventsProvider);
    final stagesState = ref.watch(nearbyStagesProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 36),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _NearbyDesktopBanner(eventCount: eventsState.valueOrNull?.length),
        ),
        const SizedBox(height: 48),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SectionHeader(
            title: 'Yaklaşan Etkinlikler',
            subtitle: 'Tarihe göre sıralı',
            titleColor: Colors.white,
            accentColor: WebColors.primaryGold,
          ),
        ),
        const SizedBox(height: 16),
        _buildEventsSection(context, eventsState),
        const SizedBox(height: 56),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SectionHeader(
            title: 'Sahne ve Mekanlar',
            subtitle: 'Yaklaşan etkinliği olan gerçek sahneler',
            titleColor: Colors.white,
            accentColor: WebColors.primaryGold,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildStagesSection(context, stagesState),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildEventsSection(
      final BuildContext context, final AsyncValue<List<NearbyEventEntry>> state) {
    return state.when(
      loading: () => SizedBox(
        height: 320,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (final context, final index) => Container(
            width: 280,
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: WebColors.darkBlueSurface,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
      error: (final err, final stack) => const _NearbyEmptyNotice(
        message: 'Etkinlikler yüklenemedi. Lütfen daha sonra tekrar deneyin.',
      ),
      data: (final entries) {
        if (entries.isEmpty)
          return const _NearbyEmptyNotice(
            message: 'Şu anda yaklaşan bir etkinlik bulunmuyor.',
          );

        return SizedBox(
          height: 340,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: entries.length,
            itemBuilder: (final context, final index) {
              final entry = entries[index];
              final formatted = DateFormatter.formatForEventCard(entry.event.date);
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: EventsCard(
                  key: ValueKey('nearby-event-${entry.event.id}'),
                  width: 280,
                  imageUrl: entry.show.imageUrl,
                  showName: entry.show.name,
                  category: entry.show.category,
                  stage: entry.stage.name,
                  price: double.tryParse(entry.event.price) ?? 0.0,
                  fullDateString: '${formatted['day']} ${formatted['monthName']}',
                  timeString: formatted['time'] ?? '',
                  premium: true,
                  onTap: () =>
                      NavigationHandler.goToShow(context, entry.show.id, entry.show.name),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStagesSection(
      final BuildContext context, final AsyncValue<List<NearbyStageGroup>> state) {
    return state.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(WebColors.primaryGold),
          ),
        ),
      ),
      error: (final err, final stack) => const _NearbyEmptyNotice(
        message: 'Sahneler yüklenemedi. Lütfen daha sonra tekrar deneyin.',
      ),
      data: (final groups) {
        if (groups.isEmpty)
          return const _NearbyEmptyNotice(
            message: 'Şu anda gösterilecek bir sahne bulunmuyor.',
          );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 340,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.35,
          ),
          itemCount: groups.length,
          itemBuilder: (final context, final index) =>
              _NearbyStageCard(group: groups[index]),
        );
      },
    );
  }
}

class _NearbyDesktopBanner extends StatelessWidget {
  final int? eventCount;

  const _NearbyDesktopBanner({required this.eventCount});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: WebColors.cardGradient,
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sahnede Şu An Neler Var?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.h3Size,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    eventCount == null
                        ? 'Gerçek etkinlik takvimi yükleniyor…'
                        : eventCount == 0
                            ? 'Şu anda takvimde yaklaşan bir etkinlik yok.'
                            : '$eventCount yaklaşan etkinlik, gerçek sahne bilgileriyle listeleniyor.',
                    style: TextStyle(
                      color: WebColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: WebColors.goldGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.theater_comedy_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      );
}

class _NearbyStageCard extends StatelessWidget {
  final NearbyStageGroup group;

  const _NearbyStageCard({required this.group});

  @override
  Widget build(final BuildContext context) {
    final stage = group.stage;
    final nearest = group.entries.first;
    final formatted = DateFormatter.formatForEventCard(nearest.event.date);

    return GestureDetector(
      onTap: () => NavigationHandler.goToStage(context, stage.id, stage.name),
      child: Container(
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface,
          // Asimetrik köşeler — show_detail_page_web / discovery kartlarıyla
          // aynı "premium" imza.
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(28),
          ),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 130,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    OptimizedCachedImage(
                        imageUrl: stage.imageUrl, fit: BoxFit.cover, borderRadius: 0),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            WebColors.darkBlueSurface.withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: WebColors.goldGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          group.entries.length == 1
                              ? '1 ETKİNLİK'
                              : '${group.entries.length} ETKİNLİK',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: WebColors.primaryGoldLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            stage.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: WebColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 13, color: WebColors.primaryGoldLight),
                        const SizedBox(width: 6),
                        Text(
                          'En yakın: ${formatted['day']} ${formatted['monthName']}, ${formatted['time']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyEmptyNotice extends StatelessWidget {
  final String message;

  const _NearbyEmptyNotice({required this.message});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Text(
          message,
          style: TextStyle(color: WebColors.textSecondary, fontSize: 15),
        ),
      );
}
