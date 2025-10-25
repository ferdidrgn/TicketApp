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
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) _fetchData();
    });
  }

  Future<void> _fetchData() async {
    Show? showData = ref.read(showProvider).getShowById(widget.showId);

    if (showData == null) {
      print("Show data not found in state, fetching from network...");
      try {
        await ref.read(showProvider.notifier).loadShowsByIds([widget.showId]);
        showData = ref.read(showProvider).getShowById(widget.showId);
        if (showData != null) {
          print("Show data fetched successfully.");
        } else {
          print("Show data still null after fetch attempt.");
        }
      } catch (e) {
        print("Error fetching show data: $e");
        return;
      }
    } else {
      print("Show data found in state.");
    }

    if (showData == null) {
      print("Cannot proceed without show data.");
      return;
    }

    print("Fetching related events and players...");

    if (showData.eventsId.isNotEmpty) {
      print("Fetching events with IDs: ${showData.eventsId}");
      await ref.read(eventProvider.notifier).loadEventsByIds(showData.eventsId);
    } else {
      print("No Event IDs to fetch.");
    }

    final allPlayerIds =
        [...showData.nowPlayersId, ...showData.oldPlayersId].toSet().toList();

    if (allPlayerIds.isNotEmpty) {
      print("Fetching players with IDs: $allPlayerIds");
      // DÜZELTME: Doğru Notifier metodunu çağır (getPlayersByIds değil, loadPlayersByIds varsayıyoruz)
      await ref.read(playerProvider.notifier).getPlayersByIds(allPlayerIds);
    } else {
      print("No Player IDs to fetch.");
    }
  }

  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showProvider);
    final eventState = ref.watch(eventProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);

    final showData = showState.getShowById(widget.showId);

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
      // Ana yükleme göstergesi hala CircularProgressIndicator olabilir, çünkü tüm sayfa etkilenir
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
            // Placeholder olarak ShimmerLoading kullanılıyor (bu doğru)
            placeholder: (final context, final url) => const ShimmerLoading(
                width: double.infinity, height: double.infinity),
            errorWidget: (final context, final url, final error) =>
                const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildShowTitle(final String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: CustomSectionTitle(
          title: name,
          fontSize: 28,
          alignment: Alignment.center,
          fontWeight: FontWeight.bold),
    );
  }

  // --- Shimmer Placeholder Widget'ları ---
  // (Bunları state sınıfının içine taşıdık)

  // Liste için Shimmer (Etkinlikler)
  Widget _buildShimmerList() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
          children: List.generate(
              2, // Genellikle 2-3 tane göstermek yeterli
              (final index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ShimmerLoading(width: double.infinity, height: 80),
                  ))));

  // Yatay Liste için Shimmer (Oyuncular)
  Widget _buildShimmerRow() => SizedBox(
      height: 195,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3, // Genellikle 3 tane göstermek yeterli
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemBuilder: (final context, final index) => Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: ShimmerLoading(
                    height: 195, width: 140), // CustomStageCard boyutuna yakın
              )));

  Widget _buildBottomSheetCard(
      final BuildContext context,
      final Show showData,
      final EventState eventState,
      final PlayerState playerState,
      final StageState stageState) {
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
            // DÜZELTME: CircularProgressIndicator yerine _buildShimmerList kullan
            if (eventState.isLoading && !eventState.hasData)
              _buildShimmerList() // <-- Shimmer burada
            else if (eventState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                    child: Text(
                        'Etkinlikler yüklenemedi: ${eventState.errorMessage}')),
              )
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
                    stageState.isLoading ? "..." : (stage?.name ?? "Sahne?"),
                    "İstanbul",
                  );
                }).toList(),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child:
                    Center(child: Text('Yaklaşan etkinlik bulunmamaktadır.')),
              ),

            const SizedBox(height: 20),
            const CustomSectionTitle(title: 'Ekip', fontSize: 22),
            const SizedBox(height: 10),

            // --- Player Bölümü ---
            // DÜZELTME: CircularProgressIndicator yerine _buildShimmerRow kullan
            if (playerState.isLoading && nowPlayerDataList.isEmpty)
              _buildShimmerRow() // <-- Shimmer burada
            else
              _buildNowPlayers(nowPlayerDataList),

            const SizedBox(height: 10),
            const CustomSectionTitle(title: 'Eski Ekip', fontSize: 22),
            const SizedBox(height: 10),

            // DÜZELTME: CircularProgressIndicator yerine _buildShimmerRow kullan
            if (playerState.isLoading && oldPlayerDataList.isEmpty)
              _buildShimmerRow() // <-- Shimmer burada
            else
              _buildOldPlayers(oldPlayerDataList),

            const SizedBox(height: 20),
            const CustomSectionTitle(title: 'Oyundan Kareler', fontSize: 22),
            const SizedBox(height: 10),
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
    final String city, // Parametre olarak city alındı
  ) {
    // 1. Yeni metodu kullanarak tarihi tek seferde parçala
    final Map<String, String> formattedDate =
        DateFormatter.formatForEventCard(date); // <-- DOĞRU METODU KULLAN

    final String dayText = formattedDate['day']!;
    final String monthText = formattedDate['monthName']!;
    final String timeText = formattedDate['time']!;

    // Hata durumunda bile null gelmemesi için ?? ile kontrol ekleyebiliriz
    // final String dayText = formattedDate['day'] ?? '?';
    // final String monthText = formattedDate['monthName'] ?? 'Hata';
    // final String timeText = formattedDate['time'] ?? '--:--';

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
              // Tarih kısmı (Değişiklik yok)
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
              // Etkinlik adı, şehir ve saat
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eventName,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 4),
                  // DÜZELTME: Sabit "İstanbul" yerine 'city' parametresini kullan
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
            // Card içindeki resim yüklenirken de shimmer kullanabilirsin
            placeholder: (final context, final url) =>
                const ShimmerLoading(width: double.infinity, height: 150),
            errorWidget: (final context, final url, final error) =>
                const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  void _showFullImage(final BuildContext context, final String photoUrl) {
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
                  // Tam ekran için spinner kalabilir
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
