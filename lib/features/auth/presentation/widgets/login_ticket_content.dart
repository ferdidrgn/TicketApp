import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/google_logo.dart';
import 'auth_ticket.dart';

/// Giriş biletinin gövdesi. [wide] → geniş web'de yatay bilet düzeni
/// (başlık solda, giriş yöntemleri sağda); değilse dikey (mobil/tablet).
class LoginTicketBody extends StatelessWidget {
  final bool wide;
  final Animation<double> headlineReveal;
  final Animation<double> detailsFade;
  final VoidCallback? onPhone;
  final VoidCallback? onGoogle;
  final bool loading;

  const LoginTicketBody({
    super.key,
    required this.wide,
    required this.headlineReveal,
    required this.detailsFade,
    required this.onPhone,
    required this.onGoogle,
    required this.loading,
  });

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    final headline = Semantics(
      header: true,
      child: AuthWipeReveal(
        reveal: headlineReveal,
        child: Text(
          'Perde\nsenin için\nkalkıyor.',
          style: TicketInk.headline(wide ? 60 : 40),
        ),
      ),
    );

    final intro = Text(
      'Oyunları keşfet, koltuğunu seç — biletin cebinde, sahne bir adım '
      'ötende.',
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: TicketInk.inkSoft(0.72),
        fontSize: wide ? 16 : 14,
        height: 1.5,
      ),
    );

    final fields = Row(
      children: [
        Expanded(child: TicketField(label: 'TARİH', value: ticketDate(now))),
        Expanded(child: TicketField(label: 'SEANS', value: ticketTime(now))),
        const Expanded(child: TicketField(label: 'KOLTUK', value: 'Sen seç')),
      ],
    );

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TicketStampButton(
          label: l10n.loginPhoneButton,
          leading: const Icon(Icons.phone_iphone_rounded,
              size: 18, color: TicketInk.paper),
          onTap: onPhone,
          loading: loading,
          loadingLabel: 'BİLET KESİLİYOR…',
        ),
        const SizedBox(height: AppSpacing.sm),
        TicketStampButton(
          label: l10n.loginGoogleButton,
          leading: const GoogleLogo(size: 18),
          onTap: loading ? null : onGoogle,
          primary: false,
        ),
      ],
    );

    if (wide) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.section, AppSpacing.huge,
            AppSpacing.huge, AppSpacing.huge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const TicketHeaderStrip(kind: 'GİRİŞ BİLETİ · TEK KİŞİLİK'),
            const SizedBox(height: AppSpacing.huge),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      headline,
                      const SizedBox(height: AppSpacing.lg),
                      FadeTransition(opacity: detailsFade, child: intro),
                      const SizedBox(height: AppSpacing.xxxl),
                      FadeTransition(opacity: detailsFade, child: fields),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.section),
                Expanded(
                  flex: 5,
                  child: FadeTransition(
                    opacity: detailsFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('GİRİŞ YÖNTEMİ', style: TicketInk.label()),
                        const SizedBox(height: AppSpacing.md),
                        actions,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const TicketHeaderStrip(kind: 'GİRİŞ BİLETİ'),
          const SizedBox(height: AppSpacing.xxl),
          headline,
          const SizedBox(height: AppSpacing.md),
          FadeTransition(opacity: detailsFade, child: intro),
          const SizedBox(height: AppSpacing.xxl),
          FadeTransition(opacity: detailsFade, child: fields),
          const SizedBox(height: AppSpacing.xxl),
          FadeTransition(opacity: detailsFade, child: actions),
        ],
      ),
    );
  }
}

/// Giriş biletinin koçanı: tek kişilik bilgisi, sözleşme notu (biletin
/// "ince yazısı"), barkod ve bugünün tarihinden seri numarası.
class LoginTicketStub extends StatelessWidget {
  final bool wide;
  const LoginTicketStub({super.key, required this.wide});

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final serial = 'No. ${ticketDate(now).replaceAll('.', '')}';

    final terms = Text(
      l10n.loginTermsNotice,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: TicketInk.inkSoft(0.55),
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        height: 1.4,
      ),
    );
    final serialText = Text(
      serial,
      style: GoogleFonts.robotoMono(
        color: TicketInk.inkSoft(0.7),
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
    );

    if (wide) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TicketField(label: 'KOÇAN', value: 'TEK KİŞİLİK'),
            const SizedBox(height: AppSpacing.lg),
            const Expanded(
              child: Center(
                child: TicketBarcode(
                  seed: 'TIYATROL-GIRIS',
                  direction: Axis.vertical,
                  height: 56,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            serialText,
            const SizedBox(height: AppSpacing.sm),
            terms,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const TicketField(label: 'KOÇAN', value: 'TEK KİŞİLİK'),
                const SizedBox(height: AppSpacing.sm),
                terms,
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            width: 104,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TicketBarcode(seed: 'TIYATROL-GIRIS', height: 44),
                const SizedBox(height: AppSpacing.xs),
                serialText,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Biletin üstündeki küçük "GİŞE AÇIK" başlığı.
class BoxOfficeCaption extends StatelessWidget {
  final String text;
  const BoxOfficeCaption({super.key, this.text = 'GİŞE AÇIK'});

  @override
  Widget build(final BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_activity_outlined,
              size: 16, color: TicketInk.accent),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: TextStyle(
              color: TicketInk.paper.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
        ],
      );
}
