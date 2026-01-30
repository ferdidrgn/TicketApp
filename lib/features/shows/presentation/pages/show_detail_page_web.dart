import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/splash/presentation/widgets/splash_data_guard.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../shared/widgets/button/back_button_glassmorphism.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../../shared/widgets/global_error_widget.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../events/domain/entities/event.dart';
import '../../../players/domain/entities/player.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../domain/entities/show.dart';
import '../providers/show_detail_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initScrollListener();
  }

  void _initControllers() {
    _heroController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _contentController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _floatingController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));

    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _heroController, curve: Curves.easeOutCubic));
    _contentFade =
        CurvedAnimation(parent: _contentController, curve: Curves.easeOut);
  }

  void _startPageAnimations() {
    if (!mounted) return;
    _heroController.forward();
    _floatingController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _contentController.forward();
    });
  }

  void _initScrollListener() => _scrollController.addListener(() {
        if (mounted) _scrollNotifier.value = _scrollController.offset;
      });

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
    final detailAsync = ref.watch(showDetailProvider(widget.showId));

    if (detailAsync.hasError)
      return GlobalErrorWidget(
        message: detailAsync.error.toString(),
        onRetry: () => ref.invalidate(showDetailProvider(widget.showId)),
      );

    return SplashDataGuard(
      isLoading: detailAsync.isLoading,
      loadingMessage: 'Sanat dolu detaylar hazırlanıyor...',
      child: Scaffold(
        backgroundColor: const Color(0xFF0a0a1a),
        body: detailAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (final err, final stack) => const SizedBox.shrink(),
          data: (final state) {
            WidgetsBinding.instance
                .addPostFrameCallback((final _) => _startPageAnimations());
            return _buildSuccessState(
                state.show, state.events, state.players, state.stages);
          },
        ),
      ),
    );
  }

  Widget _buildSuccessState(
    final Show showData,
    final List<Event> eventList,
    final List<Player> playerList,
    final List<Stage> stageList,
  ) {
    return Stack(
      children: [
        _BackgroundParticles(animation: _floatingController),
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
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
                  events: eventList,
                  players: playerList,
                  stages: stageList,
                ),
              ),
            ),
          ],
        ),
        // Sabit Butonlar
        Positioned(top: 40, left: 20, child: const GlassmorphismBackButton()),
        Positioned(
          top: 40,
          right: 20,
          child: ValueListenableBuilder<double>(
            valueListenable: _scrollNotifier,
            builder: (final context, final offset, final _) {
              final isScrolled = offset > 100;
              return IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.share_outlined,
                    size: 22,
                    color:
                        isScrolled ? context.colors.onSurface : Colors.white),
                onPressed: () => TiyatrolDeeplinkService.shareShow(
                    id: showData.id, name: showData.name),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MainContent extends StatelessWidget {
  final Show showData;
  final List<Event> events;
  final List<Player> players;
  final List<Stage> stages;

  const _MainContent(
      {required this.showData,
      required this.events,
      required this.players,
      required this.stages});

  @override
  Widget build(final BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: context.isDesktop
          ? _DesktopLayout(
              showData: showData,
              events: events,
              players: players,
              stages: stages)
          : _MobileLayout(
              showData: showData,
              events: events,
              players: players,
              stages: stages));
}

class _DesktopLayout extends StatelessWidget {
  final Show showData;
  final List<Event> events;
  final List<Player> players;
  final List<Stage> stages;

  const _DesktopLayout(
      {required this.showData,
      required this.events,
      required this.players,
      required this.stages});

  @override
  Widget build(final BuildContext context) {
    final nowPlayers = players
        .where((final p) => showData.nowPlayersId.contains(p.id))
        .toList();
    final oldPlayers = players
        .where((final p) => showData.oldPlayersId.contains(p.id))
        .toList();

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
              _EventDateList(events: events), // Hata burada çözüldü
              const SizedBox(height: 50),
              const _SectionTitle(title: 'Ekip', icon: Icons.people_rounded),
              const SizedBox(height: 24),
              PlayerSection(players: nowPlayers, isOld: false),
              const SizedBox(height: 50),
              const _SectionTitle(
                  title: 'Eski Ekip', icon: Icons.history_rounded),
              const SizedBox(height: 24),
              PlayerSection(players: oldPlayers, isOld: true),
              const SizedBox(height: 50),
              const _SectionTitle(
                  title: 'Galeri', icon: Icons.photo_library_rounded),
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
  final List<Event> events;
  final List<Player> players;
  final List<Stage> stages;

  const _MobileLayout(
      {required this.showData,
      required this.events,
      required this.players,
      required this.stages});

  @override
  Widget build(final BuildContext context) {
    final nowPlayers = players
        .where((final p) => showData.nowPlayersId.contains(p.id))
        .toList();
    final oldPlayers = players
        .where((final p) => showData.oldPlayersId.contains(p.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GlassDescriptionCard(description: showData.description),
        const SizedBox(height: 40),
        const _SectionTitle(
            title: 'Etkinlik Takvimi', icon: Icons.calendar_today_rounded),
        const SizedBox(height: 20),
        _EventDateList(events: events),
        const SizedBox(height: 40),
        const _SectionTitle(title: 'Ekip', icon: Icons.people_rounded),
        const SizedBox(height: 20),
        PlayerSection(players: nowPlayers, isOld: false),
        const SizedBox(height: 40),
        const _SectionTitle(title: 'Eski Ekip', icon: Icons.history_rounded),
        const SizedBox(height: 20),
        PlayerSection(players: oldPlayers, isOld: true),
        const SizedBox(height: 40),
        const _SectionTitle(title: 'Galeri', icon: Icons.photo_library_rounded),
        const SizedBox(height: 20),
        GallerySection(photos: showData.photosShowId),
      ],
    );
  }
}

// --- TASARIM VE HATA ÇÖZÜMÜ BÖLÜMÜ ---

class _EventDateList extends StatelessWidget {
  final List<Event> events;

  const _EventDateList({required this.events});

  @override
  Widget build(final BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Column(
      children: events
          .map((final e) => _EventItemTile(rawDateString: e.date.toString()))
          .toList(),
    );
  }
}

class _EventItemTile extends StatelessWidget {
  final String rawDateString; // Örn: "15.09.2024,19:00"
  const _EventItemTile({required this.rawDateString});

  @override
  Widget build(final BuildContext context) {
    // ÖZEL PARSER: Görüntüdeki "15.09.2024,19:00" formatını parçalar
    String gun = "00", ay = "Oca", saat = "00:00";
    try {
      final parts = rawDateString.split(',');
      final dateParts = parts[0].split('.');
      gun = dateParts[0];
      ay = _getAyIsmi(int.parse(dateParts[1]));
      if (parts.length > 1) saat = parts[1];
    } catch (e) {
      debugPrint("Tarih ayrıştırma hatası: $e");
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(gun,
                    style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(ay,
                    style: const TextStyle(
                        color: Color(0xFFD4AF37), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rawDateString.split(',')[0],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.white60, size: 14),
                    const SizedBox(width: 4),
                    Text(saat,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: Color(0xFFD4AF37), size: 14),
        ],
      ),
    );
  }

  String _getAyIsmi(final int ay) {
    const aylar = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    return aylar[ay - 1];
  }
}

// --- ESKİ ŞIK TASARIM BİLEŞENLERİ ---

class _AnimatedPoster extends StatelessWidget {
  final String imageUrl;

  const _AnimatedPoster({required this.imageUrl});

  @override
  Widget build(final BuildContext context) => Container(
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
              child:
                  OptimizedCachedImage(imageUrl: imageUrl, fit: BoxFit.cover)),
        ),
      );
}

class _GlassDescriptionCard extends StatelessWidget {
  final String description;

  const _GlassDescriptionCard({required this.description});

  @override
  Widget build(final BuildContext context) => Container(
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(final BuildContext context) => Row(
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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1)),
          const SizedBox(width: 16),
          Expanded(
              child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                    const Color(0xFFD4AF37).withOpacity(0.5),
                    Colors.transparent
                  ])))),
        ],
      );
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
          builder: (final context, final _) {
            final y = baseY + math.sin(animation.value * math.pi * 2 + i) * 30;
            return Positioned(
                left: x,
                top: y,
                child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFFD4AF37))));
          },
        );
      }),
    );
  }
}
