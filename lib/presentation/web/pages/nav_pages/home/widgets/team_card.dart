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

      final showService =
          ShowRemoteDataSourceImpl(firestore: firestore, storage: storage);
      final shows = await showService.getShowsByIds(["XqKkUbIflyWxZbNLZvqV"]);

      if (shows != null && shows.isNotEmpty) {
        await _fetchNowPlayers(
            shows.first?.nowPlayersId?.cast<String>(), firestore);
      }
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                    ?.map((e) => e?.toEntity())
                    .whereType<Player>()
                    .toList() ??
                [];
          });
        }
      } catch (error) {
        if (mounted) setState(() => errorMessage = error.toString());
      }
    }
  }

  void _scroll(final bool left) {
    final offset = left ? -300.0 : 300.0;
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
          if (isLoading)
            const CircularProgressIndicator(color: WebColors.primaryGold)
          else if (errorMessage != null)
            Text('Hata: $errorMessage',
                style: const TextStyle(color: WebColors.error))
          else if (nowPlayerDataList.isEmpty)
            const Text('Henüz oyuncu bilgisi yok',
                style: TextStyle(color: Colors.white70))
          else
            _buildTeamCarousel(context),
        ],
      ),
    );
  }

  Widget _buildTeamCarousel(final BuildContext context) {
    final cardHeight =
        context.responsive(mobile: 260.0, tablet: 320.0, desktop: 380.0);

    return SizedBox(
      height: cardHeight + 60,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: context.responsive(mobile: 16.0, desktop: 60.0),
            ),
            itemCount: nowPlayerDataList.length,
            itemBuilder: (final context, final index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _TeamMemberCard(
                    member: nowPlayerDataList[index], index: index),
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
                      Icons.arrow_back_ios, () => _scroll(true))),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                  child: _buildNavButton(
                      Icons.arrow_forward_ios, () => _scroll(false))),
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
              color: WebColors.primaryGold.withOpacity(0.5), blurRadius: 15)
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: WebColors.darkBlueBackground),
        iconSize: 20,
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
  bool _isActive = false;

  String _getInitials() {
    if (widget.member == null) return '?';
    final firstName = widget.member!.firstName ?? '';
    final lastName = widget.member!.lastName ?? '';
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();
  }

  @override
  Widget build(final BuildContext context) {
    final isMobile = context.isMobile;
    final width =
        context.responsive(mobile: 170.0, tablet: 220.0, desktop: 280.0);
    final height =
        context.responsive(mobile: 260.0, tablet: 320.0, desktop: 380.0);

    Widget cardWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      transform: Matrix4.identity()..translate(0.0, _isActive ? -10.0 : 0.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.isMobile ? 16 : 24),
        border: Border.all(
          color: _isActive
              ? WebColors.primaryGold
              : WebColors.primaryGold.withOpacity(0.3),
          width: _isActive ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isActive
                ? WebColors.primaryGold.withOpacity(0.5)
                : Colors.black.withOpacity(0.3),
            blurRadius: _isActive ? 25 : 15,
            spreadRadius: _isActive ? 2 : 0,
            offset: Offset(0, _isActive ? 12 : 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.isMobile ? 14 : 22),
        child: Stack(
          children: [
            // 1. KATMAN: GÖRSEL
            if (widget.member?.imageUrl != null)
              Positioned.fill(
                child: Image.network(
                  widget.member!.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: WebColors.darkBlueSurface),
                ),
              ),

            // 2. KATMAN: SİYAH FİLGRAN / KARARTMA (DÜZELTİLDİ)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      // Üst kısım artık şeffaf değil, hafif siyah (%30)
                      // Bu, parlak yüzleri dengeler.
                      Colors.black.withOpacity(0.1),
                      // Alt kısım metin okunması için koyu siyah (%95)
                      Colors.black.withOpacity(0.90)
                    ],
                    // Karartma üstten başlasın
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),

            // 3. KATMAN: İÇERİK
            Padding(
              padding: EdgeInsets.all(
                  context.responsive(mobile: 12.0, desktop: 24.0)),
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
                  SizedBox(
                      height: context.responsive(mobile: 4.0, desktop: 8.0)),
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
              onPointerDown: (_) => setState(() => _isActive = true),
              onPointerUp: (_) => setState(() => _isActive = false),
              onPointerCancel: (_) => setState(() => _isActive = false),
              child: cardWidget,
            )
          : MouseRegion(
              onEnter: (_) => setState(() => _isActive = true),
              onExit: (_) => setState(() => _isActive = false),
              child: cardWidget,
            ),
    );
  }
}
