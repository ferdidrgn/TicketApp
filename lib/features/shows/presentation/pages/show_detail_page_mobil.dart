import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/features/events/presentation/providers/event_provider.dart';
import 'package:ticketapp/features/players/presentation/providers/player_provider.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_provider.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_provider.dart';
import 'package:ticketapp/features/users/presentation/providers/user_provider.dart';
import 'package:ticketapp/shared/widgets/galerry_section.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/widgets/card/glass_back_bottom.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../events/presentation/widgets/events_card.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../players/presentation/pages/player_details.dart';
import '../../../players/presentation/providers/player_notifier.dart';
import '../../../players/presentation/widgets/players_bubble_card.dart';
import '../../../seat/presentation/pages/seat_details.dart';
import '../../../stages/presentation/providers/stage_notifier.dart';
import '../../domain/entities/show.dart';
import '../providers/show_notifier.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında veri çekme işlemini başlat
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _loadAllDataSequentially();
    });
  }

  /// Verileri sırasıyla ve birbirini bekleyerek yükleyen fonksiyon
  Future<void> _loadAllDataSequentially() async {
    try {
      final showId = widget.showId;

      final showNotifier = ref.read(showProvider.notifier);
      final eventNotifier = ref.read(eventProvider.notifier);
      final stageNotifier = ref.read(stageProvider.notifier);
      final playerNotifier = ref.read(playerProvider.notifier);

      var showData = ref.read(showProvider).getShowById(showId);
      if (showData == null) {
        await showNotifier.loadShowsByIds([showId]);
        // Yükleme bittikten sonra tekrar provider'dan oku
        showData = ref.read(showProvider).getShowById(showId);
      }

      // Eğer hala null ise yapacak bir şey yok, çık.
      if (showData == null) {
        debugPrint("❌ Show verisi bulunamadı.");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // ADIM 2: EVENTLERİ (ETKİNLİKLERİ) GETİR
      // Listeyi temizle ve boşlukları at
      final eventIds = showData.eventsId
          .where((final id) => id.toString().trim().isNotEmpty)
          .toList();

      if (eventIds.isNotEmpty) {
        await eventNotifier.loadEventsByIds(eventIds);

        // ADIM 3: SAHNELERİ (STAGES) GETİR
        // Provider'daki güncel event listesinden StageID'leri topla
        final allEvents = ref.read(eventProvider).dataList ?? [];
        final relevantEvents =
            allEvents.where((final e) => eventIds.contains(e.id)).toList();

        final stageIds = relevantEvents
            .map((final e) => e.stageId)
            .where((final id) => id.isNotEmpty && id != '0')
            .toSet() // Tekrarlayanları sil
            .toList();

        if (stageIds.isNotEmpty) await stageNotifier.loadStagesByIds(stageIds);
      }

      // ADIM 4: OYUNCULARI (PLAYERS) GETİR
      final allPlayerIds = {
        ...showData.nowPlayersId,
        ...showData.oldPlayersId,
      }.where((final id) => id.toString().trim().isNotEmpty).toList();

      if (allPlayerIds.isNotEmpty)
        await playerNotifier.getPlayersByIds(allPlayerIds);
    } catch (e) {
      throw ("❌ HATA OLUŞTU (_loadAllDataSequentially): $e");
    } finally {
      // Her durumda loading'i kapat
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final showData = ref.watch(showProvider).getShowById(widget.showId);

    final backgroundColor =
        context.isDarkMode ? AppDarkColors.primary : AppLightColors.background;

    // Yükleniyor durumu
    if (_isLoading && showData == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Veri yok durumu
    if (showData == null)
      return Scaffold(
        appBar: AppBar(
            leading: const BackButton(), backgroundColor: Colors.transparent),
        body: const Center(child: Text("Gösteri bilgileri alınamadı.")),
      );

    return Scaffold(
      body: Stack(
        children: [
          // 1. ARKA PLAN RESMİ (PARALLAX HEADER)
          ShowParallaxHeader(
              imageUrl: showData.imageUrl, scrollController: _scrollController),

          // 2. KAYDIRILABİLİR İÇERİK
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Resminin arkasında kalacak boşluk
              SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45)),

              // Ana İçerik Bloğu (Beyaz/Siyah Kısım)
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Başlık ve Açıklama
                      ShowInfoSection(
                          title: showData.name,
                          description: showData.description),

                      // --- ETKİNLİK LİSTESİ ---
                      ShowEventSection(
                        showData: showData,
                        onBuyTicket: _handleTicketPurchase,
                      ),

                      // --- GÜNCEL OYUNCULAR ---
                      ShowCastSection(
                        title: "OYUNCU KADROSU",
                        playerIds: showData.nowPlayersId,
                      ),

                      // --- ESKİ OYUNCULAR ---
                      if (showData.oldPlayersId.isNotEmpty)
                        ShowCastSection(
                          title: "ESKİ KADRO",
                          playerIds: showData.oldPlayersId,
                          isGrayscale: true,
                        ),

                      // --- GALERİ ---

                      SectionHeader(title: "OYUNDAN KARELER", fontSize: 20),
                      if (showData.photosShowId.isNotEmpty)
                        GallerySection(photos: showData.photosShowId),

                      // Alt boşluk (Bottom padding)
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. GERİ BUTONU (SOL ÜST)
          const Positioned(
            top: 50, // SafeArea
            left: 16,
            child: GlassBackButton(),
          ),
        ],
      ),
    );
  }

  void _handleTicketPurchase(final String eventId) {
    final loginState = ref.read(loginProvider);
    final userId = loginState.user?.uid ??
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
          showId: widget.showId,
          eventId: eventId,
          customerId: userId,
        ),
      ),
    );
  }
}

