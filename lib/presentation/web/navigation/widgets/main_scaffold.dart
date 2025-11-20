import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/web/navigation/web_nav_bar.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/home_page.dart';

/// Ana sayfa scaffold'u - Tüm componentleri bir araya getirir
/// Active section tracking, smooth scroll ve modern navbar içerir
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // Section keys
  final GlobalKey _showsKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _teamKey = GlobalKey();
  final GlobalKey _artisticKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  // Active section tracker
  final ValueNotifier<String> _activeSection = ValueNotifier<String>('home');
  late ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _activeSection.dispose();
    super.dispose();
  }

  /// Smooth scroll to section
  void _navigateToSection(final String section) {
    final Map<String, GlobalKey> sectionKeys = {
      'home': GlobalKey(), // HomePage'in ilk elementi için
      'shows': _showsKey,
      'artistic': _artisticKey,
      'about': _aboutKey,
      'team': _teamKey,
      'contact': _contactKey,
    };

    final key = sectionKeys[section];
    if (key == null) {
      // Home section için en üste scroll
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
      return;
    }

    final context = key.currentContext;
    if (context != null) {
      // Section'ın pozisyonunu hesapla
      final RenderBox box = context.findRenderObject()! as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      final scrollPosition = _scrollController.position.pixels ?? 0;
      final targetPosition =
          position.dy + scrollPosition - 80; // 80px navbar için offset

      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ana içerik
          HomePage(
            showsKey: _showsKey,
            aboutKey: _aboutKey,
            teamKey: _teamKey,
            artisticKey: _artisticKey,
            contactKey: _contactKey,
            activeSection: _activeSection,
            scrollController: _scrollController,
          ),

          // Navigation bar (her zaman üstte)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _scrollController != null
                ? WebNavBar(
                    activeSection: _activeSection,
                    onNavigate: _navigateToSection,
                    scrollController: _scrollController!,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
