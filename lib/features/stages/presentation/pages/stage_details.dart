import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../favorite/presentation/widgets/favorite_toggle_button.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/widgets/mobile/show_card.dart';
import '../../../users/domain/entities/favorite_type.dart';
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
  void onLoadMore() {}

  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(stageDetailProvider(widget.stageId));
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      // 🎯 MERKEZİ HEADER: Başlık ve alt başlık artık sistemden geliyor
      title: detailAsync.value?.stage.name.toUpperCase() ?? 'SAHNE DETAYI',
      subtitle: 'Şehrin en iyi sahnelerini keşfedin...',
      rightIcon: Icons.stadium_rounded,
      customScrollController: scrollController,
      isLoading: detailAsync.isLoading,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        ambientColor: context.colors.primary.withOpacity(0.05),
        safeAreaTop: true, // Header'ın status bar altında kalmaması için true
      ),
      child: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final err, final _) =>
            Center(child: Text('Veri yüklenemedi: $err')),
        data: (final state) => Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isLargeScreen ? 800 : double.infinity),
            child: CustomScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildStageImage(state.stage.imageUrl, widget.stageId),
                      const SizedBox(height: 32),

                      // 📖 MEKAN HİKAYESİ
                      _buildSectionLabel(
                          context, 'HAKKINDA', Icons.info_outline_rounded),
                      const SizedBox(height: 12),
                      _buildStageInfo(state.stage.description),
                      const SizedBox(height: 40),

                      // 🎬 ETKİNLİKLER
                      if (state.shows.isNotEmpty) ...[
                        _buildSectionLabel(context, 'SAHNELENEN ESERLER',
                            Icons.event_seat_rounded),
                        const SizedBox(height: 16),
                        _buildShowList(state.shows),
                        const SizedBox(height: 40),
                      ],

                      // 📍 KONUM VE ADRES
                      _buildSectionLabel(
                          context, 'LOKASYON', Icons.map_outlined),
                      const SizedBox(height: 16),
                      _buildStageMap(
                          state.stage.locationLat, state.stage.locationLng),
                      const SizedBox(height: 24),
                      _buildAddressSection(context, state.stage.address,
                          state.stage.communication),

                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI BİLEŞENLERİ ---

  Widget _buildStageImage(final String imageUrl, final String stageId) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                height: 400,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (final _, final __) => const ShimmerLoading(),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: FavoriteToggleButton(
                    itemId: stageId,
                    type: FavoriteType.stage,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildStageInfo(final String description) => Text(
        description,
        style: const TextStyle(
            fontSize: 16, height: 1.6, fontWeight: FontWeight.w400),
      );

  Widget _buildShowList(final List<Show> shows) => SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: shows.length,
          itemBuilder: (final context, final index) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ShowCard(
              imageUrl: shows[index].imageUrl,
              gameName: shows[index].name,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (final _) =>
                          ShowDetailPage(showId: shows[index].id))),
            ),
          ),
        ),
      );

  Widget _buildStageMap(final double lat, final double lng) {
    if (lat == 0 && lng == 0) return const SizedBox.shrink();
    final LatLng position = LatLng(lat, lng);
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: 15),
          markers: {
            Marker(markerId: const MarkerId('stage'), position: position)
          },
          zoomControlsEnabled: false,
          scrollGesturesEnabled: false, // Sayfa scroll'u ile çakışmaması için
        ),
      ),
    );
  }

  Widget _buildAddressSection(final BuildContext context, final String address,
          final String communication) =>
      Column(
        children: [
          _buildInfoTile(
              context, Icons.location_on_rounded, 'Açık Adres', address),
          const SizedBox(height: 16),
          _buildInfoTile(
              context, Icons.phone_in_talk_rounded, 'İletişim', communication),
        ],
      );

  Widget _buildInfoTile(final BuildContext context, final IconData icon,
          final String title, final String content) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(content,
                    style: TextStyle(
                        color: context.colors.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      );

  Widget _buildSectionLabel(final BuildContext context, final String title,
          final IconData icon) =>
      Row(
        children: [
          Icon(icon, color: context.colors.primary, size: 22),
          const SizedBox(width: 12),
          Text(title,
              style: context.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      );
}
