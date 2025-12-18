import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/features/teams/data/datasources/team_remote_data_source_and_impl.dart';
import '../../../../shared/widgets/custom_description_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../shows/data/datasources/show_remote_data_source_and_impl.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/widgets/mobile/show_card.dart';
import '../../domain/entities/team.dart';

class TeamDetailsPage extends StatefulWidget {
  final String teamId;

  const TeamDetailsPage({super.key, required this.teamId});

  @override
  _TeamDetailsPageState createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends State<TeamDetailsPage> {
  final firestore = FirebaseFirestore.instance;
  final strorage = FirebaseStorage.instance;
  late final Team? team;
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
      final teamService = TeamRemoteDataSourceImpl(firestore: firestore);
      final fetchedTeam = await teamService.getTeamsByIds([widget.teamId]);
      setState(() {
        team = fetchedTeam?.first?.toEntity();
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
    try {
      final showService =
          ShowRemoteDataSourceImpl(firestore: firestore, storage: strorage);
      final filteredTeamIds = team?.showsId.toList();
      if (filteredTeamIds == null || filteredTeamIds.isEmpty) return;
      final shows = (await showService.getShowsByIds(filteredTeamIds));
      setState(() {
        _showsDataList
            .addAll(shows?.map((final show) => show?.toEntity()) ?? []);
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gösteri verisi alınırken bir hata oluştu: $error')));
    }
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(team?.name ?? 'Ekip Detayları'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTeamDetails());

  Widget _buildTeamDetails() => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(16), child: _buildTeamImage()),
        const SizedBox(height: 16),
        SectionHeader(title: team?.name ?? 'Ekip Adı', fontSize: 28),
        const SizedBox(height: 16),
        CustomDescriptionCard(
            description: team?.description.replaceAll('\\n', '\n') ??
                'No description available'),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Gösteriler', fontSize: 20),
        _buildShowList(),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Takım Fotoğrafları', fontSize: 20),
        _buildPhotosSection()
      ]));

  Widget _buildTeamImage() => AspectRatio(
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
            placeholder: (final context, final url) => ShimmerLoading(),
            errorWidget: (final context, final url, final error) =>
                const Icon(Icons.error),
          ),
        ),
      );

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

  Widget _buildEventCard(final BuildContext context, final Show? show) =>
      GestureDetector(
          child: ShowCard(
              imageUrl: show?.imageUrl ?? 'https://via.placeholder.com/150',
              gameName: show?.name ?? 'No Name',
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (final context) =>
                            ShowDetailPage(showId: show?.id ?? '')));
              }));

  Widget _buildPhotosSection() => SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: team?.photosId.length ?? 0,
        itemBuilder: (final context, final index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CachedNetworkImage(
            imageUrl: team?.photosId[index] ?? "",
            placeholder: (final context, final url) => ShimmerLoading(),
            errorWidget: (final context, final url, final error) =>
                const Icon(Icons.error),
          ),
        ),
      ));
}
