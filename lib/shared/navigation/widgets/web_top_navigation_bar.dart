import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/notifications/presentation/providers/notification_provider.dart';
import 'ticket_nav_bar.dart';

/// 💻 WEB GEZİNME KABUĞU
///
/// Tüm shell sekmelerini (Ana Sayfa, Keşfet, Yakındakiler, Profil) saran
/// kalıcı çubuk. Temanın yüzeyinde sade bir üst şerit: solda biletin üst
/// şeridindeki gibi Playfair Display "TİYATROL" markası, ortada/sağda
/// sekmeler, en sağda hesap aksiyonları (giriş yapılmışsa Biletlerim +
/// okunmamış rozetli Bildirimler, değilse "Giriş yap"). Aktif sekme,
/// çubuğun alt çizgisine açılmış "zımba çentiği" + kalın etiketle belli.
///
/// Genişliğe göre kompozisyon değişir:
/// - masaüstü (≥1024): marka + ikonlu sekmeler + metinli giriş düğmesi
/// - tablet (768–1023): marka + sadece metinli sekmeler + ikon aksiyonlar
/// - dar (<768): üstte marka + aksiyonlar, sekmeler başparmak bölgesinde
///   alt çubukta (mobil uygulamayla aynı `TicketBottomNavBar`)
///
/// Navigasyon mantığı (goBranch, HapticFeedback, Scaffold+Column+Expanded
/// iskeleti, Profil'e `goBranch(3)`) birebir korunmuştur.
class WebTopNavigationBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const WebTopNavigationBar({super.key, required this.navigationShell});

  @override
  State<WebTopNavigationBar> createState() => WebTopNavigationBarState();
}

class WebTopNavigationBarState extends State<WebTopNavigationBar> {
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
    final cs = context.colors;
    final bool narrow = context.isMobile;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // TOP NAVIGATION BAR
          _buildTopBar(context, narrow: narrow),

          // MAIN CONTENT
          Expanded(child: widget.navigationShell),
        ],
      ),
      bottomNavigationBar: narrow
          ? TicketBottomNavBar(
              currentIndex: widget.navigationShell.currentIndex,
              onTap: _onItemTapped,
            )
          : null,
    );
  }

  Widget _buildTopBar(final BuildContext context, {required final bool narrow}) {
    final cs = context.colors;
    final bool desktop = context.isDesktop;

    return Material(
      color: cs.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: narrow ? 56 : 64,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive(
                      mobile: AppSpacing.sm,
                      tablet: AppSpacing.xxl,
                      desktop: AppSpacing.huge,
                    ),
                  ),
                  child: Row(
                    children: [
                      // LOGO
                      _BrandMark(onTap: () => NavigationHandler.goToApp(context)),

                      const Spacer(),

                      // NAVIGATION ITEMS
                      if (!narrow)
                        for (int i = 0; i < kShellDestinations.length; i++)
                          _WebNavItem(
                            destination: kShellDestinations[i],
                            active: widget.navigationShell.currentIndex == i,
                            showIcon: desktop,
                            onTap: () => _onItemTapped(i),
                          ),

                      if (!narrow) const SizedBox(width: AppSpacing.lg),

                      // PROFILE / LOGIN
                      _AccountActions(
                        compact: !desktop,
                        onLogin: () => widget.navigationShell
                            .goBranch(3), // Profil tab'ı
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Marka: uygulama ikonu + biletin üst şeridindeki "TİYATROL" yazısı.
class _BrandMark extends StatelessWidget {
  final VoidCallback onTap;
  const _BrandMark({required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    return Semantics(
      button: true,
      label: 'TiyatRol ana sayfa',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        focusColor: cs.primary.withOpacity(0.16),
        hoverColor: cs.onSurface.withOpacity(0.04),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: Image.asset(
                    'assets/images/app_icon_master.png',
                    width: 32,
                    height: 32,
                    cacheWidth: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (final context, final error, final stack) =>
                        Icon(Icons.theater_comedy_rounded,
                            color: cs.primary, size: 24),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'TİYATROL',
                  style: GoogleFonts.playfairDisplay(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Üst menü sekmesi. Hover'da zemin hafifçe koyulaşır, klavye odağında
/// temanın vurgusuyla 2px halka çizilir; aktif sekmede alt çizgiye zımba
/// çentiği açılır.
class _WebNavItem extends StatefulWidget {
  final TicketNavDestination destination;
  final bool active;
  final bool showIcon;
  final VoidCallback onTap;

  const _WebNavItem({
    required this.destination,
    required this.active,
    required this.showIcon,
    required this.onTap,
  });

  @override
  State<_WebNavItem> createState() => _WebNavItemState();
}

class _WebNavItemState extends State<_WebNavItem> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final bool active = widget.active;
    final Color fg =
        active || _hovered ? cs.onSurface : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: active,
      label: widget.destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (final v) => setState(() => _hovered = v),
        onFocusChange: (final v) => setState(() => _focused = v),
        // Hover/odak görünümünü kendimiz çiziyoruz (etiketin etrafında).
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: cs.primary.withOpacity(0.08),
        // Sekme çubuğun tam yüksekliğini kaplar ki çentik alt çizgiye otursun.
        child: SizedBox(
          height: double.infinity,
          child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: _hovered && !active
                      ? cs.onSurface.withOpacity(0.05)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: _focused ? cs.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showIcon) ...[
                      Icon(
                        active
                            ? widget.destination.activeIcon
                            : widget.destination.icon,
                        size: 18,
                        color: active ? cs.primary : fg,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      widget.destination.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: fg,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              // Çentiğin merkezi çubuğun alt çizgisinde (bkz. TicketPunchMark).
              bottom: 0,
              child: TicketPunchMark(visible: active, opensDown: false),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

/// Hesap aksiyonları. Giriş yapılmışsa Biletlerim + Bildirimler (okunmamış
/// rozetiyle), yapılmamışsa "Giriş yap" (eskisi gibi Profil sekmesine gider;
/// orada giriş seçenekleri var).
class _AccountActions extends ConsumerWidget {
  final bool compact;
  final VoidCallback onLogin;

  const _AccountActions({required this.compact, required this.onLogin});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final cs = context.colors;
    final bool loggedIn = ref.watch(isLoggedInProvider);

    if (!loggedIn) {
      if (compact)
        return IconButton(
          tooltip: 'Giriş yap',
          onPressed: onLogin,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Icon(Icons.login_rounded, color: cs.onSurface),
        );
      return FilledButton.icon(
        onPressed: onLogin,
        icon: const Icon(Icons.person_outline_rounded, size: 18),
        label: const Text('Giriş yap'),
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xs)),
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
      );
    }

    final String uid = ref.watch(currentUserIdProvider) ?? '';
    final int unread = ref.watch(unreadNotificationCountProvider(uid));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Biletlerim',
          onPressed: () => NavigationHandler.goToMyTickets(context, uid),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Icon(Icons.confirmation_number_outlined, color: cs.onSurface),
        ),
        IconButton(
          tooltip: unread > 0
              ? 'Bildirimler, $unread okunmamış'
              : 'Bildirimler',
          onPressed: () => NavigationHandler.goToNotifications(context),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 9 ? '9+' : '$unread'),
            child: Icon(Icons.notifications_none_rounded, color: cs.onSurface),
          ),
        ),
      ],
    );
  }
}
