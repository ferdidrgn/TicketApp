import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/core/widgets/shimmer.dart';
import 'package:ticketapp/data/providers/player/player_notifier.dart';
import 'package:ticketapp/data/providers/show/show_notifier.dart';
import 'package:ticketapp/data/providers/stage/stage_notifier.dart';
import 'package:ticketapp/data/providers/user/user_provider.dart';
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

class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage>
    with TickerProviderStateMixin {
  // Animasyon Controller'ları
  late final AnimationController _heroController;
  late final AnimationController _contentController;
  late final AnimationController _floatingController;

  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _contentFade;

  final ScrollController _scrollController = ScrollController();

  // Performance Optimization: setState yerine ValueNotifier kullanımı
  final ValueNotifier<double> _scrollNotifier = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    _initAnimations();

    // Scroll dinleyicisi sadece notifier'ı günceller, tüm sayfayı rebuild etmez.
    _scrollController.addListener(() {
      if (mounted) _scrollNotifier.value = _scrollController.offset;
    });

    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) {
        _fetchInitialData();
        _precacheImages();
      }
    });
  }

  Future<void> _precacheImages() async {
    final showData = ref.read(showProvider).getShowById(widget.showId);
    if (showData != null && mounted) {
      try {
        await precacheImage(
            OptimizedCachedImage.provider(
              showData.imageUrl,
              context: context,
              // Genişlik vermezsen orijinal boyutu dener,
              // performans için ekran genişliği kadar limit koymak iyidir:
              width: MediaQuery.of(context).size.width,
            ),
            context);
      } catch (e) {
        debugPrint('Image precache warning: $e');
      }
    }
  }

  void _initAnimations() {
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _heroFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
    );

    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic));

    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _heroController.forward();
    // İçerik animasyonu hero'dan biraz sonra başlar
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _contentController.forward();
    });
  }

  Future<void> _fetchInitialData() async {
    final showNotifier = ref.read(showProvider.notifier);
    Show? showData = ref.read(showProvider).getShowById(widget.showId);

    // Show verisi yoksa çek
    if (showData == null) {
      try {
        await showNotifier.loadShowsByIds([widget.showId]);
        showData = ref.read(showProvider).getShowById(widget.showId);
        if (showData == null) {
          showNotifier.setErrorState("Gösteri yüklenemedi.");
          return;
        }
      } catch (e) {
        showNotifier.setErrorState("Gösteri yüklenemedi: $e");
        return;
      }
    }

    // İlişkili verileri (Event, Player) çek
    final eventsList = showData.eventsId;
    if (eventsList.isNotEmpty) {
      final validEventIds =
          eventsList.where((final id) => id.trim().isNotEmpty).toList();
      if (validEventIds.isNotEmpty) {
        unawaited(
            ref.read(eventProvider.notifier).loadEventsByIds(validEventIds));
      }
    }

    final allPlayerIds = {...showData.nowPlayersId, ...showData.oldPlayersId}
        .where((final id) => id.trim().isNotEmpty)
        .toList();

    if (allPlayerIds.isNotEmpty) {
      unawaited(
          ref.read(playerProvider.notifier).getPlayersByIds(allPlayerIds));
    }
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
    final showState = ref.watch(showProvider);
    final eventState = ref.watch(eventProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);
    final showData = showState.getShowById(widget.showId);

    // Event state listener (Stage verilerini çekmek için)
    ref.listen<EventState>(eventProvider, (final previous, final next) {
      final justLoaded = (previous?.dataList?.isEmpty ?? true) &&
          (next.dataList?.isNotEmpty ?? false);
      if (justLoaded) {
        final stageIds = next.dataList!
            .map((final e) => e.stageId)
            .whereType<String>()
            .where((final id) => id.trim().isNotEmpty && id != '0')
            .toSet()
            .toList();
        if (stageIds.isNotEmpty) {
          unawaited(ref.read(stageProvider.notifier).loadStagesByIds(stageIds));
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1a),
      body: showState.isLoading && !showState.hasData
          ? _LoadingState(animation: _floatingController)
          : (!showState.hasData || showData == null)
              ? _ErrorState(
                  message: showState.errorMessage,
                  onRetry: () => Navigator.pop(context),
                )
              : Stack(
                  children: [
                    // Performance Optimization: RepaintBoundary
                    RepaintBoundary(
                      child:
                          _BackgroundParticles(animation: _floatingController),
                    ),

                    CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      // Cache extent artırılarak scroll sırasında takılma önlenir
                      cacheExtent: 500,
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

                    Positioned(
                      top: 40,
                      left: 20,
                      child:
                          _FloatingBackButton(animation: _floatingController),
                    ),
                  ],
                ),
    );
  }
}

// --- ALT WIDGETLAR (PERFORMANS VE OKUNABİLİRLİK İÇİN AYRILDI) ---

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

class _ParallaxHero extends StatelessWidget {
  final Show showData;
  final ValueNotifier<double> scrollNotifier;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<double> floatingAnimation;

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
              // Performance Optimization: Parallax efekti için ValueListenableBuilder
              ValueListenableBuilder<double>(
                valueListenable: scrollNotifier,
                builder: (final context, final scrollOffset, final child) {
                  return Positioned(
                    top: -(scrollOffset * 0.5),
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: height + 200, // Parallax payı
                      child: OptimizedCachedImage(
                        imageUrl: showData.imageUrl,
                        fit: BoxFit.cover,
                        // Bellek optimizasyonu için cache boyutu
                        width: MediaQuery.of(context).size.width,
                      ),
                    ),
                  );
                },
              ),
              // Gradient Overlay (Const yapılarak tekrar çizim engellenir)
              const Positioned.fill(child: _HeroGradientOverlay()),

              // Title Section
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

class _EventSection extends StatelessWidget {
  final Show showData;
  final EventState eventState;
  final StageState stageState;

  const _EventSection({
    required this.showData,
    required this.eventState,
    required this.stageState,
  });

  @override
  Widget build(final BuildContext context) {
    if (eventState.isLoading && !eventState.hasData) {
      return const SizedBox(
        height: 100,
        child:
            Center(child: ShimmerLoading()),
      );
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
        final event = entry.value;
        final stage = stageState.getStageById(event.stageId);
        // Staggered animation için basit delay
        return _AnimatedEventCard(
          date: event.date.toString(),
          eventId: event.id,
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

  const _AnimatedEventCard({
    required this.date,
    required this.eventId,
    required this.showId,
    required this.stageName,
    required this.index,
  });

  @override
  Widget build(final BuildContext context) {
    final formatted = DateFormatter.formatForEventCard(date);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 100),
      builder: (final context, final value, final child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
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
                  blurRadius: 20,
                )
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
                      Text(
                        stageName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 4),
                          Text("İstanbul",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.6))),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time,
                              size: 16, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 4),
                          Text(formatted['time'] ?? '--:--',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.6))),
                        ],
                      ),
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
    String? userId = ref.read(loginProvider).user?.uid;
    userId ??= ref.read(userProvider).dataSingle?.id;
    userId ??= LocalStorageService.userUid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı oturumu bulunamadı.")),
      );
      return;
    }
    // Navigation logic here...
  }
}

