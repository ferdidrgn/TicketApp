import 'package:flutter/material.dart';
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

    // Eğer animasyonlar başlamadıysa, ufak bir gecikmeyle başlat.
    // Bu gecikme, sayfa render olurken "takılma" olmaması içindir.
    if (!_animationsStarted) {
      Future.delayed(const Duration(milliseconds: 5000), () {
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
      body: MainScaffold(startAnimations: _animationsStarted),
    );
  }
}
