import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/features/shows/domain/entities/show.dart';
import 'package:ticketapp/features/shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../providers/player_provider.dart';

class PlayerDetailPage extends ConsumerStatefulWidget {
  final String playerId;
  const PlayerDetailPage({super.key, required this.playerId});

  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage> {
  final ValueNotifier<double> _scrollNotifier = ValueNotifier(0.0);

  @override
  void dispose() {
    _scrollNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(playerDetailProvider(widget.playerId));

    // Otantik Amber/Altın tonu
    const accentColor = Color(0xFFD4AF37);

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      isLoading: detailAsync.isLoading,
      shimmerSkeleton: const ArtisticPageShimmer(),
      layoutConfig: PageBackgroundLayoutConfig(
        backgroundColor: const Color(0xFF0F0F0F), // Derin Müze Siyahı
        ambientColor: accentColor.withOpacity(0.05),
        extendBody: true,
      ),
      child: detailAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (err, stack) => Center(child: Text("Hata: $err", style: const TextStyle(color: Colors.white))),
        data: (state) => NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              _scrollNotifier.value = notification.metrics.pixels;
            }
            return false;
          },
          child: Stack(
            children: [
              // 1. KATMAN: OTANTİK PARALLAX VE SOFT SPOTLIGHT
              _buildAuthenticHeader(context, state.player.imageUrl),

              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: context.screenHeight * 0.6)),

                  // 2. KATMAN: DEV EDİTORYAL İSİM
                  SliverToBoxAdapter(child: _buildArtistHeritageTitle(state.player)),

                  // 3. KATMAN: GALERİ KONSEPTLİ İÇERİK
                  SliverToBoxAdapter(child: _buildGalleryContent(context, state, accentColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticHeader(BuildContext context, String imageUrl) {
    return ValueListenableBuilder<double>(
      valueListenable: _scrollNotifier,
      builder: (context, offset, child) {
        double blur = (offset / 50).clamp(0, 15);
        return Positioned(
          top: -offset * 0.4,
          left: 0, right: 0,
          height: context.screenHeight * 0.85,
          child: Stack(
            fit: StackFit.expand,
            children: [
              OptimizedCachedImage(imageUrl: imageUrl, fit: BoxFit.cover),
              // Yumuşak Blur Katmanı
              if (blur > 0)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(color: Colors.black.withOpacity(0.2)),
                ),
              // Müze Aydınlatması (Vignette & Gradient)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                      const Color(0xFF0F0F0F),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArtistHeritageTitle(dynamic player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SANATIN MİRASI",
              style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 5, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "${player.firstName}\n${player.lastName}".toUpperCase(),
            style: const TextStyle(
              fontSize: 58,
              fontWeight: FontWeight.w900,
              height: 0.85,
              letterSpacing: -2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildGalleryContent(BuildContext context, PlayerDetailState state, Color accent) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),

          // 🏆 OTANTİK STATS PANELİ (Beğendiğin Yapı)
          _buildHeritageStats(state, accent),

          const SizedBox(height: 60),

          // 🖋️ BİYOGRAFİ (Spotlight Altında)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("HİKAYESİ", style: TextStyle(color: accent, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
                const SizedBox(height: 16),
                Text(
                  state.player.bio,
                  style: TextStyle(fontSize: 17, height: 1.8, color: Colors.white.withOpacity(0.7), fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),

          // 🎭 AKTİF GÖSTERİLER
          _buildGallerySectionHeader("SAHNEDEKİ ESERLER", accent),
          const SizedBox(height: 24),
          _buildHeritageSlider(context, state.activeShows, false),

          const SizedBox(height: 60),

          // 🏛️ ARŞİV (Eski oyunlar - Tıklanabilir & Şık)
          _buildGallerySectionHeader("SAHNE ARŞİVİ", accent),
          const SizedBox(height: 24),
          _buildHeritageArchive(context, state.pastShows, accent),

          const SizedBox(height: 150),
        ],
      ),
    );
  }

  Widget _buildHeritageStats(PlayerDetailState state, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _heritageStatItem("${state.activeShows.length}", "AKTİF OYUN", accent),
          _heritageStatItem("${state.pastShows.length}", "ANILAR", accent),
          _heritageStatItem("∞", "İHTİRAS", accent),
        ],
      ),
    );
  }

  Widget _heritageStatItem(String val, String label, Color accent) => Column(
    children: [
      Text(val, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5)),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accent, letterSpacing: 2)),
    ],
  );

  Widget _buildHeritageSlider(BuildContext context, List<Show> shows, bool isPast) {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 32),
        physics: const BouncingScrollPhysics(),
        itemCount: shows.length,
        itemBuilder: (context, index) {
          final show = shows[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShowDetailPage(showId: show.id))),
            child: Container(
              width: 200,
              margin: const EdgeInsets.only(right: 25),
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: OptimizedCachedImage(imageUrl: show.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(show.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeritageArchive(BuildContext context, List<Show> shows, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: shows.map((show) => GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShowDetailPage(showId: show.id))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                    child: OptimizedCachedImage(imageUrl: show.imageUrl, width: 60, height: 80, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(show.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text("ARŞİV KAYDI", style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: accent.withOpacity(0.5)),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildGallerySectionHeader(String title, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(width: 30, height: 1, color: accent),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }
}