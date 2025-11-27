import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/data/providers/login/login_provider.dart';
import 'package:ticketapp/router/splash_router.dart';
import '../../../../data/providers/login/login_state.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _fadeOutController;
  late AnimationController _progressController;

  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _fadeOut;
  late Animation<double> _progressAnimation;

  bool _isNavigationHandled = false;
  bool _isNextPageReady = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Metin animasyonu
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Fade out animasyonu
    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeInOut),
    );

    // Progress bar animasyonu
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  void _startSplashSequence() async {
    // Metin animasyonunu başlat
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _textController.forward();

    // Progress bar animasyonunu başlat
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _progressController.forward();

    // Platform kontrolü
    Future.microtask(() {
      if (SplashRouter.shouldSkipAuthCheck) {
        // 🚀 WEB MANTIĞI
        debugPrint('🟢 WEB: Skipping auth, preparing ${widget.initialRoute}');

        // Minimum splash süresi
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _isNextPageReady = true);
            _checkAndNavigate();
          }
        });
      } else {
        // 📱 MOBİL MANTIĞI
        debugPrint('🔵 MOBILE: Checking auth...');
        ref.read(loginProvider.notifier).getCurrentUser();
      }
    });
  }

  void _checkAndNavigate() {
    if (_isNextPageReady && !_isNavigationHandled) {
      _isNavigationHandled = true;

      // ✅ Callback çağır (AppSession.markAsInitialized)
      widget.onComplete?.call();

      _fadeOutController.forward().then((final _) {
        if (mounted) {
          if (SplashRouter.shouldSkipAuthCheck) {
            context.go(widget.initialRoute);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _fadeOutController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    // 💡 Mobil için auth listener
    if (!SplashRouter.shouldSkipAuthCheck) {
      ref.listen<LoginState>(loginProvider, (final previous, final next) {
        if (_isNavigationHandled) return;

        if (!next.isLoading) {
          setState(() => _isNextPageReady = true);

          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted && _isNextPageReady && !_isNavigationHandled) {
              _isNavigationHandled = true;

              // ✅ Callback çağır
              widget.onComplete?.call();

              _fadeOutController.forward().then((final _) {
                if (mounted) {
                  if (next.user != null) {
                    debugPrint('🟢 User logged in → /home');
                    context.go('/home');
                  } else {
                    debugPrint('🟡 No user → ${widget.initialRoute}');
                    context.go(widget.initialRoute);
                  }
                }
              });
            }
          });
        }
      });
    }

    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeOut,
        builder: (final context, final child) {
          return Opacity(
            opacity: _fadeOut.value,
            child: Container(
              width: screenWidth,
              height: screenHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A1628),
                    Color(0xFF1a1a2e),
                    Color(0xFF16213e),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Arka plan efekti
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SparklesPainter(animation: _textController),
                    ),
                  ),

                  // Ana içerik
                  Center(
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
                              errorBuilder: (final context, final error,
                                  final stackTrace) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFD4AF37),
                                        Color(0xFFF5E6D3),
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

                        // Animasyonlu metin
                        AnimatedBuilder(
                          animation: _textController,
                          builder: (final context, final child) {
                            return SlideTransition(
                              position: _textSlide,
                              child: Opacity(
                                opacity: _textOpacity.value,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  child: Column(
                                    children: [
                                      // Ana başlık
                                      ShaderMask(
                                        shaderCallback: (final bounds) =>
                                            const LinearGradient(
                                              colors: [
                                                Color(0xFFD4AF37),
                                                Color(0xFFF5E6D3),
                                                Color(0xFFD4AF37),
                                              ],
                                            ).createShader(bounds),
                                        child: Text(
                                          'TiyatRol',
                                          style: TextStyle(
                                            fontSize: isMobile ? 48 : 72,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),

                                      SizedBox(height: isMobile ? 20 : 30),

                                      // Alt başlık
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: const Color(0xFFD4AF37)
                                                  .withOpacity(0.4),
                                              width: 1,
                                            ),
                                            bottom: BorderSide(
                                              color: const Color(0xFFD4AF37)
                                                  .withOpacity(0.4),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Sahnede hayat, perdede hikaye',
                                          style: TextStyle(
                                            fontSize: isMobile ? 15 : 20,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFFF5E6D3)
                                                .withOpacity(0.95),
                                            letterSpacing: 2.5,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),

                                      SizedBox(height: isMobile ? 14 : 18),

                                      // Açıklama
                                      Text(
                                        'Her oyun bir yolculuk, her sahne bir keşif',
                                        style: TextStyle(
                                          fontSize: isMobile ? 13 : 15,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white.withOpacity(0.7),
                                          letterSpacing: 1.2,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),

                                      SizedBox(height: isMobile ? 40 : 60),

                                      // SARI PROGRESS BAR - GERİ EKLENDİ
                                      AnimatedBuilder(
                                        animation: _progressAnimation,
                                        builder: (context, child) {
                                          return Container(
                                            width: isMobile ? 200 : 300,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                            child: Stack(
                                              children: [
                                                // Arka plan
                                                Container(
                                                  width: double.infinity,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),

                                                // Progress doluluk
                                                AnimatedContainer(
                                                  duration: const Duration(milliseconds: 100),
                                                  width: (isMobile ? 200 : 300) * _progressAnimation.value,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Color(0xFFD4AF37),
                                                        Color(0xFFFFD700),
                                                        Color(0xFFF5E6D3),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(2),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFFD4AF37).withOpacity(0.6),
                                                        blurRadius: 8,
                                                        spreadRadius: 1,
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Parlama efekti
                                                if (_progressAnimation.value > 0)
                                                  Positioned(
                                                    right: 0,
                                                    top: 0,
                                                    child: Container(
                                                      width: 20,
                                                      height: 4,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Colors.white.withOpacity(0.8),
                                                            Colors.transparent,
                                                          ],
                                                          begin: Alignment.centerRight,
                                                          end: Alignment.centerLeft,
                                                        ),
                                                        borderRadius: const BorderRadius.only(
                                                          topRight: Radius.circular(2),
                                                          bottomRight: Radius.circular(2),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),

                                      SizedBox(height: isMobile ? 20 : 30),

                                      // Yükleniyor metni
                                      AnimatedBuilder(
                                        animation: _progressAnimation,
                                        builder: (context, child) {
                                          return Opacity(
                                            opacity: _textOpacity.value,
                                            child: Text(
                                              _getLoadingText(_progressAnimation.value),
                                              style: TextStyle(
                                                fontSize: isMobile ? 12 : 14,
                                                fontWeight: FontWeight.w300,
                                                color: const Color(0xFFD4AF37).withOpacity(0.8),
                                                letterSpacing: 1.0,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Alt bilgi
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _textController,
                      builder: (final context, final child) {
                        return Opacity(
                          opacity: _textOpacity.value * 0.5,
                          child: Column(
                            children: [
                              // Versiyon bilgisi - GERİ EKLENDİ
                              Text(
                                'v1.0.0',
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 11,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white.withOpacity(0.3),
                                  letterSpacing: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),

                              // Telif hakkı
                              Text(
                                '© 2024 TiyatRol Tiyatro Topluluğu',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white.withOpacity(0.4),
                                  letterSpacing: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getLoadingText(double progress) {
    if (progress < 0.3) return 'Sahne hazırlanıyor...';
    if (progress < 0.6) return 'Oyuncular hazırlanıyor...';
    if (progress < 0.9) return 'Perde kalkıyor...';
    return 'Hoş geldiniz!';
  }
}

// Parıltı efekti
class SparklesPainter extends CustomPainter {
  final Animation<double> animation;

  SparklesPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final random = [0.2, 0.4, 0.6, 0.8, 0.3, 0.7, 0.5, 0.9, 0.25, 0.75];

    for (int i = 0; i < 10; i++) {
      final progress = (animation.value + random[i]) % 1.0;
      final opacity = (1 - progress) * 0.4;

      paint.color = const Color(0xFFD4AF37).withOpacity(opacity);

      final x = size.width * random[i];
      final y = size.height * random[(i + 4) % 10];
      final radius = 2 + (progress * 10);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(final SparklesPainter oldDelegate) => true;
}