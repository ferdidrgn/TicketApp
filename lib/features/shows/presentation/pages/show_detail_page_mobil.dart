import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_detail_provider.dart';
import 'package:ticketapp/shared/widgets/button/back_button_glassmorphism.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/widgets/events_card.dart';
import '../../../players/domain/entities/player.dart';
import '../../../stages/domain/entities/stage.dart';
import '../widgets/mobile/show_info_section.dart';

class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final isScrolledNow = _scrollController.offset > 300;
      if (isScrolledNow != _isScrolled)
        setState(() => _isScrolled = isScrolledNow);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(showDetailProvider(widget.showId));
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      extendBodyBehindAppBar: true,
      appBar: _buildTransparentAppBar(context),
      body: detailAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: context.primaryColor)),
        error: (final err, final stack) => Center(
            child: Text("Hata: $err", style: TextStyle(color: colors.error))),
        data: (final state) => Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. SİNEMATİK HEADER
                _buildSliverHeader(context, state.show.imageUrl),

                // 2. İÇERİK
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -30),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, -10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tutamaç
                          Center(
                            child: Container(
                              margin:
                                  const EdgeInsets.only(top: 12, bottom: 24),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: colors.onSurface.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Kategori
                                Row(
                                  children: [
                                    _buildCategoryPill(context, "TİYATRO"),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.star_rounded,
                                              color: Colors.amber, size: 16),
                                          SizedBox(width: 4),
                                          Text("9.8",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // BAŞLIK
                                Text(
                                  state.show.name,
                                  style: context.textTheme.headlineMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: colors.onSurface,
                                    height: 1.1,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // İSTATİSTİKLER
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

                          // 🎫 ETKİNLİKLER (Height Fix Yapıldı)
                          if (state.events.isNotEmpty) ...[
                            _buildSectionHeader(context, "Biletler & Tarihler",
                                Icons.calendar_month_outlined),
                            const SizedBox(height: 16),
                            _buildEventsList(context, state),
                            const SizedBox(height: 32),
                          ],

                          // 🎭 GÜNCEL KADRO
                          if (state.show.nowPlayersId.isNotEmpty) ...[
                            _buildSectionHeader(context, "Oyuncular",
                                Icons.face_retouching_natural),
                            const SizedBox(height: 16),
                            _buildCastList(context, state,
                                state.show.nowPlayersId, false), // Renkli
                            const SizedBox(height: 32),
                          ],

                          // 📜 GEÇMİŞ KADRO (Şık Kartlar)
                          if (state.show.oldPlayersId.isNotEmpty) ...[
                            _buildSectionHeader(
                                context, "Geçmiş Kadro", Icons.history_edu),
                            const SizedBox(height: 16),
                            _buildCastList(
                                context,
                                state,
                                state.show.oldPlayersId,
                                true), // Grayscale & Süslü
                            const SizedBox(height: 32),
                          ],

                          // 🖼️ GALERİ (Senin Koduna Bağlandı)
                          if (state.show.photosShowId.isNotEmpty) ...[
                            _buildSectionHeader(context, "Sahne Arkası",
                                Icons.photo_library_outlined),
                            const SizedBox(height: 16),
                            // ✅ SENİN WIDGET'IN BURADA
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: GallerySection(
                                  photos: state.show.photosShowId),
                            ),
                            const SizedBox(height: 140),
                            // Bottom bar altında kalmaması için boşluk
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 3. FLOAT BOTTOM BAR (Süslü, Kıvırık, Shadowlu)
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
  // 🎨 BİLEŞENLER
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildTransparentAppBar(final BuildContext context) {
    final colors = context.colors;
    final isScrolled = _isScrolled;

    return AppBar(
      systemOverlayStyle: isScrolled
          ? (context.isDarkMode
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark)
          : SystemUiOverlayStyle.light,
      backgroundColor:
          isScrolled ? colors.surface.withOpacity(0.8) : Colors.transparent,
      elevation: 0,
      flexibleSpace: isScrolled
          ? ClipRRect(
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent)))
          : null,
      leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isScrolled
                ? colors.surfaceContainerHighest
                : Colors.black.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: GlassmorphismBackButton()),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isScrolled
                ? colors.surfaceContainerHighest
                : Colors.black.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.share_outlined,
                size: 20, color: isScrolled ? colors.onSurface : Colors.white),
            onPressed: () {
              // 1. Provider'dan o anki veriyi okuyoruz (Listen değil, Read)
              final currentState = ref.read(showDetailProvider(widget.showId));

              // 2. Eğer veri yüklendiyse (Data durumundaysa) paylaşımı tetikle
              if (currentState.hasValue && currentState.value != null) {
                final show = currentState.value!.show;

                // Servis çağrısı:
                TiyatrolDeeplinkService.shareShow(id: show.id, name: show.name);
              } else
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Veriler yükleniyor...")));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSliverHeader(final BuildContext context, final String imageUrl) {
    return SliverAppBar(
      expandedHeight: 460,
      pinned: false,
      stretch: true,
      backgroundColor: context.colors.surface,
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
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.primaryColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: context.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
            color: context.colors.onPrimary,
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
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: context.colors.onSecondary, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: context.primaryColor),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: context.colors.onSurface)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 10,
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
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
          Icon(icon, size: 20, color: context.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
                letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  // ✅ DÜZELTME: Height 340'a çıkarıldı (37px sorunu çözüldü)
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
            width: 260,
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

  // 🎭 OYUNCU LİSTESİ (ESKİ OYUNCULAR İÇİN ŞIK TASARIM)
  Widget _buildCastList(final BuildContext context, final dynamic state,
      final List<String> playerIds, final bool isGrayscale) {
    final List<Player> allPlayers =
        (state.players as List).map((final e) => e as Player).toList();
    final players =
        allPlayers.where((final p) => playerIds.contains(p.id)).toList();

    return SizedBox(
      height: 120, // Biraz daha yer açtık
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: players.length,
        separatorBuilder: (final _, final __) => const SizedBox(width: 16),
        itemBuilder: (final context, final index) {
          final player = players[index];
          return GestureDetector(
            onTap: () => context.pushNamed('playerDetail',
                pathParameters: {'playerId': player.id}),
            child: Column(
              children: [
                // ŞIK AVATAR TASARIMI
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isGrayscale
                            ? context.colors.outline
                            : context.primaryColor.withOpacity(0.5),
                        width: isGrayscale ? 2 : 3),
                    image: DecorationImage(
                      image: NetworkImage(player.imageUrl),
                      fit: BoxFit.cover,
                      colorFilter: isGrayscale
                          ? const ColorFilter.mode(
                              Colors.grey, BlendMode.saturation)
                          : null,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black
                              .withOpacity(isGrayscale ? 0.05 : 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5))
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 80,
                  child: Text(player.firstName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isGrayscale ? FontWeight.w600 : FontWeight.bold,
                          color: isGrayscale
                              ? context.colors.secondary
                              : context.colors.onSurface)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 💎 SÜSLÜ, KIVIRIK, SHADOWLU BOTTOM BAR
  Widget _buildFloatingBottomBar(
      final BuildContext context, final dynamic state) {
    double minPrice = 0;
    if (state.events.isNotEmpty) {
      minPrice = double.tryParse(state.events.first.price.toString()) ?? 0;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      // Yüzen (Floating) Effect
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer, // M3 Surface rengi
        borderRadius: BorderRadius.circular(32), // İyice kıvırık
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withOpacity(0.25), // Güçlü gölge
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
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glassmorphism içi
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
                          color: context.colors.onPrimary.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _scrollController.animateTo(900,
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOut),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: context.colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 0, // Gölgeyi Container veriyor
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
