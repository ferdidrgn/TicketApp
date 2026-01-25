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
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<String> _activeSection = ValueNotifier<String>('home');

  // Bölüm anahtarlarını merkezi bir yerde topluyoruz
  final Map<String, GlobalKey> _sectionKeys = {
    'shows': GlobalKey(),
    'artistic': GlobalKey(),
    'gozKap': GlobalKey(),
    'kurtarBeni': GlobalKey(),
    'about': GlobalKey(),
    'team': GlobalKey(),
    'contact': GlobalKey(),
  };

  static const Map<String, String> _gamesList = {
    'shows': 'Tüm Oyunlar',
    'artistic': 'Metafor',
    'kurtarBeni': 'Sevgili Doktor',
    'gozKap': 'Gözlerimi Kaparım Vazifemi Yaparım',
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
    final key = _sectionKeys[section];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(key!.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
          alignment: 0.05);
      _activeSection.value = section;
    }
  }

  void _detectActiveSection() {
    for (final entry in _sectionKeys.entries) {
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
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
              const SearchIntent(),
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
              const SearchIntent(),
        },
        child: Actions(
          actions: {
            SearchIntent: CallbackAction<SearchIntent>(
                onInvoke: (final _) => NavigationHandler.goToSearch(context))
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
                      games: _gamesList),
                  Expanded(
                    child: HomePage(
                      showsKey: _sectionKeys['shows']!,
                      artisticKey: _sectionKeys['artistic']!,
                      gozKapKey: _sectionKeys['gozKap']!,
                      kurtarBeniKey: _sectionKeys['kurtarBeni']!,
                      aboutKey: _sectionKeys['about']!,
                      teamKey: _sectionKeys['team']!,
                      contactKey: _sectionKeys['contact']!,
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
  final LayerLink _showsLink = LayerLink();
  OverlayEntry? _showsOverlay;
  bool _isHoveringShows = false;

  // --- REFACTOR: Stil Sabitleri ---
  BoxDecoration get _navDecoration => BoxDecoration(
        color: WebColors.darkBlueBackground
            .withOpacity(0.8 + (_controller.value * 0.2)),
        border: Border(
            bottom: BorderSide(
                color: WebColors.primaryGold
                    .withOpacity(0.1 + (_controller.value * 0.2)))),
      );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    widget.scrollController.addListener(() {
      final shouldScroll = widget.scrollController.offset > 100.0;
      shouldScroll ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  void dispose() {
    _closeShowsMenuDirect();
    _controller.dispose();
    super.dispose();
  }

  // --- REFACTOR: Merkezi Navigasyon Helper ---
  void _handleNavigation(final String key) {
    widget.onNavigate(key);
    _closeShowsMenuDirect();
  }

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (final context, final _) => Container(
          height: getValueForDevice(context,
              mobile: 70.0, tablet: 75.0, desktop: 80.0),
          decoration: _navDecoration,
          child: ResponsiveUtils.adaptive(
            context,
            mobile: _buildCompactLayout(context),
            tablet: _buildCompactLayout(context),
            desktop: _buildDesktopLayout(context),
          ),
        ),
      );

  // --- REFACTOR: Ortak Masaüstü Layout Parçası ---
  Widget _buildDesktopLayout(final BuildContext context) => Padding(
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
            const SizedBox(width: 24),
            _buildSearchBox(context, isMobile: false),
            const SizedBox(width: 16),
            const LanguageSelector(),
          ],
        ),
      );

  // --- REFACTOR: Ortak Mobil Layout Parçası ---
  Widget _buildCompactLayout(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            _mobileMenu(context),
            const Spacer(),
            _logo(),
            const SizedBox(width: 8),
            FittedBox(fit: BoxFit.scaleDown, child: _title(context)),
            const Spacer(),
            _buildSearchBox(context, isMobile: true),
            const SizedBox(width: 8),
            const LanguageSelector(),
          ],
        ),
      );

  // --- REFACTOR: Gelişmiş Arama Kutusu ---
  Widget _buildSearchBox(final BuildContext context,
          {required final bool isMobile}) =>
      InkWell(
        onTap: () => NavigationHandler.goToSearch(context),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12, vertical: isMobile ? 6 : 8),
          decoration: BoxDecoration(
            color: WebColors.primaryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search,
                  size: isMobile ? 14 : 16, color: WebColors.primaryGold),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                const Text("Ara...",
                    style:
                        TextStyle(color: WebColors.primaryGold, fontSize: 13)),
                const SizedBox(width: 12),
                _kbdIndicator(),
              ],
            ],
          ),
        ),
      );

  // --- REFACTOR: Overlay Builder ---
  void _openShowsMenu(final BuildContext context) {
    if (_showsOverlay != null) return;
    _showsOverlay = OverlayEntry(
      builder: (final _) => CompositedTransformFollower(
        link: _showsLink,
        showWhenUnlinked: false,
        offset: const Offset(-80, 50),
        child: Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.topLeft,
            child: _showsMenuContent(),
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_showsOverlay!);
  }

  Widget _showsMenuContent() => MouseRegion(
        onEnter: (final _) => _isHoveringShows = true,
        onExit: (final _) {
          _isHoveringShows = false;
          _closeShowsMenuWithDelay();
        },
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.games.entries
                .map((final game) => InkWell(
                      onTap: () => _handleNavigation(game.key),
                      // 🔥 Tek metod üzerinden kontrol
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Text(game.value,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                    ))
                .toList(),
          ),
        ),
      );

  List<Widget> _navItems(final BuildContext context) {
    final items = {
      'home': 'ANA SAYFA',
      'shows': context.l10n.plays.toUpperCase(),
      'about': 'HAKKIMIZDA',
      'team': 'EKİP',
      'contact': 'İLETİŞİM'
    };
    return items.entries
        .map((final e) => e.key == 'shows' && ResponsiveUtils.isDesktop(context)
            ? _buildShowsDropdown(context, e.value)
            : _navItem(context, e.key, e.value))
        .toList();
  }

  Widget _navItem(final BuildContext context, final String section,
          final String label) =>
      ValueListenableBuilder<String>(
        valueListenable: widget.activeSection,
        builder: (final context, final active, final _) {
          final bool isActive = active == section;
          return GestureDetector(
            onTap: () => widget.onNavigate(section),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              decoration: BoxDecoration(
                  gradient: isActive ? WebColors.goldGradient : null,
                  borderRadius: BorderRadius.circular(8)),
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

  Widget _buildShowsDropdown(final BuildContext context, final String label) =>
      MouseRegion(
        onEnter: (final _) {
          _isHoveringShows = true;
          _openShowsMenu(context);
        },
        onExit: (final _) {
          _isHoveringShows = false;
          _closeShowsMenuWithDelay();
        },
        child: CompositedTransformTarget(
            link: _showsLink, child: _navItem(context, 'shows', label)),
      );

  void _closeShowsMenuDirect() {
    _showsOverlay?.remove();
    _showsOverlay = null;
  }

  void _closeShowsMenuWithDelay() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!_isHoveringShows) _closeShowsMenuDirect();
  }

  Widget _mobileMenu(final BuildContext context) => PopupMenuButton<String>(
        icon: const Icon(Icons.menu, color: WebColors.primaryGold),
        color: WebColors.darkBlueSurface,
        onSelected: widget.onNavigate,
        itemBuilder: (final context) => [
          _MobileMenuItem('home', 'ANA SAYFA', Icons.home),
          PopupMenuItem(
              enabled: false,
              child: Text(context.l10n.plays.toUpperCase(),
                  style: const TextStyle(
                      color: WebColors.primaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 11))),
          ...widget.games.entries.map((final game) => PopupMenuItem<String>(
                value: game.key,
                child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Row(children: [
                      const Icon(Icons.subdirectory_arrow_right,
                          size: 14, color: Colors.white54),
                      const SizedBox(width: 8),
                      Text(game.value,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13))
                    ])),
              )),
          _MobileMenuItem('about', 'HAKKIMIZDA', Icons.info),
          _MobileMenuItem('team', 'EKİP', Icons.people),
          _MobileMenuItem('contact', 'İLETİŞİM', Icons.email),
        ],
      );

  // Ortak küçük bileşenler
  Widget _logo() =>
      Image.asset('assets/images/tiyatrol_logo.png', width: 45, height: 45);

  Widget _kbdIndicator() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
          color: WebColors.primaryGold.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4)),
      child: const Text('Ctrl K',
          style: TextStyle(
              color: WebColors.primaryGold,
              fontSize: 10,
              fontWeight: FontWeight.bold)));

  Widget _title(final BuildContext context) => ShaderMask(
      shaderCallback: WebColors.goldGradient.createShader,
      child: Text('TiyatRol',
          style: TextStyle(
              fontSize: getValueForDevice(context, mobile: 18.0, desktop: 22.0),
              fontWeight: FontWeight.w900,
              color: Colors.white)));
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
