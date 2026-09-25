import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/google_logo.dart';
import '../providers/auth_mutation_provider.dart';

/// GİRİŞ EKRANI — Sanatsal Tiyatro & Sahne Atmosferli Tasarım
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final authMutation = ref.watch(authMutationProvider);

    ref.listen<AsyncValue<void>>(
      authMutationProvider,
      (final previous, final next) {
        next.whenOrNull(
          error: (final error, final stack) =>
              _showSnackBar(context, error.toString(), isError: true),
          data: (final _) {
            if (context.mounted) NavigationHandler.goToHome(context);
          },
        );
      },
    );

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      isOverlayLoading: authMutation.isLoading,
      layoutConfig: const BasePageLayoutConfig(
        safeAreaTop: false,
        safeAreaBottom: false,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // --- 1. PEXELS HD TİYATRO/SAHNE GÖRSELİ VE PERDE ---
          Positioned.fill(
            child: Image.network(
              'https://www.quovadis.com.tr/wp-content/uploads/the-phantom-of-the-opera-turu-4.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // --- 2. ÖN PLAN İÇERİK ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst Sol Sanatsal Rozet
                  const _TheaterBadge(),
                  const Spacer(flex: 3),

                  // --- ÇARPICI SANATSAL TİPOGRAFİ ---
                  Text(
                    'Perde Açılıyor,\nYerin Sizi Bekliyor.',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
                          offset: const Offset(0, 3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Şehrin en seçkin oyunlarına, konserlerine ve sahnelerine anında kapı arala. Sanata ilk adımı at.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(flex: 4),

                  // --- GELİŞTİRİLMİŞ BUTONLAR ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ArtisticGoogleButton(
                        onTap: () => _handleGoogleSignIn(ref),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ArtisticPhoneButton(
                        label: AppLocalizations.of(context)!.loginPhoneButton,
                        onTap: () => NavigationHandler.goToPhoneLogin(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Alt Sözleşme Bilgisi
                  const _FinePrint(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn(final WidgetRef ref) async =>
      ref.read(authMutationProvider.notifier).signInWithGoogle();

  void _showSnackBar(final BuildContext context, final String msg,
      {final bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

/// Tiyatro Rozeti Bileşeni
class _TheaterBadge extends StatelessWidget {
  const _TheaterBadge();

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: const Color(0xFF8B0000).withOpacity(0.4), // Derin bordo tonu
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.theater_comedy_rounded,
            color: Color(0xFFFFD700), // Şık altın sarısı vurgu
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Tiyatro & Sahne Sanatları',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Geliştirilmiş Google Giriş Butonu
class _ArtisticGoogleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ArtisticGoogleButton({required this.onTap});

  @override
  Widget build(final BuildContext context) {
    return Semantics(
      button: true,
      label: 'Google ile giriş yap',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          splashColor: Colors.grey.withOpacity(0.15),
          highlightColor: Colors.grey.withOpacity(0.1),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                GoogleLogo(size: 22),
                SizedBox(width: AppSpacing.md),
                Text(
                  'Google ile Sahneye Adım At',
                  style: TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Geliştirilmiş Telefon Giriş Butonu (Cam Dokulu)
class _ArtisticPhoneButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ArtisticPhoneButton({required this.label, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    return Semantics(
      button: true,
      label: 'Telefon numarasıyla giriş yap',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Text(
                    'Telefon Numarası ile Devam Et',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinePrint extends StatelessWidget {
  const _FinePrint();

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.loginTermsNotice,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.45),
          letterSpacing: 0.5,
          fontSize: 10,
          height: 1.4,
        ),
      ),
    );
  }
}
