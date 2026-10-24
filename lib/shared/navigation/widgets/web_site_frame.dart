import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'web_site_header.dart';

/// Web sitesi çatısı: kabuk dışındaki sayfaları (sahne, topluluk, favoriler,
/// biletlerim, yardım, kampanya…) sitenin ortak başlığıyla çerçeveler, böylece
/// hiçbir sayfa "mobil uygulama ekranı" gibi tek başına durmaz. Mobilde ve
/// kendi başlığını çizen sayfalarda çocuğu olduğu gibi döndürür.
class WebSiteFrame extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const WebSiteFrame({super.key, required this.child, this.enabled = true});

  @override
  Widget build(final BuildContext context) {
    if (!kIsWeb || !enabled) return child;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          const WebSiteHeader(),
          Expanded(child: child),
        ],
      ),
    );
  }
}
