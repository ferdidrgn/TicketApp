import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Web karşılığı: mobildeki `TicketStubCard` ("GÜNÜN FIRSATI / Romeo &
/// Juliet / %20 İndirim Fırsatı").
///
/// UYARI (ileride çözülmesi gereken, burada YENİ eklenmeyen bir eksik):
/// mobildeki kaynağında bu kart zaten sabit/statik içerik taşıyor — sahte
/// bir stok görsel URL'i ve elle yazılmış "Romeo & Juliet %20 İndirim"
/// metni, `onTap` bile verilmemiş (tıklanamaz). Firestore'dan gelen gerçek
/// bir kampanya değil. Burada AYNI mevcut içerik birebir taşındı (yeni bir
/// şey uydurulmadı, sadece iki platformda tutarlı olsun diye kopyalandı) —
/// ama gerçek bir kampanyaya bağlanması gereken kalıcı bir borç.
class HomePromoBanner extends StatelessWidget {
  const HomePromoBanner({super.key});

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(6),
    topRight: Radius.circular(32),
    bottomLeft: Radius.circular(32),
    bottomRight: Radius.circular(6),
  );

  @override
  Widget build(final BuildContext context) => Container(
        height: 132,
        decoration: BoxDecoration(
          borderRadius: _radius,
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: _radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://img.freepik.com/premium-vector/theatre2_1189973-28.jpg?semt=ais_hybrid&w=740&q=80',
                fit: BoxFit.cover,
                errorBuilder: (final context, final error, final stack) =>
                    const ColoredBox(color: WebColors.darkBlueSurface),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      WebColors.veryDarkBlue.withOpacity(0.92),
                      WebColors.veryDarkBlue.withOpacity(0.55),
                    ],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'GÜNÜN FIRSATI',
                      style: TextStyle(
                        color: WebColors.primaryGoldLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Romeo & Juliet',
                      style: TextStyle(
                        color: WebColors.whiteText,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '%20 İndirim Fırsatı',
                      style: TextStyle(
                        color: WebColors.textSecondary,
                        fontSize: 13,
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
