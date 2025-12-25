import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/features/shows/presentation/pages/show_detail_page.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_provider.dart';
import '../../domain/entities/player.dart';
import '../providers/player_notifier.dart';
import '../providers/player_provider.dart';
import '../../../../shared/widgets/button/glass_back_button.dart';

class PlayerDetailPage extends ConsumerStatefulWidget {
  final String playerId;

  const PlayerDetailPage({super.key, required this.playerId});

  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchInitialData());
  }

  Future<void> _fetchInitialData() async {
    final playerNotifier = ref.read(playerProvider.notifier);
    final showNotifier = ref.read(showProvider.notifier);

    await playerNotifier.getPlayersByIds([widget.playerId]);
    final player = ref.read(playerProvider).getPlayerById(widget.playerId);

    if (player != null) {
      final allShowIds = [...player.nowShowsId, ...player.oldShowsId];
      await showNotifier.loadShowsByIds(allShowIds);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final playerState = ref.watch(playerProvider);
    final showState = ref.watch(showProvider);
    final playerData = playerState.getPlayerById(widget.playerId);

    if (playerState.isLoading && playerData == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (playerData == null)
      return const Scaffold(body: Center(child: Text("Sanatçı bulunamadı.")));

    final activeShows = showState.dataList
            ?.where((s) => playerData.nowShowsId.contains(s.id))
            .toList() ??
        [];
    final oldShows = showState.dataList
            ?.where((s) => playerData.oldShowsId.contains(s.id))
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- 🎨 1. SANATÇI PORTRESİ (BLUR EFEKTLİ) ---
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.55,
            pinned: true,
            stretch: true,
            leading: const Padding(
                padding: EdgeInsets.all(8.0), child: GlassBackButton()),
            backgroundColor: colors.background,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground
              ],
              title: Text(
                  "${playerData.firstName} ${playerData.lastName}"
                      .toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 2)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                      imageUrl: playerData.imageUrl, fit: BoxFit.cover),
                  DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                        Colors.transparent,
                        colors.background
                      ]))),
                ],
              ),
            ),
          ),

          // --- 📜 2. SANATSAL YOLCULUK ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildSectionLabel(context, "SANATSAL YOLCULUK",
                      "Sahne tozuna karışan bir ömür..."),
                  const SizedBox(height: 16),
                  Text(playerData.bio,
                      style: context.textTheme.bodyLarge?.copyWith(
                          height: 1.8, color: colors.onSurfaceVariant)),
                  const SizedBox(height: 40),
                  if (activeShows.isNotEmpty) ...[
                    _buildSectionLabel(context, "SAHNE İMZALARI",
                        "Şu an ruh verdiği karakterler"),
                    _buildShowList(context, activeShows, false),
                  ],
                  const SizedBox(height: 40),
                  if (oldShows.isNotEmpty) ...[
                    _buildSectionLabel(context, "ARŞİVDEKİ PERDELER",
                        "Hafızalarda kalan temsiller"),
                    _buildShowList(context, oldShows, true),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(
      BuildContext context, String title, String subtitle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 4, height: 20, color: context.colors.primary),
        const SizedBox(width: 12),
        Text(title,
            style: context.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ]),
      Text(subtitle,
          style: context.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: context.colors.primary.withOpacity(0.6))),
    ]);
  }

  Widget _buildShowList(BuildContext context, List shows, bool isGrayscale) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: shows.length,
        itemBuilder: (context, index) {
          final show = shows[index];
          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ShowDetailPage(showId: show.id))),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16, top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                            isGrayscale ? Colors.grey : Colors.transparent,
                            BlendMode.saturation),
                        child: CachedNetworkImage(
                            imageUrl: show.imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(show.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
