import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/widgets/mobile/show_card.dart';
import '../providers/stage_detail_provider.dart';

class StageDetailPage extends ConsumerWidget {
  final String stageId;

  const StageDetailPage({super.key, required this.stageId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final detailAsync = ref.watch(stageDetailProvider(stageId));

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.when(
          data: (final state) => Text(state.stage.name),
          loading: () => const Text('Yükleniyor...'),
          error: (final _, final __) => const Text('Hata'),
        ),
        centerTitle: true,
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final err, final stack) =>
            Center(child: Text('Veri yüklenemedi: $err')),
        data: (final state) => _buildStageContent(context, state),
      ),
    );
  }

  Widget _buildStageContent(
          final BuildContext context, final StageDetailState state) =>
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildStageImage(state.stage.imageUrl),
            const SizedBox(height: 16),
            _buildStageTitle(state.stage.name),
            const SizedBox(height: 16),
            _buildStageDetailsContainer(context, state),
          ],
        ),
      );

  Widget _buildStageImage(final String imageUrl) => AspectRatio(
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
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (final context, final url) => const ShimmerLoading(),
              errorWidget: (final context, final url, final error) =>
                  const Icon(Icons.error),
            ),
          ),
        ),
      );

  Widget _buildStageTitle(final String name) => Text(
        name,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      );

  Widget _buildStageDetailsContainer(
          final BuildContext context, final StageDetailState state) =>
      Container(
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
            _buildStageInfo(state.stage.description),
            const SizedBox(height: 16),
            if (state.shows.isNotEmpty) ...[
              const SectionHeader(title: 'Eşleşen Etkinlikler', fontSize: 20),
              _buildShowList(state.shows),
              const SizedBox(height: 16),
            ],
            _buildStageMap(state.stage.locationLat, state.stage.locationLng),
            const SizedBox(height: 16),
            _buildStageAddress(
                context, state.stage.address, state.stage.communication),
          ],
        ),
      );

  Widget _buildStageInfo(final String description) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          description,
          style: const TextStyle(
              fontSize: 16, height: 1.1, fontWeight: FontWeight.w300),
        ),
      );

  Widget _buildShowList(final List<Show> shows) => SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: shows.length,
          itemBuilder: (final context, final index) =>
              _buildEventCard(context, shows[index]),
        ),
      );

  Widget _buildEventCard(final BuildContext context, final Show show) =>
      GestureDetector(
        child: ShowCard(
          imageUrl: show.imageUrl,
          gameName: show.name,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (final context) => ShowDetailPage(showId: show.id),
              ),
            );
          },
        ),
      );

  Widget _buildStageMap(final double lat, final double lng) {
    final LatLng position = LatLng(lat, lng);
    return SizedBox(
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: 15),
          markers: {
            Marker(
                markerId: const MarkerId('stage-location'), position: position),
          },
        ),
      ),
    );
  }

  Widget _buildStageAddress(final BuildContext context, final String address,
          final String communication) =>
      Row(
        children: [
          _buildInfoSection('Adres', address),
          const SizedBox(width: 16),
          _buildInfoSection('İletişim Bilgileri', communication),
        ],
      );

  Widget _buildInfoSection(final String title, final String content) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: title, fontSize: 20),
            Text(
              content,
              style: const TextStyle(
                  fontSize: 16, height: 1.1, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      );
}
