import 'package:flutter/material.dart';
import 'package:ticketapp/core/custom_views/custom_show_card.dart';
import 'package:ticketapp/core/custom_views/custom_title.dart';
import 'package:ticketapp/presentation/pages/details_pages/show_details.dart';
import '../../../data/model/player.dart';
import '../../../data/model/show.dart';
import '../../../data/repository/player_service.dart';
import '../../../data/repository/show_service.dart';

class PlayerDetailPage extends StatefulWidget {
  final String playerId;

  const PlayerDetailPage({super.key, required this.playerId});

  @override
  _PlayerDetailPageState createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage> {
  Player? player;
  List<Show?> nowShowsDataList = [];
  List<Show?> oldShowsDataList = [];
  bool isLoading = true;
  double _sheetProgress = 0.1;

  @override
  void initState() {
    super.initState();
    _fetchPlayerData();
  }

  Future<void> _fetchPlayerData() async {
    try {
      final fetchedPlayer = await PlayerService().getPlayerById(widget.playerId);
      if (fetchedPlayer?.nowShowsId != null) {
        setState(() {
          player = fetchedPlayer;
        });
        await Future.wait([
          _fetchShows(player!.nowShowsId, nowShowsDataList),
          _fetchShows(player!.oldShowsId, oldShowsDataList),
        ]);
      }
    } catch (error) {
      _showErrorSnackbar('Veri alınırken bir hata oluştu: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchShows(final List<String> showsId, final List<Show?> showsList) async {
    for (final String showId in showsId) {
      try {
        final show = await ShowService().getShowById(showId);
        if (show != null) {
          setState(() {
            showsList.add(show);
          });
        }
      } catch (error) {
        _showErrorSnackbar('Gösteri verisi alınırken bir hata oluştu: $error');
      }
    }
  }

  void _showErrorSnackbar(final String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(player != null
            ? '${player!.firstName} ${player!.lastName}'
            : 'Player Details'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  _buildTopSection(),
                  DraggableScrollableSheet(
                    initialChildSize: 0.1,
                    minChildSize: 0.1,
                    maxChildSize: 0.8,
                    builder: (final context, final scrollController) {
                      return NotificationListener<
                          DraggableScrollableNotification>(
                        onNotification: (final notification) {
                          setState(() {
                            _sheetProgress = notification.extent;
                          });
                          return true;
                        },
                        child: _buildBottomSheet(scrollController),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBottomSheet(final ScrollController scrollController) {
    return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        child: Expanded(
            child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildArrowIcon(),
                      const SizedBox(height: 24),
                      _buildPlayerBio(),
                      const SizedBox(height: 24),
                      const CustomSectionTitle(title: "Gösterileri"),
                      _buildShowsSection(nowShowsDataList),
                      const SizedBox(height: 10),
                      const CustomSectionTitle(title: "Eski Gösterileri"),
                      _buildShowsSection(oldShowsDataList),
                    ]))));
  }

  Widget _buildTopSection() {
    final double imageSize = 250 - (130 * _sheetProgress);
    final double topPosition =
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

  Widget _buildPlayerImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(75)),
        border:
            Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(75)),
        child: player?.imageUrl != null
            ? Image.network(player!.imageUrl!, fit: BoxFit.cover)
            : const Icon(Icons.person, size: 50),
      ),
    );
  }

  Widget _buildPlayerName() {
    return Text('${player?.firstName} ${player?.lastName}',
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center);
  }

  Widget _buildPlayerBio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        player?.bio ?? '',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildShowsSection(final List<Show?> showsList) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: showsList.length,
        itemBuilder: (final context, final index) {
          final show = showsList[index];
          return CustomVerticalShowCard(
            imageUrl: show?.imageUrl ?? '',
            gameName: show?.name ?? '',
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (final context) =>
                        ShowDetailPage(showId: show?.id ?? '')),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildArrowIcon() {
    return Container(
      alignment: Alignment.center,
      child: Icon(
        _sheetProgress == 0.1
            ? Icons.keyboard_double_arrow_up
            : Icons.keyboard_double_arrow_down,
        size: 30,
        color: Colors.black,
      ),
    );
  }
}
