import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/features/splash/presentation/widgets/splash_data_guard.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/widgets/button/back_button_glassmorphism.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../../shared/widgets/global_error_widget.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../events/domain/entities/event.dart';
import '../../../players/domain/entities/player.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../domain/entities/show.dart';
import '../providers/show_detail_provider.dart';
import '../widgets/show_team_credit.dart';
import '../widgets/web/player_section.dart';
import '../widgets/web/show_detail_hero.dart';

class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage>
    with TickerProviderStateMixin, GlobalScrollMixin {
  late final AnimationController _heroController;
  late final AnimationController _contentController;
  late final AnimationController _floatingController;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _contentFade;

  final ValueNotifier<double> _scrollNotifier = ValueNotifier(0.0);
  final GlobalKey _eventsSectionKey = GlobalKey();
  bool _scrollToEventsHandled = false;

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

  /// Sezon takviminden ("?scrollTo=etkinlikler" ile) gelindiyse, sayfa
  /// hazır olur olmaz Etkinlik Takvimi bölümüne kaydırır. Görseller henüz
  /// yüklenirken layout biraz kayabileceği için kısa bir gecikmeyle tekrar
  /// dener.
  void _maybeScrollToEvents() {
    if (_scrollToEventsHandled || !mounted) return;
    final scrollTo = GoRouterState.of(context).uri.queryParameters['scrollTo'];
    if (scrollTo != 'etkinlikler') return;
    _scrollToEventsHandled = true;

    void attemptScroll() {
      final eventsContext = _eventsSectionKey.currentContext;
      if (eventsContext == null || !mounted) return;
      Scrollable.ensureVisible(
        eventsContext,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }

    attemptScroll();
    Future.delayed(const Duration(milliseconds: 500), attemptScroll);
  }

  void _initScrollListener() => scrollController.addListener(() {
        if (mounted) _scrollNotifier.value = scrollController.offset;
      });

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    _floatingController.dispose();
    scrollController.dispose();
    _scrollNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(showDetailProvider(widget.showId));

    if (detailAsync.hasError)
      return GlobalErrorWidget(
          message: detailAsync.error.toString(),
          onRetry: () => ref.invalidate(showDetailProvider(widget.showId)));

    // `BasePageWrapper` KASITLI OLARAK KULLANILMIYOR — bu dosya zaten yalnızca
    // web derlemesinde kullanılıyor (bkz. show_detail_page.dart'ın koşullu
    // export'u), yani "mobil mi web mi" ayrımına hiç gerek yok; her render
    // burada zaten masaüstü. BasePageWrapper'ı sarmak sadece mobil uygulama
    // çatısını (geri tuşu + gradyanlı başlık çubuğu, "yukarı kaydır" FAB'ı,
    // CustomAppBackground'ın context.primaryColor renkli — yani marka dışı —
    // FloatingParticles noktaları) gereksiz yere üstüne bindiriyordu; bu
    // sayfanın zaten kendi markaya uygun, animasyonlu `_BackgroundParticles`'ı
    // var, ikisi üst üste anlamsız bir tekrar oluşturuyordu. Üst navigasyon
    // zaten `WebTopNavigationBar`'dan geliyor.
    return SplashDataGuard(
      isLoading: detailAsync.isLoading,
      loadingMessage: 'Sanat dolu detaylar hazırlanıyor...',
      child: ColoredBox(
        color: WebColors.darkBlueBackground,
        child: detailAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (final err, final stack) => const SizedBox.shrink(),
          data: (final state) {
            WidgetsBinding.instance.addPostFrameCallback((final _) {
              _startPageAnimations();
              _maybeScrollToEvents();
            });
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
  ) =>
      Stack(
        children: [
          _BackgroundParticles(animation: _floatingController),
          CustomScrollView(
            controller: scrollController,
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
                    eventsSectionKey: _eventsSectionKey,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Footer()),
            ],
          ),
          // Sabit Butonlar
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: 'Paylaş',
                padding: EdgeInsets.zero,
                icon: Icon(Icons.share_outlined,
                    size: 22, color: context.colors.onSurface),
                onPressed: () => TiyatrolDeeplinkService.shareShow(
                    id: showData.id, name: showData.name),
              ),
            ),
          )
        ],
      );
}

