import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/data/providers/player/player_notifier.dart';
import 'package:ticketapp/data/providers/show/show_notifier.dart';
import 'package:ticketapp/data/providers/stage/stage_notifier.dart';
import 'package:ticketapp/data/providers/user/user_provider.dart';
import 'package:ticketapp/presentation/mobil/pages/splash/splash_data_guard.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/util/date_formatter.dart';
import '../../../core/widgets/optimized_cached_image.dart';
import '../../../data/providers/event/event_provider.dart';
import '../../../data/providers/event/event_state.dart';
import '../../../data/providers/login/login_provider.dart';
import '../../../data/providers/player/player_provider.dart';
import '../../../data/providers/player/player_state.dart';
import '../../../data/providers/show/show_provider.dart';
import '../../../data/providers/stage/stage_provider.dart';
import '../../../data/providers/stage/stage_state.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/show.dart';

/// Animasyon ve UI sabitleri
class _UiConstants {
  static const Duration heroDuration = Duration(milliseconds: 1200);
  static const Duration contentDuration = Duration(milliseconds: 800);
  static const Duration floatDuration = Duration(seconds: 3);
  static const int staggerDelay = 100;
  static const double parallaxFactor = 0.5;
  static const int galleryItemsPerPage = 8;
}

class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage>
    with TickerProviderStateMixin {
  late final AnimationController _heroController;
  late final AnimationController _contentController;
  late final AnimationController _floatingController;

  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _contentFade;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollNotifier = ValueNotifier(0.0);

  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initScrollListener();

    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) {
        _fetchInitialData();
        // Header resmi preload edilebilir, ancak data loaded olduktan sonra yapmak daha garantidir.
      }
    });
  }

  void _initControllers() {
    _heroController =
        AnimationController(vsync: this, duration: _UiConstants.heroDuration);
    _contentController = AnimationController(
        vsync: this, duration: _UiConstants.contentDuration);
    _floatingController =
        AnimationController(vsync: this, duration: _UiConstants.floatDuration)
          ..repeat(reverse: true);

    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _heroController, curve: Curves.easeOutCubic));
    _contentFade =
        CurvedAnimation(parent: _contentController, curve: Curves.easeOut);

    // ❌ ESKİ KOD: _heroController.forward() burada çağrılıyordu.
    // Artık Splash bittikten sonra çağıracağız.
  }

  // ✅ YENİ: Animasyonları başlatan fonksiyon
  void _startPageAnimations() {
    _heroController.forward();
    // İçerik animasyonunu Hero'dan biraz sonra başlat
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _contentController.forward();
    });
  }

  void _initScrollListener() {
    _scrollController.addListener(() {
      if (mounted) _scrollNotifier.value = _scrollController.offset;
    });
  }

  Future<void> _precacheHeaderImage() async {
    final showData = ref.read(showProvider).getShowById(widget.showId);
    if (showData != null && mounted) {
      try {
        await precacheImage(
          OptimizedCachedImage.provider(
            showData.imageUrl,
            context: context,
            width: MediaQuery.of(context).size.width,
          ),
          context,
        );
      } catch (e) {
        debugPrint('Image precache warning: $e');
      }
    }
  }

  Future<void> _fetchInitialData() async {
    if (_isDataLoaded) return;

    final showNotifier = ref.read(showProvider.notifier);
    Show? showData = ref.read(showProvider).getShowById(widget.showId);

    // 1. Show verisi yoksa çek
    if (showData == null) {
      try {
        await showNotifier.loadShowsByIds([widget.showId]);
        showData = ref.read(showProvider).getShowById(widget.showId);
        if (showData == null) {
          if (mounted) showNotifier.setErrorState("Gösteri yüklenemedi.");
          // Hata durumunda da loading'i bitir ki UI görünsün (Hata mesajı)
          if (mounted) setState(() => _isDataLoaded = true);
          return;
        }
      } catch (e) {
        if (mounted) showNotifier.setErrorState("Gösteri yüklenemedi: $e");
        if (mounted) setState(() => _isDataLoaded = true);
        return;
      }
    }

    final List<Future> futures = [];

    // 2. Etkinlikleri çek
    if (showData.eventsId.isNotEmpty) {
      final validEvents =
          showData.eventsId.where((final id) => id.trim().isNotEmpty).toList();
      if (validEvents.isNotEmpty) {
        futures
            .add(ref.read(eventProvider.notifier).loadEventsByIds(validEvents));
      }
    }

    // 3. Oyuncuları çek
    final allPlayers = {...showData.nowPlayersId, ...showData.oldPlayersId}
        .where((final id) => id.trim().isNotEmpty)
        .toList();

    if (allPlayers.isNotEmpty) {
      futures
          .add(ref.read(playerProvider.notifier).getPlayersByIds(allPlayers));
    }

    // Hepsini bekle
    await Future.wait(futures);

    // 4. Resmi önbelleğe al
    if (mounted) _precacheHeaderImage();

    // 5. Veriler hazır, Splash'i kaldır ve animasyonları başlat
    if (mounted) {
      setState(() {
        _isDataLoaded =
            true; // Bu satır Splash'in fade-out (kaybolma) sürecini başlatır
      });

      // 🚀 ZAMANLAMA: Splash'in kaybolması yaklaşık 800ms sürer.
      // Animasyonları bu sürenin sonunda başlatıyoruz ki kullanıcı görsün.
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _startPageAnimations();
      });
    }
  }

  void _safePop(final BuildContext context) {
    if (context.canPop())
      context.pop();
    else
      // Hata durumunda dönerken de shows bölümüne gitsin
      context.go('/home', extra: {'section': 'shows'});
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    _floatingController.dispose();
    _scrollController.dispose();
    _scrollNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final showData = ref
        .watch(showProvider.select((final s) => s.getShowById(widget.showId)));
    final showState = ref.read(showProvider);
    final eventState = ref.watch(eventProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);

    _listenForStageData();

    // ✅ SPLASH ENTEGRASYONU
    return SplashDataGuard(
      isLoading: !_isDataLoaded,
      loadingMessage: 'Oyun detayları hazırlanıyor...',
      child: Scaffold(
        backgroundColor: const Color(0xFF0a0a1a),
        body: showData == null
            ? (showState.isLoading
                ? const SizedBox() // DataSplashGuard zaten loading gösterecek
                : _ErrorState(
                    message: showState.errorMessage,
                    onRetry: () => _safePop(context)))
            : Stack(
                children: [
                  RepaintBoundary(
                    child: _BackgroundParticles(animation: _floatingController),
                  ),
                  CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    cacheExtent: 1000,
                    slivers: [
                      SliverToBoxAdapter(
                        child: _ParallaxHero(
                          showData: showData,
                          scrollNotifier: _scrollNotifier,
                          fadeAnimation: _heroFade,
                          slideAnimation: _heroSlide,
                          floatingAnimation: _floatingController,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _contentFade,
                          child: _MainContent(
                            showData: showData,
                            eventState: eventState,
                            playerState: playerState,
                            stageState: stageState,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Positioned(
                      top: 40, left: 20, child: _FloatingBackButton()),
                ],
              ),
      ),
    );
  }

  void _listenForStageData() {
    ref.listen<EventState>(eventProvider, (final previous, final next) {
      final justLoaded = (previous?.dataList?.isEmpty ?? true) &&
          (next.dataList?.isNotEmpty ?? false);
      if (justLoaded && mounted) {
        final stageIds = next.dataList!
            .map((final e) => e.stageId)
            .whereType<String>()
            .where((final id) => id.trim().isNotEmpty && id != '0')
            .toSet()
            .toList();
        if (stageIds.isNotEmpty) {
          ref.read(stageProvider.notifier).loadStagesByIds(stageIds);
        }
      }
    });
  }
}

// ... _MainContent, _DesktopLayout, _MobileLayout ve diğer tüm alt widget'lar ...
// (Burada kodun geri kalanı orijinal halini koruyor, sadece importları ve yukarıdaki class'ı güncellemeniz yeterli.)

class _MainContent extends StatelessWidget {
  final Show showData;
  final EventState eventState;
  final PlayerState playerState;
  final StageState stageState;

  const _MainContent({
    required this.showData,
    required this.eventState,
    required this.playerState,
    required this.stageState,
  });

  @override
  Widget build(final BuildContext context) {
    final isDesktop = context.isDesktop;
    final horizontalPadding =
        context.responsive(mobile: 16.0, tablet: 40.0, desktop: 100.0);

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 60),
      child: isDesktop
          ? _DesktopLayout(
              showData: showData,
              eventState: eventState,
              playerState: playerState,
              stageState: stageState)
          : _MobileLayout(
              showData: showData,
              eventState: eventState,
              playerState: playerState,
              stageState: stageState),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final Show showData;
  final EventState eventState;
  final PlayerState playerState;
  final StageState stageState;

  const _DesktopLayout({
    required this.showData,
    required this.eventState,
    required this.playerState,
    required this.stageState,
  });

  @override
  Widget build(final BuildContext context) {
    final nowPlayers = playerState.getPlayersByIds(showData.nowPlayersId);
    final oldPlayers = playerState.getPlayersByIds(showData.oldPlayersId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _AnimatedPoster(imageUrl: showData.imageUrl),
              const SizedBox(height: 40),
              _GlassDescriptionCard(description: showData.description),
            ],
          ),
        ),
        const SizedBox(width: 60),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                  title: 'Etkinlik Takvimi',
                  icon: Icons.calendar_today_rounded),
              const SizedBox(height: 24),
              _EventSection(
                  showData: showData,
                  eventState: eventState,
                  stageState: stageState),
              const SizedBox(height: 50),
              const _SectionTitle(title: 'Ekip', icon: Icons.people_rounded),
              const SizedBox(height: 24),
              _PlayerSection(
                  players: nowPlayers,
                  isOld: false,
                  isLoading: playerState.isLoading),
              const SizedBox(height: 50),
              const _SectionTitle(
                  title: 'Eski Ekip', icon: Icons.history_rounded),
              const SizedBox(height: 24),
              _PlayerSection(
                  players: oldPlayers,
                  isOld: true,
                  isLoading: playerState.isLoading),
              const SizedBox(height: 50),
              const _SectionTitle(
                  title: 'Galeri', icon: Icons.photo_library_rounded),
              const SizedBox(height: 24),
              _GallerySection(photos: showData.photosShowId),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Show showData;
  final EventState eventState;
  final PlayerState playerState;
  final StageState stageState;

  const _MobileLayout({
    required this.showData,
    required this.eventState,
    required this.playerState,
    required this.stageState,
  });

  @override
  Widget build(final BuildContext context) {
    final nowPlayers = playerState.getPlayersByIds(showData.nowPlayersId);
    final oldPlayers = playerState.getPlayersByIds(showData.oldPlayersId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GlassDescriptionCard(description: showData.description),
        const SizedBox(height: 40),
        const _SectionTitle(
            title: 'Etkinlik Takvimi', icon: Icons.calendar_today_rounded),
        const SizedBox(height: 20),
        _EventSection(
            showData: showData, eventState: eventState, stageState: stageState),
        const SizedBox(height: 40),
        const _SectionTitle(title: 'Ekip', icon: Icons.people_rounded),
        const SizedBox(height: 20),
        _PlayerSection(
            players: nowPlayers,
            isOld: false,
            isLoading: playerState.isLoading),
        const SizedBox(height: 40),
        const _SectionTitle(title: 'Eski Ekip', icon: Icons.history_rounded),
        const SizedBox(height: 20),
        _PlayerSection(
            players: oldPlayers, isOld: true, isLoading: playerState.isLoading),
        const SizedBox(height: 40),
        const _SectionTitle(title: 'Galeri', icon: Icons.photo_library_rounded),
        const SizedBox(height: 20),
        _GallerySection(photos: showData.photosShowId),
      ],
    );
  }
}

