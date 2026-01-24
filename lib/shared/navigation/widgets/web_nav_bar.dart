import 'package:flutter/material.dart';
import 'package:ticketapp/features/home/presentation/pages/home_page_web.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../core/theme/app_colors.dart';
import 'nav_handler.dart';

/// Ana sayfa scaffold'u - Tüm componentleri bir araya getirir
/// Active section tracking, smooth scroll ve modern navbar içerir

class WebBar extends StatefulWidget {
  final bool startAnimations;

  const WebBar({super.key, this.startAnimations = false});

  @override
  State<WebBar> createState() => WebBarState();
}

class WebBarState extends State<WebBar> {
  // SECTION KEYS
  // ------------------------
  final GlobalKey _showsKey = GlobalKey();
  final GlobalKey _artisticKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _teamKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  // SCROLL
  // ------------------------
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<String> _activeSection = ValueNotifier<String>('home');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_detectActiveSection);
  }

  void _detectActiveSection() {
    final sections = {
      'shows': _showsKey,
      'artistic': _artisticKey,
      'about': _aboutKey,
      'team': _teamKey,
      'contact': _contactKey,
    };

    for (final entry in sections.entries) {
      final context = entry.value.currentContext;
      if (context == null) continue;

      final box = context.findRenderObject() as RenderBox;
      final offset = box.localToGlobal(Offset.zero).dy;

      if (offset < 150 && offset > -300) {
        _activeSection.value = entry.key;
        return;
      }
    }

    _activeSection.value = 'home';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _activeSection.dispose();
    super.dispose();
  }

  // NAVIGATION
  // ------------------------
  void scrollToSection(final String section) {
    if (section == 'home') {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
      _activeSection.value = 'home';
      return;
    }

    final Map<String, GlobalKey> sectionMap = {
      'shows': _showsKey,
      'artistic': _artisticKey,
      'about': _aboutKey,
      'team': _teamKey,
      'contact': _contactKey,
    };

    final key = sectionMap[section];

    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
      _activeSection.value = section;
    }
  }

  // UI
  // ------------------------
  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          WebNavBar(
            activeSection: _activeSection,
            scrollController: _scrollController,
            onNavigate: scrollToSection,
          ),
          Expanded(
            child: HomePage(
              showsKey: _showsKey,
              artisticKey: _artisticKey,
              aboutKey: _aboutKey,
              teamKey: _teamKey,
              contactKey: _contactKey,
              scrollController: _scrollController,
              activeSection: _activeSection,
              startAnimations: widget.startAnimations,
            ),
          ),
        ],
      ),
    );
  }
}

class WebNavBar extends StatefulWidget {
  final ValueNotifier<String> activeSection;
  final ScrollController scrollController;
  final ValueChanged<String> onNavigate;

  const WebNavBar({
    super.key,
    required this.activeSection,
    required this.scrollController,
    required this.onNavigate,
  });

  @override
  State<WebNavBar> createState() => _WebNavBarState();
}

