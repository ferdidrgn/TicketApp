import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'home_asset_video_provider.dart';

class HeroVideoSection extends ConsumerStatefulWidget {
  final bool startAnimations;

  const HeroVideoSection({
    super.key,
    this.startAnimations = false,
  });

  @override
  ConsumerState<HeroVideoSection> createState() => _HeroVideoSectionState();
}

class _HeroVideoSectionState extends ConsumerState<HeroVideoSection>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;

  // ignore: unused_field
  bool _videoPlayAttempted = false;

  late final Animation<double> _contentOpacity;
  late final Animation<double> _contentSlide;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardOpacity;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Yazıların soldan gelişi
    _contentSlide = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
      ),
    );

    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Kartın aşağıdan yukarı çıkışı
    _cardSlide = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _cardOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    if (widget.startAnimations) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant final HeroVideoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.startAnimations && widget.startAnimations) {
      _controller.forward(from: 0);
      _attemptVideoPlay();
    }
  }

  void _attemptVideoPlay() {
    if (!_videoPlayAttempted) {
      _videoPlayAttempted = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref.read(homeAssetsProvider.notifier).playVideo();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);

    final assetsState = ref.watch(homeAssetsProvider);
    final controller = assetsState.videoController;
    final isReady = assetsState.isVideoReady;
    final hasVideo = controller != null && controller.value.isInitialized;

    // Video oynatma garantisi
    if (hasVideo && !controller.value.isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        if (mounted) ref.read(homeAssetsProvider.notifier).playVideo();
      });
    }

    return SizedBox(
      height: context.screenHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // 1. ZEMİN RENGİ (Koyu Tema)
          Container(color: const Color(0xFF050505)),

          // 2. SİNEMATİK VİDEO VE MASKELİ GEÇİŞ (Entegre Tasarım)
          if (!context.isMobile)
            Positioned.fill(
              child: _buildDesktopCinematicVideo(controller, hasVideo),
            ),

          // 3. MOBİL VİDEO YERLEŞİMİ (Basit Full Screen)
          if (context.isMobile && hasVideo)
            Positioned.fill(
              child: Opacity(
                opacity: 0.6,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller!.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            ),

          // 4. İÇERİK KATMANI (Yazılar)
          Positioned.fill(
            child: context.isMobile
                ? _buildMobileContent(context)
                : _buildDesktopContent(context),
          ),

          // 5. CAM BİLDİRİM KARTI (Video ile etkileşimli konum)
          if (!context.isMobile) _buildIntegratedGlassCard(context),

          if (context.isMobile) _buildMobileGlassCard(context),

          // 6. SCROLL INDICATOR
          if (isReady && !context.isMobile)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 1000),
                  opacity: widget.startAnimations ? 1.0 : 0.0,
                  child: Column(
                    children: [
                      Text(
                        'KEŞFETMEK İÇİN KAYDIR',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          letterSpacing: 4,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down,
                          color: WebColors.primaryGold.withOpacity(0.6)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🎨 DESKTOP: SİNEMATİK VİDEO MASKESİ (Sihirli Kısım Burası)
  // ===========================================================================
  Widget _buildDesktopCinematicVideo(
      final VideoPlayerController? controller, final bool hasVideo) {
    if (!hasVideo) return const SizedBox();

    return Row(
      children: [
        // Sol tarafı boş bırakıyoruz (Yazılar buraya gelecek)
        // Amaç: Videoyu sağa yaslamak ama sola doğru eritmek
        const Spacer(flex: 2),

        // Video Alanı (Ekranın sağ %65-70'ini kaplar)
        Expanded(
          flex: 5,
          child: ShaderMask(
            shaderCallback: (final Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent, // Sol taraf tamamen şeffaf (erimiş)
                  Colors.black.withOpacity(0.5), // Geçiş bölgesi
                  Colors.black, // Sağ taraf tamamen görünür
                ],
                stops: const [0.0, 0.3, 1.0], // Erime oranı ayarı
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn, // Bu mod maskelemeyi sağlar
            child: SizedBox(
              height: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller!.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 🖋️ DESKTOP: YAZI İÇERİĞİ (Solda ama video ile iç içe)
  // ===========================================================================
  Widget _buildDesktopContent(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80.0),
      child: Row(
        children: [
          Expanded(
            flex: 6, // Yazı alanı genişliği
            child: AnimatedBuilder(
              animation: _controller,
              builder: (final context, final child) {
                return Opacity(
                  opacity: _contentOpacity.value,
                  child: Transform.translate(
                    offset: Offset(_contentSlide.value, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Üst Başlık
                        Row(
                          children: [
                            Container(
                              height: 2,
                              width: 40,
                              color: WebColors.primaryGold,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'SAHNE SANATLARI SEZONU',
                              style: TextStyle(
                                color: WebColors.primaryGold,
                                fontSize: 14,
                                letterSpacing: 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Ana Başlık (Devasa)
                        Text(
                          'HİKAYELER\nGERÇEĞE\nDÖNÜŞÜYOR',
                          style: TextStyle(
                            fontSize: 96,
                            // Çok büyük font
                            height: 0.95,
                            // Satırlar birbirine yakın
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -2,
                            shadows: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.8),
                                offset: const Offset(4, 4),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Açıklama
                        SizedBox(
                          width: 500,
                          child: Text(
                            'TiyatRol ile sanatın büyülü dünyasına adım atın. Klasiklerden moderne, her sahnede yeni bir duygu sizi bekliyor.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.6,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Buton
                        _buildPlayButton(context),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Spacer(flex: 4), // Sağ taraf boş (Video orada)
        ],
      ),
    );
  }

  Widget _buildIntegratedGlassCard(final BuildContext context) {
    return Positioned(
      right: 80,
      bottom: 80, // Konumlandırma aynı kalıyor
      child: AnimatedBuilder(
        animation: _controller,
        builder: (final context, final child) {
          return Opacity(
            opacity: _cardOpacity.value,
            child: Transform.translate(
              offset: Offset(0, _cardSlide.value),
              child: child,
            ),
          );
        },
        child: Container(
          width: 400, // Genişlik sabit
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // O sevdiğin daha koyu ve net cam efekti
            color: const Color(0xFF1A1A1A).withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Üst Kısım: Kırmızı Etiket ve Bildirim İkonu
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
                      Icon(Icons.notifications_active_outlined,
                          color: WebColors.primaryGold.withOpacity(0.8),
                          size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Başlık: Times New Roman Style
                  Text(
                    'METAFOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Times New Roman',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tarih ve Yer Bilgisi
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '27 Haziran 2025 • 20:00',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Altunizade Kültür Merkezi',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Altın Sarısı Buton
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () async {
                          const url =
                              'https://maps.app.goo.gl/CnW99UqhxyBJt1fL6';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WebColors.primaryGold,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('BİLET AL & KONUM',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(final IconData icon, final String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 📱 MOBILE VERSİYONLAR
  // ===========================================================================
  Widget _buildMobileContent(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'HİKAYELER\nGERÇEĞE\nDÖNÜŞÜYOR',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 42,
              height: 1.0,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 15,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPlayButton(context),
        ],
      ),
    );
  }

  Widget _buildMobileGlassCard(final BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: WebColors.primaryGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.star, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'METAFOR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Yakında Sahnede',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(final BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: WebColors.primaryGold, width: 1),
          borderRadius: BorderRadius.circular(50),
          color: Colors.transparent, // Minimalist buton
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow, color: WebColors.primaryGold),
            const SizedBox(width: 12),
            Text(
              'SEZON TANITIMI',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: context.isMobile ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
