import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/base/base_page_wrapper.dart';

class PlayerDetailPage extends ConsumerStatefulWidget {
  final String playerId;

  const PlayerDetailPage({super.key, required this.playerId});

  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        ambientColor: context.colors.secondary.withOpacity(0.04),
      ),
      child: isLargeScreen
          ? _buildWebLayout(context)
          : _buildMobileLayout(context),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MOBILE LAYOUT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(final BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildMobileSliverAppBar(context),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMobileHeader(context),
                  _buildMobileStats(context),
                  _buildMobileAbout(context),
                  _buildMobileGallery(context),
                  _buildMobileShows(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSliverAppBar(final BuildContext context) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      stretch: true,
      backgroundColor: context.colors.surface,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colors.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colors.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.share_rounded, color: context.colors.primary),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.colors.secondaryContainer,
                    context.colors.tertiaryContainer,
                  ],
                ),
              ),
            ),
            // Player image (centered circular)
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 40),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      context.colors.surface,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        children: [
          // Name
          Text(
            "saçma",
            textAlign: TextAlign.center,
            style: context.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          // Role
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: context.colors.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.colors.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: context.colors.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Oyuncu & Yönetmen',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Social buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                context,
                Icons.language_rounded,
                'Website',
              ),
              const SizedBox(width: 12),
              _buildSocialButton(
                context,
                Icons.image_rounded,
                'Instagram',
              ),
              const SizedBox(width: 12),
              _buildSocialButton(
                context,
                Icons.play_circle_outline_rounded,
                'YouTube',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
      final BuildContext context, final IconData icon, final String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: context.colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStats(final BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colors.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              '47',
              'Gösteri',
              Icons.confirmation_number_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: context.colors.outlineVariant.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              '12',
              'Ödül',
              Icons.emoji_events_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: context.colors.outlineVariant.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              '15Y',
              'Deneyim',
              Icons.star_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    final BuildContext context,
    final String value,
    final String label,
    final IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: context.colors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAbout(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hakkında',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: context.colors.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Text(
              'Türk tiyatro ve sinema sanatçısı. Birçok ödüllü yapımda rol almış, '
              'aynı zamanda başarılı yönetmenlik deneyimleri bulunmaktadır. '
              'Sanat hayatı boyunca 47\'den fazla gösteride yer almış ve '
              '12 farklı ödül kazanmıştır.',
              style: context.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileGallery(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Galeri',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 5,
            itemBuilder: (final context, final index) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.shadow.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1503095396549-807759245b35?w=600',
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileShows(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son Gösteriler',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Tümünü Gör',
                  style: TextStyle(color: context.colors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: 4,
          itemBuilder: (final context, final index) {
            return _buildMobileShowCard(context, index);
          },
        ),
      ],
    );
  }

  Widget _buildMobileShowCard(final BuildContext context, final int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colors.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            child: Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primaryContainer,
                    context.colors.tertiaryContainer,
                  ],
                ),
              ),
              child: Image.network(
                'https://images.unsplash.com/photo-1503095396549-807759245b35?w=200',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gösteri ${index + 1}',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '2024 • Tiyatro',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: context.colors.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '4.${8 - index}',
                        style: context.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Arrow
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WEB/TABLET LAYOUT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildWebLayout(final BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildWebHeader(context),
                  const SizedBox(height: 40),
                  _buildWebStats(context),
                  const SizedBox(height: 48),
                  _buildWebContent(context),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebHeader(final BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Image
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                context.colors.secondaryContainer,
                context.colors.tertiaryContainer,
              ],
            ),
            border: Border.all(
              color: Colors.white,
              width: 6,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.shadow.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 60),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: context.colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.colors.secondary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: context.colors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Oyuncu & Yönetmen',
                      style: context.textTheme.titleSmall?.copyWith(
                        color: context.colors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Name
              Text(
                "saçma",
                style: context.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Bio
              Text(
                'Türk tiyatro ve sinema sanatçısı. Birçok ödüllü yapımda rol almış, '
                'aynı zamanda başarılı yönetmenlik deneyimleri bulunmaktadır. '
                'Sanat hayatı boyunca 47\'den fazla gösteride yer almış ve '
                '12 farklı ödül kazanmıştır.',
                style: context.textTheme.titleMedium?.copyWith(
                  height: 1.6,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              // Social links
              Row(
                children: [
                  _buildWebSocialButton(
                    context,
                    Icons.language_rounded,
                    'Website',
                  ),
                  const SizedBox(width: 16),
                  _buildWebSocialButton(
                    context,
                    Icons.image_rounded,
                    'Instagram',
                  ),
                  const SizedBox(width: 16),
                  _buildWebSocialButton(
                    context,
                    Icons.play_circle_outline_rounded,
                    'YouTube',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebSocialButton(
      final BuildContext context, final IconData icon, final String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebStats(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: context.colors.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildWebStatItem(
            context,
            Icons.confirmation_number_rounded,
            '47',
            'Gösteri',
          ),
          Container(
            width: 1,
            height: 80,
            color: context.colors.outlineVariant.withOpacity(0.3),
          ),
          _buildWebStatItem(
            context,
            Icons.emoji_events_rounded,
            '12',
            'Ödül',
          ),
          Container(
            width: 1,
            height: 80,
            color: context.colors.outlineVariant.withOpacity(0.3),
          ),
          _buildWebStatItem(
            context,
            Icons.star_rounded,
            '15Y',
            'Deneyim',
          ),
          Container(
            width: 1,
            height: 80,
            color: context.colors.outlineVariant.withOpacity(0.3),
          ),
          _buildWebStatItem(
            context,
            Icons.people_rounded,
            '2.5M',
            'Takipçi',
          ),
        ],
      ),
    );
  }

  Widget _buildWebStatItem(
    final BuildContext context,
    final IconData icon,
    final String value,
    final String label,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            size: 32,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          value,
          style: context.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildWebContent(final BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: context.colors.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: context.colors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: context.colors.primary,
              unselectedLabelColor: context.colors.onSurfaceVariant,
              labelStyle: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              padding: const EdgeInsets.all(8),
              tabs: const [
                Tab(text: 'Galeri'),
                Tab(text: 'Son Gösteriler'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 600,
            child: TabBarView(
              children: [
                _buildWebGallery(context),
                _buildWebShows(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebGallery(final BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.5,
      ),
      itemCount: 9,
      itemBuilder: (final context, final index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: context.colors.shadow.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              'https://images.unsplash.com/photo-1503095396549-807759245b35?w=600',
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebShows(final BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 3.5,
      ),
      itemCount: 6,
      itemBuilder: (final context, final index) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.colors.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.colors.primaryContainer,
                        context.colors.tertiaryContainer,
                      ],
                    ),
                  ),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1503095396549-807759245b35?w=300',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Gösteri ${index + 1}',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '2024 • Tiyatro • 150 dk',
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 20,
                            color: context.colors.tertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '4.${8 - index}',
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colors.tertiary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${450 + index * 50} değerlendirme)',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