class _MainContent extends StatelessWidget {
  final Show showData;
  final List<Event> events;
  final List<Player> players;
  final List<Stage> stages;
  final GlobalKey eventsSectionKey;

  const _MainContent(
      {required this.showData,
      required this.events,
      required this.players,
      required this.stages,
      required this.eventsSectionKey});

  @override
  Widget build(final BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      // landing/style.css bölümlerinde olduğu gibi geniş masaüstü
      // ekranlarında içerik ~1360px'te sınırlanır, aksi halde satır
      // uzunluğu ve poster/açıklama oranı ultra geniş monitörlerde bozulur.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: context.isDesktop
              ? _DesktopLayout(
                  showData: showData,
                  events: events,
                  players: players,
                  stages: stages,
                  eventsSectionKey: eventsSectionKey)
              : _MobileLayout(
                  showData: showData,
                  events: events,
                  players: players,
                  stages: stages,
                  eventsSectionKey: eventsSectionKey),
        ),
      ));
}

class _DesktopLayout extends StatelessWidget {
  final Show showData;
  final List<Event> events;
  final List<Player> players;
  final List<Stage> stages;
  final GlobalKey eventsSectionKey;

  const _DesktopLayout(
      {required this.showData,
      required this.events,
      required this.players,
      required this.stages,
      required this.eventsSectionKey});

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
              const SizedBox(height: 28),
              _ShowMetaChips(showData: showData),
              const SizedBox(height: 28),
              _GlassDescriptionCard(description: showData.description),
              const SizedBox(height: 24),
              ShowTeamCredit(teamId: showData.teamId),
            ],
          ),
        ),
        const SizedBox(width: 60),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyedSubtree(
                key: eventsSectionKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                        title: 'Etkinlik Takvimi',
                        icon: Icons.calendar_today_rounded),
                    _EventRuleNote(eventRule: showData.eventRule),
                    const SizedBox(height: 24),
                    _EventDateList(events: events, stages: stages),
                  ],
                ),
              ),
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
  final GlobalKey eventsSectionKey;

  const _MobileLayout(
      {required this.showData,
      required this.events,
      required this.players,
      required this.stages,
      required this.eventsSectionKey});

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
        _ShowMetaChips(showData: showData),
        const SizedBox(height: 24),
        _GlassDescriptionCard(description: showData.description),
        const SizedBox(height: 20),
        ShowTeamCredit(teamId: showData.teamId),
        const SizedBox(height: 40),
        KeyedSubtree(
          key: eventsSectionKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                  title: 'Etkinlik Takvimi',
                  icon: Icons.calendar_today_rounded),
              _EventRuleNote(eventRule: showData.eventRule),
              const SizedBox(height: 20),
              _EventDateList(events: events, stages: stages),
            ],
          ),
        ),
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
  final List<Stage> stages;

  const _EventDateList({required this.events, required this.stages});

  @override
  Widget build(final BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Column(
      children: events.map((final e) {
        Stage? stage;
        for (final s in stages) {
          if (s.id == e.stageId) {
            stage = s;
            break;
          }
        }
        return _EventItemTile(rawDateString: e.date.toString(), stage: stage, price: e.price);
      }).toList(),
    );
  }
}

class _EventItemTile extends StatelessWidget {
  final String rawDateString; // Örn: "15.09.2024,19:00"
  final Stage? stage; // Gerçek sahne verisi varsa mekan adını gösterir
  final String price; // Ham fiyat verisi (Event.price)

  const _EventItemTile(
      {required this.rawDateString, this.stage, this.price = ''});

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

