import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../data/datasources/player/player_remote_data_source_and_impl.dart';
import '../../../../../../data/datasources/show/show_remote_data_source_and_impl.dart';
import '../../../../../../domain/entities/player.dart';

class TeamCard extends StatefulWidget {
  const TeamCard({super.key});

  @override
  State<TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<TeamCard> {
  final ScrollController _scrollController = ScrollController();
  List<Player?> nowPlayerDataList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchShowData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchShowData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;

      final showService = ShowRemoteDataSourceImpl(
        firestore: firestore,
        storage: storage,
      );

      final shows = await showService.getShowsByIds(["XqKkUbIflyWxZbNLZvqV"]);

      if (shows != null && shows.isNotEmpty) {
        await _fetchNowPlayers(
            shows.first?.nowPlayersId?.cast<String>(), firestore);
      }
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchNowPlayers(
      final List<String>? playersId, final FirebaseFirestore firestore) async {
    if (playersId != null && playersId.isNotEmpty) {
      try {
        final playerService = PlayerRemoteDataSourceImpl(firestore: firestore);
        final players = await playerService.getPlayersByIds(playersId);

        if (mounted) {
          setState(() {
            nowPlayerDataList = players
                ?.map((final e) => e?.toEntity())
                .whereType<Player>()
                .toList() ??
                [];
          });
        }
      } catch (error) {
        setState(() {
          errorMessage = error.toString();
        });
      }
    }
  }

  void _scroll(final bool left) {
    final offset = left ? -350.0 : 350.0;
    _scrollController.animateTo(
      _scrollController.offset + offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: double.infinity,
      // Responsive Padding: Mobil için daha dar, masaüstü için geniş
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
          // Başlık - Responsive Font Size
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
              fontSize: context.bodySize, // ResponsiveUtils bodySize
              color: WebColors.primaryGoldLight,
              height: 1.6,
            ),
          ),

          SizedBox(
              height: context.responsive(
                  mobile: 30.0, desktop: 48.0)), // Dinamik boşluk

          // Team Content
          if (isLoading)
            const CircularProgressIndicator(color: WebColors.primaryGold)
          else if (errorMessage != null)
            _buildErrorState()
          else if (nowPlayerDataList.isEmpty)
              _buildEmptyState()
            else
              _buildTeamCarousel(context),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: WebColors.error, size: 64),
        const SizedBox(height: 16),
        Text(
          'Oyuncu bilgileri yüklenemedi',
          style: TextStyle(
            fontSize: context.bodySize,
            color: WebColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const Icon(Icons.people_outline,
            color: WebColors.textSecondary, size: 64),
        const SizedBox(height: 16),
        Text(
          'Henüz oyuncu bilgisi eklenmemiş',
          style: TextStyle(
            fontSize: context.bodySize,
            color: WebColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCarousel(final BuildContext context) {
    // Kart yüksekliğini responsive ayarlıyoruz
    // Mobilde daha kısa, masaüstünde daha uzun
    final cardHeight = context.responsive(
        mobile: 300.0, tablet: 340.0, desktop: 380.0);

    return SizedBox(
      // Efektler ve gölgeler için ekstra pay (+50)
      height: cardHeight + 50,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(
              top: 20.0,
              bottom: 20.0,
              left: context.responsive(mobile: 16.0, desktop: 60.0),
              right: context.responsive(mobile: 16.0, desktop: 60.0),
            ),
            itemCount: nowPlayerDataList.length,
            itemBuilder: (final context, final index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _TeamMemberCard(
                  member: nowPlayerDataList[index],
                  index: index,
                ),
              );
            },
          ),

          // Navigation Buttons (Sadece Desktop/Tablet'te göster)
          if (!context.isMobile) ...[
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child:
                _buildNavButton(Icons.arrow_back_ios, () => _scroll(true)),
              ),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavButton(
                    Icons.arrow_forward_ios, () => _scroll(false)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavButton(final IconData icon, final VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: WebColors.goldGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: WebColors.primaryGold.withOpacity(0.5),
            blurRadius: 15,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: WebColors.darkBlueBackground),
        iconSize: context.iconMedium,
      ),
    );
  }
}

// ------------------------------------------------------------------
// _TeamMemberCard
// ------------------------------------------------------------------

class _TeamMemberCard extends StatefulWidget {
  final Player? member;
  final int index;

  const _TeamMemberCard({
    required this.member,
    required this.index,
  });

  @override
  State<_TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<_TeamMemberCard> {
  bool _isActive = false;

  String _getInitials() {
    if (widget.member == null) return '?';
    final firstName = widget.member!.firstName ?? '';
    final lastName = widget.member!.lastName ?? '';
    final initials = (firstName.isNotEmpty ? firstName[0] : '') +
        (lastName.isNotEmpty ? lastName[0] : '');
    return initials.toUpperCase();
  }

  void _handlePointerDown(final PointerEvent event) {
    if (event is PointerDownEvent) {
      setState(() {
        _isActive = true;
      });
    }
  }

  void _handlePointerUp(final PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      setState(() {
        _isActive = false;
      });
    }
  }

  Widget _buildCardContent(final BuildContext context, final bool active) {
    // KART BOYUTLARI - Responsive
    // Mobilde genişlik 200, yükseklik 300 (Daha kompakt)
    // Masaüstünde genişlik 280, yükseklik 380 (Daha büyük)
    final width = context.responsive(mobile: 200.0, tablet: 240.0, desktop: 280.0);
    final height = context.responsive(mobile: 300.0, tablet: 340.0, desktop: 380.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      transform: Matrix4.identity()..translate(0.0, active ? -10.0 : 0.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: active
              ? WebColors.primaryGold
              : WebColors.primaryGold.withOpacity(0.3),
          width: active ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? WebColors.primaryGold.withOpacity(0.5)
                : Colors.black.withOpacity(0.3),
            blurRadius: active ? 25 : 15,
            spreadRadius: active ? 5 : 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            if (widget.member?.imageUrl != null)
              Positioned.fill(
                child: Image.network(
                  widget.member!.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (final context, final error, final stackTrace) {
                    return Container(
                      color: WebColors.darkBlueSurface,
                    );
                  },
                ),
              ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),

            // Content Padding
            Padding(
              padding: EdgeInsets.all(
                  context.responsive(mobile: 16.0, desktop: 24.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: context.responsive(mobile: 60.0, desktop: 80.0),
                    height: context.responsive(mobile: 60.0, desktop: 80.0),
                    decoration: BoxDecoration(
                      gradient: WebColors.goldGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: WebColors.primaryGold.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(),
                        style: TextStyle(
                          fontSize:
                          context.responsive(mobile: 24.0, desktop: 32.0),
                          fontWeight: FontWeight.w900,
                          color: WebColors.darkBlueBackground,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Name - GÜNCELLENDİ: ShowsSection'daki oyun başlığı stili
                  // Mobilde biraz daha küçük font
                  Text(
                    '${widget.member?.firstName ?? ''} ${widget.member?.lastName ?? ''}',
                    style: TextStyle(
                      fontSize: context.responsive(
                          mobile: 18.0, desktop: context.bodySize + 6),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                      // OYUN KARTI GÖLGESİ EKLENDİ
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 10)
                      ],
                    ),
                  ),

                  SizedBox(height: context.responsive(mobile: 8.0, desktop: 12.0)),

                  // Bio / Rol
                  Text(
                    widget.member?.bio ?? '',
                    style: TextStyle(
                      fontSize: context.captionSize + (context.isMobile ? 0 : 1),
                      color: WebColors.lightWhite,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final isMobile = context.isMobile;
    final Widget cardWidget = _buildCardContent(context, _isActive);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (final context, final value, final child) {
        final safeValue = value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.8 + (safeValue * 0.2),
          child: Opacity(
            opacity: safeValue,
            child: child,
          ),
        );
      },
      child: isMobile
          ? Listener(
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerUp,
        child: cardWidget,
      )
          : MouseRegion(
        onEnter: (final _) => setState(() => _isActive = true),
        onExit: (final _) => setState(() => _isActive = false),
        child: cardWidget,
      ),
    );
  }
}