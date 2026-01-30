import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/widgets/mobile/show_card.dart';
import '../providers/stage_detail_provider.dart';

class StageDetailPage extends ConsumerStatefulWidget {
  final String stageId;

  const StageDetailPage({super.key, required this.stageId});

  @override
  ConsumerState<StageDetailPage> createState() => _StageDetailPageState();
}

class _StageDetailPageState extends ConsumerState<StageDetailPage>
    with GlobalScrollMixin {
  @override
  void onLoadMore() {} // Mixin gereksinimi

  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(stageDetailProvider(widget.stageId));

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      customScrollController: scrollController,
      isLoading: detailAsync.isLoading,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.scaffoldBackgroundColor,
        safeAreaTop: false, // Görselin yukarı sızması için
      ),
      child: detailAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (final err, final _) =>
            Center(child: Text('Veri yüklenemedi: $err')),
        data: (final state) => _buildSliverContent(context, state),
      ),
    );
  }

  Widget _buildSliverContent(
      final BuildContext context, final StageDetailState state) {
    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Geri butonu için üstten boşluk bırakıyoruz
        SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.top + 70)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildStageImage(state.stage.imageUrl),
                const SizedBox(height: 24),
                _buildStageTitle(state.stage.name),
                const SizedBox(height: 24),

                // Detay İçeriği
                _buildStageInfo(state.stage.description),
                const SizedBox(height: 16),

                if (state.shows.isNotEmpty) ...[
                  _buildSectionLabel(
                      context, 'Eşleşen Etkinlikler', Icons.event_seat_rounded),
                  const SizedBox(height: 16),
                  _buildShowList(state.shows),
                  const SizedBox(height: 24),
                ],

                _buildSectionLabel(context, 'Konum', Icons.map_outlined),
                const SizedBox(height: 16),
                _buildStageMap(
                    state.stage.locationLat, state.stage.locationLng),
                const SizedBox(height: 16),

                _buildStageAddress(
                    context, state.stage.address, state.stage.communication),
                const SizedBox(height: 120), // FAB payı
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(
      final BuildContext context, final String title, final IconData icon) {
    return Row(
      children: [
        Icon(icon, color: context.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: context.textTheme.labelLarge?.copyWith(
            color: context.primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

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
    // Koordinatlar geçersizse (0,0 geliyorsa) haritayı hiç gösterme
    if (lat == 0 && lng == 0) return const SizedBox.shrink();

    final LatLng position = LatLng(lat, lng);
    return SizedBox(
      height: 250, // Biraz daha belirgin yükseklik
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: GoogleMap(
            // Harita tipini belirleyebiliriz
            mapType: MapType.normal,
            // Zoom ve kaydırma kontrollerini Sliver içinde çakışmaması için optimize edelim
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            // Sliver Scroll ile haritanın kendi scroll'unun çakışmasını önlemek için:
            gestureRecognizers: const {},
            initialCameraPosition: CameraPosition(target: position, zoom: 15),
            markers: {
              Marker(
                markerId: const MarkerId('stage-location'),
                position: position,
                infoWindow: const InfoWindow(title: "Mekan Konumu"),
              ),
            },
          ),
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
