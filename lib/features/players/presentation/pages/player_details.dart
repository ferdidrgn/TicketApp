import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/features/shows/domain/entities/show.dart';
import 'package:ticketapp/features/shows/presentation/pages/show_detail_page.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../providers/player_provider.dart';

class PlayerDetailPage extends ConsumerWidget {
  final String playerId;

  const PlayerDetailPage({super.key, required this.playerId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // 🔥 TEK NOKTADAN TÜM VERİ TAKİBİ
    final detailAsync = ref.watch(playerDetailProvider(playerId));

    final theme = context.theme;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = theme.primaryColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final err, final stack) =>
            _buildErrorState(backgroundColor, textColor),
        data: (final state) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- 1. PARALLAX BAŞLIK ---
            _buildSliverAppBar(
                context, state.player, backgroundColor, primaryColor),

            // --- 2. İÇERİK ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),

                    // Biyografi
                    _buildSectionTitle("BİYOGRAFİ", primaryColor, textColor),
                    const SizedBox(height: 15),
                    _buildBioText(state.player.bio, textColor),

                    const SizedBox(height: 35),

                    // AKTİF GÖSTERİLER
                    if (state.activeShows.isNotEmpty) ...[
                      _buildSectionTitle(
                          "GÖSTERİLERİ", primaryColor, textColor),
                      const SizedBox(height: 20),
                      _buildHorizontalShowList(context, state.activeShows,
                          primaryColor, backgroundColor),
                      const SizedBox(height: 30),
                    ],

                    // ESKİ GÖSTERİLER
                    if (state.pastShows.isNotEmpty) ...[
                      _buildSectionTitle(
                          "ESKİ GÖSTERİLERİ", primaryColor, textColor),
                      const SizedBox(height: 20),
                      _buildHorizontalShowList(
                        context,
                        state.pastShows,
                        primaryColor,
                        backgroundColor,
                        isGrayscale: true,
                      ),
                    ],

                    if (state.activeShows.isEmpty && state.pastShows.isEmpty)
                      _buildEmptyShowsMsg(textColor),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET PARÇALARI ---

  Widget _buildSliverAppBar(final BuildContext context, final dynamic player,
      final Color bgColor, final Color primaryColor) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.55,
      pinned: true,
      stretch: true,
      backgroundColor: bgColor,
      elevation: 0,
      leading: _buildBackButton(context),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground
        ],
        centerTitle: true,
        title: Text(
          "${player.firstName} ${player.lastName}",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        background: _buildHeaderBackground(player, primaryColor, bgColor),
      ),
    );
  }

  Widget _buildBioText(final String bio, final Color textColor) {
    return Text(
      bio.isNotEmpty ? bio : "Biyografi bilgisi bulunamadı.",
      style: TextStyle(
        color: textColor.withOpacity(0.8),
        fontSize: 16,
        height: 1.6,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  Widget _buildErrorState(final Color bgColor, final Color textColor) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
          child: Text("Oyuncu yüklenirken bir hata oluştu.",
              style: TextStyle(color: textColor))),
    );
  }

  Widget _buildEmptyShowsMsg(final Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text("Kayıtlı gösteri bulunamadı.",
          style: TextStyle(color: textColor.withOpacity(0.5))),
    );
  }

  // --- YARDIMCI METOTLAR (Eski kodunuzdan optimize edilerek taşındı) ---

  Widget _buildBackButton(final BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24)),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBackground(
      final dynamic player, final Color primaryColor, final Color bgColor) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: player.imageUrl,
          fit: BoxFit.cover,
          placeholder: (final context, final url) => Container(color: bgColor),
          errorWidget: (final context, final url, final error) =>
              Container(color: bgColor, child: const Icon(Icons.person)),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, bgColor.withOpacity(0.2), bgColor],
              stops: const [0.5, 0.8, 1.0],
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20)),
                child: const Text("OYUNCU",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              Text(
                "${player.firstName}\n${player.lastName}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1.1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
      final String title, final Color primaryColor, final Color textColor) {
    return Row(
      children: [
        Container(width: 4, height: 24, color: primaryColor),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      ],
    );
  }

  Widget _buildHorizontalShowList(final BuildContext context,
      final List<Show> shows, final Color primaryColor, final Color bgColor,
      {final bool isGrayscale = false}) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: shows.length,
        itemBuilder: (final context, final index) {
          final show = shows[index];
          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (final context) =>
                        ShowDetailPage(showId: show.id))),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 15),
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                          isGrayscale ? Colors.grey : Colors.transparent,
                          BlendMode.saturation),
                      child: CachedNetworkImage(
                        imageUrl: show.imageUrl,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                        placeholder: (final context, final url) =>
                            const ShimmerLoading(
                                width: double.infinity,
                                height: double.infinity),
                        errorWidget: (final context, final url, final error) =>
                            Container(
                                color: bgColor, child: const Icon(Icons.error)),
                      ),
                    ),
                    Positioned(
                      bottom: 15,
                      left: 15,
                      right: 15,
                      child: Text(show.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
