import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/util/comminucation_actions.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/discovery/presentation/widgets/browse_controls.dart';
import '../../../features/search/presentation/providers/search_query_provider.dart';
import '../../../features/shows/domain/entities/show.dart';
import '../../../features/shows/presentation/providers/show_provider.dart';
import '../../../features/tickets/presentation/providers/my_ticket_provider.dart';
import 'nav_handler.dart';
import 'ticket_nav_bar.dart';

/// WEB SİTE BAŞLIĞI — gerçek bir e-ticaret/bilet sitesi gibi üç katman:
///
/// 1. Üst bilgi şeridi: destek e-postası + hızlı bağlantılar
///    (Kampanyalar, Biletlerim, Sahneler, Yardım, Yasal).
/// 2. Ana başlık: marka · ortada büyük arama · Hesabım / Favorilerim /
///    Biletlerim (yaklaşan bilet sayısı rozetiyle).
/// 3. Gezinme satırı: ana sekmeler (aktif altı çizili) + tür bağlantıları
///    (gerçek oyun türleri) + sağda vurgulu "Bu akşam" ve "Kampanyalar".
///
/// Yalnız geniş ekranda (≥768) kullanılır; mobil uygulama/dar ekran kendi
/// başlığını ve alt çubuğunu korur.
class WebSiteHeader extends ConsumerStatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTab;

  const WebSiteHeader(
      {super.key, required this.currentIndex, required this.onTab});

  @override
  ConsumerState<WebSiteHeader> createState() => _WebSiteHeaderState();
}

class _WebSiteHeaderState extends ConsumerState<WebSiteHeader> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _submit(final String v) {
    final String q = v.trim();
    ref.read(searchQueryProvider.notifier).update(q);
    NavigationHandler.goToSearch(context);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.sizeOf(context).width;
    final bool wide = w >= 1100;
    final double pad = w >= 1200 ? 48 : 28;
    final bool loggedIn = ref.watch(isLoggedInProvider);
    final String uid = ref.watch(currentUserIdProvider) ?? '';
    final List<Show> shows =
        ref.watch(activeShowsProvider(false)).value ?? const [];
    final List<BrowseCategory> cats = browseCategoriesOf(shows);
    final int upcoming = loggedIn && uid.isNotEmpty
        ? (ref.watch(myTicketsProvider(uid)).value ?? const [])
            .where((final t) => !t.isPast)
            .length
        : 0;

    Widget bounded(final Widget child) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: pad), child: child),
          ),
        );

    // ── 1) Üst bilgi şeridi ──
    final Widget utility = Container(
      color: cs.surfaceContainerHigh,
      height: 38,
      child: bounded(Row(children: [
        _HoverText(
          onTap: () => TiyatrolCommunicationActions.sendEmail(),
          child: Row(children: [
            Icon(Icons.mail_outline_rounded, size: 15, color: cs.primary),
            const SizedBox(width: 7),
            Text('Bilet ve destek: iletisim@tiyatrol.com',
                style: _small(context, cs.onSurfaceVariant)),
          ]),
          label: 'Destek e-postası gönder',
        ),
        const Spacer(),
        _UtilLink('Kampanyalar', Icons.local_offer_outlined,
            () => NavigationHandler.goToCampaigns(context)),
        if (loggedIn)
          _UtilLink('Biletlerim', Icons.confirmation_number_outlined,
              () => NavigationHandler.goToMyTickets(context, uid)),
        _UtilLink('Sahneler', Icons.place_outlined,
            () => NavigationHandler.goToNearby(context)),
        _UtilLink('Yardım', Icons.help_outline_rounded,
            () => NavigationHandler.goToHelpSupport(context)),
        _UtilLink('Gizlilik ve şartlar', Icons.shield_outlined,
            () => NavigationHandler.goToContracts(context)),
      ])),
    );

    // ── 2) Ana başlık ──
    final Widget main = Container(
      color: cs.surface,
      height: 84,
      child: bounded(Row(children: [
        _Brand(onTap: () => NavigationHandler.goToApp(context)),
        const SizedBox(width: 32),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: TextField(
                controller: _search,
                onSubmitted: _submit,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Oyun, oyuncu, sahne ya da topluluk ara',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 22),
                  suffixIcon: IconButton(
                    tooltip: 'Ara',
                    onPressed: () => _submit(_search.text),
                    icon: Icon(Icons.search_rounded, color: cs.primary),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: cs.primary, width: 1.6),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _IconAction(
          icon: Icons.person_outline_rounded,
          label: loggedIn ? 'Hesabım' : 'Giriş yap',
          onTap: () => widget.onTab(3),
        ),
        _IconAction(
          icon: Icons.favorite_border_rounded,
          label: 'Favorilerim',
          onTap: () => loggedIn
              ? NavigationHandler.goToFavorites(context)
              : NavigationHandler.goToLogin(context),
        ),
        _IconAction(
          icon: Icons.confirmation_number_outlined,
          label: 'Biletlerim',
          badge: upcoming,
          onTap: () => loggedIn
              ? NavigationHandler.goToMyTickets(context, uid)
              : NavigationHandler.goToLogin(context),
        ),
      ])),
    );

    // ── 3) Gezinme satırı ──
    final Widget nav = Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
          bottom: BorderSide(color: cs.outlineVariant),
        ),
      ),
      height: 50,
      child: bounded(Row(children: [
        for (int i = 0; i < 3; i++)
          _NavLink(
            label: kShellDestinations[i].label,
            active: widget.currentIndex == i,
            onTap: () => widget.onTab(i),
          ),
        if (cats.isNotEmpty)
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: cs.outlineVariant,
          ),
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final BrowseCategory c in cats.take(wide ? 8 : 4))
                _NavLink(
                  label: c.label,
                  active: false,
                  onTap: () => NavigationHandler.goToDiscoverWithCategory(
                      context, c.label),
                ),
            ],
          ),
        ),
        _NavLink(
          label: 'Bu akşam',
          icon: Icons.nights_stay_outlined,
          accent: true,
          active: false,
          onTap: () => NavigationHandler.goToDiscover(context),
        ),
        _NavLink(
          label: 'Kampanyalar',
          icon: Icons.local_offer_rounded,
          accent: true,
          active: false,
          onTap: () => NavigationHandler.goToCampaigns(context),
        ),
      ])),
    );

    return Material(
      color: cs.surface,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        utility,
        main,
        nav,
      ]),
    );
  }
}

