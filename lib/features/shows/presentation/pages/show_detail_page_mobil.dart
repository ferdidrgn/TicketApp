import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/features/events/presentation/providers/event_provider.dart';
import 'package:ticketapp/features/players/presentation/providers/player_provider.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_provider.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_provider.dart';
import 'package:ticketapp/shared/widgets/gallery_section.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/widgets/button/glass_back_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../events/presentation/widgets/events_card.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../players/presentation/providers/player_notifier.dart';
import '../../../players/presentation/widgets/players_bubble_card.dart';
import '../../../seat/presentation/pages/seat_details.dart';
import '../../../stages/presentation/providers/stage_notifier.dart';
import '../../domain/entities/show.dart';
import '../providers/show_notifier.dart';
import '../widgets/mobile/show_info_section.dart';
import '../widgets/mobile/show_parallax_header.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((final _) => _initData());
  }

  Future<void> _initData() async {
    try {
      final showId = widget.showId;
      // 1. Önce Show verisini yükle veya bul
      var show = ref.read(showProvider).getShowById(showId);
      if (show == null) {
        await ref.read(showProvider.notifier).loadShowsByIds([showId]);
        show = ref.read(showProvider).getShowById(showId);
      }

      if (show == null || !mounted) return;

      // 2. Diğer tüm verileri paralel yükleyerek hızı artır
      await Future.wait([
        _loadEventsAndStages(show),
        _loadCast(show),
      ]);
    } catch (e) {
      debugPrint("❌ Veri yükleme hatası: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEventsAndStages(final Show show) async {
    final eventIds = show.eventsId.where((final id) => id.isNotEmpty).toList();
    if (eventIds.isEmpty) return;

    await ref.read(eventProvider.notifier).loadEventsByIds(eventIds);

    final stages = ref
        .read(eventProvider)
        .dataList
        ?.where((final e) => eventIds.contains(e.id))
        .map((final e) => e.stageId)
        .where((final id) => id.isNotEmpty && id != '0')
        .toSet()
        .toList();

    if (stages != null && stages.isNotEmpty) {
      await ref.read(stageProvider.notifier).loadStagesByIds(stages);
    }
  }

  Future<void> _loadCast(final Show show) async {
    final allPlayerIds = {...show.nowPlayersId, ...show.oldPlayersId}
        .where((final id) => id.isNotEmpty)
        .toList();
    if (allPlayerIds.isNotEmpty) {
      await ref.read(playerProvider.notifier).getPlayersByIds(allPlayerIds);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final showData = ref.watch(showProvider).getShowById(widget.showId);
    final bgColor =
        context.isDarkMode ? AppDarkColors.primary : AppLightColors.onPrimary;

    if (_isLoading && showData == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (showData == null)
      return Scaffold(
          appBar: AppBar(leading: const BackButton()),
          body: const Center(child: Text("İçerik Bulunamadı")));

    return Scaffold(
      body: Stack(
        children: [
          ShowParallaxHeader(
              imageUrl: showData.imageUrl, scrollController: _scrollController),
          _buildContent(showData, bgColor),
          const Positioned(top: 50, left: 16, child: GlassBackButton()),
        ],
      ),
    );
  }

  Widget _buildContent(final Show showData, final Color bgColor) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).size.height * 0.45)),
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                ShowInfoSection(
                    title: showData.name, description: showData.description),
                ShowEventSection(
                    showData: showData, onBuyTicket: _handleTicketPurchase),
                ShowCastSection(
                    title: "OYUNCU KADROSU", playerIds: showData.nowPlayersId),
                if (showData.oldPlayersId.isNotEmpty)
                  ShowCastSection(
                      title: "ESKİ KADRO",
                      playerIds: showData.oldPlayersId,
                      isGrayscale: true),
                if (showData.photosShowId.isNotEmpty) ...[
                  SectionHeader(title: "OYUNDAN KARELER", fontSize: 20),
                  GallerySection(photos: showData.photosShowId),
                ],
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleTicketPurchase(final String eventId) async {
    final String? userId = ref.read(loginProvider).userId;

    // 5. Veri geldiğinde ve sayfa hala ekrandaysa (mounted) yönlendirme yapıyoruz
    if (context.mounted)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (final _) => SeatSelectionScreen(
            showId: widget.showId,
            eventId: eventId,
            customerId: userId ?? "",
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

  const ShowEventSection(
      {super.key, required this.showData, required this.onBuyTicket});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final eventState = ref.watch(eventProvider);
    final stageState = ref.watch(stageProvider);

    final events = eventState.dataList
            ?.where((final e) => showData.eventsId.contains(e.id))
            .toList() ??
        [];

    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: "ETKİNLİK TAKVİMİ", fontSize: 20),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: events.length,
            separatorBuilder: (final _, final __) => const SizedBox(width: 0),
            itemBuilder: (final context, final index) {
              final event = events[index];
              final stage = stageState.getStageById(event.stageId);
              final dateInfo = DateFormatter.formatForEventCard(event.date);

              return EventsCard(
                width: 280,
                imageUrl: showData.imageUrl,
                showName: showData.name,
                category: "TİYATRO",
                date:
                    "${dateInfo['day']} ${dateInfo['monthName']} • ${dateInfo['time']}",
                stage: stage?.name ?? "Yükleniyor...",
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
        title: title, players: players, isGrayscale: isGrayscale);
  }
}
