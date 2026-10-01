import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/util/comminucation_actions.dart';
import '../../navigation/widgets/nav_handler.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';

/// Sayfaların ortak alt bilgisi — sayfanın "koçanı": üst kenarında delik
/// çizgisi (bilet dili), temanın bir ton koyu yüzeyinde. Renkler tamamen
/// temadan (eski sabit lacivert→kahve gradyanı kaldırıldı).
///
/// Bağlantıların hepsi gerçek: Sözleşmeler / Yardım & Destek rotaları ve
/// `TiyatrolCommunicationActions` (e-posta, WhatsApp, Instagram, Facebook
/// — https). InkWell'lerin hover/dalgalanması görünsün diye içerik bir
/// `Material` içinde.
class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    return Material(
      color: cs.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 2,
            child: CustomPaint(
                painter: _FooterPerforationPainter(cs.outlineVariant)),
          ),
          Padding(
            padding: context.responsive(
              mobile: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxxl,
                  AppSpacing.xl, AppSpacing.xxxl),
              tablet: const EdgeInsets.symmetric(
                  vertical: AppSpacing.huge, horizontal: AppSpacing.xxxl),
              desktop: const EdgeInsets.symmetric(
                  vertical: AppSpacing.section, horizontal: AppSpacing.section),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: context.isMobile
                    ? _buildMobileFooter(context)
                    : _buildDesktopFooter(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Ortak parçalar -------------------------------------------------

  Widget _brand(final BuildContext context) {
    final cs = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'TİYATROL',
          style: GoogleFonts.playfairDisplay(
            color: cs.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Türkiye\'de tiyatroyu keşfet, biletini al.',
          style: TextStyle(
              color: cs.onSurfaceVariant, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined,
                color: cs.onSurfaceVariant, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                'Ataşehir, İstanbul, Türkiye',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _heading(final BuildContext context, final String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Semantics(
          header: true,
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              color: context.colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
            ),
          ),
        ),
      );

  List<Widget> _corporateLinks(final BuildContext context) => [
        _heading(context, 'Kurumsal'),
        _linkRow(context, null, 'Sözleşmeler',
            () => NavigationHandler.goToContracts(context)),
        _linkRow(context, null, 'Yardım & Destek',
            () => NavigationHandler.goToHelpSupport(context)),
      ];

  List<Widget> _contactLinks(final BuildContext context) => [
        _heading(context, 'İletişim'),
        _linkRow(context, Icons.mail_outline_rounded, 'E-posta gönder',
            TiyatrolCommunicationActions.sendEmail),
        _linkRow(context, Icons.chat_bubble_outline_rounded, 'WhatsApp',
            TiyatrolCommunicationActions.contactWhatsApp),
      ];

  List<Widget> _socialLinks(final BuildContext context) => [
        _heading(context, 'Bizi takip edin'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _socialIcon(context, Icons.camera_alt_outlined, 'Instagram',
                TiyatrolCommunicationActions.openInstagram),
            _socialIcon(context, Icons.facebook, 'Facebook',
                TiyatrolCommunicationActions.openFacebook),
          ],
        ),
      ];

  Widget _copyright(final BuildContext context) => Text(
        '© ${DateTime.now().year} TiyatRol Sahne Sanatları. Tüm hakları saklıdır.',
        style: TextStyle(
            color: context.colors.onSurfaceVariant, fontSize: 12, height: 1.4),
      );

  // --- Yerleşimler ------------------------------------------------------

  /// Tablet/masaüstü: marka sütunu + üç bağlantı sütunu, altta telif satırı.
  Widget _buildDesktopFooter(final BuildContext context) {
    Widget column(final List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: _brand(context)),
            const SizedBox(width: AppSpacing.xxl),
            Expanded(flex: 3, child: column(_corporateLinks(context))),
            Expanded(flex: 3, child: column(_contactLinks(context))),
            Expanded(flex: 3, child: column(_socialLinks(context))),
          ],
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Divider(height: 1, color: context.colors.outlineVariant),
        const SizedBox(height: AppSpacing.lg),
        _copyright(context),
      ],
    );
  }

  /// Telefon: tek sütun, bölümler arasında ince çizgi.
  Widget _buildMobileFooter(final BuildContext context) {
    final Widget divider = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Divider(height: 1, color: context.colors.outlineVariant),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _brand(context),
        divider,
        ..._corporateLinks(context),
        divider,
        ..._contactLinks(context),
        divider,
        ..._socialLinks(context),
        divider,
        _copyright(context),
      ],
    );
  }

  /// 44dp yükseklikte metin bağlantısı: hover'da altı çizilir, klavye
  /// odağında temanın vurgusuyla zemin alır.
  Widget _linkRow(final BuildContext context, final IconData? icon,
          final String label, final VoidCallback onTap) =>
      _FooterLink(icon: icon, label: label, onTap: onTap);

  Widget _socialIcon(final BuildContext context, final IconData icon,
      final String label, final VoidCallback onTap) {
    final cs = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Material(
            type: MaterialType.transparency,
            shape: CircleBorder(side: BorderSide(color: cs.outlineVariant)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              focusColor: cs.primary.withOpacity(0.16),
              hoverColor: cs.onSurface.withOpacity(0.06),
              child: Icon(icon, color: cs.onSurface, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  const _FooterLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final Color fg = _hovered ? cs.onSurface : cs.onSurfaceVariant;
    return Semantics(
      link: true,
      label: widget.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (final v) => setState(() => _hovered = v),
        focusColor: cs.primary.withOpacity(0.16),
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: fg),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: fg,
                      decoration: _hovered
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: fg,
                    ),
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

/// Üst kenardaki delik çizgisi — sayfa bir bilet, footer onun koçanı.
class _FooterPerforationPainter extends CustomPainter {
  final Color color;
  const _FooterPerforationPainter(this.color);

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const double dash = 6, gap = 6;
    final double y = size.height / 2;
    for (double x = 0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant final _FooterPerforationPainter old) =>
      old.color != color;
}