class _PlayerSection extends StatefulWidget {
  final List<Player> players;
  final bool isOld;
  final bool isLoading;

  const _PlayerSection({
    required this.players,
    required this.isOld,
    required this.isLoading,
  });

  @override
  State<_PlayerSection> createState() => _PlayerSectionState();
}

class _PlayerSectionState extends State<_PlayerSection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 6;

  @override
  Widget build(final BuildContext context) {
    if (widget.players.isEmpty && !widget.isLoading) {
      return _EmptyStateMessage(
        message: widget.isOld ? 'Eski ekip bilgisi yok.' : 'Ekip bilgisi yok.',
      );
    }

    if (widget.isLoading && widget.players.isEmpty) {
      return const Center(
          child: ShimmerLoading());
    }

    final totalPages = (widget.players.length / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex =
        math.min(startIndex + _itemsPerPage, widget.players.length);
    final currentPlayers = widget.players.sublist(startIndex, endIndex);

    return Column(
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: currentPlayers
              .map((final player) =>
                  _AnimatedPlayerCard(player: player, isOld: widget.isOld))
              .toList(),
        ),
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
              offset: const Offset(0, 10),
            )
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
            // Golden Corner
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

class _GallerySection extends StatefulWidget {
  final List<String> photos;

  const _GallerySection({required this.photos});

  @override
  State<_GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends State<_GallerySection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 8;

  @override
  Widget build(final BuildContext context) {
    if (widget.photos.isEmpty)
      return const _EmptyStateMessage(message: 'Galeri boş.');

    final totalPages = (widget.photos.length / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = math.min(startIndex + _itemsPerPage, widget.photos.length);
    final currentPhotos = widget.photos.sublist(startIndex, endIndex);

    return Column(
      children: [
        context.isMobile
            ? _MobileGalleryRow(photos: currentPhotos)
            : _DesktopGalleryGrid(photos: currentPhotos),
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

// --- YARDIMCI KÜÇÜK WIDGETLAR (Reusable Components) ---

class _PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageButton(
            icon: Icons.arrow_back_ios_rounded,
            enabled: currentPage > 0,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 16),
          Text(
            '${currentPage + 1} / $totalPages',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 16),
          _PageButton(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: currentPage < totalPages - 1,
            onTap: () => onPageChanged(currentPage + 1),
          ),
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
    // Parçacıklar statik kalabilir veya ayrı bir widget olarak yönetilebilir.
    // Performance için Stack içinde RepaintBoundary ile kullanılıyor.
    final random = math.Random(42); // Sabit seed ile tutarlı render
    final size = MediaQuery.of(context).size;

    return Stack(
      children: List.generate(15, (final i) {
        final x = random.nextDouble() * size.width;
        final baseY = random.nextDouble() * size.height;

        return AnimatedBuilder(
          animation: animation,
          builder: (final context, final child) {
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(final BuildContext context) {
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

// --- Galeri Helperlar ---
class _MobileGalleryRow extends StatelessWidget {
  final List<String> photos;

  const _MobileGalleryRow({required this.photos});

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: photos.length,
        itemBuilder: (final _, final i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _GalleryItem(url: photos[i], width: 220, height: 180),
        ),
      ),
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
  final double width;
  final double height;

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
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
                child:
                    OptimizedCachedImage(imageUrl: url, fit: BoxFit.contain)),
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(30)),
                  child: const Icon(Icons.close, color: Color(0xFF0a0a1a)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Basit UI Bileşenleri ---

class _LoadingState extends StatelessWidget {
  final Animation<double> animation;

  const _LoadingState({required this.animation});

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (final _, final child) => Transform.translate(
              offset: Offset(0, math.sin(animation.value * math.pi) * 10),
              child: child,
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFF5E6A3)]),
              ),
              child: const Icon(Icons.theater_comedy,
                  size: 40, color: Color(0xFF0a0a1a)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Sahne Hazırlanıyor...',
              style: TextStyle(color: Colors.white70, fontSize: 18)),
        ],
      ),
    );
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

class _DateBox extends StatelessWidget {
  final String day;
  final String month;

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

class _FloatingBackButton extends StatelessWidget {
  final Animation<double> animation;

  const _FloatingBackButton({required this.animation});

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (final _, final child) => Transform.translate(
        offset: Offset(0, math.sin(animation.value * math.pi) * 3),
        child: child,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e).withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
            ),
            child:
                const Icon(Icons.arrow_back_rounded, color: Color(0xFFD4AF37)),
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
          child: OptimizedCachedImage(imageUrl: imageUrl, fit: BoxFit.cover),
        ),
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

// _ParallaxHero içinde kullanılan alt widgetlar
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
      shaderCallback: (final bounds) => const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF5E6A3)],
      ).createShader(bounds),
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
