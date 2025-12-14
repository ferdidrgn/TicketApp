import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/util/date_formatter.dart';
import 'package:ticketapp/features/events/domain/entities/event.dart';
import 'package:ticketapp/features/events/presentation/providers/event_provider.dart';
import 'package:ticketapp/features/events/presentation/providers/event_state.dart';
import 'package:ticketapp/features/login/presentation/providers/login_provider.dart';
import 'package:ticketapp/features/players/domain/entities/player.dart';
import 'package:ticketapp/features/players/presentation/pages/player_details.dart';
import 'package:ticketapp/features/players/presentation/providers/player_notifier.dart';
import 'package:ticketapp/features/players/presentation/providers/player_provider.dart';
import 'package:ticketapp/features/seat/presentation/pages/seat_details.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_notifier.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_provider.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_notifier.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_provider.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_state.dart';
import 'package:ticketapp/features/users/presentation/providers/user_provider.dart';

class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage> {
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
    final showNotifier = ref.read(showProvider.notifier);
    var showData = ref.read(showProvider).getShowById(widget.showId);

    if (showData == null) {
      await showNotifier.loadShowsByIds([widget.showId]);
    }
    showData = ref.read(showProvider).getShowById(widget.showId);

    if (showData != null) {
      if (showData.eventsId.isNotEmpty) {
        final validEventIds =
            showData.eventsId.where((final id) => id.trim().isNotEmpty).toList();
        if (validEventIds.isNotEmpty) {
          unawaited(
              ref.read(eventProvider.notifier).loadEventsByIds(validEventIds));
        }
      }
      final allPlayerIds = {...showData.nowPlayersId, ...showData.oldPlayersId}
          .where((final id) => id.trim().isNotEmpty)
          .toList();
      if (allPlayerIds.isNotEmpty) {
        unawaited(
            ref.read(playerProvider.notifier).getPlayersByIds(allPlayerIds));
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = theme.primaryColor; // Senin Kırmızın

    final showState = ref.watch(showProvider);
    final showData = showState.getShowById(widget.showId);
    final eventState = ref.watch(eventProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);

    ref.listen<EventState>(eventProvider, (final previous, final next) {
      if ((previous?.dataList?.isEmpty ?? true) &&
          (next.dataList?.isNotEmpty ?? false)) {
        final stageIds = next.dataList!
            .map((final e) => e.stageId)
            .where((final id) => id.isNotEmpty && id != '0')
            .toSet()
            .toList();
        if (stageIds.isNotEmpty) {
          ref.read(stageProvider.notifier).loadStagesByIds(stageIds);
        }
      }
    });

    if (showState.isLoading && showData == null) {
      return Scaffold(
          backgroundColor: backgroundColor,
          body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }

    if (showData == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
            child: Text("Gösteri bulunamadı",
                style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. ARKA PLAN RESMİ (Ayrı Widget'a gitmeden burada çağırdık)
          _ShowParallaxHeader(
            imageUrl: showData.imageUrl,
            scrollController: _scrollController,
            backgroundColor: backgroundColor,
          ),

          // 2. SCROLL İÇERİK
          // RepaintBoundary ile sararak kasma sorununu önlüyoruz
          RepaintBoundary(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                    child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45)),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          backgroundColor,
                          backgroundColor
                        ],
                        stops: const [0.0, 0.1, 1.0],
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // BİLGİ BÖLÜMÜ
                        _ShowInfoSection(
                          title: showData.name,
                          description: showData.description,
                          primaryColor: primaryColor,
                        ),

                        // ETKİNLİK LİSTESİ
                        _ShowEventList(
                          events: eventState.dataList
                                  ?.where(
                                      (final e) => showData.eventsId.contains(e.id))
                                  .toList() ??
                              [],
                          stageState: stageState,
                          primaryColor: primaryColor,
                          surfaceColor: theme.cardColor,
                          // Temadan gelen kart rengi
                          backgroundColor: backgroundColor,
                          onTicketTap: (final eventId) =>
                              _handleTicketPurchase(showData.id, eventId),
                        ),

                        // AKTİF OYUNCULAR
                        _ShowCastList(
                          title: "OYUNCU KADROSU",
                          players: playerState
                              .getPlayersByIds(showData.nowPlayersId),
                          primaryColor: primaryColor,
                          onPlayerTap: (final id) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (final _) =>
                                      PlayerDetailPage(playerId: id))),
                        ),

                        // ESKİ OYUNCULAR
                        if (showData.oldPlayersId.isNotEmpty)
                          _ShowCastList(
                            title: "ESKİ KADRO",
                            players: playerState
                                .getPlayersByIds(showData.oldPlayersId),
                            primaryColor: primaryColor,
                            isGrayscale: true,
                            onPlayerTap: (final id) => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (final _) =>
                                        PlayerDetailPage(playerId: id))),
                          ),

