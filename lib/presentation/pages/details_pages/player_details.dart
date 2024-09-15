import 'package:flutter/material.dart';
import 'package:ticketapp/core/custom_views/custom_title.dart';
import 'package:ticketapp/presentation/pages/details_pages/show_details.dart';
import 'package:ticketapp/core/custom_views/custom_show_card.dart';
import '../../../data/repository/player_service.dart';
import '../../../data/repository/show_service.dart';
import '../../../data/model/player.dart';
import '../../../data/model/show.dart';

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

  final PlayerService _playerService = PlayerService();
  final ShowService _showService = ShowService();

  @override
  void initState() {
    super.initState();
    _fetchPlayerData();
  }

  Future<void> _fetchPlayerData() async {
    try {
      final Player? fetchedPlayer =
          await _playerService.getPlayerById(widget.playerId);

      if (fetchedPlayer?.nowShowsId != null) {
        setState(() {
          player = fetchedPlayer;
        });
        _fetchNowShows(player?.nowShowsId ?? []);
        _fetchOldShows(player?.oldShowsId ?? []);
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

  Future<void> _fetchNowShows(List<String> showsId) async {
    for (String showId in showsId) {
      try {
        var show = await _showService.getShowById(showId);
        if (show != null) {
          setState(() {
            nowShowsDataList.add(show);
          });
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gösteri verisi alınırken bir hata oluştu: $error')));
      }
    }
  }

  Future<void> _fetchOldShows(List<String> showsId) async {
    for (String showId in showsId) {
      try {
        var show = await _showService.getShowById(showId);
        if (show != null) {
          setState(() {
            oldShowsDataList.add(show);
          });
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gösteri verisi alınırken bir hata oluştu: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(player != null
              ? '${player?.firstName} ${player?.lastName}'
              : 'Player Details'),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildTopSection(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: _buildBottomSection(),
                        ),
                      ],
                    ))));
  }

  Widget _buildTopSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        _buildPlayerImage(),
        const SizedBox(height: 16),
        _buildPlayerName(),
        const SizedBox(height: 16)
      ],
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.only(top: 20),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlayerBio(),
            const SizedBox(height: 24),
            const CustomSectionTitle(title: "Gösterileri"),
            _buildNowGamesSection(),
            const SizedBox(height: 10),
            const CustomSectionTitle(title: "Eski Gösterileri"),
            _buildOldGamesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerImage() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(75)),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(75)),
        child: player?.imageUrl != null
            ? Image.network(
                player!.imageUrl!,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.person, size: 50), // Placeholder for no image
      ),
    );
  }

  Widget _buildPlayerName() {
    return Text(
      '${player?.firstName} ${player?.lastName}',
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPlayerBio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        player!.bio,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNowGamesSection() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: nowShowsDataList.length,
        itemBuilder: (context, index) {
          final show = nowShowsDataList[index];
          return CustomVerticalShowCard(
            imageUrl: show?.imageUrl ?? '',
            gameName: show?.name ?? '',
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ShowDetailPage(showId: show?.id ?? '')),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOldGamesSection() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: oldShowsDataList.length,
        itemBuilder: (context, index) {
          final show = oldShowsDataList[index];
          return CustomVerticalShowCard(
            imageUrl: show?.imageUrl ?? '',
            gameName: show?.name ?? '',
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ShowDetailPage(showId: show?.id ?? '')),
              );
            },
          );
        },
      ),
    );
  }
}
