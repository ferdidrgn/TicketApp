import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/shows/domain/entities/show.dart';
import 'package:ticketapp/features/shows/presentation/pages/show_detail_page.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_provider.dart';
import 'package:ticketapp/shared/widgets/shimmer.dart';

import '../../../shows/presentation/providers/show_notifier.dart';
import '../../domain/entities/player.dart';
import '../providers/player_notifier.dart';
import '../providers/player_provider.dart';

class PlayerDetailPage extends ConsumerStatefulWidget {
  final String playerId;

  const PlayerDetailPage({super.key, required this.playerId});

  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) _fetchInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    // 1. OYUNCU KONTROLÜ (Hafızada var mı?)
    var player = ref.read(playerProvider).getPlayerById(widget.playerId);

    if (player == null) {
      await ref
          .read(playerProvider.notifier)
          .getPlayersByIds([widget.playerId]);
      player = ref.read(playerProvider).getPlayerById(widget.playerId);
    }

    // 2. OYUNLAR KONTROLÜ
    if (player != null) {
      final showState = ref.read(showProvider);

      // Modelindeki 'nowShowsId' ve 'oldShowsId' listelerini birleştiriyoruz
      final allPlayerShowIds = [...player.nowShowsId, ...player.oldShowsId];

      // Sadece hafızada OLMAYAN (eksik) oyunları bul
      final List<String> missingShowIds = allPlayerShowIds.where((final id) {
        if (id.trim().isEmpty) return false;
        return showState.getShowById(id) == null;
      }).toList();

      // Eksikleri yükle
      if (missingShowIds.isNotEmpty) {
        await ref.read(showProvider.notifier).loadShowsByIds(missingShowIds);
      }

      // 3. ETKİNLİKLER (Opsiyonel, gerekirse buraya eklenir)
    }
  }

  @override
  Widget build(final BuildContext context) {
    // TEMA AYARLARI
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = theme.primaryColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    final playerState = ref.watch(playerProvider);
    final showState = ref.watch(showProvider);

    final playerData = playerState.getPlayerById(widget.playerId);

    // Loading
    if (playerState.isLoading && playerData == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    // Hata
    if (playerData == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
            child:
                Text("Oyuncu bulunamadı.", style: TextStyle(color: textColor))),
      );
    }

    // --- GÖSTERİLERİ AYIKLA (Modeline uygun şekilde) ---
    // 1. Aktif Gösteriler
    final activeShows = showState.dataList
            ?.where((final show) => playerData.nowShowsId.contains(show.id))
            .toList() ??
        [];

    // 2. Eski Gösteriler
    final oldShows = showState.dataList
            ?.where((final show) => playerData.oldShowsId.contains(show.id))
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- 1. PARALLAX BAŞLIK ---
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.55,
            pinned: true,
            stretch: true,
            backgroundColor: backgroundColor,
            elevation: 0,
            leading: _buildBackButton(theme),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground
              ],
              centerTitle: true,
              title: Text(
                "${playerData.firstName} ${playerData.lastName}",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              background: _buildHeaderBackground(
                  playerData, primaryColor, backgroundColor),
            ),
          ),

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
                  // Modeline uygun 'bio' alanını kullanıyoruz
                  Text(
                    playerData.bio.isNotEmpty
                        ? playerData.bio
                        : "Biyografi bilgisi bulunamadı.",
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 16,
                      height: 1.6,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 35),

                  // AKTİF GÖSTERİLER
                  if (activeShows.isNotEmpty) ...[
                    _buildSectionTitle("GÖSTERİLERİ", primaryColor, textColor),
                    const SizedBox(height: 20),
                    _buildHorizontalShowList(
                        context, activeShows, primaryColor, backgroundColor),
                    const SizedBox(height: 30),
                  ],

                  // ESKİ GÖSTERİLER
                  if (oldShows.isNotEmpty) ...[
                    _buildSectionTitle(
                        "ESKİ GÖSTERİLERİ", primaryColor, textColor),
                    const SizedBox(height: 20),
                    // Eski gösteriler için isGrayscale: true yaptık
                    _buildHorizontalShowList(
                        context, oldShows, primaryColor, backgroundColor,
                        isGrayscale: true),
                  ],

                  if (activeShows.isEmpty &&
                      oldShows.isEmpty &&
                      !showState.isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text("Kayıtlı gösteri bulunamadı.",
                          style: TextStyle(color: textColor.withOpacity(0.5))),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  Widget _buildBackButton(final ThemeData theme) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
                color: (theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black)
                    .withOpacity(0.2),
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
      final Player player, final Color primaryColor, final Color bgColor) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: player.imageUrl,
          fit: BoxFit.cover,
          memCacheHeight: 800,
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
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    shadows: [
                      Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 5))
                    ]),
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    ColorFiltered(
                      colorFilter: isGrayscale
                          ? const ColorFilter.mode(
                              Colors.grey, BlendMode.saturation)
                          : const ColorFilter.mode(
                              Colors.transparent, BlendMode.saturation),
                      child: CachedNetworkImage(
                        imageUrl: show.imageUrl,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                        memCacheHeight: 400,
                        placeholder: (final context, final url) =>
                            const ShimmerLoading(
                                width: double.infinity,
                                height: double.infinity),
                        errorWidget: (final context, final url, final error) =>
                            Container(
                                color: bgColor, child: const Icon(Icons.error)),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.9)
                          ],
                              stops: const [
                            0.5,
                            1.0
                          ])),
                    ),
                    Positioned(
                      bottom: 15,
                      left: 15,
                      right: 15,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(show.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 5),
                          Text("Detaylar >",
                              style: TextStyle(
                                  color: isGrayscale
                                      ? Colors.white70
                                      : primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
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
