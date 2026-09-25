import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/google_logo.dart';
import '../providers/auth_mutation_provider.dart';

/// GİRİŞ EKRANI — Sanatsal Tiyatro & Sahne Atmosferli Tasarım
///
/// Pexels'in büyüleyici tiyatro/sahne HD görseli, vurucu tipografi ve
/// modern, göz alıcı form butonları ile yeniden tasarlandı.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final authMutation = ref.watch(authMutationProvider);

    ref.listen<AsyncValue<void>>(authMutationProvider,
            (final previous, final next) {
          next.whenOrNull(
            error: (final error, final stack) =>
                _showSnackBar(context, error.toString(), isError: true),
            data: (final _) {
              if (context.mounted) NavigationHandler.goToHome(context);
            },
          );
        });

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
          // --- 1. PEXELS HD TİYATRO/SAHNE GÖRSELİ VE SİNEMATİK PERDE ---
          Positioned.fill(
            child: Image.network(
              'https://www.quovadis.com.tr/wp-content/uploads/the-phantom-of-the-opera-turu-4.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Tipografinin ve butonların kusursuz okunması için derinleştirilmiş gradyan
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.96),
                  ],
                  stops: const [0.0, 0.45, 1.0],
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
                  // Üst Sol Sanatsal Tiyatro Rozeti
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: const Color(0xFF3C030C).withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3C030C).withOpacity(0.2),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.theater_comedy_rounded,
                          color: Color(0xFF3C030C),
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
                  ),
                  const Spacer(flex: 3),

                  // --- ÇARPICI SANATSAL TİPOGRAFİ VE AÇIKLAMA ---
                  Text(
                    'Perde Açılıyor,\nYerin Sizi Bekliyor.',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 38,
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

                  // --- EN ALT ŞIK VE ZARİF BUTONLAR (Overlay Yok, Saf Görsel Üstü) ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ArtisticGoogleButton(
                        onTap: () => _handleGoogleSignIn(context, ref),
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

  Future<void> _handleGoogleSignIn(
      final BuildContext context, final WidgetRef ref) async =>
      ref.read(authMutationProvider.notifier).signInWithGoogle();

  void _showSnackBar(final BuildContext context, final String msg,
      {final bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md))));
}

/// Google Giriş Butonu (Özel İkonlu, Vurucu Metinle)
class _ArtisticGoogleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ArtisticGoogleButton({required this.onTap});

  @override
  Widget build(final BuildContext context) => Semantics(
    button: true,
    label: 'Google ile giriş yap',
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GoogleLogo(size: 22),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Google ile Sahneye Adım At',
                style: const TextStyle(
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

/// Telefon Giriş Butonu (Cam Dokulu, Özel Ok İkonlu)
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
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Telefon Numarası ile Devam Et',
                  style: const TextStyle(
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
    );
  }
}

class _FinePrint extends StatelessWidget {
  const _FinePrint();

  @override
  Widget build(final BuildContext context) => Center(
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