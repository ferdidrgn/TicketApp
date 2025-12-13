import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/core/widgets/optimized_cached_image.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../domain/entities/player.dart';
import 'home_cast_provider.dart';

class TeamCard extends ConsumerWidget {
  const TeamCard({super.key});

  void _scroll(final ScrollController controller, final bool left) {
    if (!controller.hasClients) return;
    final offset = left ? -300.0 : 300.0;
    controller.animateTo(
      controller.offset + offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Özel provider'ı dinliyoruz
    final castAsyncValue = ref.watch(homeCastProvider);

    // Scroll controller her build'de sıfırlanmasın diye hook kullanılabilir
    // ama basitlik için stateless içinde tanımlayıp geçiyoruz.
    // (Daha profesyonel çözüm: flutter_hooks kullanımıdır, ama bu hali de çalışır)
    final ScrollController scrollController = ScrollController();

    return Container(
      width: double.infinity,
      padding: context.responsive(
        mobile: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        tablet: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
        desktop: const EdgeInsets.symmetric(vertical: 80, horizontal: 60),
      ),
      decoration: const BoxDecoration(
        gradient: WebColors.backgroundGradient,
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (final bounds) =>
                WebColors.goldGradient.createShader(bounds),
            child: Text(
              'SANATIMIZDAKİ RUHLAR',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.responsive(
                    mobile: 24.0, tablet: 36.0, desktop: 48.0),
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: context.isMobile ? 1 : 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Her oyunun arkasında tutkulu bir hikaye,\nher karakterin içinde deneyimli bir sanatçımız var',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.captionSize + 1,
              color: WebColors.primaryGoldLight,
              height: 1.5,
            ),
          ),
          SizedBox(height: context.responsive(mobile: 30.0, desktop: 50.0)),

          // Data Durum Yönetimi
          castAsyncValue.when(
            data: (final players) {
              if (players.isEmpty) {
                return const Text('Henüz oyuncu bilgisi yok',
                    style: TextStyle(color: Colors.white70));
              }
              return _buildTeamCarousel(context, players, scrollController);
            },
            loading: () =>
                const CircularProgressIndicator(color: WebColors.primaryGold),
            error: (final err, final stack) => const Text('Yüklenemedi',
                style: TextStyle(color: WebColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCarousel(final BuildContext context,
      final List<Player> players, final ScrollController controller) {
    final cardHeight =
        context.responsive(mobile: 260.0, tablet: 320.0, desktop: 380.0);

    return SizedBox(
      height: cardHeight + 60,
      child: Stack(
        children: [
          ListView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: context.responsive(mobile: 16.0, desktop: 60.0),
            ),
            itemCount: players.length,
            itemBuilder: (final context, final index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _TeamMemberCard(member: players[index], index: index),
              );
            },
          ),
          if (!context.isMobile) ...[
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                  child: _buildNavButton(
                      Icons.arrow_back_ios, () => _scroll(controller, true))),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                  child: _buildNavButton(Icons.arrow_forward_ios,
                      () => _scroll(controller, false))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavButton(final IconData icon, final VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: WebColors.goldGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: WebColors.primaryGold.withOpacity(0.5), blurRadius: 15)
          ],
        ),
        child: Icon(icon, color: WebColors.darkBlueBackground, size: 20),
      ),
    );
  }
}

class _TeamMemberCard extends StatefulWidget {
  final Player? member;
  final int index;

  const _TeamMemberCard({required this.member, required this.index});

  @override
  State<_TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<_TeamMemberCard> {
  final ValueNotifier<bool> _isHovered = ValueNotifier(false);

  String _getInitials() {
    if (widget.member == null) return '?';
    final firstName = widget.member!.firstName ?? '';
    final lastName = widget.member!.lastName ?? '';
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();
  }

  @override
  void dispose() {
    _isHovered.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final isMobile = context.isMobile;
    final width =
        context.responsive(mobile: 170.0, tablet: 220.0, desktop: 280.0);
    final height =
        context.responsive(mobile: 260.0, tablet: 320.0, desktop: 380.0);

    final Widget staticContent = ClipRRect(
      borderRadius: BorderRadius.circular(context.isMobile ? 14 : 22),
      child: Stack(
        children: [
          if (widget.member?.imageUrl != null)
            Positioned.fill(
              child: OptimizedCachedImage(
                imageUrl: widget.member!.imageUrl!,
                fit: BoxFit.cover,
                width: width,
                height: height,
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.90)
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding:
                EdgeInsets.all(context.responsive(mobile: 12.0, desktop: 24.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.responsive(mobile: 50.0, desktop: 80.0),
                  height: context.responsive(mobile: 50.0, desktop: 80.0),
                  decoration: BoxDecoration(
                    gradient: WebColors.goldGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: WebColors.primaryGold.withOpacity(0.5),
                          blurRadius: 10)
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(),
                      style: TextStyle(
                        fontSize:
                            context.responsive(mobile: 18.0, desktop: 32.0),
                        fontWeight: FontWeight.w900,
                        color: WebColors.darkBlueBackground,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.member?.firstName ?? ''} ${widget.member?.lastName ?? ''}',
                  style: TextStyle(
                    fontSize: context.responsive(
                        mobile: 16.0, tablet: 20.0, desktop: 24.0),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 10)
                    ],
                  ),
                ),
                SizedBox(height: context.responsive(mobile: 4.0, desktop: 8.0)),
                Text(
                  widget.member?.bio ?? '',
                  style: TextStyle(
                    fontSize: context.captionSize,
                    color: WebColors.lightWhite,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (final context, final value, final child) {
        final safeValue = value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.8 + (safeValue * 0.2),
          child: Opacity(opacity: safeValue, child: child),
        );
      },
      child: isMobile
          ? Listener(
              onPointerDown: (final _) => _isHovered.value = true,
              onPointerUp: (final _) => _isHovered.value = false,
              onPointerCancel: (final _) => _isHovered.value = false,
              child:
                  _buildAnimatedWrapper(width, height, isMobile, staticContent),
            )
          : MouseRegion(
              onEnter: (final _) => _isHovered.value = true,
              onExit: (final _) => _isHovered.value = false,
              child:
                  _buildAnimatedWrapper(width, height, isMobile, staticContent),
            ),
    );
  }

  Widget _buildAnimatedWrapper(final double width, final double height,
      final bool isMobile, final Widget content) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isHovered,
      builder: (final context, final isActive, final child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: width,
          height: height,
          transform: Matrix4.identity()..translate(0.0, isActive ? -10.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
            border: Border.all(
              color: isActive
                  ? WebColors.primaryGold
                  : WebColors.primaryGold.withOpacity(0.3),
              width: isActive ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? WebColors.primaryGold.withOpacity(0.5)
                    : Colors.black.withOpacity(0.3),
                blurRadius: isActive ? 25 : 15,
                spreadRadius: isActive ? 2 : 0,
                offset: Offset(0, isActive ? 12 : 8),
              ),
            ],
          ),
          child: content,
        );
      },
    );
  }
}
