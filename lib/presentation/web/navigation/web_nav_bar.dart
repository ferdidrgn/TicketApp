import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';

class WebNavBar extends StatefulWidget {
  final ValueNotifier<String> activeSection;
  final Function(String) onNavigate;
  final ScrollController scrollController;

  const WebNavBar({
    super.key,
    required this.activeSection,
    required this.onNavigate,
    required this.scrollController,
  });

  @override
  State<WebNavBar> createState() => _WebNavBarState();
}

class _WebNavBarState extends State<WebNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController.offset > 100 && !_isScrolled) {
      setState(() => _isScrolled = true);
      _controller.forward();
    } else if (widget.scrollController.offset <= 100 && _isScrolled) {
      setState(() => _isScrolled = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(final BuildContext context) {
    // ResponsiveUtils'den gelen breakpoint'i kullanıyoruz
    // Tablet ve altı (1100px altı) için mobil menü gösterelim
    final bool isNarrow = context.screenWidth < 1100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (final context, final child) {
        return Container(
          height: context.responsive(mobile: 70.0, desktop: 80.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                WebColors.darkBlueBackground.withOpacity(
                  0.7 + (_controller.value * 0.3),
                ),
                WebColors.darkBlueBackground.withOpacity(
                  0.5 + (_controller.value * 0.5),
                ),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.1 + (_controller.value * 0.2)),
                blurRadius: 10 + (_controller.value * 10),
                offset: Offset(0, 2 + (_controller.value * 3)),
              ),
            ],
            border: Border(
              bottom: BorderSide(
                color: WebColors.primaryGold.withOpacity(
                  0.1 + (_controller.value * 0.2),
                ),
                width: 1,
              ),
            ),
          ),
          child:
              isNarrow ? _buildMobileNav(context) : _buildDesktopNav(context),
        );
      },
    );
  }

  // --- MASAÜSTÜ GÖRÜNÜMÜ ---
  Widget _buildDesktopNav(final BuildContext context) {
    return Padding(
      // Responsive Padding
      padding: EdgeInsets.symmetric(
          horizontal: context.responsive(mobile: 20.0, desktop: 40.0)),
      child: Row(
        children: [
          _buildLogoImage(context),
          const SizedBox(width: 12),
          _buildWebName(context),
          const Spacer(),
          Row(
            children: [
              _buildNavItem(context, 'home', 'ANA SAYFA'),
              _buildNavItem(context, 'shows', 'OYUNLAR'),
              _buildNavItem(context, 'artistic', 'SANATSAL'),
              _buildNavItem(context, 'about', 'HAKKIMIZDA'),
              _buildNavItem(context, 'team', 'EKİP'),
              _buildNavItem(context, 'contact', 'İLETİŞİM'),
            ],
          ),
        ],
      ),
    );
  }

  // --- MOBİL GÖRÜNÜMÜ ---
  Widget _buildMobileNav(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLogoImage(context),
              _buildMobileMenu(context),
            ],
          ),
          _buildWebName(context),
        ],
      ),
    );
  }

  // --- ORTAK BİLEŞENLER ---

  Widget _buildLogoImage(final BuildContext context) {
    final size = context.responsive(mobile: 40.0, tablet: 50.0, desktop: 60.0);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (final context, final value, final child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Image.asset(
            'assets/images/tiyatrol_logo.png',
            fit: BoxFit.cover,
            width: size,
            height: size,
          ),
        );
      },
    );
  }

  // 2. Altın Efektli Yazı
  Widget _buildWebName(final BuildContext context) {
    return ShaderMask(
      shaderCallback: (final bounds) =>
          WebColors.goldGradient.createShader(bounds),
      child: Text(
        'TiyatRol',
        style: TextStyle(
          fontSize: context.responsive(mobile: 18.0, desktop: 24.0),
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // 3. Masaüstü Menü Elemanı
  Widget _buildNavItem(
      final BuildContext context, final String section, final String label) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.activeSection,
      builder: (final context, final activeSection, final child) {
        final isActive = activeSection == section;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => widget.onNavigate(section),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isActive ? WebColors.goldGradient : null,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : WebColors.primaryGold.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: context.captionSize + 1, // Responsive font
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  color: isActive
                      ? WebColors.darkBlueBackground
                      : WebColors.lightWhite,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 4. Mobil Burger Menü
  Widget _buildMobileMenu(final BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: WebColors.primaryGold.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.menu,
          color: WebColors.primaryGold,
          size: 24,
        ),
      ),
      color: WebColors.darkBlueSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: WebColors.primaryGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      onSelected: (final value) => widget.onNavigate(value),
      itemBuilder: (final context) => [
        _buildMobileMenuItem('home', 'ANA SAYFA', Icons.home),
        _buildMobileMenuItem('shows', 'OYUNLAR', Icons.theater_comedy),
        _buildMobileMenuItem('artistic', 'SANATSAL', Icons.palette),
        _buildMobileMenuItem('about', 'HAKKIMIZDA', Icons.info),
        _buildMobileMenuItem('team', 'EKİP', Icons.people),
        _buildMobileMenuItem('contact', 'İLETİŞİM', Icons.email),
      ],
    );
  }

  PopupMenuItem<String> _buildMobileMenuItem(
    final String value,
    final String label,
    final IconData icon,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: ValueListenableBuilder<String>(
        valueListenable: widget.activeSection,
        builder: (final context, final activeSection, final child) {
          final isActive = activeSection == value;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: isActive ? WebColors.goldGradient : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? WebColors.darkBlueBackground
                      : WebColors.primaryGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                    color: isActive
                        ? WebColors.darkBlueBackground
                        : WebColors.lightWhite,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
