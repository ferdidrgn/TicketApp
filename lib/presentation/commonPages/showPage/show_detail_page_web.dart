import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/data/providers/player/player_notifier.dart';
import 'package:ticketapp/data/providers/show/show_notifier.dart';
import 'package:ticketapp/data/providers/stage/stage_notifier.dart';
import 'package:ticketapp/data/providers/user/user_provider.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/util/date_formatter.dart';
import '../../../core/widgets/shimmer.dart';
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
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPage();
}

class _ShowDetailPage extends ConsumerState<ShowDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _contentController;
  late AnimationController _floatingController;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _contentFade;

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchInitialData();
    });
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
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _contentController.forward();
    });
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
  }

  Future<void> _fetchInitialData() async {
    final showNotifier = ref.read(showProvider.notifier);
    Show? showData = ref.read(showProvider).getShowById(widget.showId);

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

    final eventsList = showData.eventsId;
    if (eventsList.isNotEmpty) {
      final validEventIds =
          eventsList.where((id) => id.trim().isNotEmpty).toList();
      if (validEventIds.isNotEmpty) {
        unawaited(
            ref.read(eventProvider.notifier).loadEventsByIds(validEventIds));
      }
    }

    final allPlayerIds = {...showData.nowPlayersId, ...showData.oldPlayersId}
        .where((id) => id.trim().isNotEmpty)
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showState = ref.watch(showProvider);
    final eventState = ref.watch(eventProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);
    final showData = showState.getShowById(widget.showId);

    ref.listen<EventState>(eventProvider, (previous, next) {
      final justLoaded = (previous?.dataList?.isEmpty ?? true) &&
          (next.dataList?.isNotEmpty ?? false);
      if (justLoaded) {
        final stageIds = next.dataList!
            .map((e) => e.stageId)
            .whereType<String>()
            .where((id) => id.trim().isNotEmpty && id != '0')
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
          ? _buildLoadingState()
          : (!showState.hasData)
              ? _buildErrorState(showState.errorMessage)
              : _buildContent(
                  context, showData!, eventState, playerState, stageState),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatingController,
            builder: (_, child) => Transform.translate(
              offset:
                  Offset(0, math.sin(_floatingController.value * math.pi) * 10),
              child: child,
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFF5E6A3)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.theater_comedy,
                  size: 40, color: Color(0xFF0a0a1a)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sahne Hazırlanıyor...',
            style: TextStyle(
                color: Colors.white70, fontSize: 18, letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFD4AF37)),
          const SizedBox(height: 16),
          Text(message ?? 'Gösteri bulunamadı.',
              style: const TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 24),
          _buildGoldenButton('Geri Dön', () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildGoldenButton(String text, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFF5E6A3)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(text,
              style: const TextStyle(
                  color: Color(0xFF0a0a1a),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Show showData,
      EventState eventState, PlayerState playerState, StageState stageState) {
    final isDesktop = context.isDesktop;
    final horizontalPadding =
        context.responsive(mobile: 16.0, tablet: 40.0, desktop: 100.0);

    return Stack(
      children: [
        // Animated Background Particles
        ..._buildFloatingParticles(),

        // Main Content
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildParallaxHero(context, showData)),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _contentFade,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding, vertical: 60),
                  child: isDesktop
                      ? _buildDesktopLayout(context, showData, eventState,
                          playerState, stageState)
                      : _buildMobileLayout(context, showData, eventState,
                          playerState, stageState),
                ),
              ),
            ),
          ],
        ),

        // Floating Back Button
        Positioned(top: 40, left: 20, child: _buildFloatingBackButton()),
      ],
    );
  }

  List<Widget> _buildFloatingParticles() {
    return List.generate(15, (i) {
      final random = math.Random(i);
      return AnimatedBuilder(
        animation: _floatingController,
        builder: (_, __) {
          final x = random.nextDouble() * MediaQuery.of(context).size.width;
          final baseY =
              random.nextDouble() * MediaQuery.of(context).size.height;
          final y = baseY +
              math.sin(_floatingController.value * math.pi * 2 + i) * 30;
          return Positioned(
            left: x,
            top: y - _scrollOffset * 0.3,
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
    });
  }

  Widget _buildFloatingBackButton() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, math.sin(_floatingController.value * math.pi) * 3),
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
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                    blurRadius: 20),
              ],
            ),
            child:
                const Icon(Icons.arrow_back_rounded, color: Color(0xFFD4AF37)),
          ),
        ),
      ),
    );
  }

  Widget _buildParallaxHero(BuildContext context, Show showData) {
    final height =
        context.responsive(mobile: 500.0, tablet: 600.0, desktop: 700.0);
    final parallaxOffset = _scrollOffset * 0.5;

    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(
        position: _heroSlide,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned(
                top: -parallaxOffset,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: height + 200,
                  child: CachedNetworkImage(
                    imageUrl: showData.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ShimmerLoading(
                        width: double.infinity, height: double.infinity),
                  ),
                ),
              ),
              Container(
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
              ),
              Positioned(
                bottom: -100,
                left: 0,
                right: 0,
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFD4AF37).withOpacity(0.15),
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFFD4AF37),
                            Colors.transparent
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFF5E6A3)],
                      ).createShader(bounds),
                      child: Text(
                        showData.name.toUpperCase(),
                        style: TextStyle(
                          fontSize:
                              context.responsive(mobile: 36.0, desktop: 64.0),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8,
                          shadows: [
                            Shadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.5),
                                blurRadius: 40),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _floatingController,
                      builder: (_, __) => Container(
                        height: 4,
                        width: 120 +
                            math.sin(_floatingController.value * math.pi) * 20,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFD4AF37),
                              Color(0xFFF5E6A3),
                              Color(0xFFD4AF37)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.6),
                                blurRadius: 15),
                          ],
                        ),
                      ),
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

  Widget _buildDesktopLayout(BuildContext context, Show showData,
      EventState eventState, PlayerState playerState, StageState stageState) {
    final nowPlayers = playerState.getPlayersByIds(showData.nowPlayersId);
    final oldPlayers = playerState.getPlayersByIds(showData.oldPlayersId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildAnimatedPoster(showData.imageUrl),
              const SizedBox(height: 40),
              _buildGlassDescriptionCard(showData.description),
            ],
          ),
        ),
        const SizedBox(width: 60),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimatedSectionTitle(
                  'Etkinlik Takvimi', Icons.calendar_today_rounded),
              const SizedBox(height: 24),
              _buildEventSection(showData, eventState, stageState),
              const SizedBox(height: 50),
              _buildAnimatedSectionTitle('Ekip', Icons.people_rounded),
              const SizedBox(height: 24),
              _buildPlayerSection(
                  playerState, showData.nowPlayersId, nowPlayers, false),
              const SizedBox(height: 50),
              _buildAnimatedSectionTitle('Eski Ekip', Icons.history_rounded),
              const SizedBox(height: 24),
              _buildPlayerSection(
                  playerState, showData.oldPlayersId, oldPlayers, true),
              const SizedBox(height: 50),
              _buildAnimatedSectionTitle('Galeri', Icons.photo_library_rounded),
              const SizedBox(height: 24),
              _buildGallerySection(showData.photosShowId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, Show showData,
      EventState eventState, PlayerState playerState, StageState stageState) {
    final nowPlayers = playerState.getPlayersByIds(showData.nowPlayersId);
    final oldPlayers = playerState.getPlayersByIds(showData.oldPlayersId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGlassDescriptionCard(showData.description),
        const SizedBox(height: 40),
        _buildAnimatedSectionTitle(
            'Etkinlik Takvimi', Icons.calendar_today_rounded),
        const SizedBox(height: 20),
        _buildEventSection(showData, eventState, stageState),
        const SizedBox(height: 40),
        _buildAnimatedSectionTitle('Ekip', Icons.people_rounded),
        const SizedBox(height: 20),
        _buildPlayerSection(
            playerState, showData.nowPlayersId, nowPlayers, false),
        const SizedBox(height: 40),
        _buildAnimatedSectionTitle('Eski Ekip', Icons.history_rounded),
        const SizedBox(height: 20),
        _buildPlayerSection(
            playerState, showData.oldPlayersId, oldPlayers, true),
        const SizedBox(height: 40),
        _buildAnimatedSectionTitle('Galeri', Icons.photo_library_rounded),
        const SizedBox(height: 20),
        _buildGallerySection(showData.photosShowId),
      ],
    );
  }

  Widget _buildAnimatedPoster(String imageUrl) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (_, child) => Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(math.sin(_floatingController.value * math.pi) * 0.02),
        alignment: Alignment.center,
        child: child,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.4),
                blurRadius: 50,
                spreadRadius: 5),
            BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 20)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 9 / 13,
                child:
                    CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.5),
                        width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDescriptionCard(String description) {
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

  Widget _buildAnimatedSectionTitle(String title, IconData icon) {
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
        Text(title,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1)),
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

  Widget _buildEventSection(
      Show showData, EventState eventState, StageState stageState) {
    if (eventState.isLoading && !eventState.hasData) {
      return const SizedBox(
          height: 100,
          child: Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    }

    final events = eventState.dataList
            ?.where((e) => showData.eventsId.contains(e.id))
            .toList() ??
        [];

    if (events.isEmpty)
      return _buildEmptyState('Yaklaşan etkinlik bulunmamaktadır.');

    return Column(
      children: events.asMap().entries.map((entry) {
        final event = entry.value;
        final stage = stageState.getStageById(event.stageId);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + entry.key * 100),
          builder: (_, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)), child: child),
          ),
          child: _buildAnimatedEventCard(event.date.toString(), event.id,
              showData.id, stage?.name ?? "Sahne bilgisi yok"),
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedEventCard(
      String date, String eventId, String showId, String stageName) {
    final formatted = DateFormatter.formatForEventCard(date);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _navigateToSeatSelection(eventId, showId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  blurRadius: 20)
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 85,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFD4AF37), Color(0xFFF5E6A3)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  children: [
                    Text(formatted['day'] ?? '?',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0a0a1a))),
                    Text(formatted['monthName'] ?? '-',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0a0a1a))),
                  ],
                ),
              ),
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
    );
  }

  void _navigateToSeatSelection(String eventId, String showId) {
    String? userId = ref.read(loginProvider).user?.uid;
    userId ??= ref.read(userProvider).dataSingle?.id;
    userId ??= LocalStorageService.userUid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kullanıcı oturumu bulunamadı.")));
      return;
    }
    // Navigator.push(context, MaterialPageRoute(builder: (_) => SeatSelectionScreen(...)));
  }

  Widget _buildPlayerSection(PlayerState playerState, List<String> playerIds,
      List<Player> playerDataList, bool isOld) {
    if (playerIds.isEmpty) {
      return _buildEmptyState(
          isOld ? 'Eski ekip bilgisi yok.' : 'Ekip bilgisi yok.');
    }

    if (playerState.isLoading && playerDataList.isEmpty) {
      return const SizedBox(
          height: 220,
          child: Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    }

    if (playerDataList.isNotEmpty) {
      return _buildPlayerGrid(playerDataList, isOld);
    }

    if (!playerState.isLoading && playerDataList.isEmpty) {
      return _buildEmptyState('Ekip verileri yüklenemedi.');
    }

    return _buildEmptyState(
        isOld ? 'Eski ekip bilgisi yok.' : 'Ekip bilgisi yok.');
  }

  Widget _buildPlayerGrid(List<Player> players, bool isOld) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: players.asMap().entries.map((entry) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + entry.key * 80),
          builder: (_, value, child) => Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.8 + 0.2 * value, child: child),
          ),
          child: _buildAnimatedPlayerCard(entry.value, isOld),
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedPlayerCard(Player player, bool isOld) {
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
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: CachedNetworkImage(
                        imageUrl: player.imageUrl,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const ShimmerLoading(width: 150, height: 150),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF1a1a2e)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildGallerySection(List<String> photos) {
    if (photos.isEmpty) return _buildEmptyState('Galeri boş.');

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (_, i) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + i * 100),
          builder: (_, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
                offset: Offset(30 * (1 - value), 0), child: child),
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildAnimatedGalleryItem(photos[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedGalleryItem(String url) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showFullImage(context, url),
        child: Container(
          width: 220,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                    imageUrl: url, width: 220, height: 180, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0a0a1a).withOpacity(0.5)
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.zoom_in,
                      color: Color(0xFF0a0a1a), size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: const Color(0xFF0a0a1a).withOpacity(0.95),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF0a0a1a)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AnimatedBuilder helper widget
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
