import 'package:flutter/material.dart';

/// 🩸 "Crimson Noir" — web tanıtım (landing) sayfasına ÖZEL renk paleti.
/// Kullanıcının paylaştığı referans (House Targaryen / TheMuBa tarzı,
/// #02060E ile #C50337 gradyanı) doğrultusunda seçildi. SADECE bu sayfa ve
/// alt bölümlerinde kullanılır — uygulamanın geri kalanındaki Indigo/Bento
/// tasarım sistemine (`WebColors`/`BentoColors`) dokunmuyor.
abstract final class LandingPalette {
  static const Color bg = Color(0xFF02060E);
  static const Color bgAlt = Color(0xFF0B0410);
  static const Color surface = Color(0xFF140812);
  static const Color surfaceAlt = Color(0xFF1D0B18);

  static const Color crimson = Color(0xFFC50337);
  static const Color crimsonLight = Color(0xFFE8134F);
  static const Color crimsonDark = Color(0xFF7A0224);

  static const Color live = Color(0xFF2DD4A7);

  static const Color microBorder = Color(0x1FFFFFFF);
  static const Color microBorderStrong = Color(0x33FFFFFF);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bg, Color(0xFF1A0210), bg],
  );

  static const LinearGradient crimsonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [crimsonLight, crimson, crimsonDark],
  );

  static const RadialGradient emberGlow = RadialGradient(
    center: Alignment(0, -0.4),
    radius: 1.2,
    colors: [Color(0x33C50337), Color(0x00C50337)],
  );
}

/// Referans sitelerdeki gibi tam genişlikte, alternatif renkli "band"lara
/// bölünmüş bölüm yapısı — her bölümün kendi zemin rengi/gradyanı, üst
/// çentik etiketi (eyebrow) ve başlığı var. Sayfayı gerçek "section section"
/// hisseden bloklara ayırır.
class LandingSectionBand extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget child;
  final double hPad;
  final bool alt;
  final bool ember;

  const LandingSectionBand({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    required this.child,
    required this.hPad,
    this.alt = false,
    this.ember = false,
  });

  @override
  Widget build(final BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: alt ? LandingPalette.bgAlt : LandingPalette.bg,
          gradient: ember ? LandingPalette.emberGlow : null,
          border: const Border(
            top: BorderSide(color: LandingPalette.microBorder),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 3,
                    color: LandingPalette.crimson,
                  ),
                  const SizedBox(width: 12),
                  Text(eyebrow,
                      style: const TextStyle(
                          color: LandingPalette.crimsonLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3)),
                ],
              ),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6)),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle!,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55), fontSize: 14)),
              ],
              const SizedBox(height: 32),
              child,
            ],
          ),
        ),
      );
}

/// Veri henüz yokken bölümü tamamen gizlemek yerine gösterilen, küratörü
/// yönlendiren zarif "yakında" kartı — Sponsors bölümündeki "boşsa da
/// dursun" kararıyla aynı ilke: ziyaretçi bölümün var olduğunu görsün.
class LandingComingSoonCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const LandingComingSoonCard(
      {super.key, required this.icon, required this.message});

  @override
  Widget build(final BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: LandingPalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: LandingPalette.microBorder, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(icon, color: LandingPalette.crimsonLight.withOpacity(0.6), size: 30),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    height: 1.5)),
          ],
        ),
      );
}
