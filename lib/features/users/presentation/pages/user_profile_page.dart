import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  // --- STATE & ANIMATION ---
  late AnimationController _glowController;
  late AnimationController _badgeRotateController;
  late Animation<double> _badgeRotation;

  bool _isLoadingLocalData = true;
  Map<String, dynamic>? _localUserData;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadLocalUserData();
  }

  void _initializeAnimations() {
    _glowController =
        AnimationController(duration: const Duration(seconds: 4), vsync: this)
          ..repeat(reverse: true);
    _badgeRotateController =
        AnimationController(duration: const Duration(seconds: 20), vsync: this)
          ..repeat();
    _badgeRotation = Tween<double>(begin: 0, end: 2 * pi).animate(
        CurvedAnimation(parent: _badgeRotateController, curve: Curves.linear));
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
      _localUserData = LocalStorageService.getEssentialUserData();
    } finally {
      if (mounted) setState(() => _isLoadingLocalData = false);
    }
  }

  // --- MAIN BUILD ---
  @override
  Widget build(final BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final theme = context.theme;

    // 🔥 Login state değişikliklerini dinle
    ref.listen<LoginState>(loginProvider, (final previous, final next) {
      // Çıkış yapıldıysa login'e yönlendir
      if (previous?.user != null &&
          next.user == null &&
          !next.isLoading) if (mounted) context.go('/login');

      // Error varsa göster
      if (next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) if (mounted)
        _showErrorSnackBar(next.errorMessage!);
    });

    if (loginState.isLoading || _isLoadingLocalData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🔥 Düzeltilmiş user kontrolü
    final bool isUserLoggedIn = loginState.isLoggedIn && !loginState.isGuest;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          _buildBackgroundBlur(context.colors),
          RefreshIndicator(
            onRefresh: () async {
              await _loadLocalUserData();
              ref.invalidate(loginProvider);
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildArtisticHeader(theme, !isUserLoggedIn),
                  const SizedBox(height: 30),

                  // Dinamik Profil Alanı
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: isUserLoggedIn
                        ? _buildUserProfileCard(
                            loginState.user, theme, loginState)
                        : _buildAuthInvitationCard(theme),
                  ),

                  const SizedBox(height: 32),
                  ThemeSelectorCard(),

                  const SizedBox(height: 32),
                  _buildSectionTitle(
                      theme, isUserLoggedIn ? 'DENEYİM' : 'KEŞFET'),
                  _buildFunctionalSection(loginState, theme, !isUserLoggedIn),

                  const SizedBox(height: 32),
                  _buildSectionTitle(theme, 'GÜVENLİK VE GİZLİLİK'),
                  _buildSecuritySection(loginState, theme, !isUserLoggedIn),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ARTISTIC WIDGETS ---

  Widget _buildBackgroundBlur(final ColorScheme colors) {
    return Positioned(
      top: -100,
      left: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.primary.withOpacity(0.12),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildArtisticHeader(final ThemeData theme, final bool isGuest) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withOpacity(0.08),
          ),
          child: Icon(Icons.auto_awesome_rounded,
              size: 28, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 16),
        Text(
          'ESTETİK HAFIZA • İSİMSİZ BAŞYAPIT',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
            color: theme.colorScheme.primary.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ShaderMask(
            shaderCallback: (final bounds) => LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ).createShader(bounds),
            child: Text(
              isGuest
                  ? 'Kendi Başyapıtını\nKeşfetmeye Başla'
                  : 'Bakmanın Değil,\nGörmenin Hikayesi',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 32,
                color: Colors.white,
                height: 1.1,
                fontFamily: 'PlayfairDisplay',
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(),
            Container(
              width: 40,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  theme.colorScheme.primary.withOpacity(0),
                  theme.colorScheme.primary.withOpacity(0.5),
                  theme.colorScheme.primary.withOpacity(0),
                ]),
              ),
            ),
            _buildDot(),
          ],
        )
      ],
    );
  }

  Widget _buildDot() => Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
            color: context.colors.secondary, shape: BoxShape.circle),
      );

  BoxDecoration _artisticContainerDecoration(final ThemeData theme) {
    return BoxDecoration(
      color: theme.colorScheme.surface.withOpacity(0.7),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10))
      ],
    );
  }

  // --- PROFILE & AUTH CARDS ---

  Widget _buildUserProfileCard(
    final User? firebaseUser,
    final ThemeData theme,
    final LoginState loginState,
  ) {
    final displayName = firebaseUser?.displayName ??
        _localUserData?['displayName'] ??
        'Sanatsever';

    final email =
        firebaseUser?.email ?? _localUserData?['email'] ?? 'seruven@sanat.com';

    final photoURL = firebaseUser?.photoURL ??
        _localUserData?['photoURL'] ??
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=500&auto=format&fit=crop';

    final loginMethod = _getLoginMethod(firebaseUser);

    return Container(
      width: double.infinity,
      decoration: _artisticContainerDecoration(theme),
      child: Stack(
        children: [
          Positioned(top: 20, left: 20, child: _buildCornerDeco(theme, true)),
          Positioned(
              bottom: 20, right: 20, child: _buildCornerDeco(theme, false)),
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: _buildLoginMethodBadge(
                    _getLoginMethodText(loginMethod),
                    _getLoginMethodIcon(loginMethod),
                    _getLoginMethodColor(loginMethod),
                    theme,
                  ),
                ),
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _badgeRotation,
                      builder: (final context, final child) => Transform.rotate(
                        angle: _badgeRotation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: OptimizedCachedImage(
                          imageUrl: photoURL,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  displayName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontFamily: 'PlayfairDisplay',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                          '0',
                          'Bilet',
                          Icons.confirmation_number_outlined,
                          theme.colorScheme.primary),
                      _buildStatItem(
                          '0',
                          'Koleksiyon',
                          Icons.auto_awesome_motion_rounded,
                          theme.colorScheme.secondary),
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

  Widget _buildAuthInvitationCard(final ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _artisticContainerDecoration(theme),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_mosaic_rounded,
              size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            'Koleksiyonun Henüz Başlamadı',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, fontFamily: 'PlayfairDisplay'),
          ),
          const SizedBox(height: 12),
          Text(
            'Sana özel sanatsal bir deneyim ve bilet arşivi için galerine ilk imzayı at.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Serüvene Başla',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  // --- SECTIONS ---

  Widget _buildSectionTitle(final ThemeData theme, final String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildFunctionalSection(
      final LoginState loginState, final ThemeData theme, final bool isGuest) {
    return Container(
      decoration: _artisticContainerDecoration(theme),
      child: Column(
        children: [
          if (!isGuest && loginState.user != null) ...[
            _buildListTile(
                theme,
                Icons.edit_outlined,
                'Profil Düzenle',
                'Bilgilerini güncelle',
                Colors.blue,
                () => _navigateTo(
                    UserProfileEditScreen(userId: loginState.user!.uid))),
            _buildListTile(
                theme,
                Icons.confirmation_number,
                'Biletlerim',
                'Etkinlik biletlerin',
                Colors.green,
                () => _navigateTo(MyTicketPage(userId: loginState.user!.uid))),
            _buildListTile(
                theme,
                Icons.favorite,
                'Favoriler',
                'Kaydettiğin eserler',
                Colors.pink,
                () => _navigateTo(FavoritesPage())),
          ],
          _buildListTile(
              theme,
              Icons.settings,
              'Ayarlar',
              'Uygulama tercihleri',
              Colors.orange,
              () => _navigateTo(const AppSettingsPage())),
          _buildListTile(
              theme,
              Icons.privacy_tip,
              'Sözleşmeler',
              'Yasal metinler',
              Colors.deepPurple,
              () => _navigateTo(const ContractsPage())),
          _buildListTile(theme, Icons.help_outline, 'Yardım', 'Destek al',
              Colors.teal, () {}),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(
      final LoginState loginState, final ThemeData theme, final bool isGuest) {
    return Container(
      decoration: _artisticContainerDecoration(theme),
      child: Column(
        children: [
          // 🔥 Guest kullanıcılar hesap yükseltme seçenekleri
          if (isGuest) ...[
            _buildListTile(
                theme,
                Icons.g_mobiledata_rounded,
                'Google ile Bağla',
                'Verilerini kalıcı hale getir',
                Colors.blue,
                _linkWithGoogle),
            _buildListTile(
                theme,
                Icons.phone_iphone_rounded,
                'Telefon ile Bağla',
                'Numaranı ekle',
                Colors.green,
                _showPhoneLinkDialog),
          ],

          // Çıkış seçeneği (her durumda)
          _buildListTile(theme, Icons.logout_rounded, 'Çıkış Yap',
              'Oturumu sonlandır', Colors.orange, _signOut),

          // 🔥 Hesap silme (Guest dahil herkes silebilir)
          _buildListTile(
              theme,
              Icons.delete_forever_rounded,
              'Hesabı Sil',
              'Tüm verileri kalıcı sil',
              Colors.red,
              () => _showDeleteAccountDialog(loginState.user?.uid ?? '')),
        ],
      ),
    );
  }

  // --- ACTIONS & BUSINESS LOGIC ---

  Future<void> _linkWithGoogle() async {
    try {
      await ref.read(loginProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted)
        _showErrorSnackBar(e.toString().replaceAll("Exception: ", ""));
    }
  }

  void _showPhoneLinkDialog() {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text("Telefon Bağla"),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
              hintText: "+905xxxxxxxxx", prefixIcon: Icon(Icons.phone)),
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
              child: const Text("Kod Gönder")),
        ],
      ),
    );
  }

  Future<void> _startPhoneLinking(final String phoneNumber) async {
    if (!mounted) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final _) =>
            const CustomLoadingDialog(message: "Kod gönderiliyor..."));

    try {
      await ref.read(loginProvider.notifier).verifyPhone(phoneNumber);

      if (mounted) {
        Navigator.pop(context);
        _showOtpDialog();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar("Hata: $e");
      }
    }
  }

  void _showOtpDialog() {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) => AlertDialog(
        title: const Text("Doğrulama Kodu"),
        content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal")),
          ElevatedButton(
              onPressed: () async {
                if (otpController.text.length == 6) {
                  Navigator.pop(context);
                  await _finalizePhoneLink(otpController.text);
                }
              },
              child: const Text("Doğrula")),
        ],
      ),
    );
  }

  Future<void> _finalizePhoneLink(final String smsCode) async {
    if (!mounted) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final _) =>
            const CustomLoadingDialog(message: "Bağlanıyor..."));

    try {
      await ref.read(loginProvider.notifier).verifyOtp(smsCode);

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar("Hesap başarıyla bağlandı!");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar("Hata: $e");
      }
    }
  }

  // 🔥 DÜZELTİLMİŞ ÇIKIŞ METODU
  Future<void> _signOut() async {
    final confirmed = await _showConfirmDialog(
        "Çıkış Yap", "Oturumunuz sonlandırılacak. Emin misiniz?");

    if (!confirmed || !mounted) return;

    try {
      // Notifier içinde tüm temizlik yapılacak
      await ref.read(loginProvider.notifier).signOut();
    } catch (e) {
      if (mounted) _showErrorSnackBar("Çıkış hatası: $e");
    }
  }

  void _showDeleteAccountDialog(final String userId) {
    if (userId.isEmpty) {
      _showErrorSnackBar("Kullanıcı kimliği bulunamadı");
      return;
    }

    final loginState = ref.read(loginProvider);
    final isGuest = loginState.isGuest;

    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Hesabı Sil',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(
          isGuest
              ? 'Misafir hesabınız ve tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz. Emin misiniz?'
              : 'Hesabınız, tüm biletleriniz, favorileriniz ve tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz. Emin misiniz?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(userId);
            },
            child: const Text('SİL'),
          ),
        ],
      ),
    );
  }

  // 🔥 DÜZELTİLMİŞ HESAP SİLME METODU (Guest dahil)
  Future<void> _deleteAccount(final String userId) async {
    if (!mounted) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final _) => const Center(child: CircularProgressIndicator()));

    try {
      // 1. Firestore'dan kullanıcı dökümanını sil (varsa)
      // Guest user'lar için de Firestore kaydı olabilir
      try {
        await ref.read(userProvider.notifier).deleteUser(userId);
      } catch (e) {
        // Firestore'da kayıt yoksa devam et
        debugPrint("Firestore user silme hatası (normal olabilir): $e");
      }

      // 2. Auth hesabını sil
      // Bu işlem hem local storage'ı hem FCM token'ı temizleyecek
      await ref.read(loginProvider.notifier).deleteAccount();

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar("Hesabınız başarıyla silindi.");
        // ref.listen otomatik /login'e yönlendirecek
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar("Hesap silme hatası: $e");
      }
    }
  }

  // --- HELPERS ---

  Widget _buildListTile(
      final ThemeData theme,
      final IconData icon,
      final String title,
      final String sub,
      final Color color,
      final VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color)),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12),
    );
  }

  Future<bool> _showConfirmDialog(
      final String title, final String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (final context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Vazgeç")),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Evet")),
            ],
          ),
        ) ??
        false;
  }

  void _navigateTo(final Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (final _) => page));

  void _showErrorSnackBar(final String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(final String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getLoginMethod(final User? u) {
    if (u == null) return 'misafir';
    if (u.isAnonymous) return 'misafir';
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
          : 'Ziyaretçi';

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
        ]),
      );

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
        Text(l, style: const TextStyle(fontSize: 12))
      ]);
}
