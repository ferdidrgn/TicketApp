import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/util/global_scroll_mixin.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/web/player_detail_desktop_view.dart';

class PlayerDetailPage extends ConsumerStatefulWidget {
  final String playerId;

  const PlayerDetailPage({super.key, required this.playerId});

  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage>
    with SingleTickerProviderStateMixin, GlobalScrollMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    _animationController = AnimationController(
      // Diğer web/detay sayfalarındaki (ör. show_detail_page_web.dart'ın
      // içerik fade'i ~500ms, hero fade'i 800ms) içerik geçişleriyle aynı
      // hissi vermesi için süre kısaltıldı; eskiden 1500ms + easeInOutExpo
      // diğer sayfalara göre belirgin şekilde daha yavaştı.
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  void _onScroll() {
    if (mounted) {
      final isScrolledNow = scrollController.offset > 240;
      if (_isScrolled != isScrolledNow)
        setState(() => _isScrolled = isScrolledNow);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    // Masaüstünde (>=1024px) tamamen ayrı, gerçek bir "premium" web
    // deneyimi kullanılır (bkz. _PlayerDetailDesktopPage) — BasePageWrapper
    // (mobil uygulama çatısı: geri tuşu başlık çubuğu, "yukarı kaydır"
    // FAB'ı, pull-to-refresh, CustomAppBackground'ın rastgele renkli
    // parçacık noktaları) burada HİÇ örneklenmez. Mobil/tablet gövdesi
    // aşağıda AYNEN kalır — bu görevin kapsamı sadece masaüstü deneyimini
    // ayırmak, mobili yeniden yazmak değil.
    if (context.isDesktop) {
      return _PlayerDetailDesktopPage(playerId: widget.playerId);
    }

    final playerAsync = ref.watch(playerDetailProvider(widget.playerId));
    final colors = context.colors;

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      title: "Sanatçı Profili",
      subtitle: "Tragedya ve Komedya İlahlarının Elçileri",
      rightIcon: Icons.star,
      isLoading: playerAsync.isLoading,
      customScrollController: scrollController,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: colors.surface,
        ambientColor: colors.primary.withOpacity(0.02),
      ),
      child: playerAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(
                color: colors.primary, strokeWidth: 2)),
        error: (final err, final stack) => _buildErrorState(context, err),
        data: (final state) => _buildMobileBody(context, state),
      ),
    );
  }

  // --- 📱 MOBİL GÖVDE (DEĞİŞTİRİLMEDİ) ---
  Widget _buildMobileBody(final BuildContext context, final dynamic state) {
    return Stack(
      children: [
        CustomScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildArtisticHeader(context, state),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildEliteContentBody(context, state),
              ),
            ),
          ],
        ),
        _buildGlassTopBar(context, state),
      ],
    );
  }

  // --- 🎨 ARTISTIC HEADER (DİJİTAL SERGİ GÖRÜNÜMÜ) ---
  Widget _buildArtisticHeader(final BuildContext context, final dynamic state) {
    return SliverAppBar(
      expandedHeight: context.screenHeight * 0.6,
      pinned: true,
      stretch: true,
      backgroundColor: context.colors.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'player_${widget.playerId}',
              child: OptimizedCachedImage(
                imageUrl: state.player.imageUrl ?? '',
                fit: BoxFit.cover,
              ),
            ),
            // Ultra-modern gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    Colors.transparent,
                    context.colors.surface.withOpacity(0.8),
                    context.colors.surface,
                  ],
                  stops: const [0.0, 0.3, 0.6, 0.9, 1.0],
                ),
              ),
            ),
            // Sanatsal İsim Katmanı
            Positioned(
              bottom: 60,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text("U S T A   S A N A T Ç I",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${state.player.firstName}\n${state.player.lastName}"
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 0.85,
                      letterSpacing: -2.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 💎 GLASSMORPHISM TOP BAR ---
  Widget _buildGlassTopBar(final BuildContext context, final dynamic state) {
    final colors = context.colors;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: _isScrolled ? 20 : 0, sigmaY: _isScrolled ? 20 : 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            color: _isScrolled
                ? colors.surface.withOpacity(0.7)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _artisticIconBtn(Icons.queue_play_next, () {}),
                  AnimatedOpacity(
                    opacity: _isScrolled ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                        "${state.player.firstName} ${state.player.lastName}",
                        style: context.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  _artisticIconBtn(Icons.share_outlined, () {
                    TiyatrolDeeplinkService.shareActor(
                      id: state.player.id,
                      name:
                          '${state.player.firstName} ${state.player.lastName}',
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _artisticIconBtn(final IconData icon, final VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isScrolled
              ? context.colors.onSurface.withOpacity(0.05)
              : Colors.black26,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: _isScrolled ? context.colors.onSurface : Colors.white,
            size: 20),
      ),
    );
  }

  // --- 🧬 ELITE CONTENT BODY ---
  Widget _buildEliteContentBody(
      final BuildContext context, final dynamic state) {
    final List<Show> activeShows = List<Show>.from(state.activeShows ?? []);
    final List<Show> pastShows = List<Show>.from(state.pastShows ?? []);
    final List<dynamic> achievements = state.player.achievements ?? [];
    final List<String> collaborations =
        List<String>.from(state.player.collaborations ?? []);

    return Container(
      decoration: BoxDecoration(color: context.colors.surface),
      child: Column(
        children: [
          _buildPremiumStatsGrid(
              activeShows.length, pastShows.length, achievements.length),
          const SizedBox(height: 48),
          _buildEliteModernTabs(activeShows, pastShows, achievements,
              collaborations, state.player.bio),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildPremiumStatsGrid(
      final int active, final int past, final int awards) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _premiumStatCard("AKTİF", active.toString(), context.colors.primary),
          const SizedBox(width: 16),
          _premiumStatCard("ARŞİV", past.toString(), context.colors.secondary),
          const SizedBox(width: 16),
          _premiumStatCard("ÖDÜL", awards.toString(), Colors.amber[700]!),
        ],
      ),
    );
  }

  Widget _premiumStatCard(
      final String label, final String value, final Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -1)),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color.withOpacity(0.6),
                    letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildEliteModernTabs(
      final List<Show> active,
      final List<Show> past,
      final List<dynamic> awards,
      final List<String> collabs,
      final String bio) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            labelColor: context.colors.onSurface,
            unselectedLabelColor: context.colors.onSurface.withOpacity(0.3),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 4, color: context.colors.primary),
              insets: const EdgeInsets.symmetric(horizontal: 16),
            ),
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5),
            tabs: const [
              Tab(text: "Hikaye"),
              Tab(text: "Sahnede"),
              Tab(text: "Geçmiş"),
              Tab(text: "Başarılar")
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 650,
            child: TabBarView(
              children: [
                _eliteBioTab(bio, collabs),
                _eliteShowsTab(active, "Şu an sahnede bir oyunu bulunmuyor."),
                _eliteShowsTab(past, "Arşiv henüz güncellenmemiş."),
                _eliteTimelineTab(awards),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 🖋️ TAB: BİO & COLLABS ---
  Widget _eliteBioTab(final String bio, final List<String> collabs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bio,
              style: TextStyle(
                  height: 2.0,
                  fontSize: 17,
                  color: context.colors.onSurface.withOpacity(0.7),
                  letterSpacing: 0.2)),
          const SizedBox(height: 48),
          const Text("GÜÇLÜ İŞBİRLİKLERİ",
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: collabs
                .map((final c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10)
                        ],
                      ),
                      child: Text(c,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // --- 🎭 TAB: SHOWS ---
  Widget _eliteShowsTab(final List<Show> shows, final String emptyMsg) {
    if (shows.isEmpty)
      return Center(
          child: Text(emptyMsg,
              style: const TextStyle(fontStyle: FontStyle.italic)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: shows.length,
      itemBuilder: (final context, final i) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: context.colors.surface,
          border:
              Border.all(color: context.colors.outlineVariant.withOpacity(0.5)),
        ),
        child: InkWell(
          onTap: () =>
              NavigationHandler.goToShow(context, shows[i].id, shows[i].name),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: OptimizedCachedImage(
                      imageUrl: shows[i].imageUrl,
                      width: 80,
                      height: 100,
                      fit: BoxFit.cover),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shows[i].name.toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text("TİYATRO PERFORMANSI",
                          style: TextStyle(
                              color: context.colors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: context.colors.onSurface.withOpacity(0.3)),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 🏆 TAB: TIMELINE ACHIEVEMENTS ---
  Widget _eliteTimelineTab(final List<dynamic> awards) {
    if (awards.isEmpty)
      return const Center(child: Text("Başarı hikayesi henüz yazılmamış."));
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: awards.length,
      itemBuilder: (final context, final i) {
        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: context.colors.primary.withOpacity(0.2),
                            width: 4)),
                  ),
                  if (i != awards.length - 1)
                    Expanded(
                        child: Container(
                            width: 2,
                            color: context.colors.primary.withOpacity(0.1))),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(awards[i]['year'] ?? '----',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: context.colors.primary,
                              fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(awards[i]['title'] ?? '',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.3)),
                      if (awards[i]['detail'] != null) ...[
                        const SizedBox(height: 8),
                        Text(awards[i]['detail'],
                            style: TextStyle(
                                color:
                                    context.colors.onSurface.withOpacity(0.5),
                                fontSize: 14)),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(final BuildContext context, final Object error) {
    return Center(
        child: Text("Sanatçı profili yüklenirken bir sorun oluştu.",
            style: TextStyle(color: context.colors.error)));
  }
}

// =============================================================================
// MASAÜSTÜ (WEB) SANATÇI DETAY SAYFASI
// =============================================================================
//
/// `BasePageWrapper` KASITLI OLARAK KULLANILMIYOR — o mobil uygulama
/// çatısıdır (geri tuşu başlık çubuğu, "yukarı kaydır" FAB'ı, pull-to-
/// refresh, `CustomAppBackground`'ın rastgele renkli parçacık noktaları —
/// `particleColor` verilmediğinde markaya ait olmayan `context.primaryColor`
/// kullanır). Bunlar `home_page_web.dart`'ta "Android uygulaması gibi
/// görünüyor" şikayetinin asıl sebebiydi (bkz. o dosyadaki aynı gerekçe, ve
/// `nearby_events_page.dart` / `discovery_page.dart`'taki aynı düzeltme). Üst
/// navigasyon zaten `WebTopNavigationBar`'dan geliyor; burada ikinci bir
/// başlık çubuğuna gerek yok. Sade, düz zeminli bir kaydırma alanı.
class _PlayerDetailDesktopPage extends StatelessWidget {
  final String playerId;

  const _PlayerDetailDesktopPage({required this.playerId});

  @override
  Widget build(final BuildContext context) => ColoredBox(
        // NOT: `_PlayerDetailDesktopBody` kendi `CustomScrollView`'ı ile
        // zaten kaydırılabilir — ikinci bir SingleChildScrollView SARMAK
        // "unbounded height" hatasına yol açar, bilerek eklenmedi.
        color: WebColors.darkBlueBackground,
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: context.isLargeDesktop ? 1360 : 1180),
            child: _PlayerDetailDesktopBody(playerId: playerId),
          ),
        ),
      );
}

class _PlayerDetailDesktopBody extends ConsumerStatefulWidget {
  final String playerId;

  const _PlayerDetailDesktopBody({required this.playerId});

  @override
  ConsumerState<_PlayerDetailDesktopBody> createState() =>
      _PlayerDetailDesktopBodyState();
}

class _PlayerDetailDesktopBodyState
    extends ConsumerState<_PlayerDetailDesktopBody>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  void _onScroll() {
    if (!mounted) return;
    final bool isScrolledNow = _scrollController.offset > 240;
    if (_isScrolled != isScrolledNow) setState(() => _isScrolled = isScrolledNow);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final playerAsync = ref.watch(playerDetailProvider(widget.playerId));

    return playerAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 140),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(WebColors.primaryGold),
            strokeWidth: 2,
          ),
        ),
      ),
      error: (final err, final stack) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 140),
        child: Center(
          child: Text(
            "Sanatçı profili yüklenirken bir sorun oluştu.",
            style: TextStyle(color: WebColors.textSecondary),
          ),
        ),
      ),
      data: (final state) => _buildBody(context, state),
    );
  }

  // --- 🟢 GERÇEK "ŞU AN SAHNEDE" ÇAPRAZ KONTROLÜ ---
  // `state.activeShows`, oyuncunun `nowShowsId` alanından GELDİĞİ GİBİ
  // gelir — bu elle tutulan bir liste, ve bir oyunun son etkinliği geçtiğinde
  // birinin onu buradan çıkarmayı unutması kolayca gerçekle uyuşmaz hale
  // gelebilir. `activeShowsProvider` ise "aktiflik"i `Show.eventsId` +
  // `Event.date`'ten CANLI hesaplar (bkz. show_provider.dart) — Firestore'da
  // elle tutulan bir alan değil. Burada ikisini çapraz kontrol ediyoruz:
  // "ŞU AN SAHNEDE" bandında yalnızca hem oyuncunun `nowShowsId`
  // listesinde OLAN hem de takviminde gerçekten gelecek bir etkinliği OLAN
  // oyunlar gösterilir. `activeShowsProvider` henüz yüklenmemişse (bu proje
  // Riverpod'unda `AsyncValue.valueOrNull` YOK, `.value` kullanılır — o da
  // null dönebilir) ham listeyi olduğu gibi gösteriyoruz; ikincil bir
  // doğrulamanın yüklenmesini beklerken içeriği gizlemek yanlış olur.
  List<Show> _crossCheckedActiveShows(final List<Show> rawActiveShows) {
    if (rawActiveShows.isEmpty) return rawActiveShows;
    final List<Show>? realActiveShows =
        ref.watch(activeShowsProvider(false)).value;
    if (realActiveShows == null) return rawActiveShows;
    final Set<String> realActiveIds =
        realActiveShows.map((final s) => s.id).toSet();
    return rawActiveShows
        .where((final s) => realActiveIds.contains(s.id))
        .toList();
  }

  Widget _buildBody(final BuildContext context, final PlayerDetailState state) {
    final List<Show> activeShows = _crossCheckedActiveShows(state.activeShows);

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: PlayerDetailDesktopView(
                  player: state.player,
                  activeShows: activeShows,
                  pastShows: state.pastShows,
                ),
              ),
            ),
            // Web masaüstü deneyiminde sayfanın sonuna site geneli footer eklenir.
            const SliverToBoxAdapter(child: Footer()),
          ],
        ),
        _buildFloatingChip(context, state),
      ],
    );
  }

  // --- 💊 MASAÜSTÜ: KAYDIRINCA BELİREN SABİT MİNİ PROFİL KARTI ---
  // Apple ürün sayfalarındaki "yapışkan" (sticky) CTA hissini sayfanın
  // kaydırma durumuna (`_isScrolled`) göre yeniden üretir: kullanıcı hero'yu
  // geçtiğinde sağ altta beliren, oyuncunun adı + paylaş kısayolunu taşıyan
  // küçük bir kart.
  Widget _buildFloatingChip(
      final BuildContext context, final PlayerDetailState state) {
    final String fullName =
        '${state.player.firstName} ${state.player.lastName}';

    return Positioned(
      right: 40,
      bottom: 36,
      child: IgnorePointer(
        ignoring: !_isScrolled,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          offset: _isScrolled ? Offset.zero : const Offset(0, 0.4),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isScrolled ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
              decoration: BoxDecoration(
                color: WebColors.veryDarkBlue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(100),
                border:
                    Border.all(color: WebColors.primaryGold.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: OptimizedCachedImage(
                      imageUrl: state.player.imageUrl,
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: WebColors.whiteText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 14),
                  InkWell(
                    onTap: () => TiyatrolDeeplinkService.shareActor(
                      id: state.player.id,
                      name: fullName,
                    ),
                    borderRadius: BorderRadius.circular(100),
                    child: const Icon(Icons.share_rounded,
                        size: 18, color: WebColors.primaryGoldLight),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
