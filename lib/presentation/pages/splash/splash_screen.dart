import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/login_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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

    Timer(const Duration(seconds: 3), () {
      _checkUserLoginState();
    });
  }

  Future<void> _checkUserLoginState() async {
    final currentUser = LoginService().isUserLoggedIn;

    if (currentUser == false) {
      await Navigator.of(context).pushReplacementNamed('/login');
    } else {
      await Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.red,
        body: Center(
            child: FadeTransition(
          opacity: _animation,
          child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Image.asset('assets/images/app_logo.jpg', fit: BoxFit.cover)),
        )));
  }
}
