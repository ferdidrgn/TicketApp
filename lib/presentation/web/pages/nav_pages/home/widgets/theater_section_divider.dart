import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';

enum DividerStyle { simpleGradient, iconCenter, spotlight }

class TheaterSectionDivider extends StatelessWidget {
  final DividerStyle style;
  final double height;

  const TheaterSectionDivider({
    super.key,
    this.style = DividerStyle.spotlight,
    this.height = 120,
  });

  @override
  Widget build(final BuildContext context) {
    // Tüm stiller için ortak zemin rengi
    const backgroundColor = WebColors.darkBlueBackground;

    switch (style) {
      // ════════════════════════════════════════════════════════════
      // STİL 1: BASİT GRADYAN (ZEMİN RENGİ DÜZELTİLDİ)
      // ════════════════════════════════════════════════════════════
      case DividerStyle.simpleGradient:
        return Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.center,
          color: backgroundColor,
          // ✅ Zemin Rengi Eklendi
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Arkadaki geniş bulanık parıltı
              Container(
                height: 4,
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: WebColors.primaryGold.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Öndeki keskin çizgi
              Container(
                height: 2,
                width: MediaQuery.of(context).size.width * 0.6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent, // Zemine (Maviye) karışır
                      WebColors.primaryGold,
                      Colors.transparent, // Zemine (Maviye) karışır
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ],
          ),
        );

      // ════════════════════════════════════════════════════════════
      // STİL 2: İKONLU MERKEZ (ZEMİN RENGİ DÜZELTİLDİ)
      // ════════════════════════════════════════════════════════════
      case DividerStyle.iconCenter:
        return Container(
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          color: backgroundColor,
          // ✅ Zemin Rengi Eklendi
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sol Çizgi
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent, // Maviye karışır
                        WebColors.primaryGold.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: WebColors.primaryGold.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
              // Orta İkon ve Çemberi
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundColor, // İkonun arkası da mavi olsun
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: WebColors.primaryGold.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: WebColors.primaryGold.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.theater_comedy,
                  color: WebColors.primaryGold,
                  size: 28,
                ),
              ),
              // Sağ Çizgi
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        WebColors.primaryGold.withOpacity(0.8),
                        Colors.transparent, // Maviye karışır
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: WebColors.primaryGold.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      // ════════════════════════════════════════════════════════════
      // STİL 3: SPOTLIGHT (ZEMİN RENGİ VE GEÇİŞLER DÜZELTİLDİ)
      // ════════════════════════════════════════════════════════════
      // ════════════════════════════════════════════════════════════
      // ════════════════════════════════════════════════════════════
      // STİL 3: SPOTLIGHT (GENİŞ EKRAN SİYAH KENAR SORUNU ÇÖZÜLDÜ)
      case DividerStyle.spotlight:
        return Container(
          height: height,
          width: double.infinity,
          color: WebColors.darkBlueBackground, // Arkaplan rengi
          child: Stack(
            children: [
              // MERKEZDE IŞIK EFEKTİ
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width *
                      2, // EKRANIN 2 KATI GENİŞLİKTE
                  height: height,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.5),
                      radius: 1.0,
                      colors: [
                        WebColors.primaryGold.withOpacity(0.25),
                        WebColors.darkBlueBackground.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.8],
                    ),
                  ),
                ),
              ),

              // IŞIK KAYNAĞI ÇİZGİSİ
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 120,
                  height: 3,
                  decoration: BoxDecoration(
                    color: WebColors.primaryGold,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: WebColors.primaryGold,
                        blurRadius: 25,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
