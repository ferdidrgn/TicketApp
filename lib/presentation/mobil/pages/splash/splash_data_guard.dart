import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/presentation/mobil/pages/splash/splash_page.dart';

/// Bu widget, verilen provider'ların yüklenme durumunu kontrol eder.
/// Veriler yüklenirken Splash ekranını gösterir, yüklendiğinde içeriğe yumuşak geçiş yapar.
///
/// Kullanım:
/// DataSplashGuard(
///   providersToWatch: [homeAssetsProvider, userProfileProvider],
///   child: HomePage(),
/// )
class SplashDataGuard extends ConsumerStatefulWidget {
  final Widget child;

  /// İzlenecek provider'ların listesi veya mantıksal kontrol fonksiyonu
  /// Basitlik adına burada direkt yüklenme durumunu boolean olarak alabiliriz
  /// ya da child içinde izlenen provider'ları burada da izleyebiliriz.
  final bool isLoading;

  /// Splash ekranında görünecek mesaj
  final String? loadingMessage;

  const SplashDataGuard({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
  });

  @override
  ConsumerState<SplashDataGuard> createState() => _DataSplashGuardState();
}

class _DataSplashGuardState extends ConsumerState<SplashDataGuard> {
  // Animasyonlu geçiş için
  bool _showContent = false;

  @override
  void didUpdateWidget(covariant final SplashDataGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Eğer yüklenme bittiyse içeriği göster
    if (oldWidget.isLoading && !widget.isLoading) {
      // Küçük bir gecikme ekleyerek "yanıp sönme" efektini engelle
      // ve transition'ın pürüzsüz olmasını sağla
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showContent = true);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Başlangıçta eğer loading değilse direkt içeriği göster
    if (!widget.isLoading) {
      _showContent = true;
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Stack(
      children: [
        // 1. Gerçek Sayfa (Altta durur, hazır olunca görünür olur)
        // Offstage yerine Opacity veya Visibility kullanıyoruz ki tree'de olsun ama görünmesin
        AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          opacity: _showContent ? 1.0 : 0.0,
          child: widget.child,
        ),

        // 2. Splash Ekranı (Üstte durur, içerik hazır olunca kaybolur)
        // IgnorePointer ile kaybolurken tıklamaları engelliyoruz
        IgnorePointer(
          ignoring: _showContent,
          // İçerik göründüyse splash'e tıklanamasın (zaten yok olacak)
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            opacity: _showContent ? 0.0 : 1.0,
            child: SplashPage(
              loadingMessage: widget.loadingMessage,
            ),
          ),
        ),
      ],
    );
  }
}