class _FloatingBackButton extends StatelessWidget {
  const _FloatingBackButton();

  @override
  Widget build(final BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // ✅ GÜVENLİ GERİ DÖNÜŞ VE RESET FIX
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home', extra: {'section': 'shows'});
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e).withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Color(0xFFD4AF37)),
        ),
      ),
    );
  }
}

// --- HELPER WIDGETS ---
class _ParallaxHero extends StatelessWidget {
  final Show showData;
  final ValueNotifier<double> scrollNotifier;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final AnimationController floatingAnimation;

  const _ParallaxHero({
    required this.showData,
    required this.scrollNotifier,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.floatingAnimation,
  });

  @override
  Widget build(final BuildContext context) {
    final height =
        context.responsive(mobile: 500.0, tablet: 600.0, desktop: 700.0);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              ValueListenableBuilder<double>(
                valueListenable: scrollNotifier,
                builder: (final context, final scrollOffset, final child) {
                  return Positioned(
                    top: -(scrollOffset * _UiConstants.parallaxFactor),
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: height + 200,
                      child: OptimizedCachedImage(
                        imageUrl: showData.imageUrl,
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width,
                      ),
                    ),
                  );
                },
              ),
              const Positioned.fill(child: _HeroGradientOverlay()),
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const _HeroDivider(),
                    _HeroTitle(title: showData.name),
                    const SizedBox(height: 20),
                    _AnimatedUnderline(animation: floatingAnimation),
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

class _PlayerSection extends StatelessWidget {
  final List<Player> players;
  final bool isOld;
  final bool isLoading;

