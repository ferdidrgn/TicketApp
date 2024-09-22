import 'package:flutter/material.dart';
import '../../../data/model/team.dart';
import '../../../data/repository/team_service.dart';

class TeamDetailsPage extends StatefulWidget {
  final String teamId;

  const TeamDetailsPage({super.key, required this.teamId});

  @override
  _TeamDetailsPageState createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends State<TeamDetailsPage> {
  Team? team;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeamDetails();
  }

  Future<void> _fetchTeamDetails() async {
    TeamService teamService = TeamService();
    final fetchedTeam = await teamService.getTeamById(widget.teamId);
    setState(() {
      team = fetchedTeam;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Takım Detayları')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : team == null
          ? const Center(child: Text('Takım bulunamadı.'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(team!.imageUrl, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text(
              team!.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(team!.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            _buildPhotosSection(),
            _buildShowsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Takım Fotoğrafları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: team!.photosId.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.network(team!.photosId[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShowsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Takım Gösterileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Column(
          children: team!.showsId.map((showId) {
            return ListTile(
              title: Text('Show ID: $showId'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // Gösteri detaylarına gitmek için tıklama işlevi
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
