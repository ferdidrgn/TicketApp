import 'dart:ui';
import 'package:flutter/material.dart';

/// Saydamlaşarak geçiş (Fade)
Widget fadeTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) =>
    FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child);

/// Sağdan sola kayarak geçiş (Slide)
Widget slideTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) =>
    SlideTransition(
      position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    );

/// Büyüyerek gelme (Scale)
Widget scaleTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) =>
    ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: FadeTransition(opacity: animation, child: child));

/// 🎭 **Gelişmiş Perde Açılış Geçişi**
/// Yavaşlatıldığında gerçek bir sahne başlangıcı hissi verir.
Widget curtainTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) {
  // Animasyonun hızını daha dramatik hale getiren eğri
  final dramaticCurve = CurvedAnimation(
    parent: animation,
    curve: Curves.easeInOutQuart, // Başta ve sonda yavaş, ortada akıcı
  );

  return AnimatedBuilder(
    animation: dramaticCurve,
    builder: (final context, final child) => ClipRect(
      child: Align(
        alignment: Alignment.center,
        widthFactor: dramaticCurve.value,
        child: FadeTransition(
          opacity: dramaticCurve,
          child: child,
        ),
      ),
    ),
    child: child,
  );
}

/// 👁️ **Derin Odaklanma (Slow Focal Blur)**
/// Yavaş gelmediğinde sadece bir "titreme" gibi görünür.
/// 800ms ile rüya gibi bir netleşme sağlar.
Widget focalTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) {
  final slowCurve =
      CurvedAnimation(parent: animation, curve: Curves.easeOutQuart);

  return AnimatedBuilder(
    animation: slowCurve,
    builder: (final context, final child) {
      // Sigma değerini 15'e çıkararak bulanıklığı artırdık
      final blurValue = (1 - slowCurve.value) * 15;
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
        child: Transform.scale(
          scale: 0.8 + (slowCurve.value * 0.2), // Daha geniş bir zoom aralığı
          child: FadeTransition(
            opacity: slowCurve,
            child: child,
          ),
        ),
      );
    },
    child: child,
  );
}

/// 🎞️ **Gelişmiş Sinematik Kararma**
/// Sahne geçişlerindeki o karanlık boşluğu hissetmek için idealdir.
Widget cinematicFadeTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) =>
    Stack(
      children: [
        child,
        IgnorePointer(
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(
                parent: animation,
                // İlk %60'lık kısımda karanlık kalmasını sağlar
                curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
              ),
            ),
            child: Container(color: Colors.black),
          ),
        ),
      ],
    );

/// 🌀 **Mistik Sarmal Geçiş (Spiral Ink)**
/// Sayfa hafif bir açıyla dönerken aynı zamanda büyüyerek yerine oturur.
/// Sanki bir tuval üzerine mürekkep damlaması veya sayfanın havada süzülerek gelmesi gibi bir ağırlık kazandırır.
Widget spiralTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) =>
    RotationTransition(
      // Hafif bir rotasyon (yaklaşık 18 derece)
      turns: Tween<double>(begin: -0.05, end: 0.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );

/// ✨ **Işık Süzmesi Geçişi (Flash Shimmer)**
/// Sayfa aşağıdan yukarı hafifçe kayarken üzerinden beyaz bir ışık huzmesi geçer.
/// Özellikle karanlık temalı (Dark Mode) tasarımlarda "gizemli bir parlayış" etkisi yaratır.
Widget shimmerSlideTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) =>
    Stack(
      children: [
        SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero)
                  .animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: animation, child: child),
        ),
        // Üzerinden geçen ışık huzmesi (ignore pointer ile tıklamaya engel olmaz)
        IgnorePointer(
          child: FadeTransition(
            opacity: TweenSequence([
              TweenSequenceItem(
                  tween: Tween<double>(begin: 0.0, end: 0.4), weight: 50),
              TweenSequenceItem(
                  tween: Tween<double>(begin: 0.4, end: 0.0), weight: 50),
            ]).animate(animation),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

/// 🚪 **Gölge Kapı Geçişi (Shadow Gate)**
/// Sayfa arkadan öne doğru gelirken ekranın kenarlarında karanlık bir gölge oluşur.
/// Sahneye giriş yaparken bir kapıdan geçiyormuşçasına derinlik ve gizem katar.
Widget shadowGateTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) =>
    Stack(
      children: [
        FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.1, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        IgnorePointer(
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(animation),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

/// 📜 **Parşömen Kayması (Scroll Slide)**
/// Sayfa hafif bir kavisli hareketle aşağıdan yukarı süzülür.
/// El yazması bir metni veya tiyatro programını okumaya başlamak gibi zarif bir etki yaratır.
Widget scrollSlideTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) =>
    SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
