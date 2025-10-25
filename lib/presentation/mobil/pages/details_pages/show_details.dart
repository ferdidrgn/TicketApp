import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/widgets/custom_description_card.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';
import 'package:ticketapp/data/providers/player/player_notifier.dart';
import 'package:ticketapp/data/providers/show/show_notifier.dart';
import 'package:ticketapp/data/providers/stage/stage_notifier.dart';
import 'package:ticketapp/presentation/mobil/pages/details_pages/player_details.dart';
import 'package:ticketapp/presentation/mobil/pages/details_pages/seat_details.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../core/widgets/custom_stage_card.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../data/providers/event/event_provider.dart';
import '../../../../data/providers/event/event_state.dart';
import '../../../../data/providers/player/player_provider.dart';
import '../../../../data/providers/player/player_state.dart';
import '../../../../data/providers/show/show_provider.dart';
import '../../../../data/providers/stage/stage_provider.dart';
import '../../../../data/providers/stage/stage_state.dart';
import '../../../../domain/entities/player.dart';
import '../../../../domain/entities/show.dart';

class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage> {
  @override
  void initState() {
    super.initState();
    // Veri çekmeyi initState bittikten sonraya planla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Widget hala ağaçta mı diye kontrol et (güvenlik için)
      if (mounted) _fetchData();
    });
  }

  /// DÜZELTME 1: Yükleme mantığı buraya taşındı
