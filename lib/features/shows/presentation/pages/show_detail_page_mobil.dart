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
import 'package:ticketapp/features/players/presentation/widgets/players_bubble_card.dart';
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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final showNotifier = ref.read(showProvider.notifier);

    var showData = ref.read(showProvider).getShowById(widget.showId);

    if (showData == null) {
      await showNotifier.loadShowsByIds([widget.showId]);
      showData = ref.read(showProvider).getShowById(widget.showId);
    }

    if (showData == null) return;

    /// EVENTS
    final eventIds =
        showData.eventsId.where((id) => id.trim().isNotEmpty).toList();

    if (eventIds.isNotEmpty) {
      await ref.read(eventProvider.notifier).loadEventsByIds(eventIds);
    }

    /// 🔥 STAGES (EKSİK OLAN BUYDU)
    final events = ref.read(eventProvider).dataList ?? [];

    final stageIds = events
        .map((e) => e.stageId)
        .where((id) => id.isNotEmpty && id != '0')
        .toSet()
        .toList();

    if (stageIds.isNotEmpty) {
      unawaited(
        ref.read(stageProvider.notifier).loadStagesByIds(stageIds),
      );
    }

    /// PLAYERS
    final playerIds = {
      ...showData.nowPlayersId,
      ...showData.oldPlayersId,
    }.where((id) => id.trim().isNotEmpty).toList();

    if (playerIds.isNotEmpty) {
      unawaited(
        ref.read(playerProvider.notifier).getPlayersByIds(playerIds),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final isDark = context.isDarkMode;
    final backgroundColor =
        isDark ? AppDarkColors.primary : AppLightColors.background;
    final textColor = isDark ? Colors.white : Colors.black;

    final showState = ref.watch(showProvider);
    final showData = showState.getShowById(widget.showId);
    final eventState = ref.watch(eventProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);

    if (showState.isLoading && showData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (showData == null) {
      return Center(
        child: Text(
          "Gösteri bulunamadı",
          style: TextStyle(color: textColor),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          /// HEADER
          ShowParallaxHeader(
            imageUrl: showData.imageUrl,
            scrollController: _scrollController,
          ),

          /// CONTENT
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      ShowInfoSection(
                        title: showData.name,
                        description: showData.description,
                      ),
                      _buildEventList(
                        events: eventState.dataList
                                ?.where((final e) =>
                                    showData.eventsId.contains(e.id))
                                .toList() ??
                            [],
                        show: showData,
                        stageState: stageState,
                      ),
                      PlayersBubbleCard(
                        title: "OYUNCU KADROSU",
                        players:
                            playerState.getPlayersByIds(showData.nowPlayersId),
                        onPlayerTap: (final id) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (final _) =>
                                PlayerDetailPage(playerId: id),
                          ),
                        ),
                      ),
                      if (showData.oldPlayersId.isNotEmpty)
                        PlayersBubbleCard(
                          title: "ESKİ KADRO",
                          players: playerState
                              .getPlayersByIds(showData.oldPlayersId),
                          isGrayscale: true,
                          onPlayerTap: (final id) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (final _) =>
                                  PlayerDetailPage(playerId: id),
                            ),
                          ),
                        ),
                      if (showData.photosShowId.isNotEmpty)
                        ShowPhotoGallery(
                          photos: showData.photosShowId,
                        ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          /// BACK BUTTON
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: textColor,
                    ),
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
