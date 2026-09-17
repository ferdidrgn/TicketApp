import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../core/theme/app_colors.dart';

/// 💻 WEB TOP NAVIGATION BAR
///
/// Üst kısımda sabit duran, tüm shell sekmelerini (Ana Sayfa, Keşfet,
/// Yakındakiler, Profil) saran kalıcı gezinme çubuğu. Artık "Kırmızı &
/// Siyah" (Crimson Noir) marka kimliği — `WebColors` sabitlerinin
/// değerleri değişti, burası otomatik olarak takip ediyor. Daha kompakt
/// bir yükseklik (68px, eskiden 84px) ve barın arkasında hafif bir
/// sahne-ışığı (spotlight) motifiyle "kocaman/şişkin" hissi azaltıldı.
///
/// Navigasyon mantığı (goBranch, HapticFeedback, Scaffold+Column+Expanded
/// iskeleti) birebir korunmuştur — sadece görsel kimlik değişti.

class WebTopNavigationBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const WebTopNavigationBar({super.key, required this.navigationShell});

  @override
  State<WebTopNavigationBar> createState() => WebTopNavigationBarState();
}

class WebTopNavigationBarState extends State<WebTopNavigationBar> {
  int? _hoveredIndex;

  void _onItemTapped(final int index) {
    if (index == widget.navigationShell.currentIndex) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: WebColors.darkBlueBackground,
      body: Column(
        children: [
          // TOP NAVIGATION BAR
          _buildTopBar(context),

          // MAIN CONTENT
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }

  Widget _buildTopBar(final BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface.withOpacity(0.92),
            border: Border(
              bottom: BorderSide(
                  color: WebColors.primaryGold.withOpacity(0.14), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: WebColors.veryDarkBlue.withOpacity(0.5),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          // İnce bir sahne-ışığı (spotlight) motifi — üst barın tam
          // ortasında, zemine değil bara ait çok hafif bir kızıl parıltı.
          // `landing`'in kendi radial glow deseniyle aynı dil.
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: -40,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 420,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            WebColors.primaryGold.withOpacity(0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1600),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive(
                        mobile: 16.0,
                        tablet: 32.0,
                        desktop: 44.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // LOGO
                        _buildLogo(context),

                        const Spacer(),

                        // NAVIGATION ITEMS
                        _buildNavItems(context),

                        SizedBox(width: context.spacing * 1.5),

                        // PROFILE / LOGIN BUTTON
                        _buildProfileButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(final BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => NavigationHandler.goToApp(context),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(11),
                  bottomLeft: Radius.circular(2),
                  bottomRight: Radius.circular(11),
                ),
                border: Border.all(
                    color: WebColors.primaryGold.withOpacity(0.55), width: 1.2),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(1),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(1),
                  bottomRight: Radius.circular(10),
                ),
                child: Image.asset(
                  'assets/images/tiyatrol_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (final context, final error, final stackTrace) =>
                      Container(
                    color: WebColors.primaryGold,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.theater_comedy_rounded,
                      color: WebColors.veryDarkBlue,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: context.spacing * 0.7),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TiyatRol",
                  style: (context.textTheme.titleLarge ?? const TextStyle())
                      .copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: WebColors.whiteText,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "SANAT & KÜLTÜR",
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: WebColors.primaryGoldLight,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItems(final BuildContext context) {
    final items = [
      {"label": "Ana Sayfa", "icon": Icons.home_rounded},
      {"label": "Keşfet", "icon": Icons.explore_rounded},
      {"label": "Yakındakiler", "icon": Icons.location_city_rounded},
      {"label": "Profil", "icon": Icons.person_rounded},
    ];

    return Row(
      children: List.generate(items.length, (final index) {
        final item = items[index];
        return Padding(
          padding: EdgeInsets.only(right: context.spacing * 0.5),
          child: _buildNavItem(
            context,
            label: item["label"] as String,
            icon: item["icon"] as IconData,
            index: index,
          ),
        );
      }),
    );
  }

  Widget _buildNavItem(
    final BuildContext context, {
    required final String label,
    required final IconData icon,
    required final int index,
  }) {
    final isSelected = widget.navigationShell.currentIndex == index;
    final isHovered = _hoveredIndex == index;
    final bool highlighted = isSelected || isHovered;

    return MouseRegion(
      onEnter: (final _) => setState(() => _hoveredIndex = index),
      onExit: (final _) => setState(() => _hoveredIndex = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? WebColors.primaryGold.withOpacity(0.14)
                : (isHovered
                    ? WebColors.primaryGold.withOpacity(0.06)
                    : Colors.transparent),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(2),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: highlighted
                        ? WebColors.primaryGoldLight
                        : WebColors.textSecondary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: highlighted
                          ? WebColors.whiteText
                          : WebColors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: 2,
                width: isSelected ? 18 : 0,
                decoration: BoxDecoration(
                  gradient: WebColors.goldButtonGradient,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton(final BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Profil sayfasına git veya login modal aç
          widget.navigationShell.goBranch(3); // Profil tab'ı
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: WebColors.goldButtonGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(2),
              bottomRight: Radius.circular(14),
            ),
            boxShadow: [
              BoxShadow(
                color: WebColors.primaryGold.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: WebColors.veryDarkBlue,
                size: 16,
              ),
              const SizedBox(width: 7),
              const Text(
                "Giriş Yap",
                style: TextStyle(
                  color: WebColors.veryDarkBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
