import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_detail_provider.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/widgets/events_card.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/widgets/players_bubble_card.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../domain/entities/show.dart';

class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isStoryExpanded = ValueNotifier(false);

  @override
  void dispose() {
    _scrollController.dispose();
    _isStoryExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(showDetailProvider(widget.showId));

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      customScrollController: _scrollController,
      layoutConfig: BasePageLayoutConfig(
        safeAreaTop: false,
        extendBody: true,
        backgroundColor: context.scaffoldBackgroundColor,
      ),
      child: detailAsync.when(
        loading: () => const Center(child: ArtisticPageShimmer()),
        error: (final err, final stack) => _buildError(context),
        data: (final state) => CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(context, state.show),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: context.scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    SizedBox(height: context.spacingLarge),
                    _buildExpandableStory(context, state.show),
                    _buildQuickInfoRow(context),
                    if (state.events.isNotEmpty) ...[
                      _buildModernSectionTitle(context, "ETKİNLİK TAKVİMİ",
                          Icons.confirmation_number_outlined),
                      _buildHorizontalEvents(context, state),
                    ],
                    _buildModernSectionTitle(
                        context, "OYUNCU KADROSU", Icons.theater_comedy),
                    _buildCastSection(
                        context, state.show.nowPlayersId, state.players, false),
                    if (state.show.oldPlayersId.isNotEmpty) ...[
                      _buildModernSectionTitle(
                          context, "ESKİ KADROLAR", Icons.history),
                      _buildCastSection(context, state.show.oldPlayersId,
                          state.players, true),
                    ],
                    if (state.show.photosShowId.isNotEmpty) ...[
                      _buildModernSectionTitle(
                          context, "GALERİ", Icons.collections_outlined),
                      Padding(
                        padding: context.pagePadding,
                        child: GallerySection(photos: state.show.photosShowId),
                      ),
                    ],
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📖 AÇILIR KAPANIR HİKAYE
  Widget _buildExpandableStory(final BuildContext context, final Show show) {
    return Padding(
      padding: context.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("OYUNUN HİKAYESİ",
              style: context.textTheme.labelLarge
                  ?.copyWith(color: context.primaryColor, letterSpacing: 2)),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: _isStoryExpanded,
            builder: (final context, final isExpanded, final _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      show.description,
                      maxLines: isExpanded ? null : 4,
                      overflow: isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: context.colors.onSurface.withOpacity(0.8)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _isStoryExpanded.value = !isExpanded,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(
                        isExpanded ? "Daha Az Göster" : "Devamını Oku...",
                        style: TextStyle(
                            color: context.primaryColor,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  // 🎫 MODERN YATAY ETKİNLİK LİSTESİ
  // show_detail_page_mobil.dart içindeki _buildHorizontalEvents
  Widget _buildHorizontalEvents(
      final BuildContext context, final ShowDetailState state) {
    return SizedBox(
      height: 280, // Taşmayı önleyen sabit yükseklik
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.events.length,
        itemBuilder: (final context, final index) {
          final event = state.events[index];
          final stage = state.stages.firstWhere(
              (final s) => s.id == event.stageId,
              orElse: () => Stage(
                  id: "",
                  name: "Bilinmeyen Sahne",
                  address: "",
                  imageUrl: '',
                  capacity: '',
                  description: '',
                  communication: '',
                  locationLat: 0.0,
                  locationLng: 0.0,
                  createdAt: '',
                  updatedAt: '',
                  showsId: []));

          // TARİH HATASI ÇÖZÜMÜ: Veri yoksa 'Belirtilmedi' yaz
          String dateText = "Tarih Belirtilmedi";
          try {
            final df = DateFormatter.formatForEventCard(event.date.toString());
            dateText = "${df['day']} ${df['monthName']} ${df['time']}";
          } catch (e) {
            dateText = "Tarih Hatası";
          }

          return EventsCard(
            width: 260,
            imageUrl: state.show.imageUrl,
            showName: state.show.name,
            category: "TİYATRO",
            date: dateText,
            stage: stage.name,
            price: double.tryParse(event.price.toString()) ?? 0.0,
            onTap: () {
              final userId =
                  ref.read(currentUserProvider).value?.uid ?? "guest";
              // Router'daki slugWithId yapısına uygun navigasyon:
              context.pushNamed('seatSelection', pathParameters: {
                'slugWithId': '${widget.showId}-${event.id}-$userId'
              });
            },
          );
        },
      ),
    );
  }

  // 🎬 SLIVER HEADER (PARALLAX EFFECT)
  Widget _buildSliverHeader(final BuildContext context, final Show show) {
    return SliverAppBar(
      expandedHeight: context.screenHeight * 0.45,
      pinned: true,
      backgroundColor: context.scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            OptimizedCachedImage(imageUrl: show.imageUrl, fit: BoxFit.cover),
            // Şık Radyal Gradyan Katmanı
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    context.scaffoldBackgroundColor.withOpacity(0.8),
                    context.scaffoldBackgroundColor,
                  ],
                  stops: const [0.2, 0.7, 1.0],
                ),
              ),
            ),
            // Alt Başlık Alanı
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("TİYATRO",
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    show.name.toUpperCase(),
                    style: context.textTheme.headlineMedium?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorySection(final Show show) {
    return Padding(
      padding: context.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bölüm Başlığı
          Text(
            "OYUNUN HİKAYESİ",
            style: context.textTheme.labelLarge?.copyWith(
              color: context.primaryColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: _isStoryExpanded,
            builder: (final context, final bool isExpanded, final _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: Text(
                      show.description,
                      maxLines: isExpanded ? null : 3,
                      style: context.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: context.colors.onSurface.withOpacity(0.85),
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  // "Daha Fazla / Daha Az" Butonu
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _isStoryExpanded.value = !isExpanded,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(
                        isExpanded ? "Daha Az Gör" : "Tamamını Oku...",
                        style: TextStyle(
                          color: context.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  // 👥 OYUNCU BÖLÜMÜ (OLD/NEW)
  Widget _buildCastSection(final BuildContext context, final List<String> ids,
      final List<Player> all, final bool isGrayscale) {
    final players = all.where((final p) => ids.contains(p.id)).toList();
    if (players.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: PlayersBubbleCard(
        title: "",
        players: players,
        isGrayscale: isGrayscale,
      ),
    );
  }

  // ℹ️ HIZLI BİLGİ ROW
  Widget _buildQuickInfoRow(final BuildContext context) {
    return Padding(
      padding: context.pagePadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem(Icons.timer_outlined, "120 Dakika"),
          _buildInfoItem(Icons.family_restroom, "13+ Yaş"),
          _buildInfoItem(Icons.language, "Türkçe"),
        ],
      ),
    );
  }

  Widget _buildInfoItem(final IconData icon, final String text) {
    return Column(
      children: [
        Icon(icon, color: context.primaryColor, size: 28),
        const SizedBox(height: 4),
        Text(text, style: context.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildModernSectionTitle(
      final BuildContext context, final String title, final IconData icon) {
    return Padding(
      padding: context.pagePadding + const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: context.primaryColor, size: 22),
          const SizedBox(width: 8),
          Text(title,
              style: context.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const Spacer(),
          Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                  color: context.primaryColor,
                  borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  Widget _buildError(final BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.theater_comedy, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Oyun bilgileri yüklenemedi."),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Geri Dön")),
        ],
      ),
    );
  }
}
