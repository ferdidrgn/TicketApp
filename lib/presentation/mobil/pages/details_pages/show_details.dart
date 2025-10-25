import 'dart:async';
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
    // initState bittikten sonra ilk veri çekmeyi başlat
    // Bu, "Tried to modify a provider while the widget tree was building" hatasını önler.
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) {
        // Widget hala ağaçta mı diye kontrol et
        _fetchInitialData();
      }
    });
  }

  /// Ana veriyi (Show) çeker ve ardından ilişkili verileri (Event, Player)
  /// arka planda yüklemeyi tetikler.
  Future<void> _fetchInitialData() async {
    // Önce Show verisini state'ten oku
    Show? showData = ref.read(showProvider).getShowById(widget.showId);

    // State'te yoksa, yüklemesini BEKLE
    if (showData == null) {
      print("ShowDetailPage: Show data not found in state, fetching...");
      try {
        await ref.read(showProvider.notifier).loadShowsByIds([widget.showId]);
        // Yüklendikten sonra state'i tekrar oku
        showData = ref.read(showProvider).getShowById(widget.showId);
        if (showData == null) {
          print(
              "ShowDetailPage: Show data still null after fetch attempt. Stopping data fetch.");
          // Hata durumunu state'e yansıtmak daha iyi olabilir
          // ref.read(showProvider.notifier).setError("Gösteri yüklenemedi.");
          return; // Show yüklenemezse devam etme
        }
        print("ShowDetailPage: Show data fetched successfully.");
      } catch (e, s) {
        print("ShowDetailPage: Error fetching show data: $e \n$s");
        // Hata durumunu state'e yansıt
        // ref.read(showProvider.notifier).setError("Gösteri yüklenemedi: $e");
        return; // Hata varsa devam etme
      }
    } else {
      print("ShowDetailPage: Show data found in state.");
    }

    // Show verisi artık kesin var.
    // Event ve Player yüklemelerini BAŞLAT ama bekleme (unawaited).
    print(
        "ShowDetailPage: Triggering related events and players fetch (async)...");

    if (showData.eventsId.isNotEmpty) {
      print(
          "ShowDetailPage: Triggering events fetch with IDs: ${showData.eventsId}");
      // Arka planda çalışması için await KULLANMA
      unawaited(
          ref.read(eventProvider.notifier).loadEventsByIds(showData.eventsId));
    } else {
      print("ShowDetailPage: No Event IDs to fetch.");
      // Etkinlik ID'si yoksa event state'ini temizleyebilir veya boş olarak ayarlayabiliriz
      // ref.read(eventProvider.notifier).clearEvents(); // Opsiyonel
    }

    final allPlayerIds =
        [...showData.nowPlayersId, ...showData.oldPlayersId].toSet().toList();

    if (allPlayerIds.isNotEmpty) {
      print("ShowDetailPage: Triggering players fetch with IDs: $allPlayerIds");
      // Not: Buradaki metod adı PlayerNotifier'daki ile aynı olmalı!
      // 'loadPlayersByIds' olduğunu varsayıyoruz.
      unawaited(
          ref.read(playerProvider.notifier).getPlayersByIds(allPlayerIds));
    } else {
      print("ShowDetailPage: No Player IDs to fetch.");
      // Oyuncu ID'si yoksa player state'ini temizleyebilir veya boş olarak ayarlayabiliriz
      // ref.read(playerProvider.notifier).clearPlayers(); // Opsiyonel
    }
  }

  @override
  Widget build(final BuildContext context) {
    // Tüm state'leri izle
    final showState = ref.watch(showProvider);
    final eventState = ref.watch(eventProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);

    // İlgili Show verisini state'ten al
    final showData = showState.getShowById(widget.showId);

    // Event listesi yüklendiğinde Stage'leri yükle (arka planda)
    ref.listen<EventState>(eventProvider, (final previous, final next) {
      // Sadece event listesi ilk kez dolduğunda tetikle
      final bool justLoadedEvents = (previous?.dataList?.isEmpty ?? true) &&
          (next.dataList?.isNotEmpty ?? false);

      if (justLoadedEvents) {
        // Geçerli stageId'leri topla
        final stageIds = next.dataList!
            .map((final e) => e.stageId)
            .where((final id) =>
                id.isNotEmpty && id != '0') // Geçersiz ID'leri filtrele
            .toSet()
            .toList();
        if (stageIds.isNotEmpty) {
          print(
              "ShowDetailPage: Events loaded, triggering stage fetch for IDs: $stageIds");
          // Sahne yüklemesini de bekleme
          unawaited(ref.read(stageProvider.notifier).loadStagesByIds(stageIds));
        } else {
          print("ShowDetailPage: Events loaded, but no valid Stage IDs found.");
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
          title: Text(showData?.name ?? 'Show Detayı'), centerTitle: true),
      // Ana yükleme göstergesi: Sadece ilk Show verisi beklenirken gösterilir
      // Eğer showData null ise ama showState yüklenmiyorsa, hata mesajı gösterilir.
      body: showState.isLoading && showData == null
          ? const Center(child: CircularProgressIndicator())
          : (showData == null)
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(showState.errorMessage ??
                      'Gösteri bulunamadı veya yüklenemedi.'),
                ))
              // Show verisi geldiği anda detayları (Shimmer'lar dahil) göster
              : _buildShowDetails(
                  showData, eventState, playerState, stageState),
    );
  }

  // --- Yardımcı Build Metodları ---

  Widget _buildShowDetails(final Show showData, final EventState eventState,
      final PlayerState playerState, final StageState stageState) {
    return SingleChildScrollView(
        // physics: const BouncingScrollPhysics(), // Kaydırma efekti
        padding: const EdgeInsets.symmetric(horizontal: 5).copyWith(bottom: 20),
        // Alta boşluk
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
                color: Colors.black.withOpacity(0.6), // Gölge yumuşatıldı
                blurRadius: 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            // Kenarları yuvarlatılmış resim için
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              // Yüklenirken Shimmer göster
              placeholder: (final context, final url) => const ShimmerLoading(
                  width: double.infinity, height: double.infinity),
              // Hata durumunda ikon göster
              errorWidget: (final context, final url, final error) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 50, color: Colors.grey)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShowTitle(final String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 15), // Padding ayarlandı
      child: CustomSectionTitle(
          title: name,
          fontSize: 28,
          alignment: Alignment.center,
          fontWeight: FontWeight.bold),
    );
  }

  // --- Shimmer Placeholder Widget Metodları ---

  // Etkinlik listesi için Shimmer
  Widget _buildShimmerList() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Column(
          children: List.generate(
              2,
              (final index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ShimmerLoading(
                        width: double.infinity,
                        height: 90), // Kart yüksekliğine yakın
                  ))));

  // Oyuncu listesi için Shimmer
  Widget _buildShimmerRow() => SizedBox(
      height: 195,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3, // Kaç tane placeholder gösterilecek
          // Kenar boşlukları ayarlandı
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          itemBuilder: (final context, final index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                // Kartlar arasına boşluk
                child: ShimmerLoading(
                    height: 185, width: 140), // CustomStageCard boyutuna yakın
              )));

  // --- Alt Kart ve İçeriği ---

  Widget _buildBottomSheetCard(
      final BuildContext context,
      final Show showData,
      final EventState eventState,
      final PlayerState playerState,
      final StageState stageState) {
    // Player verilerini state'ten al
    final nowPlayerDataList =
        playerState.getPlayersByIds(showData.nowPlayersId);
    final oldPlayerDataList =
        playerState.getPlayersByIds(showData.oldPlayersId);

    return Container(
      padding: const EdgeInsets.only(top: 25, bottom: 20),
      // Padding ayarlandı
      margin: const EdgeInsets.only(top: 10),
      // Margin azaltıldı
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        // Tema rengi
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        // Yuvarlatma arttırıldı
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15), // Gölge azaltıldı
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        // Dikey padding kaldırıldı (Container'da var)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Açıklama Kartı
            CustomDescriptionCard(
                description: showData.description.replaceAll('\\n', '\n')),
            const SizedBox(height: 25),

            // Etkinlik Takvimi Bölümü
            const CustomSectionTitle(title: 'Etkinlik Takvimi', fontSize: 22),
            const SizedBox(height: 15),
            // Yükleniyorsa Shimmer göster
            if (eventState.isLoading && !eventState.hasData)
              _buildShimmerList()
            // Hata varsa göster
            else if (eventState.errorMessage != null)
              _buildErrorWidget(
                  'Etkinlikler yüklenemedi: ${eventState.errorMessage}')
            // Veri varsa listele
            else if (eventState.hasData &&
                eventState.dataList!
                    .any((final e) => showData.eventsId.contains(e.id)))
              Column(
                children: eventState.dataList!
                    .where((final e) => showData.eventsId.contains(e.id))
                    .map((final event) {
                  final stage = stageState.getStageById(event.stageId);
                  final stageName = stageState.isLoading && stage == null
                      ? "Yükleniyor..."
                      : (stage?.name ?? "Sahne?");
                  return _buildEventCard(
                    event.date.toString(),
                    event.id,
                    showData.id,
                    stageName,
                    "İstanbul",
                  );
                }).toList(),
              )
            // Veri yoksa veya filtrelenen kalmadıysa mesaj göster
            else
              _buildEmptyListWidget('Yaklaşan etkinlik bulunmamaktadır.'),

            const SizedBox(height: 25),

            // Ekip Bölümü
            const CustomSectionTitle(title: 'Ekip', fontSize: 22),
            const SizedBox(height: 10),
            // Yükleniyorsa Shimmer göster
            if (playerState.isLoading && nowPlayerDataList.isEmpty)
              _buildShimmerRow()
            // Yoksa listeyi (veya boş mesajını) göster
            else
              _buildNowPlayers(nowPlayerDataList),

            const SizedBox(height: 20),

            // Eski Ekip Bölümü
            const CustomSectionTitle(title: 'Eski Ekip', fontSize: 22),
            const SizedBox(height: 10),
            if (playerState.isLoading && oldPlayerDataList.isEmpty)
              _buildShimmerRow()
            else
              _buildOldPlayers(oldPlayerDataList),

            const SizedBox(height: 25),

            // Oyundan Kareler Bölümü
            const CustomSectionTitle(title: 'Oyundan Kareler', fontSize: 22),
            const SizedBox(height: 10),
            _buildGamePhotoSection(showData.photosShowId),
            // Kendi içinde Shimmer/boş kontrolü yapabilir
          ],
        ),
      ),
    );
  }

  // --- Etkinlik Kartı ---
  Widget _buildEventCard(
    final String date,
    final String eventId,
    final String showId,
    final String eventName, // Sahne Adı
    final String city,
  ) {
    final Map<String, String> formattedDate =
        DateFormatter.formatForEventCard(date);
    final String dayText = formattedDate['day'] ?? '?';
    final String monthText =
        formattedDate['monthName'] ?? '-'; // Hata durumunda daha kısa metin
    final String timeText = formattedDate['time'] ?? '--:--';

    return InkWell(
      // Tıklama efekti için GestureDetector yerine InkWell
      onTap: () {
        print("Tapped on Event Card: $eventId");
        ref.read(eventProvider.notifier).initializeWithParams(
              eventId: eventId,
              showId: showId,
              customerId: "test 2", // TODO: Gerçek müşteri ID'si
            );
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (final context) => SeatSelectionScreen(
                  showId: showId, eventId: eventId, customerId: "test 2")),
        );
      },
      borderRadius: BorderRadius.circular(12),
      // Tıklama efektinin kenarları için
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12), // Padding ayarlandı
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15), // Gölge daha da yumuşatıldı
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Tarih Kutusu
            Container(
              width: 70,
              // Genişlik azaltıldı
              padding: const EdgeInsets.symmetric(vertical: 10),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(monthText,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70)), // Renk açıldı
                ],
              ),
            ),
            const SizedBox(width: 15),
            // Etkinlik Bilgisi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eventName, // Sahne Adı
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87), // Renk koyulaştırıldı
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text("$city • $timeText", // Şehir • Saat
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // İleri ikonu
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // --- Oyuncu Listeleri ---
  Widget _buildNowPlayers(final List<Player> nowPlayerDataList) {
    if (nowPlayerDataList.isEmpty)
      return _buildEmptyListWidget('Aktif ekip bilgisi bulunamadı.');

    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // Kenar boşlukları ayarlandı
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: nowPlayerDataList.length,
        itemBuilder: (final context, final index) {
          final player = nowPlayerDataList[index];
          return CustomStageCard(
              text: '${player.firstName}\n${player.lastName}',
              // İsim iki satıra bölündü
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
    if (oldPlayerDataList.isEmpty)
      return _buildEmptyListWidget('Eski ekip bilgisi bulunamadı.');

    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: oldPlayerDataList.length,
        itemBuilder: (final context, final index) {
          final player = oldPlayerDataList[index];
          return Stack(children: [
            // Gri overlay için Stack
            CustomStageCard(
              text: '${player.firstName}\n${player.lastName}',
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
            // Gri Overlay
            Positioned.fill(
                child: IgnorePointer(
                    ignoring: true, // Tıklamayı engelleme
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            // Card ile aynı yuvarlatma
                            color: Colors.black.withOpacity(0.3)))))
            // Daha belirgin overlay
          ]);
        },
      ),
    );
  }

  // --- Oyun Kareleri ---
  Widget _buildGamePhotoSection(final List<String> photoDataList) {
    if (photoDataList.isEmpty) {
      return _buildEmptyListWidget('Oyundan kareler bulunamadı.');
    }
    return SizedBox(
      height: 170, // Yükseklik biraz azaltıldı
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        itemCount: photoDataList.length,
        itemBuilder: (final context, final index) {
          final photoUrl = photoDataList[index];
          return Padding(
            // Kartlar arasına boşluk
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: GestureDetector(
              child: _buildGamePhotoCard(photoUrl),
              onTap: () {
                _showFullImage(context, photoUrl);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildGamePhotoCard(final String? photoUrl) {
    // Kart boyutu ayarlandı
    return SizedBox(
      width: 130,
      height: 160,
      child: Card(
        elevation: 6, // Hafif gölge
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias, // Resmin taşmasını engelle
        child: CachedNetworkImage(
          // Padding kaldırıldı, resim tüm kartı kaplasın
          imageUrl: photoUrl ?? '',
          height: double.infinity,
          // Card boyutuna uyum sağla
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (final context, final url) => const ShimmerLoading(
              width: double.infinity, height: double.infinity),
          // Boyutlar ayarlandı
          errorWidget: (final context, final url, final error) => const Center(
              child:
                  Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
        ),
      ),
    );
  }

  // --- Yardımcı Widget'lar (Boş Liste / Hata) ---
  Widget _buildEmptyListWidget(final String message) {
    return SizedBox(
      height: 100, // Standart bir yükseklik verilebilir
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[600], fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(final String message) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            message,
            style: TextStyle(
                color: Theme.of(context).colorScheme.error, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // --- Tam Ekran Resim Gösterme Metodu ---
  void _showFullImage(final BuildContext context, final String photoUrl) {
    showDialog(
      // showGeneralDialog yerine daha basit showDialog
      context: context,
      builder: (final BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Arka planı şeffaf yap
          insetPadding: EdgeInsets.all(10), // Kenarlardan boşluk
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(), // Tıklayınca kapat
            child: InteractiveViewer(
              // Zoom için
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.contain, // Ekrana sığdır
                placeholder: (final context, final url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (final context, final url, final error) =>
                    const Center(
                        child: Icon(Icons.error_outline,
                            color: Colors.white, size: 50)),
              ),
            ),
          ),
        );
      },
    );
  }
}
