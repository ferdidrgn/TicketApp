import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';

export '../../../../shared/widgets/ticket/ticket_kit.dart';

/// Girişe özel bilet parçaları: telefon numarası alanı ve SMS kodunun
/// koltuk sırası olarak girildiği alan. Genel bilet parçaları
/// `lib/shared/widgets/ticket/ticket_kit.dart` içinde.

// ─────────────────────────────────────────────────────────────────────────
// Telefon alanı ve koltuk sırası şeklinde SMS kodu
// ─────────────────────────────────────────────────────────────────────────

/// "+90 5XX XXX XX XX" — 10 haneyi okunur gruplar hâlinde yazar.
String formatTrPhone(final String digits) {
  final d = digits.replaceAll(RegExp(r'\D'), '');
  final groups = <String>[];
  const cuts = [3, 3, 2, 2];
  int i = 0;
  for (final c in cuts) {
    if (i >= d.length) break;
    groups.add(d.substring(i, math.min(i + c, d.length)));
    i += c;
  }
  return groups.join(' ');
}

/// Biletin "sahibi" satırı — basılı form çizgisi gibi telefon girişi.
class TicketPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  const TicketPhoneField({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BİLET SAHİBİNİN TELEFONU', style: TicketInk.label()),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            label: 'Telefon numarası, başında sıfır olmadan 10 hane',
            textField: true,
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              cursorColor: TicketInk.accentOf(context),
              onSubmitted: onSubmitted,
              inputFormatters: [_DigitsOnlyNoLeadingZero()],
              style: GoogleFonts.robotoMono(
                color: TicketInk.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Text(
                    '+90',
                    style: GoogleFonts.robotoMono(
                      color: TicketInk.inkSoft(0.55),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '5XXXXXXXXX',
                hintStyle: GoogleFonts.robotoMono(
                  color: TicketInk.inkSoft(0.25),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
                counterText: '',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                enabledBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: TicketInk.inkSoft(0.45), width: 1.4),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: TicketInk.accentOf(context), width: 2),
                ),
              ),
            ),
          ),
        ],
      );
}

/// Sadece rakam; baştaki 0'ı yutar (kullanıcı alışkanlıkla "05..." yazarsa).
class _DigitsOnlyNoLeadingZero extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      final TextEditingValue oldValue, final TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('90') && digits.length > 10) {
      digits = digits.substring(2);
    }
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) digits = digits.substring(0, 10);
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

/// SMS kodu: sahneye bakan 6 koltukluk bir sıra. Her rakam bir koltuğu
/// doldurur (dolu koltuk = kırmızı). Üstte kavisli "SAHNE" çizgisi.
class SeatRowCodeInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final double seatWidth;

  const SeatRowCodeInput({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.seatWidth = 42,
  });

  PinTheme _seat({
    required final Color fill,
    required final Color border,
    required final Color digit,
    final double borderWidth = 1.4,
  }) =>
      PinTheme(
        width: seatWidth,
        height: seatWidth * 1.2,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        textStyle: GoogleFonts.robotoMono(
          color: digit,
          fontSize: seatWidth * 0.5,
          fontWeight: FontWeight.w800,
        ),
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: border, width: borderWidth),
          // Koltuk sırtı: üst köşeler yuvarlak, alt köşeler (oturak) düz.
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(seatWidth * 0.36),
            topRight: Radius.circular(seatWidth * 0.36),
            bottomLeft: const Radius.circular(4),
            bottomRight: const Radius.circular(4),
          ),
        ),
      );

  @override
  Widget build(final BuildContext context) {
    final Color accent = TicketInk.accentOf(context);
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: (seatWidth + 6) * 6,
            height: 26,
            child: CustomPaint(
              painter: _StageArcPainter(),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text('SAHNE', style: TicketInk.label()),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: 'Doğrulama kodu, 6 hane',
            textField: true,
            child: Pinput(
              length: 6,
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              separatorBuilder: (final index) =>
                  // Sıranın ortasında koridor boşluğu.
                  SizedBox(width: index == 2 ? AppSpacing.md : 0),
              defaultPinTheme: _seat(
                fill: TicketInk.paperShade,
                border: TicketInk.inkSoft(0.35),
                digit: TicketInk.ink,
              ),
              focusedPinTheme: _seat(
                fill: TicketInk.paper,
                border: accent,
                digit: TicketInk.ink,
                borderWidth: 2.2,
              ),
              submittedPinTheme: _seat(
                fill: accent,
                border: TicketInk.accentDeepOf(context),
                digit: TicketInk.onAccentOf(context),
              ),
              errorPinTheme: _seat(
                fill: TicketInk.paperShade,
                border: WebColors.error,
                digit: WebColors.error,
                borderWidth: 2,
              ),
              onCompleted: onCompleted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('SIRA K  ·  KOLTUK 1 — 6', style: TicketInk.label()),
            ],
          ),
        ],
      );
  }
}

class _StageArcPainter extends CustomPainter {
  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..color = TicketInk.inkSoft(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width / 2, size.height * 0.35, size.width,
          size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => false;
}

