import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/features/events/presentation/providers/event_provider.dart';
import 'package:ticketapp/features/events/presentation/providers/event_state.dart';
import 'package:ticketapp/features/login/presentation/providers/login_provider.dart';
import 'package:ticketapp/features/players/presentation/pages/player_details.dart';
import 'package:ticketapp/features/players/presentation/providers/player_notifier.dart';
import 'package:ticketapp/features/players/presentation/providers/player_provider.dart';
import 'package:ticketapp/features/seat/presentation/pages/seat_details.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_notifier.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_provider.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_provider.dart';
import 'package:ticketapp/features/users/presentation/providers/user_provider.dart';
import '../widgets/mobile/show_cast_list.dart';
import '../widgets/mobile/show_event_list.dart';
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

  // Veri yükleme mantığı
  Future<void> _fetchInitialData() async {
    final showNotifier = ref.read(showProvider.notifier);
    var showData = ref.read(showProvider).getShowById(widget.showId);

    if (showData == null) {
      await showNotifier.loadShowsByIds([widget.showId]);
    }
    showData = ref.read(showProvider).getShowById(widget.showId);

    if (showData != null) {
      if (showData.eventsId.isNotEmpty) {
        final validEventIds = showData.eventsId
            .where((final id) => id.trim().isNotEmpty)
            .toList();
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
  }

  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showProvider);
    final showData = showState.getShowById(widget.showId);
    final eventState = ref.watch(eventProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);

    // Etkinlik sahne dinleyicisi
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
      return const Scaffold(
          backgroundColor: Color(0xFF0a0a1a),
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    }

    if (showData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0a0a1a),
        body: Center(
            child: Text("Gösteri bulunamadı",
                style: TextStyle(color: Colors.white70))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1a),
      body: Stack(
        children: [
          // 1. WIDGET: Parallax Arka Plan
          ShowParallaxHeader(
            imageUrl: showData.imageUrl,
            scrollController: _scrollController,
          ),

          // 2. Scroll İçerik
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Şeffaf alan (Resmi görmek için)
              SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45)),

              // Ana İçerik Gövdesi
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0a0a1a),
                        const Color(0xFF0a0a1a)
                      ],
                      stops: const [0.0, 0.1, 1.0],
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // 3. WIDGET: Başlık ve Açılır/Kapanır Açıklama
                      ShowInfoSection(
                        title: showData.name,
                        description: showData.description,
                      ),

                      // 4. WIDGET: Etkinlik Listesi
                      ShowEventList(
                        events: eventState.dataList
                                ?.where((final e) =>
                                    showData.eventsId.contains(e.id))
                                .toList() ??
                            [],
                        stageState: stageState,
                        onTicketTap: (final eventId) =>
                            _handleTicketPurchase(showData.id, eventId),
                      ),

                      // 5. WIDGET: Aktif Oyuncu Listesi
                      ShowCastList(
                        title: "OYUNCU KADROSU",
                        players:
                            playerState.getPlayersByIds(showData.nowPlayersId),
                        onPlayerTap: (final id) => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (final _) =>
                                    PlayerDetailPage(playerId: id))),
                      ),

                      // 6. WIDGET: Eski Oyuncu Listesi (Varsa)
                      if (showData.oldPlayersId.isNotEmpty)
                        ShowCastList(
                          title: "ESKİ KADRO",
                          isGrayscale: true,
                          players: playerState
                              .getPlayersByIds(showData.oldPlayersId),
                          onPlayerTap: (final id) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (final _) =>
                                      PlayerDetailPage(playerId: id))),
                        ),

                      if (showData.photosShowId.isNotEmpty)
                        ShowPhotoGallery(photos: showData.photosShowId),

                      const SizedBox(height: 100), // Alt boşluk
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 7. Geri Butonu (Buzlu Cam)
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
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white24)),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
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
