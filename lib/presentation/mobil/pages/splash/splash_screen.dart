import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/data/providers/login/login_provider.dart';
import 'package:ticketapp/router/splash_router.dart';
import '../../../../data/providers/login/login_state.dart';
import '../../../web/pages/nav_pages/home/widgets/home_asset_video_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final String initialRoute;
  final VoidCallback? onComplete;

  const SplashScreen({
    required this.initialRoute,
    this.onComplete,
    super.key,
  });

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _progress;

  bool _isNavigationHandled = false;
  bool _isSplashTimeComplete = false;
  bool _isBackendReady = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _startSplashSequence();
  }

  void _startSplashSequence() {
    // ✅ Animasyonu başlat
    _controller.forward();

    ref.read(homeAssetsProvider.notifier).initializeVideo();

    // ✅ 2 saniye sonra splash zamanı bitti
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _isSplashTimeComplete = true);
        _checkAndNavigate();
      }
    });

    // ✅ Arka planda UI hazırlığı başlat (splash gösterilirken)
    Future.microtask(() {
      if (SplashRouter.shouldSkipAuthCheck) {
        // WEB: Direkt hazır
        setState(() => _isBackendReady = true);
      } else {
        // MOBİL: Auth kontrol et
        ref.read(loginProvider.notifier).getCurrentUser();
      }
    });
  }

  void _checkAndNavigate() {
    // Provider'dan videonun durumunu çekiyoruz
    final videoState = ref.read(homeAssetsProvider);

    // KURAL:
    // 1. Süre (2sn) dolmuş olmalı
    // 2. Backend (Auth) hazır olmalı
    // 3. Video (Home Assets) hazır olmalı
    if (_isSplashTimeComplete && _isBackendReady && videoState.isVideoReady && !_isNavigationHandled) {
      _isNavigationHandled = true;
      widget.onComplete?.call();

      if (mounted) {
        // extra parametresi ile Home sayfasına "Splash'ten geldim, animasyonları şimdi başlat" diyoruz.
        context.go(widget.initialRoute, extra: {'fromSplash': true});
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    ref.listen(homeAssetsProvider, (final previous, final next) {
      if (next.isVideoReady)
        _checkAndNavigate();
    });

    // ✅ MOBİL: Auth dinle
    if (!SplashRouter.shouldSkipAuthCheck) {
      ref.listen<LoginState>(loginProvider, (final previous, final next) {
        if (!next.isLoading && !_isBackendReady) {
          setState(() => _isBackendReady = true);
          _checkAndNavigate();
        }
      });
    }

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: AnimatedBuilder(
          animation: _fadeIn,
          builder: (final context, final child) {
            return Opacity(
              opacity: _fadeIn.value,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: isMobile ? 140 : 200,
                      height: isMobile ? 140 : 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.4),
                            blurRadius: 50,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/tiyatrol_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder:
                              (final context, final error, final stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFD4AF37),
                                    Color(0xFFF5E6D3)
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.theater_comedy,
                                size: 100,
                                color: Color(0xFF0A1628),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: isMobile ? 50 : 70),

                    Text(
                      'TiyatRol',
                      style: TextStyle(
                        fontSize: isMobile ? 52 : 68,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD4AF37),
                        letterSpacing: 3,
                      ),
                    ),

                    SizedBox(height: isMobile ? 40 : 60),

                    // Alt başlık
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: const Color(0xFFD4AF37).withOpacity(0.3),
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: const Color(0xFFD4AF37).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Sahnede hayat, perdede hikaye',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFF5E6D3).withOpacity(0.9),
                          letterSpacing: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: isMobile ? 12 : 16),

                    // Açıklama
                    Text(
                      'Her oyun bir yolculuk, her sahne bir keşif',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: isMobile ? 40 : 60),

                    // Progress bar
                    Container(
                      width: isMobile ? 200 : 300,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: AnimatedBuilder(
                        animation: _progress,
                        builder: (final context, final child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progress.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD4AF37),
                                    Color(0xFFFFD700)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Yükleniyor metni
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (final context, final child) {
                        return Text(
                          _getLoadingText(_progress.value),
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFFD4AF37).withOpacity(0.8),
                            letterSpacing: 1.0,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getLoadingText(final double progress) {
    if (progress < 0.3) return 'Sahne hazırlanıyor...';
    if (progress < 0.6) return 'Oyuncular hazırlanıyor...';
    if (progress < 0.9) return 'Perde kalkıyor...';
    return 'Hoş geldiniz!';
  }
}
