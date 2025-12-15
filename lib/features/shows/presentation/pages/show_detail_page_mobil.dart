import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/util/date_formatter.dart';
import 'package:ticketapp/features/events/domain/entities/event.dart';
import 'package:ticketapp/features/events/presentation/providers/event_provider.dart';
import 'package:ticketapp/features/events/presentation/providers/event_state.dart';
import 'package:ticketapp/features/events/presentation/widgets/events_card.dart'; // Senin tekil kartın
import 'package:ticketapp/features/login/presentation/providers/login_provider.dart';
import 'package:ticketapp/features/players/presentation/pages/player_details.dart';
import 'package:ticketapp/features/players/presentation/providers/player_notifier.dart';
import 'package:ticketapp/features/players/presentation/providers/player_provider.dart';
import 'package:ticketapp/features/players/presentation/widgets/players_card.dart'; // Senin oyuncu kartın
import 'package:ticketapp/features/seat/presentation/pages/seat_details.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_notifier.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_provider.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_notifier.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_provider.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_state.dart';
import 'package:ticketapp/features/users/presentation/providers/user_provider.dart';
import '../../domain/entities/show.dart';
import '../widgets/mobile/show_info_section.dart'; // Bilgi ve Açıklama
import '../widgets/mobile/show_parallax_header.dart'; // Arka plan
import '../widgets/mobile/show_photo_gallery.dart'; // Galeri

class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) _fetchInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    final showNotifier = ref.read(showProvider.notifier);
    var showData = ref.read(showProvider).getShowById(widget.showId);

    if (showData == null)
      await showNotifier.loadShowsByIds([widget.showId]);

    showData = ref.read(showProvider).getShowById(widget.showId);

    if (showData != null) {
      if (showData.eventsId.isNotEmpty) {
        final validEventIds = showData.eventsId
            .where((final id) => id.trim().isNotEmpty)
            .toList();
        if (validEventIds.isNotEmpty)
          unawaited(
              ref.read(eventProvider.notifier).loadEventsByIds(validEventIds));
      }
      final allPlayerIds = {...showData.nowPlayersId, ...showData.oldPlayersId}
          .where((final id) => id.trim().isNotEmpty)
          .toList();
      if (allPlayerIds.isNotEmpty) {
        unawaited(
            ref.read(playerProvider.notifier).getPlayersByIds(allPlayerIds));
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    // 🎨 TEMA AYARLARI
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Arka plan rengi
    final backgroundColor =
        isDark ? AppDarkColors.background : AppLightColors.background;

    // Metin rengi
    final textColor = isDark ? Colors.white : Colors.black;

    // Sabit marka rengi
    const brandColor = AppLightColors.primary;

    final showState = ref.watch(showProvider);
    final showData = showState.getShowById(widget.showId);
    final eventState = ref.watch(eventProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);

    // Sahne verilerini yükleme
    ref.listen<EventState>(eventProvider, (final previous, final next) {
      if ((previous?.dataList?.isEmpty ?? true) &&
          (next.dataList?.isNotEmpty ?? false)) {
        final stageIds = next.dataList!
            .map((final e) => e.stageId)
            .where((final id) => id.isNotEmpty && id != '0')
            .toSet()
            .toList();
        if (stageIds.isNotEmpty) {
          ref.read(stageProvider.notifier).loadStagesByIds(stageIds);
        }
      }
    });

    if (showState.isLoading && showData == null) {
      return Scaffold(
          backgroundColor: backgroundColor,
          body: Center(child: CircularProgressIndicator(color: brandColor)));
    }

    if (showData == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
            child:
                Text("Gösteri bulunamadı", style: TextStyle(color: textColor))),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. MODÜLER PARALLAX HEADER
          ShowParallaxHeader(
            imageUrl: showData.imageUrl,
            scrollController: _scrollController,
            backgroundColor: backgroundColor,
          ),

          // 2. İÇERİK
          RepaintBoundary(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                    child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45)),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          backgroundColor,
                          backgroundColor
                        ],
                        stops: const [0.0, 0.1, 1.0],
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // 3. MODÜLER INFO SECTION
                        ShowInfoSection(
                          title: showData.name,
                          description: showData.description,
                          primaryColor: brandColor,
                          textColor: textColor,
                          isDark: isDark,
                        ),

                        // 4. ETKİNLİK LİSTESİ (Helper Method ile EventsCard kullanımı)
                        _buildEventList(
                          events: eventState.dataList
                                  ?.where((final e) =>
                                      showData.eventsId.contains(e.id))
                                  .toList() ??
                              [],
                          show: showData,
                          stageState: stageState,
                          primaryColor: brandColor,
                          textColor: textColor,
                        ),

                        // 5. MODÜLER PLAYER CARD (Aktif Kadro)
                        PlayersCard(
                          title: "OYUNCU KADROSU",
                          players: playerState
                              .getPlayersByIds(showData.nowPlayersId),
                          onPlayerTap: (final id) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (final _) =>
                                      PlayerDetailPage(playerId: id))),
                        ),

                        // 6. MODÜLER PLAYER CARD (Eski Kadro)
                        if (showData.oldPlayersId.isNotEmpty)
                          PlayersCard(
                            title: "ESKİ KADRO",
                            players: playerState
                                .getPlayersByIds(showData.oldPlayersId),
                            isGrayscale: true,
                            // Gri Çerçeve
                            onPlayerTap: (final id) => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (final _) =>
                                        PlayerDetailPage(playerId: id))),
                          ),

                        // 7. MODÜLER GALERİ
                        if (showData.photosShowId.isNotEmpty)
                          ShowPhotoGallery(photos: showData.photosShowId),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // GERİ BUTONU
          Positioned(
            top: 50,
            left: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: (isDark ? Colors.white24 : Colors.black12))),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: isDark ? Colors.white : Colors.black, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ KISA YOL: EventsCard'ı Listeleyen Helper
  Widget _buildEventList(
      {required final List<Event> events,
      required final Show show,
      required final StageState stageState,
      required final Color primaryColor,
      required final Color textColor}) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
          child: Row(
            children: [
              Container(width: 4, height: 24, color: primaryColor),
              const SizedBox(width: 10),
              Text("ETKİNLİK TAKVİMİ",
                  style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
        ),

        // Liste
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: events.length,
            itemBuilder: (final context, final index) {
              final event = events[index];
              final stage = stageState.getStageById(event.stageId);
              final dateInfo =
                  DateFormatter.formatForEventCard(event.date.toString());

              // 🔥 SENİN EventsCard WIDGET'IN BURADA KULLANILIYOR
              return EventsCard(
                imageUrl: show.imageUrl,
                showName: show.name,
                category: "TİYATRO",
                date:
                    "${dateInfo['day']} ${dateInfo['monthName']} • ${dateInfo['time']}",
                stage: stage?.name ?? "Sahne Yok",
                price: double.tryParse(event.price.toString()) ?? 0.0,
                onTap: () => _handleTicketPurchase(show.id, event.id),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleTicketPurchase(final String showId, final String eventId) {
    final loginState = ref.read(loginProvider);
    String? userId = loginState.user?.uid ??
        ref.read(userProvider).dataSingle?.id ??
        LocalStorageService.userUid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen önce giriş yapınız.")));
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (final context) => SeatSelectionScreen(
                showId: showId, eventId: eventId, customerId: userId!)));
  }
}