  const _PlayerSection(
      {required this.players, required this.isOld, required this.isLoading});

  @override
  Widget build(final BuildContext context) {
    if (players.isEmpty && !isLoading) {
      return _EmptyStateMessage(
          message: isOld ? 'Eski ekip bilgisi yok.' : 'Ekip bilgisi yok.');
    }

    if (isLoading && players.isEmpty) {
      return const SizedBox(
          height: 220,
          child: Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    }

    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: players.asMap().entries.map((final entry) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(
              milliseconds: 300 + entry.key * _UiConstants.staggerDelay),
          builder: (final context, final value, final child) => Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.8 + 0.2 * value, child: child),
          ),
          child: _AnimatedPlayerCard(player: entry.value, isOld: isOld),
        );
      }).toList(),
    );
  }
}

class _AnimatedPlayerCard extends StatelessWidget {
  final Player player;
  final bool isOld;

  const _AnimatedPlayerCard({required this.player, required this.isOld});

  @override
  Widget build(final BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: OptimizedCachedImage(
                    imageUrl: player.imageUrl,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    '${player.firstName}\n${player.lastName}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.3),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            if (isOld)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Center(
                      child:
                          Icon(Icons.history, color: Colors.white38, size: 40)),
                ),
              ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      const Color(0xFFD4AF37).withOpacity(isOld ? 0.3 : 0.6),
                      Colors.transparent
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventSection extends StatelessWidget {
  final Show showData;
  final EventState eventState;
  final StageState stageState;

  const _EventSection(
      {required this.showData,
      required this.eventState,
      required this.stageState});

  @override
  Widget build(final BuildContext context) {
    if (eventState.isLoading && !eventState.hasData) {
      return const SizedBox(
          height: 100,
          child: Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    }

    final events = eventState.dataList
            ?.where((final e) => showData.eventsId.contains(e.id))
            .toList() ??
        [];

    if (events.isEmpty) {
      return const _EmptyStateMessage(
          message: 'Yaklaşan etkinlik bulunmamaktadır.');
    }

    return Column(
      children: events.asMap().entries.map((final entry) {
        final stage = stageState.getStageById(entry.value.stageId);
        return _AnimatedEventCard(
          date: entry.value.date.toString(),
          eventId: entry.value.id,
          showId: showData.id,
          stageName: stage?.name ?? "Sahne bilgisi yok",
          index: entry.key,
        );
      }).toList(),
    );
  }
}

class _AnimatedEventCard extends StatelessWidget {
  final String date;
  final String eventId;
  final String showId;
  final String stageName;
  final int index;

  const _AnimatedEventCard(
      {required this.date,
      required this.eventId,
      required this.showId,
      required this.stageName,
      required this.index});

  @override
  Widget build(final BuildContext context) {
    final formatted = DateFormatter.formatForEventCard(date);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * _UiConstants.staggerDelay),
      builder: (final context, final value, final child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _navigateToSeatSelection(context),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    blurRadius: 20)
              ],
            ),
            child: Row(
              children: [
                _DateBox(
                    day: formatted['day'] ?? '?',
                    month: formatted['monthName'] ?? '-'),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stageName,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      _EventLocationRow(time: formatted['time'] ?? '--:--'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Color(0xFFD4AF37)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSeatSelection(final BuildContext context) {
    final ref = ProviderScope.containerOf(context);
    String? userId = ref.read(loginProvider).user?.uid ??
        ref.read(userProvider).dataSingle?.id ??
        LocalStorageService.userUid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kullanıcı oturumu bulunamadı.")));
      return;
    }
    // Navigator.push(...)
  }
}

class _GallerySection extends ConsumerStatefulWidget {
  final List<String> photos;

  const _GallerySection({required this.photos});

  @override
  ConsumerState<_GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends ConsumerState<_GallerySection> {
  int _currentPage = 0;

  @override
  Widget build(final BuildContext context) {
    if (widget.photos.isEmpty)
      return const _EmptyStateMessage(message: 'Galeri boş.');

    if (context.isMobile) {
      return SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.photos.length,
          itemBuilder: (final _, final i) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _GalleryItem(url: widget.photos[i], width: 220, height: 180),
          ),
        ),
      );
    }

    final totalPages =
        (widget.photos.length / _UiConstants.galleryItemsPerPage).ceil();
    final startIndex = _currentPage * _UiConstants.galleryItemsPerPage;
    final endIndex = math.min(
        startIndex + _UiConstants.galleryItemsPerPage, widget.photos.length);
    final currentPhotos = widget.photos.sublist(startIndex, endIndex);

    return Column(
      children: [
        _DesktopGalleryGrid(photos: currentPhotos),
        if (totalPages > 1)
          _PaginationControls(
            currentPage: _currentPage,
            totalPages: totalPages,
            onPageChanged: (final page) => setState(() => _currentPage = page),
          ),
      ],
    );
  }
}

