import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../presentation/mobil/pages/bottom_nav_pages/home_page.dart';
import '../presentation/web/navigation/widgets/main_scaffold.dart';

class AppHomePage extends StatefulWidget {
  final bool startAnimations;

  const AppHomePage({
    super.key,
    this.startAnimations = false,
  });

  @override
  State<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends State<AppHomePage> {
  late bool _animationsStarted;

  @override
  void initState() {
    super.initState();
    _animationsStarted = widget.startAnimations;

    // Eğer animasyonlar başlamadıysa, 100ms sonra başlat
    if (!_animationsStarted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted)
          setState(() {
            _animationsStarted = true;
          });
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      body: _animationsStarted
          ? MainScaffold()
          : const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
              ),
            ),
    );
  }
}
