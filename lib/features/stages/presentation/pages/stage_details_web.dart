import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/widgets/bento/bento_primitives.dart';
import '../../../favorite/presentation/widgets/favorite_toggle_button.dart';
import '../../../home/presentation/widgets/web/landing/landing_palette.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page.dart';
import '../../../users/domain/entities/favorite_type.dart';
import '../providers/stage_detail_provider.dart';

/// 🏛️ Sahne Detayı — WEB. "Crimson Noir" tanıtım sayfasıyla aynı görsel dil.
/// Mobil uygulamaya (stage_details_mobil.dart) dokunmuyor, sadece web
/// tarafının kendi görünümü. Tüm veri aynı gerçek `stageDetailProvider`'dan
/// (harita konumu, adres, iletişim, sahnelenen eserler dahil) geliyor.
class StageDetailPage extends ConsumerStatefulWidget {
  final String stageId;

  const StageDetailPage({super.key, required this.stageId});

  @override
  ConsumerState<StageDetailPage> createState() => _StageDetailPageState();
}

class _StageDetailPageState extends ConsumerState<StageDetailPage>
    with GlobalScrollMixin {
  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(stageDetailProvider(widget.stageId));
    final width = MediaQuery.of(context).size.width;
    final bool isLarge = width > 900;
    final double hPad = width > 1400 ? 100 : (width > 900 ? 60 : 24);

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      title: detailAsync.value?.stage.name.toUpperCase() ?? 'SAHNE DETAYI',
      subtitle: 'Şehrin en iyi sahnelerini keşfedin',
      rightIcon: Icons.stadium_rounded,
      customScrollController: scrollController,
      isLoading: detailAsync.isLoading,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: LandingPalette.bg,
        ambientColor: LandingPalette.crimson.withOpacity(0.04),
      ),
      child: detailAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (final err, final _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: BentoErrorState(
              message: 'Sahne bilgisi yüklenemedi.',
              onRetry: () =>
                  ref.invalidate(stageDetailProvider(widget.stageId)),
            ),
          ),
        ),
        data: (final state) => CustomScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _StageHero(
                  name: state.stage.name,
                  imageUrl: state.stage.imageUrl,
                  stageId: widget.stageId,
                  hPad: hPad),
            ),
            SliverToBoxAdapter(
              child: LandingSectionBand(
                eyebrow: 'HAKKINDA',
                title: 'Mekanın Hikayesi',
                hPad: hPad,
                child: state.stage.description.trim().isEmpty
                    ? Text('Bu mekan için henüz bir açıklama eklenmedi.',
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withOpacity(0.4)))
                    : Text(state.stage.description,
                        style: TextStyle(
                            fontSize: 15.5,
                            height: 1.7,
                            color: Colors.white.withOpacity(0.75))),
              ),
            ),
            SliverToBoxAdapter(
              child: LandingSectionBand(
                eyebrow: 'REPERTUAR',
                title: 'Sahnelenen Eserler',
                hPad: hPad,
                alt: true,
                child: state.shows.isEmpty
                    ? const LandingComingSoonCard(
                        icon: Icons.event_seat_outlined,
                        message: 'Bu mekanda şu an sahnelenen bir eser yok.',
                      )
                    : _ShowsRow(shows: state.shows),
              ),
            ),
            SliverToBoxAdapter(
              child: LandingSectionBand(
                eyebrow: 'KONUM',
                title: 'Nasıl Ulaşırım?',
                hPad: hPad,
                child: isLarge
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 6,
                              child: _StageMap(
                                  lat: state.stage.locationLat,
                                  lng: state.stage.locationLng)),
                          const SizedBox(width: 32),
                          Expanded(
                              flex: 4,
                              child: _AddressCard(
                                  address: state.stage.address,
                                  communication: state.stage.communication)),
                        ],
                      )
                    : Column(
                        children: [
                          _StageMap(
                              lat: state.stage.locationLat,
                              lng: state.stage.locationLng),
                          const SizedBox(height: 24),
                          _AddressCard(
                              address: state.stage.address,
                              communication: state.stage.communication),
                        ],
                      ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }
}

class _StageHero extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String stageId;
  final double hPad;
  const _StageHero(
      {required this.name,
      required this.imageUrl,
      required this.stageId,
      required this.hPad});

  @override
  Widget build(final BuildContext context) => SizedBox(
        height: 420,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
            else
              const ColoredBox(color: LandingPalette.surface),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: LandingPalette.emberGlow),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    LandingPalette.bg.withOpacity(0.3),
                    LandingPalette.bg.withOpacity(0.5),
                    LandingPalette.bg,
                  ],
                ),
              ),
            ),
            Positioned(
              left: hPad,
              right: hPad,
              bottom: 36,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color:
                                    LandingPalette.crimsonLight.withOpacity(0.6)),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text('SAHNE / MEKAN',
                              style: TextStyle(
                                  color: LandingPalette.crimsonLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                      border: Border.all(color: LandingPalette.microBorderStrong),
                    ),
                    child: FavoriteToggleButton(
                      itemId: stageId,
                      type: FavoriteType.stage,
                      inactiveColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ShowsRow extends StatelessWidget {
  final List<Show> shows;
  const _ShowsRow({required this.shows});

  @override
  Widget build(final BuildContext context) => SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: shows.length,
          separatorBuilder: (final _, final __) => const SizedBox(width: 16),
          itemBuilder: (final context, final i) {
            final show = shows[i];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (final _) => ShowDetailPage(showId: show.id)),
              ),
              child: SizedBox(
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(imageUrl: show.imageUrl, fit: BoxFit.cover),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.88),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Text(show.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _StageMap extends StatelessWidget {
  final double lat;
  final double lng;
  const _StageMap({required this.lat, required this.lng});

  @override
  Widget build(final BuildContext context) {
    if (lat == 0 && lng == 0) {
      return const LandingComingSoonCard(
        icon: Icons.location_off_outlined,
        message: 'Bu mekan için henüz bir harita konumu eklenmedi.',
      );
    }
    final position = LatLng(lat, lng);
    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LandingPalette.microBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: 15),
          markers: {Marker(markerId: const MarkerId('stage'), position: position)},
          zoomControlsEnabled: false,
          scrollGesturesEnabled: false,
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String address;
  final String communication;
  const _AddressCard({required this.address, required this.communication});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: LandingPalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LandingPalette.microBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoTile(Icons.location_on_rounded, 'Açık Adres', address),
            const SizedBox(height: 20),
            _infoTile(Icons.phone_in_talk_rounded, 'İletişim', communication),
          ],
        ),
      );

  Widget _infoTile(final IconData icon, final String title, final String content) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: LandingPalette.crimsonLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                    content.trim().isNotEmpty
                        ? content
                        : 'Henüz eklenmedi.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13.5,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      );
}
