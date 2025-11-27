import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/data/providers/login/login_provider.dart';
import 'package:ticketapp/router/splash_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final String initialRoute;

  const SplashScreen({required this.initialRoute, super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  final int _particleCount = 25; // Ekranda uçuşacak toz sayısı

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAppFlow();
  }

  void _initAnimations() {
    // Ana animasyon kontrolcüsü (Logo ve Yazı için)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Parçacıklar için sürekli dönen kontrolcü
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 1. Logo: Hafifçe büyüyerek gelir
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Logo Opaklığı
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // 3. Yazı: Alttan yukarı kayar
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    // 4. Yazı Opaklığı
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );
  }

  Future<void> _startAppFlow() async {
    FlutterNativeSplash.remove();
    _mainController.forward();

    // Veri çekme ve Animasyon süresini bekle
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)), // En az 3 sn şov yapsın
      _loadUserData(),
    ]);

    if (mounted) {
      _navigateToNextScreen();
    }
  }

  Future<void> _loadUserData() async {
    if (SplashRouter.shouldSkipAuthCheck) return;
    try {
      await ref.read(loginProvider.notifier).getCurrentUser();
    } catch (e) {
      debugPrint("Splash Data Error: $e");
    }
  }

  void _navigateToNextScreen() {
    if (SplashRouter.shouldSkipAuthCheck) {
      context.go(widget.initialRoute);
    } else {
      final userState = ref.read(loginProvider);
      if (userState.user != null) {
        context.go('/home');
      } else {
        context.go(widget.initialRoute);
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // KATMAN 1: Arka Plan (Spot Işığı Efekti)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF1A2342), // Ortası koyu lacivert (Işık vurmuş gibi)
                  Color(0xFF050505), // Köşeler simsiyah
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),

          // KATMAN 2: Uçuşan Altın Tozları (Particles)
          ...List.generate(_particleCount, (index) {
            return _AnimatedParticle(
                controller: _particleController, index: index);
          }),

          // KATMAN 3: Logo ve Yazı
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 180, // Logoyu BÜYÜTTÜK
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              // Arkasına "Holy Light" (Kutsal Işık) efekti
                              BoxShadow(
                                color: WebColors.primaryGold.withOpacity(0.15),
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Image.asset('assets/images/app_logo.jpg'),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // YAZI
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        // TiyatRol Yazısı
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                            // Altın Gradyan
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: const Text(
                            "TiyatRol",
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Serif',
                              // Varsa serif font, yoksa default
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Alt Slogan (Opsiyonel ama şık durur)
                        Text(
                          "SAHNE SENİN",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: WebColors.primaryGold.withOpacity(0.6),
                            letterSpacing: 6.0, // Harfleri iyice açtık
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- PARTICLE (Altın Tozu) WIDGET'I ---
class _AnimatedParticle extends StatelessWidget {
  final AnimationController controller;
  final int index;

  const _AnimatedParticle({required this.controller, required this.index});

  @override
  Widget build(BuildContext context) {
    final random = math.Random(index);
    final size = MediaQuery.of(context).size;

    // Her parçacık için rastgele başlangıç pozisyonu ve hız
    final speed = 0.2 + random.nextDouble() * 0.8;
    final startX = random.nextDouble() * size.width;
    final startY = random.nextDouble() * size.height;
    final particleSize = 2.0 + random.nextDouble() * 3.0;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Yukarı doğru süzülme hareketi
        final dy =
            (startY - (controller.value * size.height * speed)) % size.height;
        // Hafif sağa sola salınım
        final dx =
            startX + math.sin((controller.value * 2 * math.pi) + index) * 20;

        // Yanıp sönme efekti (Twinkle)
        final opacity =
            (math.sin((controller.value * 5 * math.pi) + index) + 1) / 2 * 0.5;

        return Positioned(
          top: dy,
          left: dx,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: particleSize,
              height: particleSize,
              decoration: const BoxDecoration(
                  color: WebColors.primaryGold, // Altın rengi tozlar
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: WebColors.primaryGold,
                      blurRadius: 5,
                      spreadRadius: 1,
                    )
                  ]),
            ),
          ),
        );
      },
    );
  }
}
