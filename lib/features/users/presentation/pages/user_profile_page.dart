import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../shared/widgets/card/theme_selector_card.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../appTools/presentation/pages/contracts.dart';
import '../../../favorite/presentation/pages/favorite_screen.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../login/presentation/providers/login_state.dart';
import '../../../settings/presentation/pages/app_settings.dart';
import '../../../settings/presentation/pages/permission_settings.dart';
import '../../../tickets/presentation/pages/my_ticket_page.dart';
import '../providers/user_provider.dart';
import 'user_profile_edit.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _localUserData;
  bool _isLoadingLocalData = true;

  late AnimationController _glowController;
  late AnimationController _badgeRotateController;
  late Animation<double> _glowAnimation;
  late Animation<double> _badgeRotation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadLocalUserData();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _badgeRotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _badgeRotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _badgeRotateController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _badgeRotateController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalUserData() async {
    try {
      await LocalStorageService.init();
      final userData = LocalStorageService.getEssentialUserData();
      if (mounted) {
        setState(() {
          _localUserData = userData;
          _isLoadingLocalData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocalData = false;
        });
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final theme = context.theme;
    final colors = context.colors;

    // Misafir kontrolü (User var ama Anonymous mu?)
    final isGuest = loginState.isGuest && loginState.user == null;

    if (loginState.isLoading || _isLoadingLocalData)
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    colors.primary.withOpacity(context.isDarkMode ? 0.15 : 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildArtisticHeader(theme, isGuest),
                const SizedBox(height: 30),
                if (isGuest)
                  _buildGuestProfileCard(theme)
                else
                  _buildUserProfileCard(loginState.user, theme, loginState),
                const SizedBox(height: 40),
                ThemeSelectorCard(),
                const SizedBox(height: 32),
                _buildFunctionalSection(loginState, theme, isGuest),
                const SizedBox(height: 32),
                _buildSecuritySection(loginState, theme, isGuest),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildArtisticHeader(final ThemeData theme, final bool isGuest) {
    return Column(
      children: [
        Icon(Icons.museum_rounded, size: 32, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          isGuest ? 'SANAT SERÜVENİ' : 'KOLEKSİYONUNUZ',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: theme.colorScheme.primary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (final bounds) => LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ).createShader(bounds),
          child: Text(
            isGuest ? 'Hoşgeldiniz' : 'Profiliniz',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 36,
              color: Colors.white,
              letterSpacing: -1,
              fontFamily: 'Playfair',
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 10),
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              theme.colorScheme.primary.withOpacity(0),
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0),
            ]),
          ),
        )
      ],
    );
  }

  Widget _buildGuestProfileCard(final ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.1),
                border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1),
              ),
              child: Icon(Icons.person_outline_rounded,
                  size: 50, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              "Misafir Sanatsever",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Biletlerinizi saklamak ve etkinlikleri takip etmek için hesabınızı oluşturun.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            // MİSAFİR İÇİN GİRİŞ YAP BUTONU
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _navigateToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.login_rounded),
                label: const Text(
                  "GİRİŞ YAP / KAYIT OL",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileCard(
    final User? firebaseUser,
    final ThemeData theme,
    final LoginState loginState,
  ) {
    final displayName = firebaseUser?.displayName ??
        _localUserData?['displayName'] ??
        'Kullanıcı';
    final email = firebaseUser?.email ?? firebaseUser?.phoneNumber ?? '';
    final photoURL = firebaseUser?.photoURL ??
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=500&auto=format&fit=crop';
    final loginMethod = _getLoginMethod(firebaseUser);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withOpacity(0.95),
            theme.colorScheme.surface.withOpacity(0.85)
          ],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, 15),
              spreadRadius: -5),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          Positioned(top: 20, left: 20, child: _buildCornerDeco(theme, true)),
          Positioned(
              bottom: 20, right: 20, child: _buildCornerDeco(theme, false)),
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildLoginMethodBadge(
                        _getLoginMethodText(loginMethod),
                        _getLoginMethodIcon(loginMethod),
                        _getLoginMethodColor(loginMethod),
                        theme),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _badgeRotation,
                      builder: (final context, final child) {
                        return Transform.rotate(
                          angle: _badgeRotation.value,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.2),
                                  width: 1),
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                            width: 4),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2)
                        ],
                      ),
                      child: ClipOval(
                          child: OptimizedCachedImage(
                              imageUrl: photoURL, fit: BoxFit.cover)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  displayName.toUpperCase(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('0', 'Bilet', Icons.confirmation_number,
                          theme.colorScheme.primary),
                      _buildStatItem(
                          '0', 'Favori', Icons.favorite, Colors.redAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- GÜVENLİK BÖLÜMÜ ---
  Widget _buildSecuritySection(
      final LoginState loginState, final ThemeData theme, final bool isGuest) {
    // MİSAFİR İSE: "Bağla" ve "Sil"
    if (isGuest) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'HESAP BAĞLAMA',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.blue.withOpacity(0.05),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: ListTile(
              onTap: _linkWithGoogle,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.g_mobiledata_rounded,
                    color: Colors.blue, size: 28),
              ),
              title: const Text('Google ile Bağla',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold)),
              subtitle: const Text('Misafir verilerini Google hesabına aktar'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.blue),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.green.withOpacity(0.05),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: ListTile(
              onTap: _showPhoneLinkDialog,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.phone_iphone_rounded, color: Colors.green),
              ),
              title: const Text('Telefon ile Bağla',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
              subtitle: const Text('Misafir verilerini telefonuna aktar'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.green),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.red.withOpacity(0.05),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: ListTile(
              onTap: () => _showDeleteAccountDialog(loginState.user!.uid),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.delete_forever_rounded, color: Colors.red),
              ),
              title: const Text('Hesabı Sil',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              subtitle: const Text('Misafir verilerini sil ve çık'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.red),
            ),
          ),
        ],
      );
    }

    // NORMAL KULLANICI İSE
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'GÜVENLİK',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.orange.withOpacity(0.05),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: ListTile(
            onTap: _signOut,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.orange),
            ),
            title: const Text('Çıkış Yap',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold)),
            subtitle: const Text('Oturumu güvenli sonlandır'),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.red.withOpacity(0.05),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: ListTile(
            onTap: () => _showDeleteAccountDialog(loginState.user!.uid),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.delete_forever_rounded, color: Colors.red),
            ),
            title: const Text('Hesabı Sil',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text('Tüm verileri kalıcı sil'),
          ),
        ),
      ],
    );
  }

  // --- ACTIONS (İş Mantığı) ---

  Future<void> _linkWithGoogle() async {
    try {
      await ref.read(loginProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll("Exception: ", "");
        if (errorMessage.contains("already-in-use") ||
            errorMessage.contains("zaten başka")) {
          _showErrorDialog(
              "Bu Google hesabı zaten başka bir hesaba bağlı. Lütfen önce o hesaptan çıkış yapın veya başka bir hesap seçin.");
        } else {
          _showErrorDialog(errorMessage);
        }
      }
    }
  }

  void _showPhoneLinkDialog() {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text("Telefon Bağla"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Lütfen telefon numaranızı giriniz:"),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "+905xxxxxxxxx",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              if (phoneController.text.isNotEmpty) {
                Navigator.pop(context);
                _startPhoneLinking(phoneController.text.trim());
              }
            },
            child: const Text("Kod Gönder"),
          ),
        ],
      ),
    );
  }

  Future<void> _startPhoneLinking(final String phoneNumber) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final _) =>
          const CustomLoadingDialog(message: "Kod gönderiliyor..."),
    );

    try {
      await ref.read(loginProvider.notifier).verifyPhone(
            phoneNumber: phoneNumber,
            onVerificationCompleted: (final credential) async {
              if (mounted && Navigator.canPop(context)) Navigator.pop(context);

              try {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  await currentUser.linkWithCredential(credential);
                  await LocalStorageService.saveEssentialUserData(
                      uid: currentUser.uid,
                      displayName: currentUser.phoneNumber,
                      role: "user");

                  if (mounted)
                    _showSuccessDialog("Telefon başarıyla otomatik bağlandı!");
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  if (e.code == 'credential-already-in-use') {
                    _showErrorDialog("Bu numara zaten başka bir hesaba bağlı!");
                  } else {
                    _showErrorDialog("Hata: ${e.message}");
                  }
                }
              }
            },
            onCodeSent: (final verificationId, final resendToken) {
              if (mounted && Navigator.canPop(context)) Navigator.pop(context);
              _showOtpDialog(verificationId);
            },
            onAutoRetrievalTimeout: (final id) {},
          );
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        _showErrorDialog("Hata: $e");
      }
    }
  }

  void _showOtpDialog(final String verificationId) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => AlertDialog(
        title: const Text("Doğrulama Kodu"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("SMS ile gelen 6 haneli kodu giriniz."),
            const SizedBox(height: 10),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                hintText: "000000",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (otpController.text.length == 6) {
                Navigator.pop(context);
                await _finalizePhoneLink(verificationId, otpController.text);
              }
            },
            child: const Text("Doğrula"),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizePhoneLink(
      final String verificationId, final String smsCode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final _) => const CustomLoadingDialog(message: "Bağlanıyor..."),
    );

    try {
      await ref.read(loginProvider.notifier).verifyOtp(smsCode);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await LocalStorageService.saveEssentialUserData(
            uid: user.uid, displayName: user.phoneNumber, role: "user");
      }

      if (mounted) {
        Navigator.pop(context); // Loading kapa
        _showSuccessDialog("Hesap başarıyla telefonunuza bağlandı!");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading kapa

        String err = e.toString();
        if (err.contains("already-in-use")) {
          _showErrorDialog("Bu numara zaten kullanımda.");
        } else if (err.contains("invalid-verification-code")) {
          _showErrorDialog("Kod hatalı.");
        } else {
          _showErrorDialog("Hata: $err");
        }
      }
    }
  }

  Future<void> _signOut() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final _) =>
            const CustomLoadingDialog(message: "Çıkış yapılıyor..."));
    try {
      await LocalStorageService.clearAllUserData();
      await ref.read(loginProvider.notifier).signOut();
      if (mounted) Navigator.pop(context);
      _navigateToLogin();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog("Hata: $e");
      }
    }
  }

  // 🔥 SİLME İŞLEMİ (DÜZELTİLDİ)
  Future<void> _deleteAccount(final String userId) async {
    Navigator.pop(context); // Onay penceresini kapat
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final _) =>
            const CustomLoadingDialog(message: "Hesap siliniyor..."));

    try {
      // 1. Notifier üzerinden hesabı sil (Auth + Firestore)
      //    (Notifier içinde local storage da siliniyor zaten)
      final userNotifier = ref.read(userProvider.notifier);
      await userNotifier.deleteUser(userId); // Firestore verisini sil

      await ref
          .read(loginProvider.notifier)
          .deleteAccount(); // Auth'tan sil ve state temizle

      if (mounted) {
        Navigator.pop(context); // Loading kapa
        // Başarı mesajı
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (final _) => CustomSuccessDialog(
            message: "Hesabınız başarıyla silindi.",
            onConfirm: () {
              // 🔥 KESİN ÇÖZÜM: Direkt login sayfasına at
              _navigateToLogin();
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog(e.toString());
      }
    }
  }

  void _navigateToLogin() => Navigator.of(context)
      .pushNamedAndRemoveUntil('/login', (final route) => false);

  void _navigateTo(final Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (final _) => page));

  void _showDeleteAccountDialog(final String userId) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Hesabı Sil', style: TextStyle(color: Colors.red)),
        content: const Text('Tüm veriler silinecek. Emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => _deleteAccount(userId),
            child: const Text('SİL'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(final String msg) {
    showDialog(
        context: context,
        builder: (final _) => CustomSuccessDialog(
              message: msg,
              onConfirm: () {
                // Silme durumunda login'e at, diğerlerinde dialog'u kapat
                if (msg.contains("silindi")) _navigateToLogin();
              },
            ));
  }

  void _showErrorDialog(final String msg) {
    showDialog(
        context: context,
        builder: (final _) => CustomErrorDialog(
              message: msg,
              onConfirm: () {},
            ));
  }

  Widget _buildThemeSelectorArtistic(
      final WidgetRef ref, final ThemeData theme) {
    final currentTheme = ref.watch(themeProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: theme.colorScheme.outline.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TEMA TERCİHİ',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _buildThemeButton(
                    'Açık', ThemeMode.light, Icons.wb_sunny_rounded, ref)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildThemeButton(
                    'Koyu', ThemeMode.dark, Icons.nights_stay_rounded, ref)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildThemeButton('Sistem', ThemeMode.system,
                    Icons.phone_iphone_rounded, ref)),
          ]),
        ],
      ),
    );
  }

  Widget _buildThemeButton(final String label, final ThemeMode mode,
      final IconData icon, final WidgetRef ref) {
    final theme = Theme.of(context);
    final isActive = ref.watch(themeProvider) == mode;
    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isActive
                    ? Colors.transparent
                    : theme.colorScheme.outline.withOpacity(0.2))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              size: 16,
              color: isActive ? Colors.white : theme.colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: isActive ? Colors.white : theme.colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.bold))
        ]),
      ),
    );
  }

  Widget _buildFunctionalSection(
      final LoginState loginState, final ThemeData theme, final bool isGuest) {
    final buttons = isGuest
        ? [
            {
              'title': 'Ayarlar',
              'icon': Icons.settings,
              'color': Colors.orange,
              'onTap': () => _navigateTo(const AppSettingsPage())
            },
            {
              'title': 'Sözleşmeler',
              'icon': Icons.privacy_tip,
              'color': Colors.purple,
              'onTap': () => _navigateTo(const ContractsPage())
            },
            {
              'title': 'Yardım',
              'icon': Icons.help_outline,
              'color': Colors.teal,
              'onTap': () {}
            },
          ]
        : [
            {
              'title': 'Profil Düzenle',
              'icon': Icons.edit_outlined,
              'color': Colors.blue,
              'onTap': () => _navigateTo(
                  UserProfileEditScreen(userId: loginState.user!.uid))
            },
            {
              'title': 'Biletlerim',
              'icon': Icons.confirmation_number,
              'color': Colors.green,
              'onTap': () =>
                  _navigateTo(MyTicketPage(userId: loginState.user!.uid))
            },
            {
              'title': 'Favoriler',
              'icon': Icons.favorite,
              'color': Colors.pink,
              'onTap': () => _navigateTo(FavoritesPage())
            },
            {
              'title': 'Ayarlar',
              'icon': Icons.settings,
              'color': Colors.orange,
              'onTap': () => _navigateTo(const AppSettingsPage())
            },
            {
              'title': 'İzinler',
              'icon': Icons.notifications_outlined,
              'color': Colors.purpleAccent,
              'onTap': () => _navigateTo(const PermissionSettingsScreen())
            },
            {
              'title': 'Sözleşmeler',
              'icon': Icons.privacy_tip,
              'color': Colors.deepPurple,
              'onTap': () => _navigateTo(const ContractsPage())
            },
            {
              'title': 'Yardım',
              'icon': Icons.help_outline,
              'color': Colors.teal,
              'onTap': () {}
            },
          ];

    return Container(
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: theme.colorScheme.outline.withOpacity(0.1))),
      child: Column(
        children: buttons
            .map((final btn) => ListTile(
                  onTap: btn['onTap'] as VoidCallback,
                  leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: (btn['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(btn['icon'] as IconData,
                          color: btn['color'] as Color)),
                  title: Text(btn['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                ))
            .toList(),
      ),
    );
  }

  // Helpers
  String _getLoginMethod(final User? u) {
    if (u == null) return 'misafir';
    if (u.providerData.any((final p) => p.providerId == 'google.com'))
      return 'google';
    if (u.providerData.any((final p) => p.providerId == 'phone'))
      return 'phone';
    return 'misafir';
  }

  String _getLoginMethodText(final String m) => m == 'google'
      ? 'Google'
      : m == 'phone'
          ? 'Telefon'
          : 'Misafir';

  IconData _getLoginMethodIcon(final String m) => m == 'google'
      ? Icons.g_mobiledata_rounded
      : m == 'phone'
          ? Icons.phone_android
          : Icons.person_outline;

  Color _getLoginMethodColor(final String m) => m == 'google'
      ? Colors.blue
      : m == 'phone'
          ? Colors.green
          : Colors.orange;

  Widget _buildLoginMethodBadge(final String t, final IconData i, final Color c,
          final ThemeData th) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.withOpacity(0.5))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(i, size: 12, color: c),
            const SizedBox(width: 4),
            Text(t,
                style: TextStyle(
                    color: c, fontSize: 10, fontWeight: FontWeight.bold))
          ]));

  Widget _buildCornerDeco(final ThemeData t, final bool tl) => Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          border: Border(
              top: tl
                  ? BorderSide(
                      color: t.colorScheme.primary.withOpacity(0.3), width: 2)
                  : BorderSide.none,
              left: tl
                  ? BorderSide(
                      color: t.colorScheme.primary.withOpacity(0.3), width: 2)
                  : BorderSide.none,
              bottom: !tl
                  ? BorderSide(
                      color: t.colorScheme.primary.withOpacity(0.3), width: 2)
                  : BorderSide.none,
              right: !tl
                  ? BorderSide(
                      color: t.colorScheme.primary.withOpacity(0.3), width: 2)
                  : BorderSide.none)));

  Widget _buildStatItem(
          final String v, final String l, final IconData i, final Color c) =>
      Column(children: [
        Icon(i, color: c),
        Text(v,
            style:
                TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(l, style: TextStyle(fontSize: 12))
      ]);
}
