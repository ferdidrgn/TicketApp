import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_detail_provider.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/widgets/events_card.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../players/domain/entities/player.dart';
import '../widgets/mobile/show_info_section.dart'; // Hazır bileşen

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
      if (_scrollController.offset > 300 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 300 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(showDetailProvider(widget.showId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Canlı ama yumuşak zemin
      extendBodyBehindAppBar: true,
      appBar: _buildTransparentAppBar(context),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.black)),
        error: (err, stack) => Center(child: Text("Hata: $err")),
        data: (state) => Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. HEADER (Sinematik)
                _buildSliverHeader(state.show.imageUrl),

                // 2. İÇERİK GÖVDESİ
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -30),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F6F9),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // MERKEZİ HİZALAMA
                        children: [
                          // Tutamaç Çizgisi
                          Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 20),
                            width: 50, height: 5,
                            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                          ),

                          // BAŞLIK ALANI (Center)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                _buildCategoryTag(context, "TİYATRO"),
                                const SizedBox(height: 16),
                                Text(
                                  state.show.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      letterSpacing: -0.5,
                                      height: 1.1
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // İstatistikler (Center)
                                _buildStatsRow(context),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // 📖 HİKAYE (ShowInfoSection)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ShowInfoSection(
                              title: "Hikaye",
                              description: state.show.description,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // 📅 ETKİNLİKLER (Hemen Hikaye Altında)
                          if (state.events.isNotEmpty) ...[
                            _buildSectionTitle("Biletler & Tarihler", Icons.confirmation_number_rounded),
                            const SizedBox(height: 16),
                            _buildEventsList(context, state),
                            const SizedBox(height: 30),
                          ],

                          // 🎭 GÜNCEL KADRO
                          if (state.show.nowPlayersId.isNotEmpty) ...[
                            _buildSectionTitle("Oyuncular", Icons.star_rounded),
                            const SizedBox(height: 16),
                            _buildPlayersList(context, state, state.show.nowPlayersId, false),
                            const SizedBox(height: 30),
                          ],

                          // 📜 ESKİ KADRO
                          if (state.show.oldPlayersId.isNotEmpty) ...[
                            _buildSectionTitle("Geçmiş Kadro", Icons.history_edu_rounded),
                            const SizedBox(height: 16),
                            _buildPlayersList(context, state, state.show.oldPlayersId, true), // Grayscale true
                            const SizedBox(height: 30),
                          ],

                          // 🖼️ GALERİ
                          if (state.show.photosShowId.isNotEmpty) ...[
                            _buildSectionTitle("Sahne Arkası", Icons.photo_camera_back_rounded),
                            const SizedBox(height: 16),
                            _buildCustomGallery(state.show.photosShowId),
                            const SizedBox(height: 120), // Alt bar payı
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 3. YÜZEN ALT BAR
            Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBlurBar(context, state)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🎨 TASARIM BİLEŞENLERİ (Deep & Vivid UI)
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildTransparentAppBar(BuildContext context) {
    return AppBar(
      systemOverlayStyle: _isScrolled ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      backgroundColor: _isScrolled ? Colors.white.withOpacity(0.95) : Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: _isScrolled
          ? const Text("Oyun Detayı", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16))
          : null,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isScrolled ? Colors.white : Colors.black.withOpacity(0.2),
          shape: BoxShape.circle,
          boxShadow: _isScrolled ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)] : null,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: _isScrolled ? Colors.black : Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _isScrolled ? Colors.white : Colors.black.withOpacity(0.2),
            shape: BoxShape.circle,
            boxShadow: _isScrolled ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)] : null,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.favorite_border, size: 20, color: _isScrolled ? Colors.black : Colors.white),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSliverHeader(String imageUrl) {
    return SliverAppBar(
      expandedHeight: 450,
      pinned: false,
      stretch: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            OptimizedCachedImage(imageUrl: imageUrl, fit: BoxFit.cover),
            // Derinlik veren Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.6), // Alt kısmı daha koyu
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.primaryColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: context.primaryColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Text(text.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  // 📊 MERKEZİ VE DERİN İSTATİSTİKLER
  Widget _buildStatsRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // Eşit dağılım
        children: [
          _buildStatItem(Icons.timer_outlined, "120 dk", "Süre", Colors.blue),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          _buildStatItem(Icons.group_outlined, "13+", "Yaş", Colors.orange),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          _buildStatItem(Icons.translate_rounded, "Türkçe", "Dil", Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String val, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // 🏷️ BÖLÜM BAŞLIKLARI (Ortalı ve İkonlu)
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // MERKEZİ
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  // 🎟️ ETKİNLİK KARTLARI (EventsCard)
  Widget _buildEventsList(BuildContext context, dynamic state) {
    return SizedBox(
      height: 280, // Yükseklik verildi, YAN YANA
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        scrollDirection: Axis.horizontal, // YATAY KAYDIRMA
        physics: const BouncingScrollPhysics(),
        itemCount: state.events.length,
        itemBuilder: (context, index) {
          final event = state.events[index];
          final stage = state.stages.firstWhere((s) => s.id == event.stageId, orElse: () => Stage(id: "", name: "Sahne", address: "", imageUrl: "", capacity: "", description: "", communication: "", locationLat: 0, locationLng: 0, createdAt: "", updatedAt: "", showsId: []));

          String dateText = event.date;
          String timeText = "--:--";
          try {
            if (event.date.contains(',')) {
              final parts = event.date.split(',');
              final dParts = parts[0].split('.');
              if (dParts.length == 3) {
                dateText = "${dParts[0]} ${_getMonthName(int.tryParse(dParts[1])??1)}";
                timeText = parts.length > 1 ? parts[1] : "";
              }
            }
          } catch (_) {}

          return EventsCard(
            width: 260, // Sabit genişlik
            margin: const EdgeInsets.only(right: 16), // Yan boşluk
            imageUrl: state.show.imageUrl,
            showName: state.show.name,
            category: "TİYATRO",
            fullDateString: dateText,
            timeString: timeText,
            stage: stage.name,
            price: double.tryParse(event.price.toString()) ?? 0.0,
            onTap: () {
              final userId = ref.read(currentUserProvider).value?.uid ?? "guest";
              context.pushNamed('seatSelection', pathParameters: {'slugWithId': '${widget.showId}-${event.id}-$userId'});
            },
          );
        },
      ),
    );
  }

  // 🎭 OYUNCULAR (Bubble Style & Navigasyonlu)
  Widget _buildPlayersList(BuildContext context, dynamic state, List<String> playerIds, bool isGrayscale) {
    final List<Player> allPlayers = (state.players as List).map((e) => e as Player).toList();
    final players = allPlayers.where((p) => playerIds.contains(p.id)).toList();

    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: players.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final player = players[index];
          return GestureDetector(
            onTap: () {
              // Player Detail Navigasyonu
              context.pushNamed('playerDetail', pathParameters: {'playerId': player.id});
            },
            child: Column(
              children: [
                Container(
                  width: 75, height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                    image: DecorationImage(
                      image: NetworkImage(player.imageUrl),
                      fit: BoxFit.cover,
                      colorFilter: isGrayscale ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 80,
                  child: Text(
                      player.firstName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isGrayscale ? Colors.grey : Colors.black87
                      )
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🖼️ GALERİ
  Widget _buildCustomGallery(List<String> photos) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: OptimizedCachedImage(imageUrl: photos[index], width: 260, height: 180, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  // 💵 ALT BAR
  Widget _buildBottomBlurBar(BuildContext context, dynamic state) {
    double minPrice = 0;
    if (state.events.isNotEmpty) {
      minPrice = double.tryParse(state.events.first.price.toString()) ?? 0;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Başlayan", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text("₺${minPrice.toStringAsFixed(0)}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: context.primaryColor, height: 1)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _scrollController.animateTo(600, duration: const Duration(seconds: 1), curve: Curves.easeInOut), // Biletler kısmına scroll
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 10,
                  shadowColor: Colors.black.withOpacity(0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Bilet Al", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(width: 8),
                    Icon(Icons.confirmation_number_rounded, size: 18)
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _getMonthName(int monthIndex) {
    const months = ["", "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"];
    return (monthIndex > 0 && monthIndex <= 12) ? months[monthIndex] : "";
  }
}