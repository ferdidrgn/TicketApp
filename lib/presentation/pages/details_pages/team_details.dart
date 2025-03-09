import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';
import 'package:ticketapp/presentation/pages/details_pages/show_details.dart';
import '../../../core/widgets/custom_description_card.dart';
import '../../../core/widgets/custom_show_card.dart';
import '../../../data/model/show_model.dart';
import '../../../data/model/team.dart';
import '../../../data/repository/show_service.dart';
import '../../../data/repository/team_service.dart';

class TeamDetailsPage extends StatefulWidget {
  final String teamId;

  const TeamDetailsPage({super.key, required this.teamId});

  @override
  _TeamDetailsPageState createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends State<TeamDetailsPage> {
  Team? team;
  final List<Show?> _showsDataList = [];
  bool isLoading = true;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchTeamDetails();
  }

  Future<void> _fetchTeamDetails() async {
    try {
      final TeamService teamService = TeamService();
      final fetchedTeam = await teamService.getTeamById(widget.teamId);
      setState(() {
        team = fetchedTeam;
      });
      await _fetchShows();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri alınırken bir hata oluştu: $error')));
    } finally {
      setState(() {
        isLoading = false; // Yükleme tamamlandı
      });
    }
  }

  Future<void> _fetchShows() async {
    for (final String showId in team?.showsId ?? []) {
      try {
        final Show? show = await ShowService().getShowById(showId);
        if (show != null) {
          setState(() {
            _showsDataList.add(show);
          });
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gösteri verisi alınırken bir hata oluştu: $error')));
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(team?.name ?? 'Ekip Detayları'), centerTitle: true),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildTeamDetails());
  }

  Widget _buildTeamDetails() {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
              padding: const EdgeInsets.all(16), child: _buildTeamImage()),
          const SizedBox(height: 16),
          CustomSectionTitle(title: team?.name ?? 'Ekip Adı', fontSize: 28),
          const SizedBox(height: 16),
          CustomDescriptionCard(
              description: team?.description.replaceAll('\\n', '\n') ??
                  'No description available'),
          const SizedBox(height: 16),
          const CustomSectionTitle(title: 'Gösteriler', fontSize: 20),
          _buildShowList(),
          const SizedBox(height: 16),
          const CustomSectionTitle(title: 'Takım Fotoğrafları', fontSize: 20),
          _buildPhotosSection()
        ]));
  }

  Widget _buildTeamImage() {
    return AspectRatio(
      aspectRatio: 16 / 9,
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
          imageUrl: team?.imageUrl ?? '',
          fit: BoxFit.cover,
          placeholder: (final context, final url) =>
              const CircularProgressIndicator(),
          errorWidget: (final context, final url, final error) =>
              const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildShowList() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _showsDataList.length,
        itemBuilder: (final context, final index) =>
            _buildEventCard(context, _showsDataList[index]),
      ),
    );
  }

  Widget _buildEventCard(final BuildContext context, final Show? show) {
    return GestureDetector(
        child: CustomVerticalShowCard(
            imageUrl: show?.imageUrl ?? 'https://via.placeholder.com/150',
            gameName: show?.name ?? 'No Name',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (final context) =>
                          ShowDetailPage(showId: show?.id ?? '')));
            }));
  }

  Widget _buildPhotosSection() {
    return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: team!.photosId.length,
          itemBuilder: (final context, final index) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CachedNetworkImage(
                imageUrl: team!.photosId[index],
                placeholder: (final context, final url) => const CircularProgressIndicator(),
                errorWidget: (final context, final url, final error) => const Icon(Icons.error),
              ),
            );
          },
        ));
  }
}
