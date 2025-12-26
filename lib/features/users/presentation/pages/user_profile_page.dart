import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../core/services/sign_out_delete.dart';
import '../../../../shared/widgets/card/theme_selector_card.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../login/presentation/providers/login_state.dart';
import '../../../settings/presentation/pages/app_settings.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with
        TickerProviderStateMixin, // Animasyonlar için şart
        ProfileSnackBarHandler,
        ProfileSignOutHandler,
        ProfileDeleteAccountHandler,
        ProfilePhoneLinkHandler,
        ProfileGoogleLinkHandler {
  late AnimationController _badgeRotateController;
  late Animation<double> _badgeRotation;

  @override
  void initState() {
    super.initState();
    _badgeRotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _badgeRotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _badgeRotateController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _badgeRotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final theme = context.theme;
    final bool isUserLoggedIn = loginState.isLoggedIn && !loginState.isGuest;

    // Logic Dinleyicisi
    ref.listen<LoginState>(loginProvider, (final previous, final next) {
      if (previous?.isLoggedIn == true && !next.isLoggedIn)
        context.go('/login');
      if (next.isAccountDeleted) context.go('/login');
    });

    if (loginState.isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackgroundBlur(context.colors),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildArtisticHeader(theme, !isUserLoggedIn),
                  const SizedBox(height: 30),

                  // Animasyonlu Profil Kartı Geçişi
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: isUserLoggedIn
                        ? _buildUserProfileCard(loginState, theme)
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
                  _buildSecuritySection(loginState, theme),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ESKİ ŞIK TASARIM WIDGETLARI ---

  Widget _buildBackgroundBlur(final ColorScheme colors) => Positioned(
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

  Widget _buildArtisticHeader(final ThemeData theme, final bool isGuest) =>
      Column(
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
          Text(
            isGuest
                ? 'Kendi Başyapıtını\nKeşfetmeye Başla'
                : 'Bakmanın Değil,\nGörmenin Hikayesi',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 32,
              height: 1.1,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
        ],
      );

  Widget _buildUserProfileCard(final LoginState state, final ThemeData theme) =>
      Container(
        decoration: _artisticContainerDecoration(theme),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              // Login Method Badge
              Align(
                alignment: Alignment.topRight,
                child: _buildLoginMethodBadge(state, theme),
              ),
              // Avatar with Rotating Border
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
                              width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: OptimizedCachedImage(
                        imageUrl:
                            state.photoUrl ?? 'https://via.placeholder.com/150',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                (state.displayName ?? 'Sanatsever').toUpperCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900, fontFamily: 'PlayfairDisplay'),
              ),
              Text(state.email ?? '',
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5))),
              const SizedBox(height: 30),
              // Stats Row
              Row(
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
            ],
          ),
        ),
      );

  Widget _buildAuthInvitationCard(final ThemeData theme) => Container(
        padding: const EdgeInsets.all(28),
        decoration: _artisticContainerDecoration(theme),
        child: Column(
          children: [
            Icon(Icons.auto_awesome_mosaic_rounded,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            const Text('Koleksiyonun Henüz Başlamadı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Serüvene Başla'),
            ),
          ],
        ),
      );

  Widget _buildFunctionalSection(final LoginState loginState,
          final ThemeData theme, final bool isGuest) =>
      Container(
        decoration: _artisticContainerDecoration(theme),
        child: Column(
          children: [
            if (!isGuest) ...[
              _buildListTile(
                  theme,
                  Icons.edit_outlined,
                  'Profil Düzenle',
                  'Bilgilerini güncelle',
                  Colors.blue,
                  () => context.push('/profile-edit/${loginState.userId}')),
              _buildListTile(theme, Icons.confirmation_number, 'Biletlerim',
                  'Etkinlik biletlerin', Colors.green, () {}),
              _buildListTile(theme, Icons.favorite, 'Favoriler',
                  'Kaydettiğin eserler', Colors.pink, () {}),
            ],
            _buildListTile(
                theme,
                Icons.settings,
                'Ayarlar',
                'Uygulama tercihleri',
                Colors.orange,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (final _) => const AppSettingsPage()))),
          ],
        ),
      );

  Widget _buildSecuritySection(final LoginState state, final ThemeData theme) =>
      Container(
        decoration: _artisticContainerDecoration(theme),
        child: Column(
          children: [
            if (state.isGuest) ...[
              _buildListTile(
                  theme,
                  Icons.g_mobiledata_rounded,
                  'Google ile Bağla',
                  'Verilerini kalıcı hale getir',
                  Colors.blue,
                  () => handleGoogleLink(context, ref)),
              _buildListTile(
                  theme,
                  Icons.phone_iphone_rounded,
                  'Telefon ile Bağla',
                  'Numaranı ekle',
                  Colors.green,
                  () => showPhoneLinkDialog(context, ref)),
            ],
            _buildListTile(
                theme,
                Icons.logout_rounded,
                'Çıkış Yap',
                'Oturumu sonlandır',
                Colors.orange,
                () => showSignOutDialog(context, ref)),
            _buildListTile(
                theme,
                Icons.delete_forever_rounded,
                'Hesabı Sil',
                'Tüm verileri kalıcı sil',
                Colors.red,
                () =>
                    showDeleteAccountDialog(context, ref, state.userId ?? '')),
          ],
        ),
      );

  // --- HELPERS (Eski Tasarım Detayları) ---

  BoxDecoration _artisticContainerDecoration(final ThemeData theme) =>
      BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      );

  Widget _buildSectionTitle(final ThemeData theme, final String title) =>
      Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 12),
        child: Text(title,
            style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: Colors.grey)),
      );

  Widget _buildListTile(
          final ThemeData theme,
          final IconData icon,
          final String title,
          final String sub,
          final Color color,
          final VoidCallback onTap) =>
      ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12),
      );

  Widget _buildStatItem(
          final String v, final String l, final IconData i, final Color c) =>
      Column(
        children: [
          Icon(i, color: c),
          Text(v,
              style: TextStyle(
                  color: c, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(l, style: const TextStyle(fontSize: 12)),
        ],
      );

  Widget _buildLoginMethodBadge(final LoginState state, final ThemeData theme) {
    final method = state.loginMethod;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getLoginMethodIcon(method),
              size: 12, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(method.toUpperCase(),
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getLoginMethodIcon(final String method) {
    if (method == 'google') return Icons.g_mobiledata_rounded;
    if (method == 'phone') return Icons.phone_android;
    return Icons.person_outline;
  }
}
