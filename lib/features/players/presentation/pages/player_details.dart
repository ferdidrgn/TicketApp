import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/features/shows/data/datasources/show_remote_data_source_and_impl.dart';
import '../../../../shared/widgets/custom_title.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/widgets/mobile/custom_show_card.dart';
import '../../data/datasources/player_remote_data_source_and_impl.dart';
import '../../domain/entities/player.dart';

class PlayerDetailPage extends StatefulWidget {
  final String playerId;

  const PlayerDetailPage({super.key, required this.playerId});

  @override
  _PlayerDetailPageState createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage> {
  Player? player;
  final List<Show> nowShowsDataList = [];
  final List<Show> oldShowsDataList = [];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  bool isLoading = true;
  bool hasError = false;
  double _sheetProgress = 0.1;

  @override
  void initState() {
    super.initState();
    _fetchPlayerData();
  }

  Future<void> _fetchPlayerData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final fetchedPlayer =
          (await PlayerRemoteDataSourceImpl(firestore: firestore)
                  .getPlayersByIds([widget.playerId]))
              ?.first;

      if (fetchedPlayer != null) {
        setState(() => player = fetchedPlayer.toEntity());

        await Future.wait([
          _fetchShows(player!.nowShowsId, nowShowsDataList),
          _fetchShows(player!.oldShowsId, oldShowsDataList),
        ]);
      }
    } catch (error) {
      _showErrorSnackbar('Veri alınırken bir hata oluştu: $error');
      setState(() => hasError = true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchShows(
      final List<String>? showsIds, final List<Show> showsList) async {
    if (showsIds == null || showsIds.isEmpty) return;

    try {
      final shows =
          await ShowRemoteDataSourceImpl(firestore: firestore, storage: storage)
              .getShowsByIds(showsIds);

      setState(() {
        showsList.addAll(
            shows?.map((final e) => e?.toEntity()).toList().whereType<Show>() ??
                []);
      });
    } catch (error) {
      _showErrorSnackbar('Gösteri verisi alınırken bir hata oluştu: $error');
    }
  }

  void _showErrorSnackbar(final String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            player != null
                ? '${player!.firstName} ${player!.lastName}'
                : 'Oyuncu Detayı',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
                ? _buildErrorContent()
                : _buildContent(),
      );

  Widget _buildErrorContent() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'İnternet bağlantısı yok',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Bağlantı kurulunca otomatik olarak yenilenecek.'),
            ],
          ),
        ),
      );

  Widget _buildContent() => SafeArea(
        child: Stack(
          children: [
            _buildTopSection(),
            DraggableScrollableSheet(
              initialChildSize: 0.1,
              minChildSize: 0.1,
              maxChildSize: 0.8,
              builder: (final context, final scrollController) =>
                  NotificationListener<DraggableScrollableNotification>(
                onNotification: (final notification) {
                  setState(() => _sheetProgress = notification.extent);
                  return true;
                },
                child: _buildBottomSheet(scrollController),
              ),
            ),
          ],
        ),
      );

  Widget _buildBottomSheet(final ScrollController scrollController) =>
      Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              _buildArrowIcon(),
              const SizedBox(height: 24),
              _buildPlayerBio(),
              const SizedBox(height: 24),
              const CustomSectionTitle(title: "Gösterileri"),
              SizedBox(
                  height: 200, child: _buildShowsSection(nowShowsDataList)),
              const SizedBox(height: 10),
              const CustomSectionTitle(title: "Eski Gösterileri"),
              SizedBox(
                  height: 200, child: _buildShowsSection(oldShowsDataList)),
            ],
          ));

  Widget _buildTopSection() {
    final imageSize = 250 - (130 * _sheetProgress);
    final topPosition =
        MediaQuery.of(context).size.height * 0.30 * (0.8 - _sheetProgress);

    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: imageSize,
            height: imageSize,
            child: _buildPlayerImage(),
          ),
          const SizedBox(height: 16),
          Opacity(opacity: 1 - _sheetProgress, child: _buildPlayerName()),
          const SizedBox(height: 16),
          Opacity(opacity: 1 - _sheetProgress, child: _buildPlayerBio()),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPlayerImage() => Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(75)),
        border:
            Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(75)),
        child: player?.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: player!.imageUrl,
                fit: BoxFit.cover,
                placeholder: (final _, final __) => const ShimmerLoading(),
                errorWidget: (final _, final __, final ___) =>
                    const Icon(Icons.error),
              )
            : const Icon(Icons.person, size: 50),
      ));

  Widget _buildPlayerName() =>
      Text('${player?.firstName ?? ''} ${player?.lastName ?? ''}',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w500),
          textAlign: TextAlign.center);

  Widget _buildPlayerBio() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(player?.bio ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center));

  Widget _buildShowsSection(final List<Show> showsList) {
    if (showsList.isEmpty) return Center(child: Text('Gösteri bulunamadı.'));

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: showsList.length,
      itemBuilder: (final context, final index) {
        final show = showsList[index];
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CustomVerticalShowCard(
            imageUrl: show.imageUrl,
            gameName: show.name,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (final _) => ShowDetailPage(showId: show.id)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildArrowIcon() => Container(
      alignment: Alignment.center,
      child: Icon(
          _sheetProgress == 0.1
              ? Icons.keyboard_double_arrow_up
              : Icons.keyboard_double_arrow_down,
          size: 30,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)));
}
