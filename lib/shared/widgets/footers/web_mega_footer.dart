import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/util/comminucation_actions.dart';
import '../../../features/discovery/presentation/widgets/browse_controls.dart';
import '../../../features/shows/domain/entities/show.dart';
import '../../../features/shows/presentation/providers/show_provider.dart';
import '../../navigation/widgets/nav_handler.dart';

/// WEB ALT BİLGİ — mağaza sitesi gibi geniş, çok sütunlu:
/// marka + kısa tanıtım + iletişim · Keşfet · Türler · Yardım · Kurumsal,
/// altında telif satırı. Tüm bağlantılar gerçek rotalara gider.
class WebMegaFooter extends ConsumerWidget {
  const WebMegaFooter({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.sizeOf(context).width;
    final bool wide = w >= 900;
    final double pad = w >= 1200 ? 48 : (w >= 768 ? 32 : 20);
    final List<Show> shows =
        ref.watch(activeShowsProvider(false)).value ?? const [];
    final List<BrowseCategory> cats = browseCategoriesOf(shows);

    Widget link(final String t, final VoidCallback tap) => _FooterLink(t, tap);
    Widget col(final String title, final List<Widget> links) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            ...links,
          ],
        );

    final Widget brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TİYATROL',
            style: GoogleFonts.playfairDisplay(
                color: cs.onSurface,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 3)),
        const SizedBox(height: 12),
        Text(
            'Türkiye\'de tiyatroyu keşfet: oyunları, sahneleri ve oyuncuları bul, seans seç, koltuğunu belirle, biletini al.',
            style: TextStyle(
                color: cs.onSurfaceVariant, fontSize: 14, height: 1.6)),
        const SizedBox(height: 18),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _Social(Icons.mail_outline_rounded, 'E-posta',
              () => TiyatrolCommunicationActions.sendEmail()),
          _Social(Icons.camera_alt_outlined, 'Instagram',
              () => TiyatrolCommunicationActions.openInstagram()),
          _Social(Icons.facebook_rounded, 'Facebook',
              () => TiyatrolCommunicationActions.openFacebook()),
        ]),
        const SizedBox(height: 14),
        Text('iletisim@tiyatrol.com',
            style: TextStyle(
                color: cs.onSurface, fontSize: 13.5, fontWeight: FontWeight.w700)),
      ],
    );

    final List<Widget> cols = [
      col('Keşfet', [
        link('Ana Sayfa', () => NavigationHandler.goToHome(context)),
        link('Tüm oyunlar', () => NavigationHandler.goToDiscover(context)),
        link('Yakındaki sahneler', () => NavigationHandler.goToNearby(context)),
        link('Kampanyalar', () => NavigationHandler.goToCampaigns(context)),
        link('Arama', () => NavigationHandler.goToSearch(context)),
      ]),
      col('Türler', [
        for (final BrowseCategory c in cats.take(6))
          link(c.label,
              () => NavigationHandler.goToDiscoverWithCategory(context, c.label)),
        if (cats.isEmpty)
          link('Tüm türler', () => NavigationHandler.goToDiscover(context)),
      ]),
      col('Yardım', [
        link('Yardım ve destek', () => NavigationHandler.goToHelpSupport(context)),
        link('Bize yazın', () => TiyatrolCommunicationActions.sendEmail()),
        link('Biletlerim', () => NavigationHandler.goToProfile(context)),
        link('Favorilerim', () => NavigationHandler.goToFavorites(context)),
      ]),
      col('Kurumsal', [
        link('Gizlilik politikası', () => NavigationHandler.goToContracts(context)),
        link('Kullanım şartları', () => NavigationHandler.goToContracts(context)),
        link('Ayarlar', () => NavigationHandler.goToSettings(context)),
      ]),
    ];

    return Material(
      color: cs.surfaceContainerLow,
      child: Column(
        children: [
          Container(height: 3, color: cs.primary),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 56, pad, 28),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: brand),
                          const SizedBox(width: 48),
                          for (final Widget c in cols) Expanded(flex: 2, child: c),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          brand,
                          const SizedBox(height: 32),
                          Wrap(spacing: 40, runSpacing: 28, children: [
                            for (final Widget c in cols)
                              SizedBox(width: 150, child: c),
                          ]),
                        ],
                      ),
              ),
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: 20),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 6,
                  children: [
                    Text('© ${DateTime.now().year} TiyatRol. Tüm hakları saklıdır.',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13)),
                    Text('Tiyatroyu herkes için keşfedilebilir kılmak için.',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _FooterLink(this.text, this.onTap);

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text(widget.text,
              style: TextStyle(
                  color: _hover ? cs.primary : cs.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration:
                      _hover ? TextDecoration.underline : TextDecoration.none)),
        ),
      ),
    );
  }
}

class _Social extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Social(this.icon, this.label, this.onTap);

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: IconButton.outlined(
        tooltip: label,
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: cs.onSurface),
      ),
    );
  }
}
