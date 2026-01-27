import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';

/// 💻 WEB TOP NAVIGATION BAR
///
/// Üst kısımda sabit duran navigation bar
/// Home, Keşfet, Yakındakiler, Profil sekmelerini içerir

class WebTopNavigationBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const WebTopNavigationBar({super.key, required this.navigationShell});

  @override
  State<WebTopNavigationBar> createState() => _WebTopNavigationBarState();
}

class _WebTopNavigationBarState extends State<WebTopNavigationBar> {
  int? _hoveredIndex;

  void _onItemTapped(int index) {
    if (index == widget.navigationShell.currentIndex) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // TOP NAVIGATION BAR
          _buildTopBar(context),

          // MAIN CONTENT
          Expanded(
            child: widget.navigationShell,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final accentColor = context.colors.primary;
    final isDark = context.isDarkMode;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: context.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(
            mobile: 20.0,
            tablet: 40.0,
            desktop: 60.0,
          ),
        ),
        child: Row(
          children: [
            // LOGO
            _buildLogo(context, accentColor, isDark),

            const Spacer(),

            // NAVIGATION ITEMS
            _buildNavItems(context, accentColor, isDark),

            SizedBox(width: context.spacing * 2),

            // PROFILE / LOGIN BUTTON
            _buildProfileButton(context, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, Color accentColor, bool isDark) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/app'),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.theater_comedy,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: context.spacing),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TicketApp",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  "Sanat & Kültür",
                  style: TextStyle(
                    fontSize: 10,
                    color: accentColor,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItems(BuildContext context, Color accentColor, bool isDark) {
    final items = [
      {"label": "Ana Sayfa", "icon": Icons.home_rounded},
      {"label": "Keşfet", "icon": Icons.explore_rounded},
      {"label": "Yakındakiler", "icon": Icons.location_city_rounded},
      {"label": "Profil", "icon": Icons.person_rounded},
    ];

    return Row(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Padding(
          padding: EdgeInsets.only(right: context.spacing),
          child: _buildNavItem(
            context,
            label: item["label"] as String,
            icon: item["icon"] as IconData,
            index: index,
            accentColor: accentColor,
            isDark: isDark,
          ),
        );
      }),
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required String label,
    required IconData icon,
    required int index,
    required Color accentColor,
    required bool isDark,
  }) {
    final isSelected = widget.navigationShell.currentIndex == index;
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withOpacity(0.15)
                : (isHovered ? accentColor.withOpacity(0.08) : Colors
                .transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? accentColor.withOpacity(0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? accentColor
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? accentColor
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context, Color accentColor) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Profil sayfasına git veya login modal aç
          widget.navigationShell.goBranch(3); // Profil tab'ı
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor, accentColor.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                color: context.colors.onPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Giriş Yap",
                style: TextStyle(
                  color: context.colors.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}