import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/google_logo.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
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
          leading: const Icon(Icons.phone_iphone_rounded),
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
            const SizedBox(height: AppSpacing.xxl),
            const TicketPosterBanner(height: 200),
            const SizedBox(height: AppSpacing.xxl),
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
          const SizedBox(height: AppSpacing.xl),
          const TicketPosterBanner(height: 164),
          const SizedBox(height: AppSpacing.xl),
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
          Icon(Icons.local_activity_outlined,
              size: 16, color: TicketInk.stageAccentOf(context)),
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

/// Biletin üstüne basılı "BU SEZON SAHNEDE" görseli: uygulamanın kendi
/// GERÇEK, şu an sahnede olan oyunlarının afişleri, birkaç saniyede bir
/// yumuşakça değişir. Afişler Firebase'den geldiği için web dahil her
/// platformda yüklenir (dış stok fotoğraf / kırık link yok). Veri yoksa
/// bant hiç çizilmez.
class TicketPosterBanner extends ConsumerStatefulWidget {
  final double height;
  const TicketPosterBanner({super.key, required this.height});

  @override
  ConsumerState<TicketPosterBanner> createState() => _TicketPosterBannerState();
}

class _TicketPosterBannerState extends ConsumerState<TicketPosterBanner> {
  // Afiş değiştirme aralığı (animasyon süresi değil, bekleme süresi).
  static const Duration _interval = Duration(seconds: 4);

  Timer? _timer;
  int _index = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ensureRotation(final int count) {
    if (_timer != null || count < 2) return;
    if (MediaQuery.of(context).disableAnimations) return;
    _timer = Timer.periodic(_interval, (final _) {
      if (mounted) setState(() => _index++);
    });
  }

  @override
  Widget build(final BuildContext context) {
    final List<Show> shows =
        (ref.watch(activeShowsProvider(true)).value ?? const <Show>[])
            .where((final s) => s.imageUrl.trim().isNotEmpty)
            .take(6)
            .toList();

    return AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: shows.isEmpty ? const SizedBox(width: double.infinity) : _banner(shows),
    );
  }

  /// Afişler dikey (2:3); yatay bir banda sığdırmak onları ortadan
  /// kırpıp basıklaştırıyordu. Artık afiş kendi oranında, tam olarak solda
  /// duruyor; oyun adı bilet kağıdına basılı gibi sağda. Bant [height]
  /// kadar yer kaplar (afişin yüksekliği).
  Widget _banner(final List<Show> shows) {
    _ensureRotation(shows.length);
    final int i = _index % shows.length;
    final Show show = shows[i];
    final String kind = show.category.trim();

    return Semantics(
      label: 'Bu sezon sahnede: ${show.name}',
      image: true,
      child: SizedBox(
        height: widget.height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  boxShadow: AppShadows.level2(TicketInk.ink),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: ColoredBox(
                    color: TicketInk.inkSoft(0.08),
                    child: AnimatedSwitcher(
                      duration: AppMotion.slow,
                      switchInCurve: AppMotion.standard,
                      switchOutCurve: AppMotion.standard,
                      layoutBuilder: (final current, final previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, if (current != null) current],
                      ),
                      child: OptimizedCachedImage(
                        key: ValueKey(show.id),
                        imageUrl: show.imageUrl,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BU SEZON SAHNEDE', style: TicketInk.label()),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppMotion.normal,
                      // Eski ad hemen çekilir; iki ad üst üste binmez.
                      switchOutCurve: const Threshold(0),
                      layoutBuilder: (final current, final previous) => Stack(
                        alignment: Alignment.topLeft,
                        children: [...previous, if (current != null) current],
                      ),
                      child: Column(
                        key: ValueKey(show.id),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            show.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              color: TicketInk.ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          if (kind.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              kind.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TicketInk.label(
                                  color: TicketInk.accentOf(context)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (shows.length > 1)
                    ExcludeSemantics(
                      child: Row(
                        children: [
                          for (int k = 0; k < shows.length; k++) ...[
                            if (k > 0) const SizedBox(width: AppSpacing.xs + 2),
                            AnimatedContainer(
                              duration: AppMotion.fast,
                              width: k == i ? 14 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: k == i
                                    ? TicketInk.accentOf(context)
                                    : TicketInk.inkSoft(0.22),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
