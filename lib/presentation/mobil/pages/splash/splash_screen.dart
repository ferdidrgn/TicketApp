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
    with SingleTickerProviderStateMixin {
  // ✅ TEK AnimationController
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _progress;

  bool _isNavigationHandled = false;
  bool _isSplashTimeComplete = false; // ✅ 2 saniye tamamlandı mı?
  bool _isBackendReady = false; // ✅ Arka plan hazır mı?

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000), // ✅ 2 saniye
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
    // ✅ Hem 2 saniye bitti HEM backend hazır OLUNCA git
    if (_isSplashTimeComplete && _isBackendReady && !_isNavigationHandled) {
      _isNavigationHandled = true;
      widget.onComplete?.call();

      if (mounted) {
        context.go(widget.initialRoute);
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

    // ✅ MOBİL: Auth dinle
    if (!SplashRouter.shouldSkipAuthCheck) {
      ref.listen<LoginState>(loginProvider, (previous, next) {
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
          builder: (context, child) {
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
                          errorBuilder: (context, error, stackTrace) {
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
                        builder: (context, child) {
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

                    Text(
                      'Sahne hazırlanıyor...',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFFD4AF37).withOpacity(0.8),
                        letterSpacing: 1.0,
                      ),
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
}