TextStyle _small(final BuildContext context, final Color color) =>
    TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w600);

/// Hover'da altı çizilen/renklenen metin düğmesi.
class _HoverText extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String label;
  const _HoverText(
      {required this.child, required this.onTap, required this.label});

  @override
  State<_HoverText> createState() => _HoverTextState();
}

class _HoverTextState extends State<_HoverText> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) => Semantics(
        button: true,
        label: widget.label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Opacity(opacity: _hover ? 0.7 : 1, child: widget.child),
          ),
        ),
      );
}

class _UtilLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _UtilLink(this.label, this.icon, this.onTap);

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 22),
      child: _HoverText(
        onTap: onTap,
        label: label,
        child: Row(children: [
          Icon(icon, size: 15, color: cs.primary),
          const SizedBox(width: 6),
          Text(label,
              style: _small(context, cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final VoidCallback onTap;
  const _Brand({required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return _HoverText(
      onTap: onTap,
      label: 'TiyatRol ana sayfa',
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/app_icon_master.png',
            width: 44,
            height: 44,
            cacheWidth: 132,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.theater_comedy_rounded, color: cs.primary, size: 36),
          ),
        ),
        const SizedBox(width: 12),
        Text('TİYATROL',
            style: GoogleFonts.playfairDisplay(
                color: cs.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 3)),
      ]),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;
  const _IconAction(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.badge = 0});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 22),
      child: _HoverText(
        onTap: onTap,
        label: label,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Badge(
            isLabelVisible: badge > 0,
            label: Text(badge > 9 ? '9+' : '$badge'),
            child: Icon(icon, size: 26, color: cs.onSurface),
          ),
          const SizedBox(height: 3),
          Text(label, style: _small(context, cs.onSurface)),
        ]),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final bool active;
  final bool accent;
  final IconData? icon;
  final VoidCallback onTap;
  const _NavLink({
    required this.label,
    required this.active,
    required this.onTap,
    this.accent = false,
    this.icon,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color c = widget.accent
        ? cs.primary
        : (widget.active || _hover ? cs.primary : cs.onSurface);
    return Semantics(
      button: true,
      selected: widget.active,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: widget.active || _hover
                      ? cs.primary
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: c),
                const SizedBox(width: 6),
              ],
              Text(widget.label,
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 13.5,
                      color: c,
                      fontWeight: widget.accent || widget.active
                          ? FontWeight.w800
                          : FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }
}
