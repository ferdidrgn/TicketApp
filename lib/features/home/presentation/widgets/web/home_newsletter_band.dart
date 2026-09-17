import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// "Özel Fırsatlar" — mobildeki `NewsletterSubscribe`'ın web karşılığı.
///
/// Mobil tarafta da bu form dekoratif — "Abone Ol" butonunun `onTap`'ı yok,
/// hiçbir yere veri göndermiyor. Aynı durum burada da korundu (yeni bir
/// sahte entegrasyon eklenmedi); ileride gerçek bir e-posta listesine
/// bağlanması gereken bilinen bir eksik.
class HomeNewsletterBand extends StatelessWidget {
  const HomeNewsletterBand({super.key});

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(4),
    topRight: Radius.circular(28),
    bottomLeft: Radius.circular(28),
    bottomRight: Radius.circular(4),
  );

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              WebColors.primaryGold.withOpacity(0.10),
              WebColors.darkBlueSurface,
            ],
          ),
          borderRadius: _radius,
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.25)),
        ),
        child: LayoutBuilder(
          builder: (final context, final constraints) {
            final bool wide = constraints.maxWidth >= 640;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Özel Fırsatlar',
                  style: TextStyle(
                    color: WebColors.whiteText,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Haftalık etkinlik önerileri al',
                  style: TextStyle(
                    color: WebColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ],
            );

            final field = Container(
              height: 48,
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: WebColors.veryDarkBlue.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(4),
                ),
                border:
                    Border.all(color: WebColors.darkBlueAccent, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'E-posta adresin…',
                      style: TextStyle(
                        color: WebColors.textTertiary.withOpacity(0.8),
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  const Icon(Icons.mail_outline,
                      size: 16, color: WebColors.textTertiary),
                ],
              ),
            );

            if (!wide)
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  copy,
                  const SizedBox(height: 18),
                  field,
                ],
              );

            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 24),
                field,
              ],
            );
          },
        ),
      );
}
