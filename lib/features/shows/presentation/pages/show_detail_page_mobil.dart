import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/util/global_scroll_mixin.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_detail_provider.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/button/back_button_glassmorphism.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart'
    show currentUserIdProvider;
import '../../../events/presentation/widgets/events_card.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/widgets/players_bubble_card.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../users/presentation/providers/user_provider.dart'
    show userProfileProvider;
import '../widgets/mobile/show_info_section.dart';

class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage>
    with SingleTickerProviderStateMixin, GlobalScrollMixin {
  bool _isScrolled = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Scroll listener
    scrollController.addListener(() {
      final isScrolledNow = scrollController.offset > 250;
      if (isScrolledNow != _isScrolled)
        setState(() => _isScrolled = isScrolledNow);
    });

    // Animations
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(showDetailProvider(widget.showId));
    final colors = context.colors;
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return BasePageWrapper(
      showBackButton: false,
      showFab: !isLargeScreen,
      customScrollController: scrollController,
      isLoading: detailAsync.isLoading && !detailAsync.hasValue,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: colors.surface,
        ambientColor: colors.primary.withOpacity(0.04),
      ),
      child: detailAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.primary)),
        error: (final err, final stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text("Bir hata oluştu",
                  style: context.textTheme.titleLarge?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 8),
              Text("$err",
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  )),
            ],
          ),
        ),
        data: (final state) => isLargeScreen
            ? _buildWebLayout(context, state)
            : _buildMobileLayout(context, state),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MOBILE LAYOUT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(final BuildContext context, final dynamic state) {
    final colors = context.colors;

    return Stack(
      children: [
        CustomScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero Header
            _buildMobileSliverHeader(context, state.show.imageUrl),

            // Content Body
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Transform.translate(
                    offset: const Offset(0, -40),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Drag Handle
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 12, bottom: 8),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: colors.onSurfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Header Section
                          _buildMobileHeaderSection(context, state),

                          // Quick Stats
                          _buildMobileQuickStats(context, state),

                          const SizedBox(height: 32),

                          // Description
                          if (state.show.description.isNotEmpty) ...[
                            _buildSectionHeader(
                                context, "Hikaye", Icons.auto_stories_rounded),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: ShowInfoSection(
                                title: "",
                                description: state.show.description,
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Events
                          if (state.events.isNotEmpty) ...[
                            _buildSectionHeader(context, "Seanslar & Biletler",
                                Icons.event_rounded),
                            const SizedBox(height: 16),
                            _buildMobileEventsList(context, state),
                            const SizedBox(height: 32),
                          ],

                          // Current Cast
                          if (state.show.nowPlayersId.isNotEmpty) ...[
                            _buildSectionHeader(context, "Oyuncu Kadrosu",
                                Icons.people_rounded),
                            const SizedBox(height: 16),
                            PlayersBubbleCard(
                              players: (state.players as List<Player>)
                                  .where((final p) =>
                                      state.show.nowPlayersId.contains(p.id))
                                  .toList(),
                              isGrayscale: false,
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Past Cast
                          if (state.show.oldPlayersId.isNotEmpty) ...[
                            _buildSectionHeader(context, "Geçmiş Kadrolar",
                                Icons.history_rounded),
                            const SizedBox(height: 16),
                            PlayersBubbleCard(
                              players: (state.players as List<Player>)
                                  .where((final p) =>
                                      state.show.oldPlayersId.contains(p.id))
                                  .toList(),
                              isGrayscale: true,
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Gallery
                          if (state.show.photosShowId.isNotEmpty) ...[
                            _buildSectionHeader(context, "Sahne Arkası",
                                Icons.photo_library_rounded),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: GallerySection(
                                  photos: state.show.photosShowId),
                            ),
                          ],

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Top Bar
        _buildMobileTopBar(context),

        // Floating Bottom Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildFloatingBottomBar(context, state),
        ),
      ],
    );
  }

  Widget _buildMobileSliverHeader(
      final BuildContext context, final String imageUrl) {
    final colors = context.colors;

    return SliverAppBar(
      expandedHeight: 420,
      pinned: false,
      stretch: true,
      backgroundColor: colors.surface,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Resim (Hero)
            Hero(
              tag: 'show_${widget.showId}',
              child: OptimizedCachedImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            // 2. Sadeleştirilmiş Gradyan (Sadece yazının okunması için dipte hafif geçiş)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    // Üstteki ikonlar görünsün diye hafif koyuluk
                    Colors.transparent,
                    // Resmin ortası tamamen net
                    Colors.transparent,
                    colors.surface,
                    // En altta sayfa rengine yumuşak geçiş
                  ],
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTopBar(final BuildContext context) {
    final colors = context.colors;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const GlassmorphismBackButton(),
              Row(
                children: [
                  // Favorite Button
                  Container(
                    decoration: BoxDecoration(
                      color: _isScrolled
                          ? colors.surfaceContainerHighest.withOpacity(0.95)
                          : Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isScrolled
                            ? colors.outline.withOpacity(0.1)
                            : Colors.white.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.favorite_border_rounded,
                        size: 22,
                        color: _isScrolled ? colors.primary : Colors.white,
                      ),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share Button
                  Container(
                    decoration: BoxDecoration(
                      color: _isScrolled
                          ? colors.surfaceContainerHighest.withOpacity(0.95)
                          : Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isScrolled
                            ? colors.outline.withOpacity(0.1)
                            : Colors.white.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.share_rounded,
                        size: 22,
                        color: _isScrolled ? colors.onSurface : Colors.white,
                      ),
                      onPressed: () {
                        final currentState =
                            ref.read(showDetailProvider(widget.showId));
                        if (currentState.hasValue &&
                            currentState.value != null) {
                          final show = currentState.value!.show;
                          TiyatrolDeeplinkService.shareShow(
                              id: show.id, name: show.name);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeaderSection(
      final BuildContext context, final dynamic state) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category & Rating
          Row(
            children: [
              // Category Chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.theater_comedy_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "TİYATRO",
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Rating Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.tertiary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: colors.tertiary, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "4.8",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.tertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            state.show.name,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileQuickStats(
      final BuildContext context, final dynamic state) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow(
            context,
            Icons.access_time_rounded,
            "Süre",
            "120 dakika",
          ),
          const SizedBox(height: 16),
          Divider(
            color: colors.outlineVariant.withOpacity(0.3),
            height: 1,
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            context,
            Icons.language_rounded,
            "Dil",
            "Türkçe",
          ),
          const SizedBox(height: 16),
          Divider(
            color: colors.outlineVariant.withOpacity(0.3),
            height: 1,
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            context,
            Icons.child_care_rounded,
            "Yaş Sınırı",
            "13+",
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    final BuildContext context,
    final IconData icon,
    final String label,
    final String value,
  ) {
    final colors = context.colors;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    final BuildContext context,
    final String title,
    final IconData icon,
  ) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileEventsList(
          final BuildContext context, final dynamic state) =>
      SizedBox(
        height: 340,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                showsId: [],
              ),
            );

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
                // Auth'dan gelen UID'yi doğrudan alıyoruz
                final userId = ref.read(currentUserIdProvider) ?? "guest";
                NavigationHandler.goToSeatSelection(
                    context, widget.showId, event.id, userId);
              },
            );
          },
        ),
      );

  Widget _buildFloatingBottomBar(
      final BuildContext context, final dynamic state) {
    final colors = context.colors;
    double minPrice = 0;
    if (state.events.isNotEmpty)
      minPrice = double.tryParse(state.events.first.price.toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.surfaceContainer.withOpacity(0.98),
            colors.surfaceContainerHighest.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Price Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Başlayan",
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "₺${minPrice.toStringAsFixed(0)}",
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => scrollController.animateTo(
                        800,
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutCubic,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Bilet Al",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WEB/TABLET LAYOUT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildWebLayout(final BuildContext context, final dynamic state) =>
      SingleChildScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildWebHeader(context, state),
                    const SizedBox(height: 48),
                    _buildWebContent(context, state),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildWebHeader(final BuildContext context, final dynamic state) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        Expanded(
          flex: 2,
          child: Hero(
            tag: 'show_${widget.showId}',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: OptimizedCachedImage(
                    imageUrl: state.show.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
        // Info
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category & Rating
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: colors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.theater_comedy_rounded,
                            size: 20, color: colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          "TİYATRO",
                          style: context.textTheme.titleSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 22, color: colors.tertiary),
                        const SizedBox(width: 6),
                        Text(
                          "4.8",
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                state.show.name,
                style: context.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              // Description
              Text(
                state.show.description,
                style: context.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 32),
              // Stats
              _buildWebQuickStats(context, state),
              const SizedBox(height: 32),
              // CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => scrollController.animateTo(
                    800,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOutCubic,
                  ),
                  icon: const Icon(Icons.confirmation_number_rounded),
                  label: const Text(
                    "Bilet Al",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebQuickStats(final BuildContext context, final dynamic state) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildWebStatItem(
              context,
              Icons.access_time_rounded,
              "Süre",
              "120 dk",
            ),
          ),
          Expanded(
            child: _buildWebStatItem(
              context,
              Icons.language_rounded,
              "Dil",
              "Türkçe",
            ),
          ),
          Expanded(
            child: _buildWebStatItem(
              context,
              Icons.child_care_rounded,
              "Yaş",
              "13+",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebStatItem(
    final BuildContext context,
    final IconData icon,
    final String label,
    final String value,
  ) {
    final colors = context.colors;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 24, color: colors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: context.textTheme.labelMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildWebContent(final BuildContext context, final dynamic state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Events
        if (state.events.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            "Seanslar & Biletler",
            Icons.event_rounded,
          ),
          const SizedBox(height: 24),
          _buildWebEventsList(context, state),
          const SizedBox(height: 48),
        ],

        // Cast
        if (state.show.nowPlayersId.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            "Oyuncu Kadrosu",
            Icons.people_rounded,
          ),
          const SizedBox(height: 24),
          PlayersBubbleCard(
            players: (state.players as List<Player>)
                .where((final p) => state.show.nowPlayersId.contains(p.id))
                .toList(),
            isGrayscale: false,
          ),
          const SizedBox(height: 48),
        ],

        // Gallery
        if (state.show.photosShowId.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            "Sahne Arkası",
            Icons.photo_library_rounded,
          ),
          const SizedBox(height: 24),
          GallerySection(photos: state.show.photosShowId),
        ],
      ],
    );
  }

  Widget _buildWebEventsList(final BuildContext context, final dynamic state) =>
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.5,
        ),
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
              showsId: [],
            ),
          );

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
            imageUrl: state.show.imageUrl,
            showName: state.show.name,
            category: "TİYATRO",
            fullDateString: dateText,
            timeString: timeText,
            stage: stage.name,
            price: double.tryParse(event.price.toString()) ?? 0.0,
            onTap: () {
              // Auth'dan gelen UID'yi doğrudan alıyoruz
              final userId = ref.read(currentUserIdProvider) ?? "guest";
              NavigationHandler.goToSeatSelection(
                  context, widget.showId, event.id, userId);
            },
          );
        },
      );

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
