import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';

/// 💻 WEB İÇİN YAN MENÜLÜ NAVIGATION SHELL
///
/// Bu widget web'de sidebar (yan menü) gösterir ve 4 tab arasında geçiş yapar:
/// 1. Ana Sayfa (Home)
/// 2. Keşfet (Discover)
/// 3. Yakındakiler (Nearby)
/// 4. Profil (Profile)

class WebNavigationShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const WebNavigationShell({super.key, required this.navigationShell});

  @override
  State<WebNavigationShell> createState() => _WebNavigationShellState();
}

class _WebNavigationShellState extends State<WebNavigationShell> {
  int? _hoveredIndex;

  void _onItemTapped(final int index) {
    // Aynı tab'e tıklanırsa bir şey yapma
    if (index == widget.navigationShell.currentIndex) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.selectionClick();

    // Tab'i değiştir
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
        body: Row(
          children: [
            // 1️⃣ YAN MENÜ (SIDEBAR)
            _buildSidebar(context),

            // 2️⃣ ANA İÇERİK (Seçili tab'ın sayfası)
            Expanded(
              child: widget.navigationShell,
            ),
          ],
        ),
      );

  Widget _buildSidebar(final BuildContext context) {
    // Renkler
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final accentColor = const Color(0xFFD4AF37); // Altın rengi

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // LOGO BÖLÜMÜ
          _buildLogo(accentColor, isDark),

          const SizedBox(height: 40),

          // MENÜ BUTONLARI
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.home_rounded,
                  label: "Ana Sayfa",
                  index: 0,
                  accentColor: accentColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context,
                  icon: Icons.event_seat_rounded,
                  label: "Keşfet",
                  index: 1,
                  accentColor: accentColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context,
                  icon: Icons.location_city_rounded,
                  label: "Yakındakiler",
                  index: 2,
                  accentColor: accentColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context,
                  icon: Icons.people_rounded,
                  label: "Profil",
                  index: 3,
                  accentColor: accentColor,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // ALT BÖLÜM (Ayarlar vs)
          _buildFooter(accentColor, isDark),
        ],
      ),
    );
  }

  Widget _buildLogo(final Color accentColor, final bool isDark) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Logo icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.theater_comedy,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Logo text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TicketApp",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                "Sanat & Kültür",
                style: TextStyle(
                  fontSize: 12,
                  color: accentColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    final BuildContext context, {
    required final IconData icon,
    required final String label,
    required final int index,
    required final Color accentColor,
    required final bool isDark,
  }) {
    // Bu menü seçili mi?
    final isSelected = widget.navigationShell.currentIndex == index;
    // Mouse üzerinde mi?
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (final _) => setState(() => _hoveredIndex = index),
      onExit: (final _) => setState(() => _hoveredIndex = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withOpacity(0.15)
                : (isHovered
                    ? accentColor.withOpacity(0.08)
                    : Colors.transparent),
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
              // Icon
              AnimatedScale(
                scale: isSelected || isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? accentColor
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? accentColor
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
              // Seçili nokta
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(final Color accentColor, final bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Divider(
            color: context.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: accentColor.withOpacity(0.2),
                child: Icon(Icons.person, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Kullanıcı",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      "Profil ayarları",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.settings_rounded, color: accentColor),
                onPressed: () {
                  // Ayarlar sayfasına git
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
