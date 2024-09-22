import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ticketapp/presentation/pages/details_pages/show_details.dart';
import '../../../core/custom_views/custom_show_card.dart';
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
  late Stage _stage;
  final List<Show> _showsDataList = [];
  bool _isLoading = true;

  final StageService _stageService = StageService();
  final ShowService _showService = ShowService();

  @override
  void initState() {
    super.initState();
    _fetchStageData();
  }

  Future<void> _fetchStageData() async {
    try {
      final Stage? fetchedStage =
          await _stageService.getStageById(widget.stageId);

      if (fetchedStage != null) {
        setState(() {
          _stage = fetchedStage;
        });
        _fetchShows(fetchedStage.showsId ?? []);
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

  Future<void> _fetchShows(List<String> showsId) async {
    for (String showId in showsId) {
      try {
        final Show? show = await _showService.getShowById(showId);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildStageContent(context),
      ),
    );
  }

  Widget _buildStageContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStageImage(_stage),
          const SizedBox(height: 16),
          _buildStageTitle(_stage),
          const SizedBox(height: 16),
          _buildBottomSheet(context),
        ],
      ),
    );
  }

  Widget _buildStageImage(Stage stage) {
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
            imageUrl: stage.imageUrl ?? '',
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
                const Center(child: Icon(Icons.error, color: Colors.red)),
          ),
        ),
      ),
    );
  }

  Widget _buildStageTitle(Stage stage) {
    return Text(
      stage.name ?? '',
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
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
          _buildStageInfo(_stage),
          const SizedBox(height: 16),
          _buildShowList(),
          const SizedBox(height: 16),
          //_buildStageMap(_stage),
          const SizedBox(height: 16),
          _buildStageAddress(context, _stage),
        ],
      ),
    );
  }

  Widget _buildStageInfo(Stage stage) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        stage.description ?? '',
        style: const TextStyle(
            fontSize: 16, height: 1.1, fontWeight: FontWeight.w300),
      ),
    );
  }

  Widget _buildShowList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Eşleşen Etkinlikler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _showsDataList.length,
            itemBuilder: (context, index) =>
                _buildEventCard(context, _showsDataList[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, Show? show) {
    return GestureDetector(
        child: CustomVerticalShowCard(
            imageUrl: show?.imageUrl ?? 'https://via.placeholder.com/150',
            gameName: show?.name ?? 'No Name',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ShowDetailPage(showId: show?.id ?? '')));
            }));
  }

  Widget _buildStageMap(Stage stage) {
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

  Widget _buildStageAddress(BuildContext context, Stage stage) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(stage.address ?? '',
                  style: const TextStyle(
                      fontSize: 16, height: 1.1, fontWeight: FontWeight.w300)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(stage.communication ?? '',
                  style: const TextStyle(
                      fontSize: 16, height: 1.1, fontWeight: FontWeight.w300)),
            ],
          ),
        ),
      ],
    );
  }
}
