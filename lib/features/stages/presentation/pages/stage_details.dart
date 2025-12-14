import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../shows/presentation/widgets/mobile/show_card.dart';
import '../../../../shared/widgets/custom_title.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../shows/data/datasources/show_remote_data_source_and_impl.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../data/datasources/stage_remote_data_source_and_impl.dart';
import '../../domain/entities/stage.dart';

class StageDetailPage extends StatefulWidget {
  final String stageId;

  const StageDetailPage({super.key, required this.stageId});

  @override
  _StageDetailPageState createState() => _StageDetailPageState();
}

class _StageDetailPageState extends State<StageDetailPage> {
  final firestore = FirebaseFirestore.instance;
  final strorage = FirebaseStorage.instance;
  Stage? _stage;
  final List<Show> _showsDataList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStageData();
  }

  Future<void> _fetchStageData() async {
    try {
      final stageService = StageRemoteDataSourceImpl(firestore: firestore);
      final fetchedStage = await stageService.getStagesByIds([widget.stageId]);

      if (fetchedStage != null) {
        setState(() {
          _stage = fetchedStage.first?.toEntity();
        });
        await _fetchShows();
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri alınırken bir hata oluştu: $error')));
    } finally {
      setState(() {
        _isLoading = false; // Yükleme tamamlandı
      });
    }
  }

  Future<void> _fetchShows() async {
    try {
      final showService =
          ShowRemoteDataSourceImpl(firestore: firestore, storage: strorage);
      if (_stage == null) return;
      final filteredStageIds = _stage?.showsId.toList();
      if (filteredStageIds == null || filteredStageIds.isEmpty) return;
      final shows = await showService.getShowsByIds(filteredStageIds);
      setState(() {
        _showsDataList.addAll(
            shows!.map((final show) => show?.toEntity()).whereType<Show>());
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gösteri verisi alınırken bir hata oluştu: $error')));
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(_stage?.name ?? 'Sahne Detayları'), centerTitle: true),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildStageContent(context));
  }

  Widget _buildStageContent(final BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStageImage(),
          const SizedBox(height: 16),
          _buildStageTitle(),
          const SizedBox(height: 16),
          _buildBottomSheet(context),
        ],
      ),
    );
  }

  Widget _buildStageImage() {
    return AspectRatio(
      aspectRatio: 3 / 3.5,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CachedNetworkImage(
            imageUrl: _stage?.imageUrl ?? '',
            fit: BoxFit.cover,
            placeholder: (final context, final url) => ShimmerLoading(),
            errorWidget: (final context, final url, final error) =>
                const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildStageTitle() {
    return Text(
      _stage?.name ?? '',
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBottomSheet(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          _buildStageInfo(),
          const SizedBox(height: 16),
          const CustomSectionTitle(title: 'Eşleşen Etkinlikler', fontSize: 20),
          _buildShowList(),
          const SizedBox(height: 16),
          //_buildStageMap(_stage),
          const SizedBox(height: 16),
          _buildStageAddress(context),
        ],
      ),
    );
  }

  Widget _buildStageInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(_stage?.description ?? '',
          style: const TextStyle(
              fontSize: 16, height: 1.1, fontWeight: FontWeight.w300)),
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
        ));
  }

  Widget _buildEventCard(final BuildContext context, final Show? show) {
    return GestureDetector(
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
  }

  Widget _buildStageMap(final Stage stage) {
    // Ensure latitude and longitude are not null before using them
    final LatLng position = LatLng(stage.locationLat, stage.locationLng);
    return SizedBox(
      height: 200,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: position,
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('stages-location'),
            position: position,
          ),
        },
      ),
    );
  }

  Widget _buildStageAddress(final BuildContext context) {
    return Row(
      children: [
        _buildInfoSection('Adres', _stage?.address ?? ''),
        const SizedBox(width: 16),
        _buildInfoSection('İletişim Bilgileri', _stage?.communication ?? ''),
      ],
    );
  }

  Widget _buildInfoSection(final String title, final String content) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomSectionTitle(title: title, fontSize: 20),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.1,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