                        // GALERİ
                        if (showData.photosShowId.isNotEmpty)
                          _ShowPhotoGallery(
                            photos: showData.photosShowId,
                            primaryColor: primaryColor,
                          ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // GERİ BUTONU
          Positioned(
            top: 50,
            left: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                      color: (theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: (theme.brightness == Brightness.dark
                              ? Colors.white24
                              : Colors.black12))),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: theme.iconTheme.color ??
                            (theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black),
                        size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTicketPurchase(final String showId, final String eventId) {
    final loginState = ref.read(loginProvider);
    String? userId = loginState.user?.uid ??
        ref.read(userProvider).dataSingle?.id ??
        LocalStorageService.userUid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen önce giriş yapınız.")));
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (final context) => SeatSelectionScreen(
                showId: showId, eventId: eventId, customerId: userId!)));
  }
}

// -----------------------------------------------------------------------------
// YARDIMCI WIDGETLAR (Aynı dosya içinde private class olarak)
// -----------------------------------------------------------------------------

class _ShowParallaxHeader extends StatelessWidget {
  final String imageUrl;
  final ScrollController scrollController;
  final Color backgroundColor;

  const _ShowParallaxHeader({
    required this.imageUrl,
    required this.scrollController,
    required this.backgroundColor,
  });

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (final context, final child) {
        double offset = 0;
        if (scrollController.hasClients) offset = scrollController.offset;

        return Positioned(
          top: -offset * 0.5,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.6 +
              (offset < 0 ? -offset : 0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl, fit: BoxFit.cover,
                memCacheHeight: 800, // Optimizasyon
                errorWidget: (final context, final url, final error) =>
                    Container(color: backgroundColor),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black12, Colors.black54, backgroundColor],
                  ),
                ),
              ),
              if (offset > 0)
                BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: (offset / 100).clamp(0, 5),
                      sigmaY: (offset / 100).clamp(0, 5)),
                  child: Container(color: Colors.transparent),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ShowInfoSection extends StatefulWidget {
  final String title;
  final String description;
  final Color primaryColor;

  const _ShowInfoSection(
      {required this.title,
      required this.description,
      required this.primaryColor});

  @override
  State<_ShowInfoSection> createState() => _ShowInfoSectionState();
}