// YARDIMCI WIDGETLAR (Hepsi tek dosyada)
// ==============================================================================

/// Etkinlik Kartlarını Listeleyen Widget
class ShowEventSection extends ConsumerWidget {
  final Show showData;
  final Function(String eventId) onBuyTicket;

  const ShowEventSection({
    super.key,
    required this.showData,
    required this.onBuyTicket,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Sadece gerekli state'leri dinle
    final eventState = ref.watch(eventProvider);
    final stageState = ref.watch(stageProvider);

    // Bu gösteriye ait eventleri filtrele
    final events = eventState.dataList
            ?.where((final e) => showData.eventsId.contains(e.id))
            .toList() ??
        [];

    if (events.isEmpty) {
      // Veri yükleniyor veya yoksa boş dön
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: "ETKİNLİK TAKVİMİ", fontSize: 20),
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
                imageUrl: showData.imageUrl,
                showName: showData.name,
                category: "TİYATRO",
                date:
                    "${dateInfo['day']} ${dateInfo['monthName']} • ${dateInfo['time']}",
                stage: stage?.name ?? "Sahne Bilgisi Yükleniyor...",
                price: double.tryParse(event.price.toString()) ?? 0.0,
                onTap: () => onBuyTicket(event.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Oyuncuları Listeleyen Widget
class ShowCastSection extends ConsumerWidget {
  final String title;
  final List<String> playerIds;
  final bool isGrayscale;

  const ShowCastSection({
    super.key,
    required this.title,
    required this.playerIds,
    this.isGrayscale = false,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final playerState = ref.watch(playerProvider);

    // Gelen ID listesine göre oyuncuları state'den çek
    // Boş string ID'leri filtrele
    final validIds =
        playerIds.where((final id) => id.trim().isNotEmpty).toList();
    final players = playerState.getPlayersByIds(validIds);

    if (players.isEmpty) return const SizedBox.shrink();

    return PlayersBubbleCard(
      title: title,
      players: players,
      isGrayscale: isGrayscale,
      onPlayerTap: (final id) => Navigator.push(
        context,
        MaterialPageRoute(builder: (final _) => PlayerDetailPage(playerId: id)),
      ),
    );
  }
}