    final priceValue = double.tryParse(price);
    final priceLabel =
        priceValue != null && priceValue > 0 ? '₺${priceValue.toStringAsFixed(0)}' : null;
    final venueName = (stage?.name ?? '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(22),
          bottomRight: Radius.circular(6),
          bottomLeft: Radius.circular(22),
        ),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: WebColors.primaryGold.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(4),
                bottomLeft: Radius.circular(14),
              ),
            ),
            child: Column(
              children: [
                Text(gun,
                    style: const TextStyle(
                        color: WebColors.primaryGold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(ay,
                    style: const TextStyle(
                        color: WebColors.primaryGold, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rawDateString.split(',')[0],
                    style: TextStyle(
                        color: WebColors.whiteText,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        color: WebColors.whiteText.withOpacity(0.6), size: 14),
                    const SizedBox(width: 4),
                    Text(saat,
                        style: TextStyle(
                            color: WebColors.whiteText.withOpacity(0.6),
                            fontSize: 14)),
                    if (venueName.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.place_outlined,
                          color: WebColors.whiteText.withOpacity(0.6),
                          size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(venueName,
                            style: TextStyle(
                                color: WebColors.whiteText.withOpacity(0.6),
                                fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (priceLabel != null) ...[
                Text(priceLabel,
                    style: const TextStyle(
                        color: WebColors.primaryGoldLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
              ],
              const Icon(Icons.arrow_forward_ios,
                  color: WebColors.primaryGold, size: 14),
            ],
          ),
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

  // Landing sitesindeki köşegen "büyük/küçük" köşe dili (bkz. style.css
  // .show { border-radius:4px 28px 4px 28px }) — üst-sol & alt-sağ küçük,
  // üst-sağ & alt-sol büyük.
  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(8),
    topRight: Radius.circular(34),
    bottomRight: Radius.circular(8),
    bottomLeft: Radius.circular(34),
  );

  @override
  Widget build(final BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: [
            BoxShadow(
                color: WebColors.primaryGold.withOpacity(0.4),
                blurRadius: 50,
                spreadRadius: 5)
          ],
        ),
        child: ClipRRect(
          borderRadius: _radius,
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
          color: WebColors.darkBlueSurface.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(6),
            bottomLeft: Radius.circular(28),
          ),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: WebColors.primaryGold.withOpacity(0.1), blurRadius: 30)
          ],
        ),
        child: Text(
          description.replaceAll('\\n', '\n'),
          style: TextStyle(
              color: WebColors.whiteText.withOpacity(0.7),
              fontSize: 16,
              height: 1.9,
              letterSpacing: 0.3),
        ),
      );
}

/// Show.duration / category / type / ageLimit alanlarından — hepsi gerçek
/// Firestore verisi, önceden bu sayfada hiç gösterilmiyordu. Boş gelen
/// alanlar sessizce gizlenir, hiçbir metin uydurulmaz.
class _ShowMetaChips extends StatelessWidget {
  final Show showData;

  const _ShowMetaChips({required this.showData});

  @override
  Widget build(final BuildContext context) {
    final items = <(IconData, String)>[
      if (showData.duration.trim().isNotEmpty)
        (Icons.schedule_rounded, showData.duration.trim()),
      if (showData.category.trim().isNotEmpty)
        (Icons.theater_comedy_rounded, showData.category.trim()),
      if (showData.type.trim().isNotEmpty)
        (Icons.style_rounded, showData.type.trim()),
      if (showData.ageLimit.trim().isNotEmpty)
        (Icons.shield_outlined, showData.ageLimit.trim()),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((final item) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: WebColors.darkBlueSurface.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                    bottomLeft: Radius.circular(16),
                  ),
                  border:
                      Border.all(color: WebColors.primaryGold.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.$1, size: 15, color: WebColors.primaryGoldLight),
                    const SizedBox(width: 6),
                    Text(item.$2,
                        style: TextStyle(
                            color: WebColors.whiteText.withOpacity(0.85),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

/// Show.eventRule dolu geldiğinde (ör. bilet/iade kuralı) takvim
/// başlığının hemen altında küçük bir not olarak gösterilir; boşsa hiç yer
/// kaplamaz.
class _EventRuleNote extends StatelessWidget {
  final String eventRule;

  const _EventRuleNote({required this.eventRule});

  @override
  Widget build(final BuildContext context) {
    final text = eventRule.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 14, color: WebColors.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: WebColors.textTertiary,
                    fontSize: 12.5,
                    height: 1.5,
                    fontStyle: FontStyle.italic)),
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
  Widget build(final BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: WebColors.goldButtonGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(4),
                bottomLeft: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                    color: WebColors.primaryGold.withOpacity(0.4),
                    blurRadius: 15)
              ],
            ),
            child: Icon(icon,
                color: WebColors.darkBlueBackground, size: 22),
          ),
          const SizedBox(width: 16),
          Text(title,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: WebColors.whiteText,
                  letterSpacing: 1)),
          const SizedBox(width: 16),
          Expanded(
              child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                    WebColors.primaryGold.withOpacity(0.5),
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
                        shape: BoxShape.circle,
                        color: WebColors.primaryGold)));
          },
        );
      }),
    );
  }
}
