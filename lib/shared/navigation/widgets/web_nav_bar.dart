import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/features/home/presentation/pages/home_page_web.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/util/responsive_utils.dart';
import '../../widgets/button/language_selector.dart';
import 'nav_handler.dart';

class SearchIntent extends Intent {
  const SearchIntent();
}

class WebBar extends StatefulWidget {
  final bool startAnimations;

  const WebBar({super.key, this.startAnimations = false});

  @override
  State<WebBar> createState() => WebBarState();
}

class WebBarState extends State<WebBar> with ResponsiveUtils {
  // Bölüm anahtarları - HomePage ile paylaşılır
  final GlobalKey _showsKey = GlobalKey();
  final GlobalKey _artisticKey = GlobalKey();
  final GlobalKey _gozKapKey = GlobalKey();
  final GlobalKey _kurtarBeniKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _teamKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<String> _activeSection = ValueNotifier<String>('home');

  // OYUN LİSTESİ (Hem WebBar hem NavBar için merkezi veri)
  static const Map<String, String> _gamesList = {
    'artistic': 'Metafor',
    'gozKap': 'Gözlerimi Kaparım Vazifemi Yaparım',
    'kurtarBeni': 'Sevgili Doktor',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_detectActiveSection);
  }

  void scrollToSection(final String section) {
    if (section == 'home') {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic);
      return;
    }

    // Navigasyon Hedef Haritası
    final Map<String, GlobalKey> sectionMap = {
      'shows': _showsKey,
      'artistic': _artisticKey,
      'kurtarBeni': _kurtarBeniKey,
      'gozKap': _gozKapKey,
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

  void _detectActiveSection() {
    final sections = {
      'shows': _showsKey,
      'artistic': _artisticKey,
      'gozKap': _gozKapKey,
      'kurtarBeni': _kurtarBeniKey,
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
  Widget build(final BuildContext context) => Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
              const SearchIntent(),
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
              const SearchIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            SearchIntent: CallbackAction<SearchIntent>(
                onInvoke: (final intent) =>
                    NavigationHandler.goToSearch(context)),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Column(
                children: [
                  WebNavBar(
                    activeSection: _activeSection,
                    scrollController: _scrollController,
                    onNavigate: scrollToSection,
                    games: _gamesList,
                  ),
                  Expanded(
                    child: HomePage(
                      showsKey: _showsKey,
                      artisticKey: _artisticKey,
                      gozKapKey: _gozKapKey,
                      kurtarBeniKey: _kurtarBeniKey,
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
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _scrollController.dispose();
    _activeSection.dispose();
    super.dispose();
  }
}

class WebNavBar extends StatefulWidget {
  final ValueNotifier<String> activeSection;
  final ScrollController scrollController;
  final ValueChanged<String> onNavigate;
  final Map<String, String> games;

  const WebNavBar({
    super.key,
    required this.activeSection,
    required this.scrollController,
    required this.onNavigate,
    required this.games,
  });

  @override
  State<WebNavBar> createState() => _WebNavBarState();
}

class _WebNavBarState extends State<WebNavBar>
    with SingleTickerProviderStateMixin, ResponsiveUtils {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldScroll = widget.scrollController.offset > 100.0;
    shouldScroll ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (final context, final _) => Container(
          height: getValueForDevice(context,
              mobile: 70.0, tablet: 75.0, desktop: 80.0),
          decoration: BoxDecoration(
            color: WebColors.darkBlueBackground
                .withOpacity(0.8 + (_controller.value * 0.2)),
            border: Border(
                bottom: BorderSide(
                    color: WebColors.primaryGold
                        .withOpacity(0.1 + (_controller.value * 0.2)))),
          ),
          child: ResponsiveUtils.adaptive(
            context,
            mobile: _mobileLayout(context),
            tablet: _tabletLayout(context),
            desktop: _desktopLayout(context),
          ),
        ),
      );

  // --- MASAÜSTÜ: Full Menu + Search Box ---
  Widget _desktopLayout(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          children: [
            _logo(),
            const SizedBox(width: 15),
            _title(context),
            const Spacer(),
            Flexible(
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _navItems(context))),
            const SizedBox(width: 20),
            _buildSearchBox(context, isMobile: false),
            const LanguageSelector(),
          ],
        ),
      );

  // --- TABLET & MOBİL: Logo + Hamburger + Search Icon ---
  Widget _tabletLayout(final BuildContext context) => _mobileLayout(context);

  Widget _mobileLayout(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            _mobileMenu(context),
            const Spacer(),
            _logo(),
            const SizedBox(width: 8),
            _title(context),
            const Spacer(),
            _buildSearchBox(context, isMobile: true),
            const SizedBox(width: 8),
            const LanguageSelector(),
          ],
        ),
      );

  // --- YARDIMCI BİLEŞENLER ---

  Widget _buildSearchBox(final BuildContext context, {required final bool isMobile}) => InkWell(
        onTap: () => NavigationHandler.goToSearch(context),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: isMobile ? 6 : 8
          ),
          decoration: BoxDecoration(
            color: WebColors.primaryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: isMobile ? 14 : 16, color: WebColors.primaryGold),              const SizedBox(width: 8),
              const Text("Ara...",
                  style: TextStyle(color: WebColors.primaryGold, fontSize: 13)),
              const SizedBox(width: 12),
             _kbdIndicator(),
            ],
          ),
        ),
      );

  Widget _kbdIndicator() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
            color: WebColors.primaryGold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4)),
        child: const Text('Ctrl K',
            style: TextStyle(
                color: WebColors.primaryGold,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      );

  Widget _logo() =>
      Image.asset('assets/images/tiyatrol_logo.png', width: 45, height: 45);

  Widget _title(final BuildContext context) => ShaderMask(
        shaderCallback: WebColors.goldGradient.createShader,
        child: Text('TiyatRol',
            style: TextStyle(
                fontSize:
                    getValueForDevice(context, mobile: 18.0, desktop: 22.0),
                fontWeight: FontWeight.w900,
                color: Colors.white)),
      );

  List<Widget> _navItems(final BuildContext context) {
    const items = {
      'home': 'ANA SAYFA',
      'shows': 'OYUNLAR',
      'about': 'HAKKIMIZDA',
      'team': 'EKİP',
      'contact': 'İLETİŞİM'
    };

    return items.entries.map((final e) {
      if (e.key == 'shows' && ResponsiveUtils.isDesktop(context))
        return _buildShowsDropdown(context, e.value);
      return _navItem(context, e.key, e.value);
    }).toList();
  }

  Widget _navItem(final BuildContext context, final String section,
          final String label) =>
      ValueListenableBuilder<String>(
        valueListenable: widget.activeSection,
        builder: (final context, final active, final _) {
          bool isActive = active == section;
          if (section == 'shows')
            isActive = active == 'shows' || widget.games.containsKey(active);

          return GestureDetector(
            onTap: () => widget.onNavigate(section),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              decoration: BoxDecoration(
                gradient: isActive ? WebColors.goldGradient : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                      color: isActive
                          ? WebColors.darkBlueBackground
                          : WebColors.lightWhite,
                      fontSize: context.responsive(mobile: 12, desktop: 14))),
            ),
          );
        },
      );

  Widget _buildShowsDropdown(final BuildContext context, final String label) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      position: PopupMenuPosition.under,
      color: WebColors.darkBlueSurface,
      onSelected: (final value) => widget.onNavigate(value),
      child: _navItem(context, 'shows', label),
      itemBuilder: (final context) => widget.games.entries.map((final game) {
        return PopupMenuItem<String>(
          value: game.key,
          child: Text(game.value,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        );
      }).toList(),
    );
  }

  // MOBİL DRAWER MENÜ (İçe Girik Yapı)
  Widget _mobileMenu(final BuildContext context) => PopupMenuButton<String>(
        icon: const Icon(Icons.menu, color: WebColors.primaryGold),
        color: WebColors.darkBlueSurface,
        onSelected: widget.onNavigate,
        itemBuilder: (final context) => [
          _MobileMenuItem('home', 'ANA SAYFA', Icons.home),
          // "Oyunlar" Başlığı (Tıklanamaz)
          const PopupMenuItem(
            enabled: false,
            child: Text('OYUNLAR',
                style: TextStyle(
                    color: WebColors.primaryGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ),
          // Alt Oyunlar
          ...widget.games.entries.map((final game) => PopupMenuItem<String>(
                value: game.key,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.subdirectory_arrow_right,
                          size: 14, color: Colors.white54),
                      const SizedBox(width: 8),
                      Text(game.value,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              )),
          _MobileMenuItem('about', 'HAKKIMIZDA', Icons.info),
          _MobileMenuItem('team', 'EKİP', Icons.people),
          _MobileMenuItem('contact', 'İLETİŞİM', Icons.email),
        ],
      );

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }
}

class _MobileMenuItem extends PopupMenuItem<String> {
  _MobileMenuItem(final String value, final String label, final IconData icon)
      : super(
            value: value,
            child: Row(children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Text(label)
            ]));
}
