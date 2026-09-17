import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/widgets/mobile/show_card.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../domain/entities/stage.dart';
import '../providers/stage_detail_provider.dart';
import '../widgets/web/scroll_reveal_section.dart';
import '../widgets/web/stage_hero_section.dart';
import '../widgets/web/stage_info_rail.dart';
import '../widgets/web/stage_show_tile.dart';

class StageDetailPage extends ConsumerStatefulWidget {
  final String stageId;

  const StageDetailPage({super.key, required this.stageId});

  @override
  ConsumerState<StageDetailPage> createState() => _StageDetailPageState();
}

class _StageDetailPageState extends ConsumerState<StageDetailPage>
    with GlobalScrollMixin {
  @override
  void onLoadMore() {}

  @override
  Widget build(final BuildContext context) {
    // 🖥️ Masaüstünde `BasePageWrapper` hiç kurulmuyor -- o mobil uygulama
    // çatısıdır (geri tuşu başlık çubuğu, "yukarı kaydır" FAB'ı,
    // pull-to-refresh, `CustomAppBackground`'ın rastgele renkli parçacık
    // noktaları). Bunun yerine tamamen ayrı, bağımsız bir masaüstü sayfası
    // döndürülüyor (bkz. nearby_events_page.dart'taki
    // `_NearbyEventsDesktopPage` referans deseni ve aşağıdaki
    // `_StageDetailDesktopPage`). Mobil/tablet gövdesi aşağıda AYNEN
    // kalıyor -- bu değişikliğin kapsamı sadece masaüstünü ayrı bir kabuğa
    // taşımak, mobili yeniden yazmak değil.
    if (context.isDesktop) {
      return _StageDetailDesktopPage(stageId: widget.stageId);
    }

    final detailAsync = ref.watch(stageDetailProvider(widget.stageId));
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      // 🎯 MERKEZİ HEADER: Başlık ve alt başlık artık sistemden geliyor
      title: detailAsync.value?.stage.name.toUpperCase() ?? 'SAHNE DETAYI',
      subtitle: 'Şehrin en iyi sahnelerini keşfedin...',
      rightIcon: Icons.stadium_rounded,
      customScrollController: scrollController,
      isLoading: detailAsync.isLoading,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        ambientColor: context.colors.primary.withOpacity(0.05),
        safeAreaTop: true, // Header'ın status bar altında kalmaması için true
      ),
      child: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final err, final _) =>
            Center(child: Text('Veri yüklenemedi: $err')),
        data: (final state) =>
            _buildMobileBody(context, isLargeScreen, state),
      ),
    );
  }

  // --- MOBİL/TABLET GÖVDE (ORİJİNAL, DEĞİŞTİRİLMEMİŞ YERLEŞİM) ---

  Widget _buildMobileBody(final BuildContext context, final bool isLargeScreen,
          final StageDetailState state) =>
      Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isLargeScreen ? 800 : double.infinity),
          child: CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStageImage(state.stage.imageUrl),
                    const SizedBox(height: 32),

                    // 📖 MEKAN HİKAYESİ
                    _buildSectionLabel(
                        context, 'HAKKINDA', Icons.info_outline_rounded),
                    const SizedBox(height: 12),
                    _buildStageInfo(state.stage.description),
                    const SizedBox(height: 40),

                    // 🎬 ETKİNLİKLER
                    if (state.shows.isNotEmpty) ...[
                      _buildSectionLabel(context, 'SAHNELENEN ESERLER',
                          Icons.event_seat_rounded),
                      const SizedBox(height: 16),
                      _buildShowList(state.shows),
                      const SizedBox(height: 40),
                    ],

                    // 📍 KONUM VE ADRES
                    _buildSectionLabel(
                        context, 'LOKASYON', Icons.map_outlined),
                    const SizedBox(height: 16),
                    _buildStageMap(
                        state.stage.locationLat, state.stage.locationLng),
                    const SizedBox(height: 24),
                    _buildAddressSection(context, state.stage.address,
                        state.stage.communication),

                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),
        ),
      );

  // --- UI BİLEŞENLERİ ---

  Widget _buildStageImage(final String imageUrl) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            height: 400,
            fit: BoxFit.cover,
            placeholder: (final _, final __) => const ShimmerLoading(),
          ),
        ),
      );

  Widget _buildStageInfo(final String description) => Text(
        description,
        style: const TextStyle(
            fontSize: 16, height: 1.6, fontWeight: FontWeight.w400),
      );

  Widget _buildShowList(final List<Show> shows) => SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: shows.length,
          itemBuilder: (final context, final index) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ShowCard(
              imageUrl: shows[index].imageUrl,
              gameName: shows[index].name,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (final _) =>
                          ShowDetailPage(showId: shows[index].id))),
            ),
          ),
        ),
      );

  Widget _buildStageMap(final double lat, final double lng) {
    if (lat == 0 && lng == 0) return const SizedBox.shrink();
    final LatLng position = LatLng(lat, lng);
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: 15),
          markers: {
            Marker(markerId: const MarkerId('stage'), position: position)
          },
          zoomControlsEnabled: false,
          scrollGesturesEnabled: false, // Sayfa scroll'u ile çakışmaması için
        ),
      ),
    );
  }

  Widget _buildAddressSection(final BuildContext context, final String address,
          final String communication) =>
      Column(
        children: [
          _buildInfoTile(
              context, Icons.location_on_rounded, 'Açık Adres', address),
          const SizedBox(height: 16),
          _buildInfoTile(
              context, Icons.phone_in_talk_rounded, 'İletişim', communication),
        ],
      );

  Widget _buildInfoTile(final BuildContext context, final IconData icon,
          final String title, final String content) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(content,
                    style: TextStyle(
                        color: context.colors.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      );

  Widget _buildSectionLabel(final BuildContext context, final String title,
          final IconData icon) =>
      Row(
        children: [
          Icon(icon, color: context.colors.primary, size: 22),
          const SizedBox(width: 12),
          Text(title,
              style: context.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      );
}

// =============================================================================
// MASAÜSTÜ (WEB) SAHNE DETAY SAYFASI — TAMAMEN BAĞIMSIZ KABUK
// =============================================================================
//
// `BasePageWrapper` KASITLI OLARAK KULLANILMIYOR — o mobil uygulama
// çatısıdır (geri tuşu başlık çubuğu, "yukarı kaydır" FAB'ı, pull-to-
// refresh, `CustomAppBackground`'ın rastgele renkli parçacık noktaları +
// `context.primaryColor` kullanan ambient glow — `WebColors` marka
// paletiyle DEĞİL). Bunlar `home_page_web.dart`/`nearby_events_page.dart`'ta
// "Android uygulaması gibi görünüyor" şikayetinin asıl sebebiydi. Üst
// navigasyon zaten `WebTopNavigationBar`'dan geliyor; burada ikinci bir
// başlık çubuğuna gerek yok.
//
// Sticky-sidebar / hero giriş animasyonu mantığı BİREBİR korunuyor — sadece
// bunu saran kabuk değişti (BasePageWrapper yerine düz `ColoredBox`).
class _StageDetailDesktopPage extends ConsumerStatefulWidget {
  final String stageId;

  const _StageDetailDesktopPage({required this.stageId});

  @override
  ConsumerState<_StageDetailDesktopPage> createState() =>
      _StageDetailDesktopPageState();
}

class _StageDetailDesktopPageState
    extends ConsumerState<_StageDetailDesktopPage>
    with TickerProviderStateMixin {
  // Bu sayfa artık `BasePageWrapper`/`GlobalScrollMixin`'e bağlı değil,
  // sticky sidebar hesaplaması (`StickyEditorialSplit`) için kendi
  // `ScrollController`'ını tutuyor.
  final ScrollController _scrollController = ScrollController();

  // 🎬 MASAÜSTÜ HERO GİRİŞ ANİMASYONU — orijinal
  // `_StageDetailPageState`'teki ile birebir aynı desen, sadece artık bu
  // sayfaya ait (show_detail_page_web.dart'taki hero fade/slide
  // yaklaşımıyla aynı).
  late final AnimationController _heroController;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  bool _heroAnimationStarted = false;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _heroController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _heroController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startHeroAnimationOnce() {
    if (_heroAnimationStarted) return;
    _heroAnimationStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) _heroController.forward();
    });
  }

  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(stageDetailProvider(widget.stageId));

    return ColoredBox(
      // NOT: Aşağıdaki `CustomScrollView` kendi kendine kaydırılabilir
      // (kendi `controller`'ı ile) — burada ikinci bir
      // `SingleChildScrollView` SARMAK "unbounded height" hatasına yol
      // açar, bilerek eklenmedi.
      color: WebColors.darkBlueBackground,
      child: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(WebColors.primaryGold),
          ),
        ),
        error: (final err, final _) => Center(
          child: Text(
            'Veri yüklenemedi: $err',
            style: const TextStyle(color: WebColors.whiteText),
          ),
        ),
        data: (final state) => _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(final BuildContext context, final StageDetailState state) {
    _startHeroAnimationOnce();

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: StageHeroSection(
            stage: state.stage,
            fadeAnimation: _heroFade,
            slideAnimation: _heroSlide,
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 72),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScrollRevealSection(
                      id: 'stage-${state.stage.id}-split',
                      child: StickyEditorialSplit(
                        scrollListenable: _scrollController,
                        sidebar: StageInfoCard(stage: state.stage),
                        content: _buildContentColumn(context, state),
                      ),
                    ),
                    const SizedBox(height: 80),
                    if (state.stage.locationLat != 0 ||
                        state.stage.locationLng != 0)
                      ScrollRevealSection(
                        id: 'stage-${state.stage.id}-map',
                        delay: const Duration(milliseconds: 120),
                        child: _buildMapSection(state.stage),
                      ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentColumn(
      final BuildContext context, final StageDetailState state) {
    // 🟢 Bu sahnede sahnelenen eserleri "hiç var olmuş olan her şey"
    // yerine gerçekten aktif olanlarla sınırlıyoruz (bkz.
    // `show_provider.dart`'taki `activeShowsProvider` — takviminde en az
    // bir gelecek etkinliği olan oyunlar). `.value` kullanılıyor çünkü bu
    // Riverpod sürümünde `AsyncValue.valueOrNull` YOK. Provider henüz
    // yüklenmemiş/hata vermişse (`null`), listeyi boş göstermek yerine
    // `stageDetailProvider`'ın kendi listesine (state.shows) düşülüyor —
    // yalnızca bir görsel iyileştirme, veri kaybı riski yok. Bu filtre
    // SADECE masaüstü gövdesinde uygulanıyor; mobil/tablet yerleşimi
    // (`_buildMobileBody`) ve paylaşılan `stageDetailProvider` DOKUNULMADAN
    // kalıyor.
    final activeShowIds = ref
        .watch(activeShowsProvider(false))
        .value
        ?.map((final s) => s.id)
        .toSet();
    final displayedShows = activeShowIds == null
        ? state.shows
        : state.shows.where((final s) => activeShowIds.contains(s.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DesktopSectionTitle(
            title: 'Hakkında', icon: Icons.info_outline_rounded),
        const SizedBox(height: 24),
        Text(
          state.stage.description,
          style: const TextStyle(
            color: WebColors.textSecondary,
            fontSize: 17,
            height: 1.85,
            letterSpacing: 0.2,
          ),
        ),
        if (displayedShows.isNotEmpty) ...[
          const SizedBox(height: 56),
          const _DesktopSectionTitle(
              title: 'Sahnelenen Eserler', icon: Icons.event_seat_rounded),
          const SizedBox(height: 28),
          ...displayedShows.map(
            (final show) => StageUpcomingShowTile(
              show: show,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (final _) => ShowDetailPage(showId: show.id))),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMapSection(final Stage stage) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DesktopSectionTitle(title: 'Konum', icon: Icons.map_outlined),
          const SizedBox(height: 28),
          Container(
            height: 420,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: WebColors.primaryGold.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                    target: LatLng(stage.locationLat, stage.locationLng),
                    zoom: 15),
                markers: {
                  Marker(
                      markerId: const MarkerId('stage'),
                      position: LatLng(stage.locationLat, stage.locationLng)),
                },
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
              ),
            ),
          ),
        ],
      );
}

/// Masaüstü sayfasındaki bölüm başlıkları için, `show_detail_page_web.dart`
/// içindeki `_SectionTitle` ile aynı görsel dile sahip (gradyanlı ikon
/// rozeti + büyük başlık + solan çizgi) özel bileşen.
class _DesktopSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _DesktopSectionTitle({required this.title, required this.icon});

  @override
  Widget build(final BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [WebColors.primaryGold, WebColors.primaryGoldLight]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: WebColors.primaryGold.withOpacity(0.4),
                    blurRadius: 15),
              ],
            ),
            child: Icon(icon, color: WebColors.veryDarkBlue, size: 22),
          ),
          const SizedBox(width: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: WebColors.whiteText,
                  letterSpacing: 0.5)),
          const SizedBox(width: 16),
          Expanded(
              child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                    WebColors.primaryGold.withOpacity(0.5),
                    Colors.transparent,
                  ])))),
        ],
      );
}
