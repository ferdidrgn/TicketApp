import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/widgets/custom_description_card.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';
import 'package:ticketapp/data/datasources/player/player_remote_data_source_and_impl.dart';
import 'package:ticketapp/data/datasources/show/show_remote_data_source_and_impl.dart';
import 'package:ticketapp/presentation/pages/details_pages/player_details.dart';
import 'package:ticketapp/presentation/pages/details_pages/seat_details.dart';
import '../../../core/util/shimmer.dart';
import '../../../core/widgets/custom_stage_card.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/show.dart';

class ShowDetailPage extends StatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  _ShowDetailPageState createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends State<ShowDetailPage> {
  final firestore = FirebaseFirestore.instance;
  final strorage = FirebaseStorage.instance;
  late final PlayerRemoteDataSourceImpl? playerService;
  Show? showData;
  List<Player?> nowPlayerDataList = [];
  List<Player?> oldPlayerDataList = [];
  List<String?> photoDataList = [];
  bool isLoading = true;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    playerService = PlayerRemoteDataSourceImpl(firestore: firestore);
    _fetchShowData();
  }

  Future<void> _fetchShowData() async {
    try {
      final showService =
          ShowRemoteDataSourceImpl(firestore: firestore, storage: strorage);
      final show = await showService.getShowById(widget.showId);
      if (show != null) {
        setState(() {
          showData = show.toEntity();
          photoDataList = show.photosShowId;
        });
        await _fetchNowPlayers(show.nowPlayersId);
        await _fetchOldPlayers(show.oldPlayersId);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri alınırken bir hata oluştu: $error')));
    } finally {
      setState(() {
        isLoading = false; // Yükleme tamamlandı
      });
    }
  }

  Future<void> _fetchNowPlayers(final List<String>? playersId) async {
    try {
      if (playersId != null) {
        for (final String playerId in playersId) {
          final player = await playerService?.getPlayerById(playerId);
          if (player != null) {
            setState(() {
              nowPlayerDataList.add(player.toEntity());
            });
          }
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Oyuncu verisi alınırken bir hata oluştu: $error')));
    }
  }

  Future<void> _fetchOldPlayers(final List<String>? playersId) async {
    try {
      if (playersId != null) {
        for (final String playerId in playersId) {
          final player = await playerService?.getPlayerById(playerId);
          if (player != null) {
            setState(() {
              oldPlayerDataList.add(player.toEntity());
            });
          }
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Oyuncu verisi alınırken bir hata oluştu: $error')));
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(showData?.name ?? 'Show Detail'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildShowDetails(),
    );
  }

  Widget _buildShowDetails() {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildShowImage(),
          ),
          const SizedBox(height: 16),
          _buildShowTitle(),
          const SizedBox(height: 16),
          _buildBottomSheetCard(context)
        ]));
  }

  Widget _buildShowImage() {
    return AspectRatio(
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
        child: Image.network(
          showData?.imageUrl ?? '',
          fit: BoxFit.cover,
          loadingBuilder: (final context, final child, final loadingProgress) {
            if (loadingProgress == null) return child;
            return const ShimmerLoading();
          },
          errorBuilder: (final context, final error, final stackTrace) {
            return const Center(child: Icon(Icons.error));
          },
        ),
      ),
    );
  }

  Widget _buildShowTitle() {
    return Text(
      showData?.name ?? 'Show Title',
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBottomSheetCard(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
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
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomDescriptionCard(
                description: showData?.description.replaceAll('\\n', '\n') ??
                    'No description available'),
            const SizedBox(height: 20),
            const CustomSectionTitle(title: 'Etkinlik Takvimi', fontSize: 20),
            const SizedBox(height: 16),
            Column(
              children:
                  List.generate(showData?.eventsId.length ?? 0, (final index) {
                return _buildEventCard(
                    "15.04.2004".toString(),
                    "Şubat".toString(),
                    showData!.eventsId[index],
                    'city'.toString());
              }),
            ),
            const SizedBox(height: 20),
            const CustomSectionTitle(title: 'Ekip', fontSize: 20),
            _buildNowPlayers(),
            const SizedBox(height: 10),
            const CustomSectionTitle(title: 'Eski Ekip', fontSize: 20),
            _buildOldPlayers(),
            const SizedBox(height: 20),
            const CustomSectionTitle(title: 'Oyundan Kareler', fontSize: 20),
            _buildGamePhotoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(final String date, final String month,
      final String eventId, final String city) {
    return GestureDetector(
      onTap: () {
        // Koltuk seçimi sayfasına yönlendirme
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (final context) => SeatSelectionScreen(
                  showId: showData?.id ?? '', eventId: eventId)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(1, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Tarih kısmı
            Container(
              width: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(date,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text(month,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("eventName",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  Text(city, style: const TextStyle(fontSize: 14))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNowPlayers() {
    return nowPlayerDataList.isNotEmpty
        ? SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: nowPlayerDataList.length,
              itemBuilder: (final context, final index) {
                return CustomStageCard(
                    text:
                        '${nowPlayerDataList[index]?.firstName ?? ''} ${nowPlayerDataList[index]?.lastName ?? ''}',
                    imageUrl: nowPlayerDataList[index]?.imageUrl ?? '',
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (final context) => PlayerDetailPage(
                                  playerId:
                                      nowPlayerDataList[index]?.id ?? '')));
                    });
              },
            ),
          )
        : const Center(
            child: Text('Oyuncu bilgisi mevcut değil.'),
          );
  }

  Widget _buildOldPlayers() {
    return oldPlayerDataList.isNotEmpty
        ? SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: oldPlayerDataList.length,
              itemBuilder: (final context, final index) {
                return Stack(children: [
                  CustomStageCard(
                    text:
                        '${oldPlayerDataList[index]?.firstName ?? ''} ${oldPlayerDataList[index]?.lastName ?? ''}',
                    imageUrl: oldPlayerDataList[index]?.imageUrl ?? '',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (final context) => PlayerDetailPage(
                                playerId: oldPlayerDataList[index]?.id ?? '')),
                      );
                    },
                  ),
                  Positioned.fill(
                      child: IgnorePointer(
                          ignoring: true,
                          child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(70),
                                  color: Colors.grey.withOpacity(0.5)))))
                ]);
              },
            ),
          )
        : const Center(child: Text('Oyuncu bilgisi mevcut değil.'));
  }

  Widget _buildGamePhotoSection() {
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: photoDataList.length,
        itemBuilder: (final context, final index) {
          final photoUrl = photoDataList[index] ?? '';
          return GestureDetector(
            child: _buildGamePhotoCard(photoUrl),
            onTap: () {
              _showFullImage(context, photoUrl); // Tıklayınca tam ekran göster
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
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.network(
            photoUrl ?? '',
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (final context, final child, final loadingProgress) {
              if (loadingProgress == null) return child;
              return const ShimmerLoading();
            },
            errorBuilder: (final context, final error, final stackTrace) {
              return const Center(child: Icon(Icons.error));
            },
          ),
        ),
      ),
    );
  }

// Tam boyutlu görseli gösteren dialog
  void _showFullImage(final BuildContext context, final String photoUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      // Tıklayınca kapansın
      barrierLabel: 'Tam Ekran Görsel',
      barrierColor: Colors.black.withOpacity(0.3),
      pageBuilder: (final context, final _, final __) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop(); // Ekrana tıklayınca dialog kapansın
          },
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.3),
            // Arkaplan rengini ayarlamak için
            body: Center(
              child: InteractiveViewer(
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain, // Görseli tam boyutta göster
                  loadingBuilder: (final context, final child, final loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const ShimmerLoading();
                  },
                  errorBuilder: (final context, final error, final stackTrace) {
                    return const Center(child: Icon(Icons.error));
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
