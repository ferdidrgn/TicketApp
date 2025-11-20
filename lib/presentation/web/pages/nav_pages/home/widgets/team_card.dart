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
      padding: context.responsive(
        mobile: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        desktop: const EdgeInsets.symmetric(vertical: 80, horizontal: 60),
      ),
      decoration: const BoxDecoration(
        gradient: WebColors.backgroundGradient,
      ),
      child: Column(
        children: [
          // Başlık
          ShaderMask(
            shaderCallback: (final bounds) =>
                WebColors.goldGradient.createShader(bounds),
            child: Text(
              'SANATIMIZDAKİ RUHLAR',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.responsive(mobile: 28.0, desktop: 48.0),
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Her oyunun arkasında tutkulu bir hikaye,\nher karakterin içinde deneyimli bir sanatçımız var',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.bodySize,
              color: WebColors.primaryGoldLight,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 48),

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
    return SizedBox(
      height: 430,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(
              // Üstten ve alttan boşluk ekleniyor
              top: 10.0, // Kartın yukarı kayma miktarı kadar üstten boşluk
              bottom: 10.0, // Alt kısım için güvenlik boşluğu
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

          // Navigation Buttons
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
        iconSize: 24,
      ),
    );
  }
}

// ------------------------------------------------------------------
// BAŞLANGIÇ: _TeamMemberCard güncellenmiş kodu
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
  // Hem hover hem de tap durumunu tutar
  bool _isActive = false;

  String _getInitials() {
    if (widget.member == null) return '?';
    final firstName = widget.member!.firstName ?? '';
    final lastName = widget.member!.lastName ?? '';
    final initials = (firstName.isNotEmpty ? firstName[0] : '') +
        (lastName.isNotEmpty ? lastName[0] : '');
    return initials.toUpperCase();
  }

  // **YENİ:** Dokunmatik (Pointer) başlangıcı (Kaydırma başlasa bile aktif kalır)
  void _handlePointerDown(final PointerEvent event) {
    if (event is PointerDownEvent) {
      setState(() {
        _isActive = true;
      });
    }
  }

  // **YENİ:** Dokunmatik (Pointer) bitişi (Parmak ekrandan kalktığında)
  void _handlePointerUp(final PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      setState(() {
        _isActive = false;
      });
    }
  }

  // Kart içeriğini oluşturur (MouseRegion/Listener dışında kalan kısım)
  Widget _buildCardContent(final BuildContext context, final bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: context.responsive(mobile: 240.0, desktop: 280.0),
      height: 360,
      // Hover/Tap Animasyonu: Üzerine gelindiğinde/dokunulduğunda yukarı kayar
      transform: Matrix4.identity()..translate(0.0, active ? -10.0 : 0.0),
      // Yukarı Kayma Efekti
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: active
              ? WebColors.primaryGold // Vurgulu Kenarlık
              : WebColors.primaryGold.withOpacity(0.3),
          width: active ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? WebColors.primaryGold.withOpacity(0.5) // Vurgulu Gölge
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
            // Background Image
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

            // Gradient Overlay
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

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
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
                              context.responsive(mobile: 28.0, desktop: 32.0),
                          fontWeight: FontWeight.w900,
                          color: WebColors.darkBlueBackground,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Name
                  Text(
                    '${widget.member?.firstName ?? ''} ${widget.member?.lastName ?? ''}',
                    style: TextStyle(
                      fontSize: context.bodySize + 2,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bio
                  Text(
                    widget.member?.bio ?? '',
                    style: TextStyle(
                      fontSize: context.captionSize + 1,
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
    // Mobil veya Masaüstü ayrımı yapıyoruz
    final isMobile = context.isMobile;

    final Widget cardWidget = _buildCardContent(context, _isActive);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (final context, final value, final child) {
        // Değeri 0.0 ile 1.0 arasında sınırla
        final safeValue = value.clamp(0.0, 1.0);

        return Transform.scale(
          scale: 0.8 + (safeValue * 0.2),
          child: Opacity(
            opacity: safeValue, // Sınırlı değeri kullan
            child: child,
          ),
        );
      },
      child: isMobile
          ? Listener(
              // MOBİL: Listener ile dokunma olaylarını yakala
              onPointerDown: _handlePointerDown,
              onPointerUp: _handlePointerUp,
              onPointerCancel: _handlePointerUp,
              child: cardWidget,
            )
          : MouseRegion(
              // MASAÜSTÜ: Hover olaylarını yakala
              onEnter: (final _) => setState(() => _isActive = true),
              onExit: (final _) => setState(() => _isActive = false),
              // Masaüstünde MouseRegion zaten kaydırma durumunda efekti kesmez.
              child: cardWidget,
            ),
    );
  }
}