class _HeroGradientOverlay extends StatelessWidget {
  const _HeroGradientOverlay();

  @override
  Widget build(final BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0a0a1a).withOpacity(0.3),
            Colors.transparent,
            const Color(0xFF0a0a1a).withOpacity(0.9),
            const Color(0xFF0a0a1a),
          ],
          stops: const [0.0, 0.3, 0.8, 1.0],
        ),
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Colors.transparent,
          Color(0xFFD4AF37),
          Colors.transparent
        ]),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  final String title;

  const _HeroTitle({required this.title});

  @override
  Widget build(final BuildContext context) {
    return ShaderMask(
      shaderCallback: (final bounds) =>
          const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFF5E6A3)])
              .createShader(bounds),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: context.responsive(mobile: 36.0, desktop: 64.0),
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 8,
          shadows: [
            BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 40)
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AnimatedUnderline extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedUnderline({required this.animation});

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (final _, final __) => Container(
        height: 4,
        width: 120 + math.sin(animation.value * math.pi) * 20,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            Color(0xFFD4AF37),
            Color(0xFFF5E6A3),
            Color(0xFFD4AF37)
          ]),
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.6), blurRadius: 15)
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String day, month;

  const _DateBox({required this.day, required this.month});

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFF5E6A3)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(day,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0a0a1a))),
          Text(month,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0a0a1a))),
        ],
      ),
    );
  }
}

