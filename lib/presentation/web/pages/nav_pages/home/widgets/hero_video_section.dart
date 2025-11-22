import 'dart:ui'; // BackdropFilter için gerekli
import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../../../../core/theme/app_colors.dart';

class HeroVideoSection extends StatefulWidget {
  const HeroVideoSection({super.key});

  @override
  State<HeroVideoSection> createState() => _HeroVideoSectionState();
}

class _HeroVideoSectionState extends State<HeroVideoSection>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _mainController;

  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideUpAnimation;
  late Animation<double> _pulseAnimation;

  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();

    // Ana animasyon kontrolcüsü
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    _slideUpAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    // Scroll ikonu için sonsuz döngü
    _pulseAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Video Başlatma
    _videoController = VideoPlayerController.network(
      'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG_20250310_200748-ANIMATION.mp4?alt=media&token=feab36d3-1d54-4ff8-868f-76f6591e8705',
    )
      ..setLooping(true)
      ..setVolume(0)
      ..setPlaybackSpeed(0.5)
      ..initialize().then((final _) {
        if (mounted) {
          _videoController.play();
          setState(() => _isVideoReady = true);
          _mainController.forward();
        }
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    // Ekran yüksekliği
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight, // Tam ekran kapla
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. VİDEO KATMANI
          _buildVideoBackground(),

          // 2. SİNEMATİK OVERLAY (Karartma ve Spot Işığı)
          _buildCinematicOverlay(),

          // 3. MERKEZ İÇERİK (Başlıklar)
          _buildHeroContent(context),

          // 4. SAĞ TARAFTAKİ GLASS KART (Prömiyer)
          _buildGlassPremiereCard(context),

          // 5. SCROLL GÖSTERGESİ
          _buildScrollIndicator(),
        ],
      ),
    );
  }

// 1. VİDEOYU EN ALTTA YOK ETMEK İÇİN MASKE (ShaderMask)
  Widget _buildVideoBackground() {
    if (!_isVideoReady) {
      return Image.network(
        "https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG_20250310_205137.jpg?alt=media&token=79e2c500-6f44-42a3-a28d-8b62c84867af",
        fit: BoxFit.cover,
      );
    }

    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0a0a1a),
        // Arka plan rengi (Video silinince bu görünür)
        child: ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black, // Üst kısımlar net
                Colors.black,
                Colors.transparent, // En alt tamamen şeffaf (yok olur)
              ],
              // Buradaki ayar önemli: 0.8 (%80)'e kadar video net,
              // 1.0 (%100)'da tamamen silinmiş oluyor.
              stops: [0.0, 0.85, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController.value.size.width,
              height: _videoController.value.size.height,
              child: VideoPlayer(_videoController),
            ),
          ),
        ),
      ),
    );
  }

  // 2. SİYAH DEGRADE KATMANI (Gradient Overlay)
  Widget _buildCinematicOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.4), // En tepe (Header için hafif koyu)
            Colors.transparent, // Orta kısım (Video net)
            const Color(0xFF0a0a1a).withOpacity(0.0), // Geçiş başlangıcı
            const Color(0xFF0a0a1a), // En alt (Tamamen siyah/zemin rengi)
          ],
          // En alt %15'lik kısımda tam siyaha dönüşür
          stops: const [0.0, 0.3, 0.85, 1.0],
        ),
      ),
    );
  }

  Widget _buildHeroContent(final BuildContext context) {
    final isDesktop = context.isDesktop;

    return Positioned.fill(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.responsive(mobile: 20, desktop: 100)),
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideUpAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: isDesktop
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  // İKON VE ÜST BAŞLIK
                  Row(
                    mainAxisAlignment: isDesktop
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Icon(Icons.theater_comedy,
                          color: WebColors.primaryGold, size: 30),
                      const SizedBox(width: 12),
                      Text(
                        'SAHNE SANATLARI',
                        style: TextStyle(
                          color: WebColors.primaryGold,
                          fontSize: 16,
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ANA BAŞLIK (Devasa)
                  Text(
                    'HİKAYELER\nGERÇEĞE DÖNÜŞÜYOR',
                    textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    style: TextStyle(
                      fontSize: context.responsive(
                          mobile: 42, tablet: 60, desktop: 80),
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 10),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ALT METİN
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Text(
                      'TiyatRol ile sanatın büyülü dünyasına adım atın. Klasiklerden moderne, her sahnede yeni bir duygu, her oyunda farklı bir hayat.',
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                      style: TextStyle(
                        fontSize: context.responsive(mobile: 16, desktop: 20),
                        color: Colors.white.withOpacity(0.8),
                        height: 1.6,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // AKSİYON BUTONU
                  _buildPlayButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(final BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: WebColors.primaryGold, width: 1),
          borderRadius: BorderRadius.circular(50),
          color: Colors.white.withOpacity(0.05), // Glass effect
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_fill,
                color: WebColors.primaryGold, size: 32),
            const SizedBox(width: 16),
            Text(
              'SEZON TANITIMI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassPremiereCard(final BuildContext context) {
    // Desktop'ta sağda, Mobilde altta (ya da gizli) olabilir.
    // Burada Desktop için sağ alt/orta konumlandırıyoruz.
    if (context.isMobile) return const SizedBox.shrink();

    return Positioned(
      right: 60,
      bottom: 150,
      child: FadeTransition(
        opacity: _fadeInAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: WebColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YAKINDA',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.notifications_none,
                          color: Colors.white70),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'METAFOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Times New Roman',
                      // Varsa
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '27 Haziran 2025 • 20:00\nAltunizade Kültür Merkezi',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        const url = 'https://maps.app.goo.gl/CnW99UqhxyBJt1fL6';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WebColors.primaryGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('KONUMU GÖR',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollIndicator() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _mainController,
          builder: (final context, final child) {
            return Transform.translate(
              offset: Offset(0, _pulseAnimation.value), // Aşağı yukarı hareket
              child: Column(
                children: [
                  Text(
                    'AŞAĞI KAYDIR',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: WebColors.primaryGold.withOpacity(0.8),
                    size: 30,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
