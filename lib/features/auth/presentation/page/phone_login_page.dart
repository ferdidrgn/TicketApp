import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/features/auth/presentation/providers/auth_mutation_provider.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../providers/auth_provider.dart';

enum _PendingAuthAction { none, sendCode, verifyCode }

/// TELEFON İLE GİRİŞ / OTP EKRANI
/// Sanatsal Tiyatro teması ve Cam Dokulu (Glassmorphism) UI mimarisi.
class PhoneLogInPage extends ConsumerStatefulWidget {
  const PhoneLogInPage({super.key});

  @override
  ConsumerState<PhoneLogInPage> createState() => _PhoneLogInPageState();
}

class _PhoneLogInPageState extends ConsumerState<PhoneLogInPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isCodeSent = false;
  _PendingAuthAction _pendingAction = _PendingAuthAction.none;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showSnackBar("Lütfen geçerli bir telefon numarası girin (Başında 0 olmadan)", isError: true);
      return;
    }

    final formattedPhone = phone.startsWith("+90") ? phone : "+90$phone";
    _pendingAction = _PendingAuthAction.sendCode;
    await ref.read(authMutationProvider.notifier).verifyPhone(formattedPhone);
  }

  Future<void> _signInWithOTP() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showSnackBar("Lütfen 6 haneli kodu eksiksiz girin", isError: true);
      return;
    }
    _pendingAction = _PendingAuthAction.verifyCode;
    await ref.read(authMutationProvider.notifier).verifyOtp(otp);
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final authMutation = ref.watch(authMutationProvider);

    ref.listen<AsyncValue<void>>(
      authMutationProvider,
          (previous, next) {
        next.whenOrNull(
          error: (error, stack) => _showSnackBar("Hata: ${error.toString()}", isError: true),
          data: (_) {
            switch (_pendingAction) {
              case _PendingAuthAction.sendCode:
                if (ref.read(isLoggedInProvider)) {
                  if (context.mounted) NavigationHandler.goToHome(context);
                } else {
                  setState(() => _isCodeSent = true);
                }
                break;
              case _PendingAuthAction.verifyCode:
                if (context.mounted) NavigationHandler.goToHome(context);
                break;
              case _PendingAuthAction.none:
                break;
            }
            _pendingAction = _PendingAuthAction.none;
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
      child: PopScope(
        canPop: !_isCodeSent,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_isCodeSent) setState(() => _isCodeSent = false);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // --- 1. YENİ SAHNE / TİYATRO GÖRSELİ (Farklı Bir Atmosfer) ---
            Positioned.fill(
              child: Image.network(
                // Klasik, boş ve dramatik ışıklı bir tiyatro salonu görseli
                'https://images.unsplash.com/photo-1514306191717-452ec28c7814?q=80&w=2070&auto=format&fit=crop',
                fit: BoxFit.cover,
              ),
            ),
            // Form ve tipografinin okunabilirliği için derin gradyan
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.98),
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
                    // Sol Üst Güvenlik/Tiyatro Rozeti
                    _StatusBadge(isCodeSent: _isCodeSent),
                    const Spacer(flex: 2),

                    // --- SANATSAL BAŞLIKLAR (Animasyonlu Geçiş) ---
                    AnimatedSwitcher(
                      duration: AppMotion.normal,
                      switchInCurve: AppMotion.standard,
                      switchOutCurve: AppMotion.standard,
                      child: _buildHeaderText(key: ValueKey(_isCodeSent)),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // --- CAM DOKULU (GLASSMORPHISM) FORM ALANI ---
                    AnimatedSwitcher(
                      duration: AppMotion.normal,
                      switchInCurve: AppMotion.standard,
                      switchOutCurve: AppMotion.standard,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _isCodeSent ? _buildOtpUI() : _buildPhoneUI(),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// BAŞLIK VE ALT BAŞLIK
  Widget _buildHeaderText({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isCodeSent ? 'Son Bir\nAdım Kaldı.' : 'Sahne Kapısı\nAralanıyor.',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.15,
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.7),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _isCodeSent
              ? 'Telefonunuza gönderdiğimiz 6 haneli kodu girerek perdeyi açın.'
              : 'Biletinizi almak ve yerinizi seçmek için telefon numaranızı girin.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.75),
            height: 1.5,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  /// 1. AŞAMA: TELEFON NUMARASI GİRİŞ EKRANI
  Widget _buildPhoneUI() {
    return Column(
      key: const ValueKey('phone_ui'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GlassTextField(
          controller: _phoneController,
          label: 'TELEFON NUMARASI',
          hint: '5XX XXX XX XX',
          prefix: '+90  ',
          maxLength: 10,
          semanticLabel: 'Telefon numarası girişi',
        ),
        const SizedBox(height: AppSpacing.xl),
        _ArtisticActionButton(
          label: 'KOD GÖNDER',
          icon: Icons.send_rounded,
          onTap: _verifyPhone,
        ),
      ],
    );
  }

  /// 2. AŞAMA: OTP (SMS KODU) GİRİŞ EKRANI
  Widget _buildOtpUI() {
    final remainingSeconds = ref.watch(otpTimerProvider);
    final bool canResend = remainingSeconds <= 0;
    final timerText = "00:${remainingSeconds.toString().padLeft(2, '0')}";

    return Column(
      key: const ValueKey('otp_ui'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GlassTextField(
          controller: _otpController,
          label: '6 HANELİ SMS KODU',
          hint: '000000',
          textAlign: TextAlign.center,
          maxLength: 6,
          semanticLabel: 'Doğrulama kodu',
        ),
        const SizedBox(height: AppSpacing.sm),

        // Zamanlayıcı
        Center(
          child: Text(
            timerText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: canResend ? Colors.red.shade400 : const Color(0xFFFFD700),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        _ArtisticActionButton(
          label: 'DOĞRULA VE BAŞLA',
          icon: Icons.check_circle_outline_rounded,
          onTap: _signInWithOTP,
        ),
        const SizedBox(height: AppSpacing.md),

        // Alt Aksiyon Butonları (Yeniden Gönder / Numarayı Düzenle)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _isCodeSent = false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.6),
              ),
              child: const Text(
                "Numarayı Düzenle",
                style: TextStyle(fontSize: 13, decoration: TextDecoration.underline),
              ),
            ),
            AnimatedOpacity(
              duration: AppMotion.fast,
              opacity: canResend ? 1.0 : 0.4,
              child: TextButton(
                onPressed: canResend ? _verifyPhone : null,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD700),
                ),
                child: const Text(
                  "Kodu Yeniden Gönder",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// GÜVENLİK / DURUM ROZETİ
class _StatusBadge extends StatelessWidget {
  final bool isCodeSent;
  const _StatusBadge({required this.isCodeSent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: const Color(0xFF8B0000).withOpacity(0.4),
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
          Icon(
            isCodeSent ? Icons.mark_email_read_rounded : Icons.security_rounded,
            color: const Color(0xFFFFD700),
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isCodeSent ? 'Doğrulama Aşaması' : 'Güvenli Giriş',
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

/// CAM DOKULU (GLASSMORPHISM) METİN KUTUSU
class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? prefix;
  final TextAlign textAlign;
  final int maxLength;
  final String semanticLabel;

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.prefix,
    this.textAlign = TextAlign.start,
    required this.maxLength,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Semantics(
          label: semanticLabel,
          textField: true,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: controller,
              textAlign: textAlign,
              keyboardType: TextInputType.number,
              maxLength: maxLength,
              keyboardAppearance: Brightness.dark,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  letterSpacing: 2,
                ),
                prefixText: prefix,
                prefixStyle: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                counterText: "",
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// SANATSAL AKSİYON BUTONU (Glass/Solid Karışımı)
class _ArtisticActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ArtisticActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          splashColor: Colors.grey.withOpacity(0.2),
          highlightColor: Colors.grey.withOpacity(0.1),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: const Color(0xFF1F1F1F)),
                const SizedBox(width: AppSpacing.md),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.5,
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