class _EventLocationRow extends StatelessWidget {
  final String time;

  const _EventLocationRow({required this.time});

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on, size: 16, color: Color(0xFFD4AF37)),
        const SizedBox(width: 4),
        Text("İstanbul",
            style:
                TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
        const SizedBox(width: 16),
        const Icon(Icons.access_time, size: 16, color: Color(0xFFD4AF37)),
        const SizedBox(width: 4),
        Text(time,
            style:
                TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
      ],
    );
  }
}

class _DesktopGalleryGrid extends StatelessWidget {
  final List<String> photos;

  const _DesktopGalleryGrid({required this.photos});

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final ctx, final constraints) {
        final crossAxisCount =
            context.responsive(mobile: 2, tablet: 3, desktop: 4);
        final spacing = context.gridSpacing;
        final itemWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;
        final itemHeight = itemWidth * 0.75;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: photos
              .map((final url) =>
                  _GalleryItem(url: url, width: itemWidth, height: itemHeight))
              .toList(),
        );
      },
    );
  }
}

class _GalleryItem extends StatelessWidget {
  final String url;
  final double width, height;

  const _GalleryItem(
      {required this.url, required this.width, required this.height});

  @override
  Widget build(final BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showFullImage(context, url),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.15),
                  blurRadius: 20)
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: OptimizedCachedImage(
                imageUrl: url, width: width, height: height, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  void _showFullImage(final BuildContext context, final String url) {
    showDialog(
      context: context,
      barrierColor: const Color(0xFF0a0a1a).withOpacity(0.95),
      builder: (final _) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                child: Center(
                  child: OptimizedCachedImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                          )
                        ]),
                    child: const Icon(Icons.close,
                        color: Color(0xFF0a0a1a), size: 24),
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

class _AnimatedPoster extends StatelessWidget {
  final String imageUrl;

  const _AnimatedPoster({required this.imageUrl});

  @override
  Widget build(final BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.4),
              blurRadius: 50,
              spreadRadius: 5)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
            aspectRatio: 9 / 13,
            child: OptimizedCachedImage(imageUrl: imageUrl, fit: BoxFit.cover)),
      ),
    );
  }
}

