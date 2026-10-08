import 'package:flutter/material.dart';

import '../widgets/mobile/mobile_home_canvas.dart';

/// Native Android/iOS ana sayfa. Telefon ve tablette aynı program yüzeyi;
/// tablette içerik 720'de ortalanır (`MobileHomeCanvas`).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(final BuildContext context) => const MobileHomeCanvas();
}
