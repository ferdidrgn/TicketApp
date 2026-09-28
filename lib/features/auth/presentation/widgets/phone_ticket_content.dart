import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import 'auth_ticket.dart';

/// Telefonla giriş biletinin gövdesi — iki adım:
///  1) "Bilet kimin adına kesilsin?" → telefon numarası
///  2) "Kapıdaki kodu söyle." → SMS kodu, sahneye bakan koltuk sırası olarak
class PhoneTicketBody extends StatelessWidget {
  final bool wide;
  final bool isCodeSent;
  final Animation<double> headlineReveal;
  final Animation<double> detailsFade;
  final Animation<double> stamp;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final VoidCallback onSendCode;
  final ValueChanged<String?> onVerify;
  final VoidCallback onEditNumber;
  final VoidCallback? onResend;
  final String timerText;
  final bool loading;

  const PhoneTicketBody({
    super.key,
    required this.wide,
    required this.isCodeSent,
    required this.headlineReveal,
    required this.detailsFade,
    required this.stamp,
    required this.phoneController,
    required this.otpController,
    required this.onSendCode,
    required this.onVerify,
    required this.onEditNumber,
    required this.onResend,
    required this.timerText,
    required this.loading,
  });

  @override
  Widget build(final BuildContext context) {
    final headline = Semantics(
      header: true,
      child: AuthWipeReveal(
        reveal: headlineReveal,
        child: Text(
          isCodeSent ? 'Kapıdaki\nkodu söyle.' : 'Bilet kimin\nadına kesilsin?',
          style: TicketInk.headline(wide ? 54 : 36),
        ),
      ),
    );

    final intro = Text(
      isCodeSent
          ? '+90 ${formatTrPhone(phoneController.text)} numarasına gelen 6 '
              'haneli kodu koltuklara yerleştir.'
          : 'Kodu SMS ile göndereceğiz. Biletlerin ve koltukların bu numaraya '
              'bağlı olacak.',
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: TicketInk.inkSoft(0.72),
        fontSize: wide ? 15.5 : 14,
        height: 1.5,
      ),
    );

    final form = AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: (final child, final animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: child,
        ),
      ),
      child: isCodeSent ? _codeStep() : _phoneStep(),
    );

    final Widget titleBlock = Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            headline,
            const SizedBox(height: AppSpacing.md),
            FadeTransition(opacity: detailsFade, child: intro),
          ],
        ),
        // Kod gönderildiğinde bilete "güm" diye basılan mürekkep damgası.
        Positioned(
          top: -AppSpacing.sm,
          right: 0,
          child: TicketInkStamp(text: 'KOD GÖNDERİLDİ', appear: stamp),
        ),
      ],
    );

    final String kind =
        isCodeSent ? 'ADIM 2/2 · KAPI KONTROLÜ' : 'ADIM 1/2 · BİLET SAHİBİ';

    if (wide) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.section, AppSpacing.huge,
            AppSpacing.huge, AppSpacing.huge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TicketHeaderStrip(kind: kind),
            const SizedBox(height: AppSpacing.huge),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: titleBlock),
                const SizedBox(width: AppSpacing.section),
                Expanded(
                  flex: 6,
                  child: FadeTransition(opacity: detailsFade, child: form),
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
          TicketHeaderStrip(kind: kind),
          const SizedBox(height: AppSpacing.xxl),
          titleBlock,
          const SizedBox(height: AppSpacing.xxl),
          FadeTransition(opacity: detailsFade, child: form),
        ],
      ),
    );
  }

  Widget _phoneStep() => Column(
        key: const ValueKey('phone-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TicketPhoneField(
            controller: phoneController,
            autofocus: wide,
            onSubmitted: (final _) => onSendCode(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TicketStampButton(
            label: 'KOD GÖNDER',
            leading: const Icon(Icons.sms_outlined,
                size: 18, color: TicketInk.paper),
            onTap: onSendCode,
            loading: loading,
            loadingLabel: 'GÖNDERİLİYOR…',
          ),
        ],
      );

  Widget _codeStep() => Column(
        key: const ValueKey('code-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (final context, final constraints) {
              // 6 koltuk + her birinin 6px payı + ortadaki koridor boşluğu
              // mevcut genişliğe sığmalı (küçük telefonlarda taşmasın).
              final double seat = math.min(
                  wide ? 52.0 : 48.0,
                  (constraints.maxWidth - AppSpacing.md) / 6 - 6);
              return Center(
                child: SeatRowCodeInput(
                  controller: otpController,
                  seatWidth: seat,
                  onCompleted: onVerify,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.xs,
            children: [
              TicketTextLink(label: 'Numarayı düzenle', onTap: onEditNumber),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'Kodun geçerlilik süresi $timerText',
                    child: Text(
                      timerText,
                      style: GoogleFonts.robotoMono(
                        color: onResend != null
                            ? TicketInk.inkSoft(0.4)
                            : TicketInk.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TicketTextLink(
                    label: 'Yeniden gönder',
                    onTap: onResend,
                    emphasize: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TicketStampButton(
            label: 'DOĞRULA VE İÇERİ GİR',
            leading: const Icon(Icons.login_rounded,
                size: 18, color: TicketInk.paper),
            onTap: () => onVerify(null),
            loading: loading,
            loadingLabel: 'KAPI AÇILIYOR…',
          ),
        ],
      );
}

/// Telefonla giriş biletinin koçanı: numara yazıldıkça "SAHİBİ" alanına
/// basılır, barkod da o numaradan üretilir — bilet gerçekten o kişi için
/// basılıyormuş gibi.
class PhoneTicketStub extends StatelessWidget {
  final bool wide;
  final bool isCodeSent;
  final TextEditingController phoneController;

  const PhoneTicketStub({
    super.key,
    required this.wide,
    required this.isCodeSent,
    required this.phoneController,
  });

  @override
  Widget build(final BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: phoneController,
        builder: (final context, final value, final _) {
          final String digits = value.text;
          final String owner =
              digits.isEmpty ? '—' : '+90 ${formatTrPhone(digits)}';
          final Widget ownerField =
              TicketField(label: 'SAHİBİ', value: owner);
          final Widget statusField = TicketField(
            label: 'DURUM',
            value: isCodeSent ? 'KOD YOLDA' : 'BASILIYOR',
          );
          final String seed = 'TIYATROL-$digits';

          if (wide) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ownerField,
                  const SizedBox(height: AppSpacing.lg),
                  statusField,
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: Center(
                      child: TicketBarcode(
                        seed: seed,
                        direction: Axis.vertical,
                        height: 56,
                      ),
                    ),
                  ),
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
                      ownerField,
                      const SizedBox(height: AppSpacing.sm),
                      statusField,
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(
                  width: 104,
                  child: TicketBarcode(seed: seed, height: 44),
                ),
              ],
            ),
          );
        },
      );
}

/// Sayaç metni: saniyeyi "d:ss" biçimine çevirir (60 → 1:00).
String otpTimerText(final int seconds) {
  final int s = seconds < 0 ? 0 : seconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}