class _GlassDescriptionCard extends StatelessWidget {
  final String description;

  const _GlassDescriptionCard({required this.description});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.1), blurRadius: 30)
        ],
      ),
      child: Text(
        description.replaceAll('\\n', '\n'),
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.9,
            letterSpacing: 0.3),
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  final int currentPage, totalPages;
  final Function(int) onPageChanged;

  const _PaginationControls(
      {required this.currentPage,
      required this.totalPages,
      required this.onPageChanged});

  @override
  Widget build(final BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageButton(
              icon: Icons.arrow_back_ios_rounded,
              enabled: currentPage > 0,
              onTap: () => onPageChanged(currentPage - 1)),
          const SizedBox(width: 16),
          Text('${currentPage + 1} / $totalPages',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 16),
          _PageButton(
              icon: Icons.arrow_forward_ios_rounded,
              enabled: currentPage < totalPages - 1,
              onTap: () => onPageChanged(currentPage + 1)),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: enabled
                ? const Color(0xFFD4AF37)
                : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: enabled ? const Color(0xFF0a0a1a) : Colors.white38,
              size: 16),
        ),
      ),
    );
  }
}

class _BackgroundParticles extends StatelessWidget {
  final Animation<double> animation;

  const _BackgroundParticles({required this.animation});

  @override
  Widget build(final BuildContext context) {
    final random = math.Random(42);
    final size = MediaQuery.of(context).size;
    return Stack(
      children: List.generate(15, (final i) {
        final x = random.nextDouble() * size.width;
        final baseY = random.nextDouble() * size.height;
        return AnimatedBuilder(
          animation: animation,
          builder: (final _, final __) {
            final y = baseY + math.sin(animation.value * math.pi * 2 + i) * 30;
            return Positioned(
              left: x,
              top: y,
              child: Container(
                width: 4 + random.nextDouble() * 4,
                height: 4 + random.nextDouble() * 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4AF37)
                      .withOpacity(0.1 + random.nextDouble() * 0.2),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _EmptyStateMessage extends StatelessWidget {
  final String message;

  const _EmptyStateMessage({required this.message});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline,
              color: Colors.white.withOpacity(0.3), size: 20),
          const SizedBox(width: 12),
          Text(message,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 15)),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(final BuildContext context) {
    return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
  }
}

class _ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _ErrorState({this.message, required this.onRetry});

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFD4AF37)),
          const SizedBox(height: 16),
          Text(message ?? 'Hata',
              style: const TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFF5E6A3)]),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text('Geri Dön',
                  style: TextStyle(
                      color: Color(0xFF0a0a1a), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFF5E6A3)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.4),
                  blurRadius: 15)
            ],
          ),
          child: Icon(icon, color: const Color(0xFF0a0a1a), size: 22),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.5),
                  Colors.transparent
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
