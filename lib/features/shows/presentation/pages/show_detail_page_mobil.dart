import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/util/global_scroll_mixin.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_detail_provider.dart';
import 'package:ticketapp/shared/widgets/button/back_button_glassmorphism.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/widgets/events_card.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/widgets/players_bubble_card.dart';
import '../../../stages/domain/entities/stage.dart';
import '../widgets/mobile/show_info_section.dart';

class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage>
    with GlobalScrollMixin {
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      final isScrolledNow = scrollController.offset > 300;
      if (isScrolledNow != _isScrolled) {
        setState(() => _isScrolled = isScrolledNow);
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(showDetailProvider(widget.showId));

    final colors = context.colors;

    // Home ile aynı zemin rengi
    final surfaceColor = colors.surface;
    final onSurfaceColor = colors.onSurface;
    final primaryColor = context.primaryColor;

    return BasePageWrapper(
      showBackButton: false,
      showFab: true,
      customScrollController: scrollController,
      isLoading: detailAsync.isLoading && !detailAsync.hasValue,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: surfaceColor,
        ambientColor: primaryColor.withOpacity(0.05),
      ),
      child: detailAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (final err, final stack) => Center(
            child: Text("Hata: $err", style: TextStyle(color: colors.error))),
        data: (final state) => Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. SİNEMATİK HEADER
                _buildSliverHeader(context, state.show.imageUrl),

                // 2. İÇERİK GÖVDESİ (MODAL GÖRÜNÜMÜ)
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -50),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(40)),
                        boxShadow: [
                          BoxShadow(
                            color: context.isDarkMode
                                ? Colors.white.withOpacity(0.02)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 1,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              margin:
                                  const EdgeInsets.only(top: 16, bottom: 20),
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: onSurfaceColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildCategoryPill(context, "TİYATRO"),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color:
                                                Colors.amber.withOpacity(0.3)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.star_rounded,
                                              color: Colors.amber, size: 18),
                                          SizedBox(width: 4),
                                          Text("9.8",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.amber,
                                                  fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // BAŞLIK
                                Text(
                                  state.show.name,
                                  style: context.textTheme.headlineMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: onSurfaceColor,
                                    // Tema metin rengi
                                    height: 1.1,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // İSTATİSTİKLER (Tema uyumlu)
                                _buildStatsRow(context),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 📖 HİKAYE
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ShowInfoSection(
                              title: "Hikaye",
                              description: state.show.description,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 🎫 ETKİNLİKLER
                          if (state.events.isNotEmpty) ...[
                            _buildSectionHeader(context, "Biletler & Tarihler",
                                Icons.calendar_month_rounded),
                            const SizedBox(height: 16),
                            _buildEventsList(context, state),
                            const SizedBox(height: 32),
                          ],

                          // 🎭 OYUNCULAR
                          if (state.show.nowPlayersId.isNotEmpty) ...[
                            _buildSectionHeader(context, "Oyuncu Kadrosu",
                                Icons.face_retouching_natural_rounded),
                            const SizedBox(height: 16),
                            PlayersBubbleCard(
                              players: (state.players as List<Player>)
                                  .where((final p) =>
                                      state.show.nowPlayersId.contains(p.id))
                                  .toList(),
                              isGrayscale: false, // Renkli
                            ),
                            const SizedBox(height: 32),
                          ],

                          // 📜 GEÇMİŞ KADRO
                          if (state.show.oldPlayersId.isNotEmpty) ...[
                            _buildSectionHeader(context, "Geçmiş Kadrolar",
                                Icons.history_edu_rounded),
                            const SizedBox(height: 16),

                            // 👇 BURASI DEĞİŞTİ: ARTIK HAZIR WIDGET'I ÇAĞIRIYORUZ
                            PlayersBubbleCard(
                              players: (state.players as List<Player>)
                                  .where((final p) =>
                                      state.show.oldPlayersId.contains(p.id))
                                  .toList(),
                              isGrayscale: true, // Siyah-Beyaz
                            ),

                            const SizedBox(height: 32),
                          ],

                          // 🖼️ GALERİ
                          if (state.show.photosShowId.isNotEmpty) ...[
                            _buildSectionHeader(context, "Sahne Arkası",
                                Icons.photo_camera_back_rounded),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: GallerySection(
                                  photos: state.show.photosShowId),
                            ),
                            const SizedBox(height: 150),
                          ],

                          if (state.show.photosShowId.isEmpty)
                            const SizedBox(height: 150),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            _buildTopBar(context),

            // 3. YÜZEN LÜKS BOTTOM BAR
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFloatingBottomBar(context, state),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🎨 BİLEŞENLER (TEMA İLE %100 UYUMLU)
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(final BuildContext context) {
    final colors = context.colors;
    final isScrolled = _isScrolled;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlassmorphismBackButton(),
          Container(
            decoration: BoxDecoration(
              color: isScrolled
                  ? colors.surfaceContainerHighest
                  : Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.share_outlined,
                  size: 20,
                  color: isScrolled ? colors.onSurface : Colors.white),
              onPressed: () {
                final currentState =
                    ref.read(showDetailProvider(widget.showId));
                if (currentState.hasValue && currentState.value != null) {
                  final show = currentState.value!.show;
                  TiyatrolDeeplinkService.shareShow(
                      id: show.id, name: show.name);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(final BuildContext context, final String imageUrl) {
    return SliverAppBar(
      expandedHeight: 480,
      pinned: false,
      stretch: true,
      backgroundColor: context.colors.surface,
      // Tema Rengi
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            OptimizedCachedImage(imageUrl: imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(final BuildContext context, final String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: context.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildStatsRow(final BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow, // Tema SurfaceLow (Kart rengi)
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStat(context, Icons.schedule, "120", "Dakika"),
          Container(width: 1, height: 24, color: colors.outlineVariant),
          _buildStat(context, Icons.explicit, "13+", "Yaş Sınırı"),
          Container(width: 1, height: 24, color: colors.outlineVariant),
          _buildStat(context, Icons.translate, "Türkçe", "Altyazısız"),
        ],
      ),
    );
  }

  Widget _buildStat(final BuildContext context, final IconData icon,
      final String value, final String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.colors.onSecondary, // Tema OnSecondary
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: context.primaryColor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: context.colors.onSurface)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 10,
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      final BuildContext context, final String title, final IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: context.primaryColor),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
                letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(final BuildContext context, final dynamic state) {
    return SizedBox(
      height: 340,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: state.events.length,
        itemBuilder: (final context, final index) {
          final event = state.events[index];
          final stage = state.stages.firstWhere(
              (final s) => s.id == event.stageId,
              orElse: () => Stage(
                  id: "",
                  name: "Sahne",
                  address: "",
                  imageUrl: "",
                  capacity: "",
                  description: "",
                  communication: "",
                  locationLat: 0,
                  locationLng: 0,
                  createdAt: "",
                  updatedAt: "",
                  showsId: []));

          String dateText = event.date;
          String timeText = "--:--";
          try {
            if (event.date.contains(',')) {
              final parts = event.date.split(',');
              final dParts = parts[0].split('.');
              if (dParts.length == 3) {
                dateText =
                    "${dParts[0]} ${_getMonthName(int.tryParse(dParts[1]) ?? 1)}";
                timeText = parts.length > 1 ? parts[1] : "";
              }
            }
          } catch (_) {}

          return EventsCard(
            width: 270,
            margin: const EdgeInsets.only(right: 16),
            imageUrl: state.show.imageUrl,
            showName: state.show.name,
            category: "TİYATRO",
            fullDateString: dateText,
            timeString: timeText,
            stage: stage.name,
            price: double.tryParse(event.price.toString()) ?? 0.0,
            onTap: () {
              final userId =
                  ref.read(currentUserProvider).value?.uid ?? "guest";
              context.pushNamed('seatSelection', pathParameters: {
                'slugWithId': '${widget.showId}-${event.id}-$userId'
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildBubbleCastList(final BuildContext context, final dynamic state,
      final List<String> playerIds, final bool isGrayscale) {
    final List<Player> allPlayers = List<Player>.from(state.players ?? []);
    final players =
        allPlayers.where((final p) => playerIds.contains(p.id)).toList();

    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: players.length,
        itemBuilder: (final context, final index) {
          final player = players[index];
          final fullName = "${player.firstName} ${player.lastName}";

          return Container(
            width: 125,
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => context.pushNamed('playerDetail',
                  pathParameters: {'playerId': player.id}),
              borderRadius: BorderRadius.circular(60),
              child: Card(
                elevation: 4,
                shadowColor: context.colors.shadow.withOpacity(0.1),
                color: context.colors.surfaceContainer,
                // Tema Surface rengi
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(60)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: ClipOval(
                        child: Container(
                          width: 115,
                          height: 115,
                          color: context.colors.surfaceContainerHighest,
                          child: ColorFiltered(
                            colorFilter: isGrayscale
                                ? const ColorFilter.mode(
                                    Colors.grey, BlendMode.saturation)
                                : const ColorFilter.mode(
                                    Colors.transparent, BlendMode.dst),
                            child: OptimizedCachedImage(
                                imageUrl: player.imageUrl, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          fullName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isGrayscale ? FontWeight.w600 : FontWeight.bold,
                            color: isGrayscale
                                ? context.colors.secondary
                                : context.colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingBottomBar(
      final BuildContext context, final dynamic state) {
    double minPrice = 0;
    if (state.events.isNotEmpty) {
      minPrice = double.tryParse(state.events.first.price.toString()) ?? 0;
    }

    // Modal Rengi
    final barColor = context.colors.surfaceContainer.withOpacity(0.95);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: context.colors.onSurface.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Başlayan",
                        style: TextStyle(
                            fontSize: 11,
                            color: context.colors.secondary,
                            fontWeight: FontWeight.w600)),
                    Text("₺${minPrice.toStringAsFixed(0)}",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: context.colors.onSecondary,
                            height: 1)),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: context.colors.onPrimary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => scrollController.animateTo(900,
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOut),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: context.colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Bilet Al",
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 18)),
                          SizedBox(width: 8),
                          Icon(Icons.confirmation_number_rounded, size: 22)
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(final int monthIndex) {
    const months = [
      "",
      "Ocak",
      "Şubat",
      "Mart",
      "Nisan",
      "Mayıs",
      "Haziran",
      "Temmuz",
      "Ağustos",
      "Eylül",
      "Ekim",
      "Kasım",
      "Aralık"
    ];
    return (monthIndex > 0 && monthIndex <= 12) ? months[monthIndex] : "";
  }
}
