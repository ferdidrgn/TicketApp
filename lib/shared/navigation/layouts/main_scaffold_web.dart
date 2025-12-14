import 'package:flutter/material.dart';
import 'package:ticketapp/shared/navigation/widgets/web_nav_bar.dart';
import 'package:ticketapp/features/home/presentation/pages/home_page_web.dart';

/// Ana sayfa scaffold'u - Tüm componentleri bir araya getirir
/// Active section tracking, smooth scroll ve modern navbar içerir
class MainScaffold extends StatefulWidget {
  final bool startAnimations;

  const MainScaffold({
    super.key,
    this.startAnimations = false
  });

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
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<String> _activeSection = ValueNotifier('home');

  @override
  void dispose() {
    _activeSection.dispose();
    super.dispose();
  }

  void _scrollToSection(final String section) {
    // 1. Ana Sayfa Kontrolü (En başa sarar)
    if (section == 'home') {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
      _activeSection.value = 'home'; // Navigasyonu manuel güncelle
      return;
    }

    final Map<String, GlobalKey> sectionKeys = {
      'home': GlobalKey(), // HomePage'in ilk elementi için
      'shows': _showsKey,
      'artistic': _artisticKey,
      'about': _aboutKey,
      'team': _teamKey,
      'contact': _contactKey,
    };

    final key = sectionKeys[section];

    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.05, // Hafif üstten boşluk
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          WebNavBar(
            activeSection: _activeSection,
            onNavigate: (final section) => _scrollToSection(section),
            scrollController: _scrollController,
          ),
          Expanded(
            child: HomePage(
              showsKey: _showsKey,
              aboutKey: _aboutKey,
              teamKey: _teamKey,
              artisticKey: _artisticKey,
              contactKey: _contactKey,
              activeSection: _activeSection,
              scrollController: _scrollController,
              startAnimations: widget.startAnimations, // ✅ Burayı ekleyin
            ),
          )
        ],
      ),
    );
  }
}
