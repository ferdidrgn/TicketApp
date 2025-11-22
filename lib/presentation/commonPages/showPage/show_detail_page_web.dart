import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/data/providers/player/player_notifier.dart';
import 'package:ticketapp/data/providers/show/show_notifier.dart';
import 'package:ticketapp/data/providers/stage/stage_notifier.dart';
import 'package:ticketapp/data/providers/user/user_provider.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/util/date_formatter.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../data/providers/event/event_provider.dart';
import '../../../data/providers/event/event_state.dart';
import '../../../data/providers/login/login_provider.dart';
import '../../../data/providers/player/player_provider.dart';
import '../../../data/providers/player/player_state.dart';
import '../../../data/providers/show/show_provider.dart';
import '../../../data/providers/stage/stage_provider.dart';
import '../../../data/providers/stage/stage_state.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/show.dart';

class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    final showNotifier = ref.read(showProvider.notifier);
    final Show? showData = ref.read(showProvider).getShowById(widget.showId);

    // Gösteri verisi yoksa sunucudan çek
    if (showData == null) {
      try {
        await showNotifier.loadShowsByIds([widget.showId]);
        if (showData == null) {
          showNotifier.setErrorState("Gösteri yüklenemedi.");
          return;
        }
      } catch (e) {
        showNotifier.setErrorState("Gösteri yüklenemedi: $e");
        return;
      }
    }

    final eventsList = showData.eventsId ?? [];
    if (eventsList.isNotEmpty)
      unawaited(ref.read(eventProvider.notifier).loadEventsByIds(eventsList));

    final nowPlayers = showData.nowPlayersId ?? [];
    final oldPlayers = showData.oldPlayersId ?? [];

    final allPlayerIds = {...nowPlayers, ...oldPlayers}.toList();

    if (allPlayerIds.isNotEmpty)
      unawaited(
          ref.read(playerProvider.notifier).getPlayersByIds(allPlayerIds));
  }

  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showProvider);
    final eventState = ref.watch(eventProvider);
    final playerState = ref.watch(playerProvider);
    final stageState = ref.watch(stageProvider);
    final showData = showState.getShowById(widget.showId);

    ref.listen<EventState>(eventProvider, (final previous, final next) {
      final justLoaded = (previous?.dataList?.isEmpty ?? true) &&
          (next.dataList?.isNotEmpty ?? false);
      if (justLoaded) {
        final stageIds = next.dataList!
            .map((final e) => e.stageId)
            .whereType<String>()
            .where((final id) => id.trim().isNotEmpty && id != '0')
            .toSet()
            .toList();
        if (stageIds.isNotEmpty) {
          unawaited(ref.read(stageProvider.notifier).loadStagesByIds(stageIds));
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f23),
      body: showState.isLoading && !showState.hasData
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : (!showState.hasData)
              ? _buildErrorState(showState.errorMessage)
              : _buildContent(
                  context, showData!, eventState, playerState, stageState),
    );
  }

  Widget _buildErrorState(final String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFD4AF37)),
          const SizedBox(height: 16),
          Text(
            message ?? 'Gösteri bulunamadı.',
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37)),
            child:
                const Text('Geri Dön', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      final BuildContext context,
      final Show showData,
      final EventState eventState,
      final PlayerState playerState,
      final StageState stageState) {
    final isDesktop = context.isDesktop;
    final horizontalPadding =
        context.responsive(mobile: 16.0, tablet: 40.0, desktop: 80.0);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero Section
          _buildHeroSection(context, showData),

          // Main Content
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 40),
            child: isDesktop
                ? _buildDesktopLayout(
                    context, showData, eventState, playerState, stageState)
                : _buildMobileLayout(
                    context, showData, eventState, playerState, stageState),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(final BuildContext context, final Show showData) {
    final height =
        context.responsive(mobile: 400.0, tablet: 500.0, desktop: 600.0);

    return Stack(
      children: [
        // Background Image
        SizedBox(
          height: height,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: showData.imageUrl,
            fit: BoxFit.cover,
            placeholder: (final _, final __) => const ShimmerLoading(
                width: double.infinity, height: double.infinity),
            errorWidget: (final _, final __, final ___) =>
                Container(color: const Color(0xFF1a1a2e)),
          ),
        ),
        // Gradient Overlay
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFF0f0f23).withOpacity(0.8),
                const Color(0xFF0f0f23),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        ),
        // Back Button
        Positioned(
          top: 40,
          left: 20,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
        // Title
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                showData.name,
                style: TextStyle(
                  fontSize: context.responsive(mobile: 32.0, desktop: 56.0),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 20)],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                height: 4,
                width: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFF5E6A3)]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
      final BuildContext context,
      final Show showData,
      final EventState eventState,
      final PlayerState playerState,
      final StageState stageState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sol: Poster ve Açıklama
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPosterCard(context, showData.imageUrl),
              const SizedBox(height: 32),
              _buildDescriptionSection(showData.description),
            ],
          ),
        ),
        const SizedBox(width: 48),
        // Sağ: Etkinlikler, Ekip, Galeri
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Etkinlik Takvimi'),
              const SizedBox(height: 20),
              _buildEventSection(showData, eventState, stageState),
              const SizedBox(height: 40),
              _buildSectionTitle('Ekip'),
              const SizedBox(height: 20),
              _buildPlayerGrid(context,
                  playerState.getPlayersByIds(showData.nowPlayersId), false),
              const SizedBox(height: 40),
              _buildSectionTitle('Eski Ekip'),
              const SizedBox(height: 20),
              _buildPlayerGrid(context,
                  playerState.getPlayersByIds(showData.oldPlayersId), true),
              const SizedBox(height: 40),
              _buildSectionTitle('Galeri'),
              const SizedBox(height: 20),
              _buildGalleryGrid(context, showData.photosShowId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
      final BuildContext context,
      final Show showData,
      final EventState eventState,
      final PlayerState playerState,
      final StageState stageState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescriptionSection(showData.description),
        const SizedBox(height: 32),
        _buildSectionTitle('Etkinlik Takvimi'),
        const SizedBox(height: 16),
        _buildEventSection(showData, eventState, stageState),
        const SizedBox(height: 32),
        _buildSectionTitle('Ekip'),
        const SizedBox(height: 16),
        _buildPlayerRow(
            playerState.getPlayersByIds(showData.nowPlayersId), false),
        const SizedBox(height: 32),
        _buildSectionTitle('Eski Ekip'),
        const SizedBox(height: 16),
        _buildPlayerRow(
            playerState.getPlayersByIds(showData.oldPlayersId), true),
        const SizedBox(height: 32),
        _buildSectionTitle('Galeri'),
        const SizedBox(height: 16),
        _buildGalleryRow(showData.photosShowId),
      ],
    );
  }

  Widget _buildPosterCard(final BuildContext context, final String imageUrl) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 350),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 9 / 13,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (final _, final __) => const ShimmerLoading(
                width: double.infinity, height: double.infinity),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(final String title) {
    return Row(
      children: [
        Container(width: 4, height: 28, color: const Color(0xFFD4AF37)),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(final String description) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Text(
        description.replaceAll('\\n', '\n'),
        style:
            const TextStyle(color: Colors.white70, fontSize: 16, height: 1.8),
      ),
    );
  }

  Widget _buildEventSection(final Show showData, final EventState eventState,
      final StageState stageState) {
    if (eventState.isLoading && !eventState.hasData) {
      return const SizedBox(
          height: 100,
          child: Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    }

    final events = eventState.dataList
            ?.where((final e) => showData.eventsId.contains(e.id))
            .toList() ??
        [];
    if (events.isEmpty) {
      return _buildEmptyState('Yaklaşan etkinlik bulunmamaktadır.');
    }

    return Column(
      children: events.map((final event) {
        final stage = stageState.getStageById(event.stageId);
        final stageName = stage?.name ?? "Sahne bilgisi yok";
        return _buildEventCard(
            event.date.toString(), event.id, showData.id, stageName);
      }).toList(),
    );
  }

  Widget _buildEventCard(final String date, final String eventId,
      final String showId, final String stageName) {
    final formatted = DateFormatter.formatForEventCard(date);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _navigateToSeatSelection(eventId, showId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFF5E6A3)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(formatted['day'] ?? '?',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0f0f23))),
                    Text(formatted['monthName'] ?? '-',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0f0f23))),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stageName,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Text("İstanbul • ${formatted['time'] ?? '--:--'}",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.white54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.arrow_forward, color: Color(0xFFD4AF37)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSeatSelection(final String eventId, final String showId) {
    String? userId = ref.read(loginProvider).user?.uid;
    userId ??= ref.read(userProvider).dataSingle?.id;
    userId ??= LocalStorageService.userUid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı oturumu bulunamadı.")),
      );
      return;
    }
    // Web'de seat selection sayfasına yönlendirme
    // Navigator.push(context, MaterialPageRoute(builder: (_) => SeatSelectionScreen(...)));
  }

  Widget _buildPlayerGrid(final BuildContext context,
      final List<Player> players, final bool isOld) {
    if (players.isEmpty)
      return _buildEmptyState(
          isOld ? 'Eski ekip bilgisi yok.' : 'Ekip bilgisi yok.');

    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: players
          .map((final p) => _buildPlayerCard(context, p, isOld))
          .toList(),
    );
  }

  Widget _buildPlayerRow(final List<Player> players, final bool isOld) {
    if (players.isEmpty)
      return _buildEmptyState(
          isOld ? 'Eski ekip bilgisi yok.' : 'Ekip bilgisi yok.');

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: players.length,
        itemBuilder: (final _, final i) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildPlayerCard(context, players[i], isOld),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(
      final BuildContext context, final Player player, final bool isOld) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: player.imageUrl,
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                    placeholder: (final _, final __) =>
                        const ShimmerLoading(width: 140, height: 140),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${player.firstName}\n${player.lastName}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            if (isOld)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryGrid(
      final BuildContext context, final List<String> photos) {
    if (photos.isEmpty) return _buildEmptyState('Galeri boş.');

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: photos.map((final url) => _buildGalleryItem(url)).toList(),
    );
  }

  Widget _buildGalleryRow(final List<String> photos) {
    if (photos.isEmpty) return _buildEmptyState('Galeri boş.');

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (final _, final i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildGalleryItem(photos[i]),
        ),
      ),
    );
  }

  Widget _buildGalleryItem(final String url) {
    return GestureDetector(
      onTap: () => _showFullImage(context, url),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(final String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Text(message,
          style: const TextStyle(color: Colors.white38, fontSize: 16)),
    );
  }

  void _showFullImage(final BuildContext context, final String url) {
    showDialog(
      context: context,
      builder: (final _) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