class _WebNavBarState extends State<WebNavBar>
    with SingleTickerProviderStateMixin {
  static const _scrollThreshold = 100.0;

  late final AnimationController _controller;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldScroll = widget.scrollController.offset > _scrollThreshold;
    if (shouldScroll == _isScrolled) return;

    setState(() => _isScrolled = shouldScroll);
    shouldScroll ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (final _, final __) {
          return SizedBox(
            height: context.responsive(mobile: 70.0, desktop: 80.0),
            child: DecoratedBox(
              decoration: _navDecoration,
              child:
                  context.isMobile ? _mobileNav(context) : _desktopNav(context),
            ),
          );
        },
      );

  // ------------------------
  // DECORATION
  // ------------------------
  BoxDecoration get _navDecoration => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            WebColors.darkBlueBackground
                .withOpacity(0.7 + (_controller.value * 0.3)),
            WebColors.darkBlueBackground
                .withOpacity(0.5 + (_controller.value * 0.5)),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1 + (_controller.value * 0.2)),
            blurRadius: 10 + (_controller.value * 10),
            offset: Offset(0, 2 + (_controller.value * 3)),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: WebColors.primaryGold
                .withOpacity(0.1 + (_controller.value * 0.2)),
          ),
        ),
      );

  // ------------------------
  // DESKTOP
  // ------------------------
  Widget _desktopNav(final BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.responsive(mobile: 20, desktop: 40)),
        child: Row(
          children: [
            _logo(context),
            const SizedBox(width: 12),
            _title(context),
            const Spacer(),
            Row(
              children: [
                ..._navItems(context),
                const SizedBox(width: 12),
                _searchButton(context),
              ],
            ),
          ],
        ),
      );

  List<Widget> _navItems(final BuildContext context) {
    const items = {
      'home': 'ANA SAYFA',
      'shows': 'OYUNLAR',
      'artistic': 'SANATSAL',
      'about': 'HAKKIMIZDA',
      'team': 'EKİP',
      'contact': 'İLETİŞİM',
    };

    return items.entries
        .map((final e) => _navItem(context, e.key, e.value))
        .toList();
  }

  // ------------------------
  // MOBILE
  // ------------------------
  Widget _mobileNav(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _logo(context),
            const SizedBox(width: 8),
            Expanded(child: _title(context)),
            _searchButton(context),
            _mobileMenu(context),
          ],
        ),
      );

  // ------------------------
  // COMMON
  // ------------------------
  Widget _logo(final BuildContext context) {
    final size = context.responsive(mobile: 40.0, tablet: 50.0, desktop: 60.0);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0, end: 1),
      builder: (final _, final value, final __) => Transform.scale(
        scale: 0.8 + value * 0.2,
        child: Image.asset(
          'assets/images/tiyatrol_logo.png',
          width: size,
          height: size,
        ),
      ),
    );
  }

  Widget _title(final BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: ShaderMask(
      shaderCallback: WebColors.goldGradient.createShader,
      child: Text(
        'TiyatRol',
        style: TextStyle(
          fontSize: context.responsive(mobile: 18, desktop: 24),
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    ),
  );

  Widget _navItem(final BuildContext context, final String section,
          final String label) =>
      ValueListenableBuilder<String>(
        valueListenable: widget.activeSection,
        builder: (final _, final active, final __) {
          final isActive = active == section;
          return GestureDetector(
            onTap: () => widget.onNavigate(section),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isActive ? WebColors.goldGradient : null,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : WebColors.primaryGold.withOpacity(0.2),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  color: isActive
                      ? WebColors.darkBlueBackground
                      : WebColors.lightWhite,
                ),
              ),
            ),
          );
        },
      );

  Widget _mobileMenu(final BuildContext context) => PopupMenuButton<String>(
        icon: const Icon(Icons.menu, color: WebColors.primaryGold),
        color: WebColors.darkBlueSurface,
        onSelected: widget.onNavigate,
        itemBuilder: (final _) => [
          _MobileMenuItem('home', 'ANA SAYFA', Icons.home),
          _MobileMenuItem('shows', 'OYUNLAR', Icons.theater_comedy),
          _MobileMenuItem('artistic', 'SANATSAL', Icons.palette),
          _MobileMenuItem('about', 'HAKKIMIZDA', Icons.info),
          _MobileMenuItem('team', 'EKİP', Icons.people),
          _MobileMenuItem('contact', 'İLETİŞİM', Icons.email),
        ],
      );

  Widget _searchButton(final BuildContext context) => IconButton(
        onPressed: () => NavigationHandler.goToSearch(context),
        icon: const Icon(Icons.search_rounded, color: WebColors.primaryGold),
        tooltip: 'Deneyim',
        splashRadius: 24,
      );
}

class _MobileMenuItem extends PopupMenuItem<String> {
  _MobileMenuItem(final String value, final String label, final IconData icon)
      : super(
          value: value,
          child: Row(
            children: [
              Icon(icon, size: 20),
              SizedBox(width: 12),
              Text(label),
            ],
          ),
        );
}
