import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; //
import 'package:ticketapp/data/providers/login/login_provider.dart';
import 'package:ticketapp/router/splash_router.dart';
import '../../../../data/providers/login/login_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  // main_scaffold.dart'tan gelen rota (Web için '/home', Mobil için '/onboarding' vb.)
  final String initialRoute;

  // Constructor'ı initialRoute alacak şekilde güncelliyoruz
  const SplashScreen({required this.initialRoute, super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isNavigationHandled = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    Future.microtask(() {
      if (SplashRouter.shouldSkipAuthCheck) {
        // 🚀 WEB MANTIĞI
        _isNavigationHandled = true;
        print(
            '🟢 WEB: Skipping auth check, going directly to ${widget.initialRoute}');

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // Hata almamak için 'mounted' kontrolü iyi olur
            // ✅ 2. DEĞİŞİKLİK: context.go Kullanımı
            context.go(widget.initialRoute);
          }
        });
      } else {
        // 📱 MOBİL MANTIĞI
        ref.read(loginProvider.notifier).getCurrentUser();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    // 💡 Sadece Auth kontrolü yapılan platformlar (Mobil) için dinleyici aktif.
    if (!SplashRouter.shouldSkipAuthCheck) {
      ref.listen<LoginState>(loginProvider, (final previous, final next) {
        if (_isNavigationHandled) return;

        if (!next.isLoading) {
          _isNavigationHandled = true;

          if (next.user != null) {
            // Kullanıcı giriş yapmış -> Home'a git
            print('🟢 User already logged in, going to home');
            // ✅ 3. DEĞİŞİKLİK: context.go('/home')
            context.go('/home');
          } else {
            // Kullanıcı giriş yapmamış -> Başlangıç rotasına git
            print(
                '🟡 No user found, going to initial route: ${widget.initialRoute}');
            // ✅ 4. DEĞİŞİKLİK: context.go(widget.initialRoute)
            context.go(widget.initialRoute);
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Image.asset(
              'assets/images/app_logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (final context, final error, final stackTrace) {
                return Container(
                  color: Colors.white,
                  child: const Center(
                    child: Text(
                      'Ticket App',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
