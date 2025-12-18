import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/core/util/date_formatter.dart';
import 'package:ticketapp/features/events/domain/entities/event.dart';
import 'package:ticketapp/features/events/presentation/providers/event_provider.dart';
import 'package:ticketapp/features/events/presentation/providers/event_state.dart';
import 'package:ticketapp/features/events/presentation/widgets/events_card.dart';
import 'package:ticketapp/features/login/presentation/providers/login_provider.dart';
import 'package:ticketapp/features/players/presentation/pages/player_details.dart';
import 'package:ticketapp/features/players/presentation/providers/player_notifier.dart';
import 'package:ticketapp/features/players/presentation/providers/player_provider.dart';
import 'package:ticketapp/features/players/presentation/widgets/players_card.dart';
import 'package:ticketapp/features/seat/presentation/pages/seat_details.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_notifier.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_provider.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_notifier.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_provider.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_state.dart';
import 'package:ticketapp/features/users/presentation/providers/user_provider.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/show.dart';
import '../widgets/mobile/show_info_section.dart';
import '../widgets/mobile/show_parallax_header.dart';
import '../widgets/mobile/show_photo_gallery.dart';

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

    if (showData == null) await showNotifier.loadShowsByIds([widget.showId]);

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
      if (allPlayerIds.isNotEmpty)
        unawaited(
            ref.read(playerProvider.notifier).getPlayersByIds(allPlayerIds));
    }
  }

  @override
  Widget build(final BuildContext context) {
    final isDark = context.isDarkMode;

    // Arka plan rengi
    final backgroundColor =
        isDark ? AppDarkColors.primary : AppLightColors.background;

    // Metin rengi
    final textColor = isDark ? Colors.white : Colors.black;

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
        if (stageIds.isNotEmpty)
          ref.read(stageProvider.notifier).loadStagesByIds(stageIds);
      }
    });

    if (showState.isLoading && showData == null)
      return Scaffold(body: Center(child: CircularProgressIndicator()));

    if (showData == null)
      return Scaffold(
          body: Center(
              child: Text("Gösteri bulunamadı",
                  style: TextStyle(color: textColor))));

    return Scaffold(
      body: Stack(
        children: [
          // 1. MODÜLER PARALLAX HEADER
          ShowParallaxHeader(
              imageUrl: showData.imageUrl, scrollController: _scrollController),

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
                            description: showData.description),

                        // 4. ETKİNLİK LİSTESİ (Helper Method ile EventsCard kullanımı)
                        _buildEventList(
                          events: eventState.dataList
                                  ?.where((final e) =>
                                      showData.eventsId.contains(e.id))
                                  .toList() ??
                              [],
                          show: showData,
                          stageState: stageState,
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
                      color: (textColor).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: (isDark ? Colors.white24 : Colors.black12))),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: textColor, size: 20),
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

  Widget _buildEventList(
      {required final List<Event> events,
      required final Show show,
      required final StageState stageState}) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
            child: SectionHeader(title: "ETKİNLİK TAKVİMİ", fontSize: 20)),

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
    final String? userId = loginState.user?.uid ??
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
                showId: showId, eventId: eventId, customerId: userId)));
  }
}
