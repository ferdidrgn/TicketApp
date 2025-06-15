import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../pages/nav_pages/home/home_page.dart';

class WebTabNavigation extends StatefulWidget {
  const WebTabNavigation({super.key});

  @override
  _WebTabNavigationState createState() => _WebTabNavigationState();
}

class _WebTabNavigationState extends State<WebTabNavigation>
    with TickerProviderStateMixin {
  int currentTab = 0;
  late AnimationController _glowController;
  final ScrollController _scrollController = ScrollController();
  bool _headerTransparent = true;

  final GlobalKey _showsKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _teamKey = GlobalKey();
  final GlobalKey _artisticKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  final List<String> tabTitles = [
    'Ana Sayfa',
    'Oyunlarımız',
    'Hakkımızda',
    'Ekibimiz',
    'Kürasyon',
    'İletişim',
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scrollController.addListener(() {
      setState(() {
        _headerTransparent = _scrollController.offset < 100;
      });
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(final GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppWebLightColors.darkBlueBackground,
              Color(0xFF16213e),
              Color(0xFF0f3460)
            ],
          ),
        ),
        child: CustomScrollView(
          controller: _scrollController,
          key: const PageStorageKey('WebHomeScroll'),
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(
              child: HomePage(
                showsKey: _showsKey,
                aboutKey: _aboutKey,
                teamKey: _teamKey,
                artisticKey: _artisticKey,
                contactKey: _contactKey,
              ),
            ),
            SliverToBoxAdapter(child: _buildFooter()),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: _headerTransparent
          ? AppWebLightColors.darkBlueBackground.withOpacity(0.95)
          : AppWebLightColors.darkBlueBackground.withOpacity(0.98),
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppWebLightColors.primaryGold, width: 2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo + Başlık
              Row(
                children: const [
                  Text('🎭',
                      style: TextStyle(fontSize: 24, color: Colors.amber)),
                  SizedBox(width: 8),
                  Text(
                    'Sahne Sanatları',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppWebLightColors.primaryGold,
                    ),
                  ),
                ],
              ),
              // Navigasyon
              Expanded(child: _buildNavigationTabs()),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- NAVIGATION ----------------
  Widget _buildNavigationTabs() {
    return LayoutBuilder(
      builder: (final context, final constraints) {
        final bool isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          return PopupMenuButton<int>(
            icon: const Icon(Icons.menu, color: AppWebLightColors.primaryGold),
            onSelected: (final index) => _onTabSelected(index),
            itemBuilder: (final context) => tabTitles
                .asMap()
                .entries
                .map(
                  (final entry) => PopupMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: tabTitles.asMap().entries.map((final entry) {
            final int index = entry.key;
            final String title = entry.value;
            final bool isActive = currentTab == index;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildNavButton(title, index, isActive),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildNavButton(
      final String title, final int index, final bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed: () => _onTabSelected(index),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isActive ? AppWebLightColors.primaryGold : Colors.transparent,
          foregroundColor: isActive
              ? AppWebLightColors.darkBlueBackground
              : AppWebLightColors.primaryGold,
          side:
              const BorderSide(color: AppWebLightColors.primaryGold, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: isActive ? 5 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _onTabSelected(final int index) {
    setState(() {
      currentTab = index;
    });

    switch (index) {
      case 0:
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        break;
      case 1:
        _scrollTo(_showsKey);
        break;
      case 2:
        _scrollTo(_aboutKey);
        break;
      case 3:
        _scrollTo(_teamKey);
        break;
      case 4:
        _scrollTo(_artisticKey);
        break;
      case 5:
        _scrollTo(_contactKey);
        break;
    }
  }

  // ---------------- FOOTER ----------------
  Widget _buildFooter() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppWebLightColors.darkBlueBackground,
            Color(0xFF16213e),
            Color(0xFF0f3460)
          ],
        ),
      ),
      child: const Text(
        "© 2025 Sahne Sanatları - Tüm Hakları Saklıdır.",
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}
