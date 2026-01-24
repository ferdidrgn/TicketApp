import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_detail_provider.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/widgets/button/glass_back_button.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/widgets/events_card.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/widgets/players_bubble_card.dart';
import '../../../seat/presentation/pages/seat_details.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../domain/entities/show.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    // 🔥 TEK SATIRDA TÜM VERİ YÖNETİMİ
    final detailAsync = ref.watch(showDetailProvider(widget.showId));

    final bgColor =
        context.isDarkMode ? AppDarkColors.primary : AppLightColors.onPrimary;

    return Scaffold(
      body: detailAsync.when(
        // 1. Loading Durumu
        loading: () => const Center(child: CircularProgressIndicator()),

        // 2. Hata Durumu
        error: (final err, final stack) => Center(child: Text("Hata: $err")),

        // 3. Veri Geldi
        data: (final state) => Stack(
          children: [
            ShowParallaxHeader(
              imageUrl: state.show.imageUrl,
              scrollController: _scrollController,
            ),
            _buildContent(state, bgColor),
            const Positioned(top: 50, left: 16, child: GlassBackButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(final ShowDetailState state, final Color bgColor) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).size.height * 0.45),
        ),
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
                // Show Info
                ShowInfoSection(
                  title: state.show.name,
                  description: state.show.description,
                ),

                // Events (Veriyi direkt veriyoruz, widget tekrar fetch yapmıyor)
                _ShowEventSection(
                  show: state.show,
                  events: state.events,
                  stages: state.stages,
                  onBuyTicket: _handleTicketPurchase,
                ),

                // Cast (Current)
                _ShowCastSection(
                  title: "OYUNCU KADROSU",
                  playerIds: state.show.nowPlayersId,
                  allPlayers: state.players,
                ),

                // Cast (Old)
                if (state.show.oldPlayersId.isNotEmpty)
                  _ShowCastSection(
                    title: "ESKİ KADRO",
                    playerIds: state.show.oldPlayersId,
                    allPlayers: state.players,
                    isGrayscale: true,
                  ),

                // Gallery
                if (state.show.photosShowId.isNotEmpty) ...[
                  const SectionHeader(title: "OYUNDAN KARELER", fontSize: 20),
                  GallerySection(photos: state.show.photosShowId),
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
    final String? userId = ref.read(currentUserProvider).value?.uid;
    if (context.mounted && userId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (final _) => SeatSelectionScreen(
            showId: widget.showId,
            eventId: eventId,
            customerId: userId,
          ),
        ),
      );
    }
  }
}

// ==============================================================================
// INTERNAL WIDGETS (Stateless & Dumb)
// Bu widget'lar artık Provider okumaz, sadece gelen veriyi gösterir.
// ==============================================================================

class _ShowEventSection extends StatelessWidget {
  final Show show;
  final List<Event> events;
  final List<Stage> stages;
  final Function(String) onBuyTicket;

  const _ShowEventSection({
    required this.show,
    required this.events,
    required this.stages,
    required this.onBuyTicket,
  });

  @override
  Widget build(final BuildContext context) {
    // Show'a ait eventleri filtrele (Gerekirse, provider zaten yapmış olabilir)
    final relevantEvents =
        events.where((final e) => show.eventsId.contains(e.id)).toList();

    if (relevantEvents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "ETKİNLİK TAKVİMİ", fontSize: 20),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: relevantEvents.length,
            separatorBuilder: (final _, final __) => const SizedBox(width: 0),
            itemBuilder: (final context, final index) {
              final event = relevantEvents[index];
              // Stage listesinden ilgili sahneyi bul
              final stage = stages.firstWhere(
                (final s) => s.id == event.stageId,
                orElse: () => const Stage(
                    id: '0',
                    name: 'Bilinmiyor',
                    imageUrl: '',
                    capacity: '',
                    description: '',
                    communication: '',
                    address: '',
                    locationLat: 0.0,
                    locationLng: 0.0,
                    createdAt: '',
                    updatedAt: '',
                    showsId: []),
              );

              final dateInfo = DateFormatter.formatForEventCard(event.date);

              return EventsCard(
                width: 280,
                imageUrl: show.imageUrl,
                showName: show.name,
                category: "TİYATRO",
                date:
                    "${dateInfo['day']} ${dateInfo['monthName']} • ${dateInfo['time']}",
                stage: stage.name,
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

class _ShowCastSection extends StatelessWidget {
  final String title;
  final List<String> playerIds;
  final List<Player> allPlayers;
  final bool isGrayscale;

  const _ShowCastSection({
    required this.title,
    required this.playerIds,
    required this.allPlayers,
    this.isGrayscale = false,
  });

  @override
  Widget build(final BuildContext context) {
    // Tüm oyuncu listesinden sadece bu bölüme ait olanları filtrele
    final relevantPlayers =
        allPlayers.where((final p) => playerIds.contains(p.id)).toList();

    if (relevantPlayers.isEmpty) return const SizedBox.shrink();

    return PlayersBubbleCard(
      title: title,
      players: relevantPlayers,
      isGrayscale: isGrayscale,
    );
  }
}
