import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/constants/app_constants.dart';
import 'package:ticketapp/features/splash/presentation/widgets/splash_data_guard.dart';
import '../../../../core/util/responsive_utils.dart';
import '../../../../shared/widgets/error_stage_widget_web.dart';
import '../../../../shared/widgets/galerry_section.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../events/presentation/providers/event_state.dart';
import '../../../players/presentation/providers/player_notifier.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../players/presentation/providers/player_state.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../stages/presentation/providers/stage_state.dart';
import '../../domain/entities/show.dart';
import '../providers/show_notifier.dart';
import '../providers/show_provider.dart';
import '../providers/show_state.dart';
import '../widgets/web/event_section.dart';
import '../widgets/web/player_section.dart';
import '../widgets/web/show_detail_hero.dart';

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

  // _showData değişkenini kaldırdık, veriyi doğrudan provider'dan okuyacağız.
  bool _isInitLoading = true;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initScrollListener();

    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _fetchInitialData();
    });
  }

  void _initControllers() {
    _heroController = AnimationController(
      vsync: this,
      duration: AppConstants.heroAnimationDuration,
    );
    _contentController = AnimationController(
      vsync: this,
      duration: AppConstants.contentAnimationDuration,
    );
    _floatingController = AnimationController(
      vsync: this,
      duration: AppConstants.floatAnimationDuration,
    );

    _heroFade = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOut,
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: Curves.easeOutCubic,
      ),
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
  }

  void _startPageAnimations() {
    if (!mounted) return;

    _heroController.forward();
    _floatingController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _contentController.forward();
    });
  }

  void _initScrollListener() {
    _scrollController.addListener(() {
      if (mounted) _scrollNotifier.value = _scrollController.offset;
    });
  }

  // Header resmini önbelleğe alma
  Future<void> _precacheHeaderImage(final Show show) async {
    if (mounted) {
      try {
        await precacheImage(
          OptimizedCachedImage.provider(
            show.imageUrl,
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
    final showNotifier = ref.read(showProvider.notifier);

    // 1. Önce Show Provider'da veri var mı kontrol et
    Show? currentShow = ref.read(showProvider).getShowById(widget.showId);

    // 2. Veri yoksa sunucudan çek
    if (currentShow == null) {
      try {
        await showNotifier.loadShowsByIds([widget.showId]);
        // Yükleme bitti, güncel veriyi tekrar kontrol et
        currentShow = ref.read(showProvider).getShowById(widget.showId);

        if (currentShow == null) {
          if (mounted) {
            showNotifier.setErrorState("Gösteri bulunamadı.");
            setState(() => _isInitLoading = false);
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          showNotifier.setErrorState("Veri yüklenirken hata oluştu: $e");
          setState(() => _isInitLoading = false);
        }
        return;
      }
    }

    // Buraya geldiysek elimizde kesinlikle currentShow var demektir.
    final List<Future> futures = [];

    // Events yükle
    if (currentShow.eventsId.isNotEmpty) {
      final validEvents = currentShow.eventsId
          .where((final id) => id.trim().isNotEmpty)
          .toList();
      if (validEvents.isNotEmpty) {
        futures.add(
          ref.read(eventProvider.notifier).loadEventsByIds(validEvents),
        );
      }
    }

    // Oyuncuları yükle
    final allPlayers = {...currentShow.nowPlayersId, ...currentShow.oldPlayersId}
        .where((final id) => id.trim().isNotEmpty)
        .toList();

    if (allPlayers.isNotEmpty) {
      futures.add(
        ref.read(playerProvider.notifier).getPlayersByIds(allPlayers),
      );
    }

    await Future.wait(futures);

    if (mounted) {
      await _precacheHeaderImage(currentShow);
      setState(() => _isInitLoading = false);

      // Animasyonları başlat
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _startPageAnimations();
      });
    }
  }

  void _safePop(final BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home', extra: {'section': 'shows'});
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

    // REAKTİF KISIM: Veriyi değişkenden değil, doğrudan STATE'ten alıyoruz.
    // Böylece loadShowsByIds tamamlandığı an burası null olmaktan çıkıp doluyor.
    final showData = showState.getShowById(widget.showId);

    _listenForStageData(showData);

    return SplashDataGuard(
      // Veri yükleniyorsa VEYA (hata yoksa ama veri henüz gelmemişse) loading göster
      isLoading: _isInitLoading || (showData == null && !showState.hasError),
      loadingMessage: 'Oyun detayları hazırlanıyor...',
      child: Scaffold(
        backgroundColor: const Color(0xFF0a0a1a),
        // showData null ise ve loading bitmişse hata vardır
        body: showData == null
            ? _buildErrorState(showState)
            : _buildSuccessState(showData, eventState, playerState, stageState),
      ),
    );
  }

  Widget _buildErrorState(final ShowState showState) {
    // Eğer hala loading ise boş dön, SplashDataGuard zaten loading gösteriyor
    if (showState.isLoading) return const SizedBox();

    return Center(
      child: ErrorStateWidget(
        message: showState.errorMessage ?? "Oyun bilgisi bulunamadı.",
        onRetry: () {
          setState(() => _isInitLoading = true);
          _fetchInitialData();
        },
      ),
    );
  }

  Widget _buildSuccessState(
      final Show showData,
      final EventState eventState,
      final PlayerState playerState,
      final StageState stageState,
      ) {
    return Stack(
      children: [
        // Arka plan
        _BackgroundParticles(animation: _floatingController),

        // Ana içerik
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          cacheExtent: 500,
          slivers: [
            SliverToBoxAdapter(
              child: ShowDetailHero(
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

        // Navigasyon butonu
        const Positioned(
          top: 40,
          left: 20,
          child: _FloatingBackButton(),
        ),
      ],
    );
  }

  void _listenForStageData(final Show? showData) {
    ref.listen<EventState>(eventProvider, (final previous, final next) {
      final justLoaded = (previous?.dataList?.isEmpty ?? true) &&
          (next.dataList?.isNotEmpty ?? false);

      if (justLoaded && mounted && showData != null) {
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
    final horizontalPadding = context.responsive(
      mobile: AppConstants.mobilePadding,
      tablet: AppConstants.tabletPadding,
      desktop: AppConstants.desktopPadding,
    );

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 60),
      child: isDesktop
          ? _DesktopLayout(
              showData: showData,
              eventState: eventState,
              playerState: playerState,
              stageState: stageState,
            )
          : _MobileLayout(
              showData: showData,
              eventState: eventState,
              playerState: playerState,
              stageState: stageState,
            ),
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
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(height: 24),
              EventSection(
                showData: showData,
                eventState: eventState,
                stageState: stageState,
              ),
              const SizedBox(height: 50),
              const _SectionTitle(title: 'Ekip', icon: Icons.people_rounded),
              const SizedBox(height: 24),
              PlayerSection(
                players: nowPlayers,
                isOld: false,
                isLoading: playerState.isLoading,
              ),
              const SizedBox(height: 50),
              const _SectionTitle(
                title: 'Eski Ekip',
                icon: Icons.history_rounded,
              ),
              const SizedBox(height: 24),
              PlayerSection(
                players: oldPlayers,
                isOld: true,
                isLoading: playerState.isLoading,
              ),
              const SizedBox(height: 50),
              const _SectionTitle(
                title: 'Galeri',
                icon: Icons.photo_library_rounded,
              ),
              const SizedBox(height: 24),
              GallerySection(photos: showData.photosShowId),
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
          title: 'Etkinlik Takvimi',
          icon: Icons.calendar_today_rounded,
        ),
        const SizedBox(height: 20),
        EventSection(
          showData: showData,
          eventState: eventState,
          stageState: stageState,
        ),
        const SizedBox(height: 40),
        const _SectionTitle(title: 'Ekip', icon: Icons.people_rounded),
        const SizedBox(height: 20),
        PlayerSection(
          players: nowPlayers,
          isOld: false,
          isLoading: playerState.isLoading,
        ),
        const SizedBox(height: 40),
        const _SectionTitle(title: 'Eski Ekip', icon: Icons.history_rounded),
        const SizedBox(height: 20),
        PlayerSection(
          players: oldPlayers,
          isOld: true,
          isLoading: playerState.isLoading,
        ),
        const SizedBox(height: 40),
        const _SectionTitle(title: 'Galeri', icon: Icons.photo_library_rounded),
        const SizedBox(height: 20),
        GallerySection(photos: showData.photosShowId),
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
            color: Color(0xFF1a1a2e).withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(0xFFD4AF37).withOpacity(0.5),
            ),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFFD4AF37),
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
            color: Color(0xFFD4AF37).withOpacity(0.4),
            blurRadius: 50,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 9 / 13,
          child: OptimizedCachedImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
          ),
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
        color: Color(0xFF1a1a2e).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFFD4AF37).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD4AF37).withOpacity(0.1),
            blurRadius: 30,
          ),
        ],
      ),
      child: Text(
        description.replaceAll('\\n', '\n'),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          height: 1.9,
          letterSpacing: 0.3,
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
                  color: Color(0xFFD4AF37)
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
            gradient: LinearGradient(
              colors: [
                Color(0xFFD4AF37),
                Color(0xFFF5E6A3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFD4AF37).withOpacity(0.4),
                blurRadius: 15,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Color(0xFF0a0a1a),
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFD4AF37).withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
