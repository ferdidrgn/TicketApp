import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../providers/auth_mutation_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final authMutation = ref.watch(authMutationProvider);
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    ref.listen<AsyncValue<void>>(authMutationProvider,
        (final previous, final next) {
      next.whenOrNull(
        error: (final error, final stack) =>
            _showSnackBar(context, error.toString(), isError: true),
        data: (final _) {
          if (ref.read(isLoggedInProvider)) if (context.mounted)
            NavigationHandler.goToHome(context);
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
      child: Stack(
        children: [
          // 1. ARKA PLAN (Stack içinde olduğu için tüm alanı kaplar)
          Positioned.fill(
            child: Image.asset(
              'assets/images/book_logo.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. KARARTMA
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // 3. İÇERİK
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: isLargeScreen ? 500 : double.infinity),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 3),
                    _buildArtisticTitle(context),
                    const Spacer(flex: 4),
                    _buildLoginCard(context, ref, authMutation.isLoading),
                    const SizedBox(height: 24),
                    _buildFooterText(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... (Diğer _build metodların (title, card, button) aynı kalabilir)

  Widget _buildArtisticTitle(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SANATIN\nDÜNYASI',
            style: TextStyle(
              fontSize: 48,
              height: 0.9,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(3))),
        ],
      );

  Widget _buildLoginCard(final BuildContext context, final WidgetRef ref,
          final bool isLoading) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGradientButton(
                  text: 'GOOGLE İLE BAĞLAN',
                  icon: Icons.g_mobiledata_rounded,
                  colors: [const Color(0xFF4285F4), const Color(0xFF34A853)],
                  onTap: () => _handleGoogleSignIn(context, ref),
                ),
                const SizedBox(height: 16),
                _buildGradientButton(
                  text: 'TELEFON İLE DEVAM ET',
                  icon: Icons.phone_iphone_rounded,
                  colors: [context.colors.primary, context.colors.secondary],
                  onTap: () => NavigationHandler.goToPhoneLogin(context),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildGradientButton(
          {required final String text,
          required final IconData icon,
          required final List<Color> colors,
          required final VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: colors.first.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const SizedBox(width: 12),
                Text(text,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 14)),
              ],
            ),
          ),
        ),
      );

  Widget _buildFooterText(final BuildContext context) => Center(
        child: InkWell(
          onTap: () => NavigationHandler.goToContracts(context),
          child: Opacity(
            opacity: 0.6,
            child: Text(
              'KOLEKSİYONA KATILARAK ŞARTLARI KABUL EDERSİNİZ',
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  letterSpacing: 1.2,
                  fontSize: 9,
                  decoration: TextDecoration.underline),
            ),
          ),
        ),
      );

  Future<void> _handleGoogleSignIn(
          final BuildContext context, final WidgetRef ref) async =>
      ref.read(authMutationProvider.notifier).signInWithGoogle();

  void _showSnackBar(final BuildContext context, final String msg,
          {final bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : Colors.green));
}
