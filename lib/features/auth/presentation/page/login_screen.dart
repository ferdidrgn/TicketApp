import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/google_logo.dart';
import '../providers/auth_mutation_provider.dart';
import '../widgets/auth_stage_widgets.dart';

/// GİRİŞ EKRANI — "Sahne Kapısı" (Stage Door)
///
/// Eski tasarım (tam ekran fotoğraf + karartma gradyanı + üzerinde bulanık
/// cam kart, ortalanmış dikey stack) tamamen terk edildi. Bunun yerine:
///
/// - **Mobil**: tek sütun ama sahneye "giriş anı" hissi veren bir açılış —
///   üstte küçük bir sahne paneli, sayfa mount olur olmaz gerçek bir tiyatro
///   perdesi gibi ortadan açılıp `book_logo.jpg`'yi ortaya çıkarıyor
///   (`AuthCurtainStage` — teknik `page_transitions.dart`'taki
///   `curtainTransition` ve `theatre_show_card.dart`'ın hover reveal'ıyla
///   birebir aynı `ClipRect(Align(widthFactor: t))`), altında başlık ve
///   düz bir form paneli (artık glassmorphism yok).
/// - **Masaüstü/web**: GERÇEK split-screen — solda sahne panelinin BÜYÜK
///   versiyonu + üzerine oturan editoryal marka hikayesi ("SAHNE IŞIKLARI
///   SENİ BEKLİYOR"), sağda dar ve dikey ortalanmış form sütunu. Bu,
///   `home_page_web.dart`/`home_page_mobile.dart` ikilisindeki "aynı
///   widget'ı responsive yapmak yerine platforma özel gerçek kompozisyon"
///   prensibinin giriş akışına uygulanmış hali (`AuthStageScaffold`, hem bu
///   dosyada hem `phone_login_page.dart`'ta kullanılıyor — ikisi otomatik
///   tutarlı).
///
/// Google/telefon aksiyonlarının GERÇEK mantığı (authMutationProvider,
/// ref.listen hata/başarı yakalama, NavigationHandler) hiç değişmedi —
/// sadece görsel/yapısal katman yenilendi. Renkler yalnızca mevcut
/// `context.colors.*` paletinden — hiçbir yeni hex değeri icat edilmedi.
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
          // Not: Burada önceden `ref.read(isLoggedInProvider)` ile ekstra bir
          // kontrol yapılıyordu. isLoggedInProvider, authStateProvider'ın
          // (FirebaseAuth.userChanges() stream'i) senkron `.value`'sunu okur;
          // ama _handlePostLogin sonunda bu provider invalidate edildiğinde
          // stream'in yeni değeri (özellikle web'de, IndexedDB/JS SDK
          // round-trip'i nedeniyle) HENÜZ senkron olarak gelmemiş olabiliyor.
          // Bu da başarılı bir Google girişinde bu okumanın an itibarıyla
          // hâlâ eski/boş state döndürüp yönlendirmenin sessizce atlanmasına
          // yol açabiliyordu (kullanıcı login ekranında "asılı" kalıyordu).
          // authMutationProvider zaten yalnızca _handlePostLogin TAMAMEN
          // BAŞARILI olduğunda `data` state'ine geçtiği için (aksi halde
          // `error` dalı tetiklenir) bu noktada giriş kesinlikle başarılıdır;
          // ekstra provider kontrolüne gerek yok.
          if (context.mounted) NavigationHandler.goToHome(context);
        },
      );
    });

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      isOverlayLoading: authMutation.isLoading,
      layoutConfig: const BasePageLayoutConfig(
        safeAreaTop: true, // 💡 Status bar çakışmasını önlemek için true yaptık
        safeAreaBottom: false,
      ),
      child: AuthStageScaffold(
        stagePanelBuilder: (final stageContext, final isLargeScreen) =>
            AuthCurtainStage(
          imagePath: 'assets/images/book_logo.jpg',
          borderRadius: AppRadius.asymLg,
          curtainColor: stageContext.colors.primary,
          overlay: isLargeScreen
              ? const StageEditorialCaption(
                  eyebrow: 'Perde Aralanıyor',
                  title: 'SAHNE IŞIKLARI\nSENİ BEKLİYOR',
                  subtitle:
                      'Şehrin en iyi oyunları, oyuncuları ve sahneleri tek '
                      'çatı altında — girişini yap, bilet almaya başla.',
                )
              : const StageBadge(
                  icon: Icons.theater_comedy_rounded,
                  label: 'TİYATROL',
                ),
        ),
        headline: const AuthHeadlineBlock(
          kicker: 'Perde Aralanıyor',
          title: 'SAHNEYE\nHOŞ GELDİN',
          subtitle: 'Giriş yap, ışıklar senin için yansın.',
        ),
        formCard: _LoginOptionsPanel(
          onGoogleTap: () => _handleGoogleSignIn(context, ref),
          onPhoneTap: () => NavigationHandler.goToPhoneLogin(context),
        ),
        finePrint: const _FinePrint(),
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
          backgroundColor: isError ? Colors.red : Colors.green));
}

/// Google + telefon seçeneklerini barındıran düz (artık cam efektsiz) panel.
class _LoginOptionsPanel extends StatelessWidget {
  final VoidCallback onGoogleTap;
  final VoidCallback onPhoneTap;

  const _LoginOptionsPanel({
    required this.onGoogleTap,
    required this.onPhoneTap,
  });

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.colors.primary.withOpacity(0.14)),
          boxShadow: AppShadows.level2(context.colors.shadow),
        ),
        child: Column(
          children: [
            _GoogleButton(onTap: onGoogleTap),
            const SizedBox(height: AppSpacing.lg),
            const AuthOrDivider(),
            const SizedBox(height: AppSpacing.lg),
            AuthActionButton(
              label: AppLocalizations.of(context)!.loginPhoneButton,
              icon: Icons.phone_iphone_rounded,
              semanticLabel: 'Telefon numarasıyla giriş yap',
              useAsymCorner: true,
              onTap: onPhoneTap,
            ),
          ],
        ),
      );
}

/// Google'ın kendi marka yönergeleri, "Google ile Oturum Aç" düğmesi için
/// uygulamanın serbest bir renk paleti kullanmasına İZİN VERMEZ — nötr
/// (beyaz/açık gri) bir zemin üzerinde gerçek çok renkli "G" markası ve
/// koyu metin şart. Bu kısıt bilinçli olarak korunuyor; sadece köşe/gölge
/// tokenlarla yeniden giydirildi.
class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GoogleButton({required this.onTap});

  @override
  Widget build(final BuildContext context) => Semantics(
        button: true,
        label: 'Google ile giriş yap',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.black.withOpacity(0.12)),
              boxShadow: AppShadows.level1(Colors.black),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GoogleLogo(size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Text(AppLocalizations.of(context)!.loginGoogleButton,
                      style: const TextStyle(
                          color: Color(0xFF1F1F1F),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _FinePrint extends StatelessWidget {
  const _FinePrint();

  @override
  Widget build(final BuildContext context) => Center(
        child: Text(
          AppLocalizations.of(context)!.loginTermsNotice,
          textAlign: TextAlign.center,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.onSurface.withOpacity(0.45),
            letterSpacing: 1.2,
            fontSize: 9,
          ),
        ),
      );
}
