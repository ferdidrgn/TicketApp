import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ticketapp/presentation/pages/details_pages/show_details.dart';
import '../../../core/widgets/custom_show_card.dart';
import '../../../core/widgets/custom_title.dart';
import '../../../data/model/show.dart';
import '../../../data/model/stage.dart';
import '../../../data/repository/show_service.dart';
import '../../../data/repository/stage_service.dart';

class StageDetailPage extends StatefulWidget {
  final String stageId;

  const StageDetailPage({super.key, required this.stageId});

  @override
  _StageDetailPageState createState() => _StageDetailPageState();
}

class _StageDetailPageState extends State<StageDetailPage> {
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
      final Stage? fetchedStage =
          await StageService().getStageById(widget.stageId);

      if (fetchedStage != null) {
        setState(() {
          _stage = fetchedStage;
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
    for (final String showId in _stage?.showsId ?? []) {
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
            placeholder: (final context, final url) => const CircularProgressIndicator(),
            errorWidget: (final context, final url, final error) => const Icon(Icons.error),
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

  Widget _buildStageMap(final Stage stage) {
    // Ensure latitude and longitude are not null before using them
    if (stage.locationLat != null && stage.locationLng != null) {
      final LatLng position = LatLng(stage.locationLat!, stage.locationLng!);
      return SizedBox(
        height: 200,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: position,
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('stage-location'),
              position: position,
            ),
          },
        ),
      );
    } else {
      return const Center(child: Text('Konum bilgisi mevcut değil.'));
    }
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
