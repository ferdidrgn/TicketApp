import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/data/providers/login/login_provider.dart';

import '../../../../data/providers/login/login_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isNavigationHandled = false; // ✅ Çift yönlendirmeyi önle

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

    // Kullanıcıyı kontrol et
    Future.microtask(() {
      ref.read(loginProvider.notifier).getCurrentUser();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    ref.listen<LoginState>(loginProvider, (final previous, final next) {
      // ✅ Çift yönlendirmeyi önle
      if (_isNavigationHandled) return;

      // ✅ Loading bittiğinde ve hata yoksa yönlendir
      if (!next.isLoading) {
        _isNavigationHandled = true;

        if (next.user != null) {
          // Kullanıcı zaten giriş yapmış - home'a git
          print('🟢 User already logged in, going to home');
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Kullanıcı giriş yapmamış - login'e git
          print('🟡 No user found, going to login');
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    });

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
                // ✅ Eğer resim yoksa placeholder göster
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
