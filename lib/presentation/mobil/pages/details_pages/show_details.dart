import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/widgets/custom_description_card.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';
import 'package:ticketapp/data/providers/player/player_notifier.dart';
import 'package:ticketapp/data/providers/show/show_notifier.dart';
import 'package:ticketapp/data/providers/stage/stage_notifier.dart';
import 'package:ticketapp/data/providers/user/user_provider.dart';
import 'package:ticketapp/domain/entities/stage.dart';
import 'package:ticketapp/presentation/mobil/pages/details_pages/player_details.dart';
import 'package:ticketapp/presentation/mobil/pages/details_pages/seat_details.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../core/widgets/custom_stage_card.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../data/providers/event/event_provider.dart';
import '../../../../data/providers/event/event_state.dart';
import '../../../../data/providers/login/login_provider.dart';
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
      if (mounted) _fetchInitialData(); // Widget hala ağaçta mı diye kontrol et
    });
  }

  /// Ana veriyi (Show) çeker ve ardından ilişkili verileri (Event, Player)
  /// arka planda yüklemeyi tetikler.
  Future<void> _fetchInitialData() async {
    final showNotifier = ref.read(showProvider.notifier);
    Show? showData = ref.read(showProvider).getShowById(widget.showId);

    if (showData == null) {
      try {
        await showNotifier.loadShowsByIds([widget.showId]);
        showData = ref.read(showProvider).getShowById(widget.showId);
        if (showData == null) {
          showNotifier.setErrorState("Gösteri yüklenemedi.");
          return;
        }
      } catch (e) {
        showNotifier.setErrorState("Gösteri yüklenemedi: $e");
        return;
      }
    }

    if (showData.eventsId.isNotEmpty)
      unawaited(
          ref.read(eventProvider.notifier).loadEventsByIds(showData.eventsId));

    final allPlayerIds =
        {...showData.nowPlayersId, ...showData.oldPlayersId}.toList();
    if (allPlayerIds.isNotEmpty)
      unawaited(
          ref.read(playerProvider.notifier).getPlayersByIds(allPlayerIds));
  }

  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showProvider);
    final eventState = ref.watch(eventProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);

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
            .whereType<String>()
            .where((final id) => id.trim().isNotEmpty && id != '0')
            .toSet()
            .toList();
        if (stageIds.isNotEmpty)
          // Sahne yüklemesini de bekleme
          unawaited(ref.read(stageProvider.notifier).loadStagesByIds(stageIds));
      }
    });

    return Scaffold(
        appBar: AppBar(
            title: Text(showData?.name ?? 'Gösteri Detayları'),
            centerTitle: true),
        body: showState.isLoading && !showState.hasData
            ? const Center(child: CircularProgressIndicator())
            : (!showState.hasData)
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(showState.errorMessage ??
                            'Gösteri bulunamadı veya yüklenemedi.')))
                : _buildShowDetails(
                    showData!, eventState, playerState, stageState));
  }

  Widget _buildShowDetails(final Show showData, final EventState eventState,
      final PlayerState playerState, final StageState stageState) {
    return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        // Kaydırma efekti
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
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (final context, final url) => const ShimmerLoading(
                  width: double.infinity, height: double.infinity),
              errorWidget: (final context, final url, final error) => Container(
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20)),
                  child: const Center(
                      child: Icon(Icons.broken_image_outlined,
                          size: 50, color: Colors.grey))),
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
      height: 170,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4, // Kaç tane placeholder gösterilecek
          // Kenar boşlukları ayarlandı
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemBuilder: (final context, final index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                // Kartlar arasına boşluk
                child: ShimmerLoading(
                    height: 170, width: 120), // CustomStageCard boyutuna yakın
              )));

  // --- Alt Kart ve İçeriği ---

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
      padding: const EdgeInsets.only(top: 25, bottom: 20),
      margin: const EdgeInsets.only(top: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomDescriptionCard(
                description: showData.description.replaceAll('\\n', '\n')),
            const SizedBox(height: 25),
            const CustomSectionTitle(title: 'Etkinlik Takvimi', fontSize: 22),
            const SizedBox(height: 15),
            if (eventState.isLoading && !eventState.hasData)
              _buildShimmerList()
            else if (eventState.hasData &&
                eventState.dataList!
                    .any((final e) => showData.eventsId.contains(e.id)))
              Column(
                  children: eventState.dataList!
                      .where((final e) => showData.eventsId.contains(e.id))
                      .map((final event) {
                final Stage? stage = stageState.getStageById(event.stageId);
                final stageName = stageState.isLoading && stage == null
                    ? "Yükleniyor..."
                    : (stage?.name ?? "Sahne adı verisi yok");
                return _buildEventCard(event.date.toString(), event.id,
                    showData.id, stageName, "İstanbul");
              }).toList())
            else
              _buildEmptyListWidget('Yaklaşan etkinlik bulunmamaktadır.'),
            const SizedBox(height: 25),
            const CustomSectionTitle(title: 'Ekip', fontSize: 22),
            const SizedBox(height: 10),
            if (playerState.isLoading && nowPlayerDataList.isEmpty)
              _buildShimmerRow()
            else
              _buildNowPlayers(nowPlayerDataList),
            const SizedBox(height: 20),
            const CustomSectionTitle(title: 'Eski Ekip', fontSize: 22),
            const SizedBox(height: 10),
            if (playerState.isLoading && oldPlayerDataList.isEmpty)
              _buildShimmerRow()
            else
              _buildOldPlayers(oldPlayerDataList),
            const SizedBox(height: 25),
            const CustomSectionTitle(title: 'Oyundan Kareler', fontSize: 22),
            const SizedBox(height: 10),
            _buildGamePhotoSection(showData.photosShowId),
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
    final String stageName,
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
        // 1️⃣ Önce LoginState'ten dene
        final loginState = ref.read(loginProvider);
        String? userId = loginState.user?.uid;

        // 2️⃣ Eğer null ise UserState'ten dene
        if (userId == null) {
          final userState = ref.read(userProvider);
          userId = userState.dataSingle?.id;
        }

        // 3️⃣ Hâlâ null ise LocalStorage'dan dene
        userId ??= LocalStorageService.userUid;

        // 4️⃣ Hiçbiri yoksa kullanıcıya uyarı ver veya login'e yönlendir
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Kullanıcı oturumu bulunamadı.")));
          Navigator.of(context).pushReplacementNamed('/login');
        }

        // 5️⃣ Artık güvenle yönlendirebiliriz
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (final context) => SeatSelectionScreen(
                showId: showId, eventId: eventId, customerId: userId!),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      // Tıklama efektinin kenarları için
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                // Gölge daha da yumuşatıldı
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Tarih Kutusu
            Container(
              width: 70,
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
                          color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(width: 15),
            // Etkinlik Bilgisi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stageName,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text("$city • $timeText", // Şehir • Saat
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)
                ],
              ),
            ),
            const SizedBox(width: 10),
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
    if (photoDataList.isEmpty)
      return _buildEmptyListWidget('Oyundan kareler bulunamadı.');

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
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: GestureDetector(
                child: _buildGamePhotoCard(photoUrl),
                onTap: () => _showFullImage(context, photoUrl)),
          );
        },
      ),
    );
  }

  Widget _buildGamePhotoCard(final String? photoUrl) {
    return SizedBox(
      width: 130,
      height: 160,
      child: Card(
        elevation: 6, // Hafif gölge
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias, // Resmin taşmasını engelle
        child: CachedNetworkImage(
            imageUrl: photoUrl ?? '',
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (final context, final url) => const ShimmerLoading(
                width: double.infinity, height: double.infinity),
            errorWidget: (final context, final url, final error) =>
                const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: Colors.grey))),
      ),
    );
  }

  // --- Yardımcı Widget'lar (Boş Liste / Hata) ---
  Widget _buildEmptyListWidget(final String message) {
    return SizedBox(
      height: 100,
      child: Center(
          child: Text(message,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
              textAlign: TextAlign.center)),
    );
  }

  Widget _buildErrorWidget(final String message) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(message,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 15),
              textAlign: TextAlign.center),
        ),
      ),
    );
  }

  // --- Tam Ekran Resim Gösterme Metodu ---
  void _showFullImage(final BuildContext context, final String photoUrl) {
    showDialog(
      context: context,
      builder: (final BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Arka planı şeffaf yap
          insetPadding: EdgeInsets.all(10),
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
                              color: Colors.white, size: 50))),
            ),
          ),
        );
      },
    );
  }
}