// _fetchData metodu aynı kalabilir (önceki cevaptaki gibi)
  Future<void> _fetchData() async {
    // 1. State'te veri var mı diye oku
    Show? showData = ref.read(showProvider).getShowById(widget.showId);

    // 2. State'te yoksa, yükle ve tamamlanmasını bekle
    if (showData == null) {
      print(
          "Show data not found in state, fetching from network..."); // Log ekle
      try {
        await ref.read(showProvider.notifier).loadShowsByIds([widget.showId]);
        showData = ref.read(showProvider).getShowById(widget.showId);
        if (showData != null) {
          print("Show data fetched successfully."); // Log ekle
        } else {
          print("Show data still null after fetch attempt."); // Log ekle
        }
      } catch (e) {
        print("Error fetching show data: $e"); // Hata log'u ekle
        // Hata durumunda state'i güncellemek için notifier'ı kullanabilirsin
        // ref.read(showProvider.notifier).setError("Gösteri yüklenemedi: $e");
        return; // Hata varsa devam etme
      }
    } else {
      print("Show data found in state."); // Log ekle
    }

    // 3. showData hâlâ null ise devam etme
    if (showData == null) {
      print("Cannot proceed without show data."); // Log ekle
      return;
    }

    // 4. Diğer yüklemeleri tetikle
    print("Fetching related events and players..."); // Log ekle

    // Event'leri yükle
    if (showData.eventsId.isNotEmpty) {
      print("Fetching events with IDs: ${showData.eventsId}"); // Log ekle
      ref.read(eventProvider.notifier).loadEventsByIds(showData.eventsId);
    } else {
      print("No Event IDs to fetch."); // Log ekle
    }

    // Player'ları yükle
    final allPlayerIds =
        [...showData.nowPlayersId, ...showData.oldPlayersId].toSet().toList();

    if (allPlayerIds.isNotEmpty) {
      print("Fetching players with IDs: $allPlayerIds"); // Log ekle
      ref.read(playerProvider.notifier).getPlayersByIds(allPlayerIds);
    } else {
      print("No Player IDs to fetch."); // Log ekle
    }
  }

  @override
  Widget build(final BuildContext context) {
    // Tüm ilgili state'leri 'watch' ile izle
    final showState = ref.watch(showProvider);
    final eventState = ref.watch(eventProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);

    final showData = showState.getShowById(widget.showId);

    // DÜZELTME 2: 'ref.listen<ShowState>' bloğu SİLİNDİ.

    // 'Event' listesi yüklendiğinde, 'Stage' verilerini tetikle (BU KALMALI)
    ref.listen<EventState>(eventProvider, (final previous, final next) {
      final bool justLoadedEvents = (previous == null ||
              previous.dataList == null ||
              previous.dataList!.isEmpty) &&
          (next.dataList != null && next.dataList!.isNotEmpty);

      if (justLoadedEvents) {
        final stageIds =
            next.dataList!.map((final e) => e.stageId).toSet().toList();
        ref.read(stageProvider.notifier).loadStagesByIds(stageIds);
      }
    });

    return Scaffold(
      appBar: AppBar(
          title: Text(showData?.name ?? 'Show Detayı'), centerTitle: true),
      // Ana yüklemeyi 'showData'ya değil, 'showState'e bağla
      body: showState.isLoading && showData == null
          ? const Center(child: CircularProgressIndicator())
          : (showData == null)
              ? const Center(
                  child: Text('Gösteri bulunamadı veya yüklenemedi.'))
              : _buildShowDetails(
                  showData, eventState, playerState, stageState),
    );
  }

  Widget _buildShowDetails(final Show showData, final EventState eventState,
      final PlayerState playerState, final StageState stageState) {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _buildShowImage(showData.imageUrl),
          _buildShowTitle(showData.name),
          _buildBottomSheetCard(
              context, showData, eventState, playerState, stageState)
        ]));
  }

  Widget _buildShowImage(final String imageUrl) {
    // ... (Değişiklik yok)
    return Container(
      padding: const EdgeInsets.all(15),
      child: AspectRatio(
        aspectRatio: 9 / 13,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (final context, final url) => ShimmerLoading(),
            errorWidget: (final context, final url, final error) =>
                const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildShowTitle(final String name) {
    // ... (Değişiklik yok)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: CustomSectionTitle(
          title: name,
          fontSize: 28,
          alignment: Alignment.center,
          fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBottomSheetCard(
      final BuildContext context,
      final Show showData,
      final EventState eventState,
      final PlayerState playerState,
      final StageState stageState) {
    // Verileri state'ten al
    final nowPlayerDataList =
        playerState.getPlayersByIds(showData.nowPlayersId);
    final oldPlayerDataList =
        playerState.getPlayersByIds(showData.oldPlayersId);

    return Container(
      padding: const EdgeInsets.only(top: 20),
      margin: const EdgeInsets.only(top: 15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomDescriptionCard(
                description: showData.description.replaceAll('\\n', '\n')),
            const SizedBox(height: 20),
            const CustomSectionTitle(title: 'Etkinlik Takvimi', fontSize: 22),
            const SizedBox(height: 15),

            // --- Event Bölümü ---
            // 'eventState.isLoading' ve 'hasData' birlikte kontrol edilmeli
            if (eventState.isLoading && !eventState.hasData)
              const Center(child: CircularProgressIndicator())
            else if (eventState.errorMessage != null)
              Center(
                  child: Text(
                      'Etkinlikler yüklenemedi: ${eventState.errorMessage}'))
            else if (eventState.hasData)
              Column(
                children: eventState.dataList!
                    .where((final e) => showData.eventsId.contains(e.id))
                    .map((final event) {
                  final stage = stageState.getStageById(event.stageId);

                  return _buildEventCard(
                    event.date.toString(),
                    event.id,
                    showData.id,
                    stage?.name ?? "...", // Sahne Adı
                    "İstanbul",
                  );
                }).toList(),
              )
            else
              const Center(child: Text('Yaklaşan etkinlik bulunmamaktadır.')),

            const SizedBox(height: 20),
            const CustomSectionTitle(title: 'Ekip', fontSize: 22),

            // --- Player Bölümü ---
            // 'playerState.isLoading' ve listenin boş olup olmadığı kontrol edilmeli
            if (playerState.isLoading && nowPlayerDataList.isEmpty)
              const SizedBox(
                  height: 195,
                  child: Center(child: CircularProgressIndicator()))
            else
              _buildNowPlayers(nowPlayerDataList),

            const SizedBox(height: 10),
            const CustomSectionTitle(title: 'Eski Ekip', fontSize: 22),

            if (playerState.isLoading && oldPlayerDataList.isEmpty)
              const SizedBox(
                  height: 195,
                  child: Center(child: CircularProgressIndicator()))
            else
              _buildOldPlayers(oldPlayerDataList),

            const SizedBox(height: 20),
            const CustomSectionTitle(title: 'Oyundan Kareler', fontSize: 22),
            _buildGamePhotoSection(showData.photosShowId),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(
    final String date,
    final String eventId,
    final String showId,
    final String eventName,
    final String city,
  ) {
    // ... (Değişiklik yok)
    final Map<String, String> formattedDate =
        DateFormatter.parseFormattedDateTime(date);

    final String dayText = formattedDate['day'] ?? '?';
    final String monthText = formattedDate['monthName'] ?? 'Hata';
    final String timeText = formattedDate['time'] ?? '--:--';

    return GestureDetector(
      onTap: () {
        ref.read(eventProvider.notifier).initializeWithParams(
              eventId: eventId,
              showId: showId,
              customerId: "test 2", // TODO: Bu ID'yi dinamik almalısın
            );

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (final context) => SeatSelectionScreen(
                  showId: showId, eventId: eventId, customerId: "test 2")),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayText,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text(monthText,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eventName,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(
                    "$city • $timeText",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNowPlayers(final List<Player> nowPlayerDataList) {
    // ... (Değişiklik yok)
    return nowPlayerDataList.isEmpty
        ? const SizedBox(
            height: 195,
            child: Center(
              child: Text('Aktif ekip bilgisi bulunamadı.'),
            ),
          )
        : SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: nowPlayerDataList.length,
              itemBuilder: (final context, final index) {
                final player = nowPlayerDataList[index];
                return CustomStageCard(
                    text: '${player.firstName} ${player.lastName}',
                    imageUrl: player.imageUrl,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (final context) =>
                                  PlayerDetailPage(playerId: player.id)));
                    });
              },
            ),
          );
  }

  Widget _buildOldPlayers(final List<Player> oldPlayerDataList) {
    // ... (Değişiklik yok)
    return oldPlayerDataList.isEmpty
        ? const SizedBox(
            height: 195,
            child: Center(
              child: Text('Eski ekip bilgisi bulunamadı.'),
            ),
          )
        : SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: oldPlayerDataList.length,
              itemBuilder: (final context, final index) {
                final player = oldPlayerDataList[index];
                return Stack(children: [
                  CustomStageCard(
                    text: '${player.firstName} ${player.lastName}',
                    imageUrl: player.imageUrl,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (final context) =>
                                PlayerDetailPage(playerId: player.id)),
                      );
                    },
                  ),
                  Positioned.fill(
                      child: IgnorePointer(
                          ignoring: true,
                          child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.withOpacity(0.5)))))
                ]);
              },
            ),
          );
  }

  Widget _buildGamePhotoSection(final List<String> photoDataList) {
    // ... (Değişiklik yok)
    return photoDataList.isEmpty
        ? const SizedBox(
            height: 210,
            child: Center(
              child: Text('Oyundan kareler bulunamadı.'),
            ),
          )
        : SizedBox(
            height: 210,
            width: double.infinity,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: photoDataList.length,
              itemBuilder: (final context, final index) {
                final photoUrl = photoDataList[index];
                return GestureDetector(
                  child: _buildGamePhotoCard(photoUrl),
                  onTap: () {
                    _showFullImage(context, photoUrl);
                  },
                );
              },
            ),
          );
  }

  Widget _buildGamePhotoCard(final String? photoUrl) {
    // ... (Değişiklik yok)
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CachedNetworkImage(
            imageUrl: photoUrl ?? '',
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (final context, final url) => ShimmerLoading(),
            errorWidget: (final context, final url, final error) =>
                const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  void _showFullImage(final BuildContext context, final String photoUrl) {
    // ... (Değişiklik yok)
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tam Ekran Görsel',
      barrierColor: Colors.black.withOpacity(0.7),
      pageBuilder: (final context, final _, final __) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.contain,
                  placeholder: (final context, final url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (final context, final url, final error) =>
                      const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