class _ShowInfoSectionState extends State<_ShowInfoSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final cleanDesc = widget.description.replaceAll('\\n', '\n');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius: BorderRadius.circular(20)),
            child: const Text("TİYATRO",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 15),
          Text(widget.title,
              style: TextStyle(
                  color: textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.1)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.star, color: widget.primaryColor, size: 20),
              const SizedBox(width: 5),
              Text("4.8 (120 İnceleme)",
                  style: TextStyle(
                      color: textColor.withOpacity(0.7), fontSize: 14)),
              const SizedBox(width: 20),
              Icon(Icons.timer, color: textColor.withOpacity(0.5), size: 18),
              const SizedBox(width: 5),
              Text("120 Dk",
                  style: TextStyle(
                      color: textColor.withOpacity(0.7), fontSize: 14)),
            ],
          ),
          const SizedBox(height: 25),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanDesc,
                  maxLines: _isExpanded ? null : 4,
                  overflow: _isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 16,
                      height: 1.6,
                      fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          _isExpanded
                              ? "Daha Az Göster"
                              : "Daha Fazlasını Göster",
                          style: TextStyle(
                              color: widget.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: widget.primaryColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowEventList extends StatelessWidget {
  final List<Event> events;
  final StageState stageState;
  final Color primaryColor;
  final Color surfaceColor;
  final Color backgroundColor;
  final Function(String) onTicketTap;

  const _ShowEventList(
      {required this.events,
      required this.stageState,
      required this.primaryColor,
      required this.surfaceColor,
      required this.backgroundColor,
      required this.onTicketTap});

  @override
  Widget build(final BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
          child: Row(
            children: [
              Container(width: 4, height: 24, color: primaryColor),
              const SizedBox(width: 10),
              Text("ETKİNLİK TAKVİMİ",
                  style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: events.length,
            itemBuilder: (final context, final index) {
              final event = events[index];
              final stage = stageState.getStageById(event.stageId);
              final dateInfo =
                  DateFormatter.formatForEventCard(event.date.toString());

              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 15),
                child: InkWell(
                  onTap: () => onTicketTap(event.id),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5))
                      ],
                    ),
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: primaryColor.withOpacity(0.5)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(dateInfo['day'] ?? '00',
                                  style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  dateInfo['monthName']?.toUpperCase() ?? 'AAA',
                                  style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(stage?.name ?? 'Sahne Bilgisi Yok',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 5),
                              Text("${dateInfo['time']} • İstanbul",
                                  style: TextStyle(
                                      color: textColor.withOpacity(0.6),
                                      fontSize: 13)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text("BİLET AL >",
                                    style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShowCastList extends StatelessWidget {
  final List<Player> players;
  final String title;
  final Color primaryColor;
  final bool isGrayscale;
  final Function(String) onPlayerTap;

  const _ShowCastList(
      {required this.players,
      required this.title,
      required this.primaryColor,
      required this.onPlayerTap,
      this.isGrayscale = false});

  @override
  Widget build(final BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
          child: Row(
            children: [
              Container(
                  width: 4,
                  height: 24,
                  color: isGrayscale ? Colors.grey : primaryColor),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: players.length,
            itemBuilder: (final context, final index) {
              final player = players[index];
              return GestureDetector(
                onTap: () => onPlayerTap(player.id),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 15),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isGrayscale ? Colors.grey : primaryColor,
                              width: 2),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 4))
                          ],
                        ),
                        child: ClipOval(
                          child: isGrayscale
                              ? ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
                                      Colors.grey, BlendMode.saturation),
                                  child: CachedNetworkImage(
                                      imageUrl: player.imageUrl,
                                      fit: BoxFit.cover,
                                      memCacheHeight: 200,
                                      memCacheWidth: 200))
                              : CachedNetworkImage(
                                  imageUrl: player.imageUrl,
                                  fit: BoxFit.cover,
                                  memCacheHeight: 200,
                                  memCacheWidth: 200),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text("${player.firstName}\n${player.lastName}",
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isGrayscale
                                  ? textColor.withOpacity(0.5)
                                  : textColor,
                              fontSize: 12,
                              fontWeight: isGrayscale
                                  ? FontWeight.normal
                                  : FontWeight.w500)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShowPhotoGallery extends StatelessWidget {
  final List<String> photos;
  final Color primaryColor;

  const _ShowPhotoGallery({required this.photos, required this.primaryColor});

  @override
  Widget build(final BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
          child: Row(
            children: [
              Container(width: 4, height: 24, color: primaryColor),
              const SizedBox(width: 10),
              Text("OYUNDAN KARELER",
                  style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: photos.length,
            itemBuilder: (final context, final index) {
              return GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.95),
                  builder: (final _) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        InteractiveViewer(
                            child: CachedNetworkImage(imageUrl: photos[index])),
                        Positioned(
                            top: 50,
                            right: 20,
                            child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        color: Colors.white)))),
                      ],
                    ),
                  ),
                ),
                child: Container(
                  width: 260,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4))
                      ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                        imageUrl: photos[index],
                        fit: BoxFit.cover,
                        memCacheHeight: 400,
                        memCacheWidth: 600),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
