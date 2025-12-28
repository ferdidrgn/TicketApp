import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/features/appTools/presentation/pages/help_support_page.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../shared/widgets/card/theme_selector_card.dart';
import '../../../auth/presentation/widgets/sign_out_delete_handler.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../login/presentation/providers/login_state.dart';
import '../../domain/entities/user.dart' as entity;
import '../providers/user_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with
        TickerProviderStateMixin,
        ProfileSnackBarHandler,
        ProfileSignOutHandler,
        ProfileDeleteAccountHandler,
        ProfilePhoneLinkHandler,
        ProfileGoogleLinkHandler {
  @override
  Widget build(final BuildContext context) {
    final loginState = ref.watch(loginProvider);
    // ⚡ Firestore verilerini izliyoruz (Yaş, şehir gibi detaylar için)
    final userState = ref.watch(userProvider);
    final user = userState.dataSingle;
    final theme = context.theme;
    final bool isUserLoggedIn = loginState.isLoggedIn && !loginState.isGuest;

    final Color bgColor = theme.colorScheme.surface;
    final Color lightShadow =
        context.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white;
    final Color darkShadow = context.isDarkMode
        ? Colors.black.withOpacity(0.4)
        : Colors.grey.withOpacity(0.3);

    return Scaffold(
      body: CustomAppBackground(
        backgroundColor: bgColor,
        ambientColor: Colors.black,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: SafeArea(
            child: Column(
              children: [
                _buildArtisticHeader(theme, !isUserLoggedIn),
                const SizedBox(height: 32),
                if (isUserLoggedIn)
                  _buildCanvasPortraitCard(
                      loginState, user, theme, bgColor, lightShadow, darkShadow)
                else
                  _buildGalleryInvitation(
                      theme, bgColor, lightShadow, darkShadow),
                const SizedBox(height: 32),
                _buildSectionHeader(theme, "TUVAL RENKLERİ"),
                ThemeSelectorCard(),
                const SizedBox(height: 32),
                _buildSectionHeader(theme, "KOLEKSİYON DEFTERİ"),
                _buildArtisticActionList(loginState, theme, !isUserLoggedIn,
                    bgColor, lightShadow, darkShadow),
                const SizedBox(height: 32),
                _buildSectionHeader(theme, "ATÖLYE KARARLARI"),
                _buildStudioDecisionsList(
                    loginState, theme, bgColor, lightShadow, darkShadow),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 🎨 SANATSAL YARDIMCI METODLAR ---

  Widget _buildArtisticHeader(final ThemeData theme, final bool isGuest) =>
      Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.08)),
            child: Icon(Icons.palette_outlined,
                size: 28, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text('ESTETİK HAFIZA • SENİN BAŞYAPITIN',
              style: theme.textTheme.labelMedium
                  ?.copyWith(letterSpacing: 4, fontSize: 10)),
          const SizedBox(height: 12),
          Text(
              isGuest
                  ? 'Kendi Başyapıtını\nKeşfetmeye Başla'
                  : 'Görmenin Değil,\nTanık Olmanın Sanatı',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w800, fontSize: 28)),
        ],
      );

  Widget _buildCanvasPortraitCard(
      final LoginState state,
      final entity.User? userDetail, // EKLENDİ
      final ThemeData theme,
      final Color bg,
      final Color light,
      final Color dark) {
    final badge = _getUserBadge(state);

    final String currentDisplayName =
        LocalStorageService.displayName ?? state.displayName ?? 'ANONİM';
    final String currentPhotoUrl = LocalStorageService.photoUrl ??
        state.photoUrl ??
        'https://via.placeholder.com/150';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _neuBox(bg, light, dark, borderRadius: 28),
      child: Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: badge.color.withOpacity(0.2),
            child: ClipOval(
                child: OptimizedCachedImage(
                    imageUrl: currentPhotoUrl)), // ⚡ Yerel URL kullanıldı
          ),
          const SizedBox(height: 20),
          Text(currentDisplayName.toUpperCase(), // ⚡ Yerel İsim kullanıldı
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

          const SizedBox(height: 8),
          // ⚡ Firestore'dan gelen ek bilgiler (Şehir)
          if (userDetail != null && userDetail.city.isNotEmpty)
            Text(userDetail.city,
                style: TextStyle(color: Colors.grey, fontSize: 12)),

          const SizedBox(height: 16),
          _buildBadgeWidget(badge),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ⚡ Bilet sayısını Firestore nesnesinden (userDetail) çekebilirsin
              _buildArtStat('Biletler', '${userDetail?.ticketsId.length ?? 0}',
                  Icons.confirmation_number_outlined),
              _buildArtStat('Eserler', '42', Icons.auto_awesome_mosaic),
              _buildArtStat('Puan', '8.9', Icons.star_rate_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeWidget(final _UserBadgeInfo badge) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
            color: badge.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badge.color.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(badge.icon, size: 12, color: badge.color),
          const SizedBox(width: 8),
          Text(badge.label,
              style: TextStyle(
                  color: badge.color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _buildGalleryInvitation(final ThemeData theme, final Color bg,
      final Color light, final Color dark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: _neuBox(bg, light, dark, borderRadius: 28),
      child: Column(
        children: [
          // Sanatsal İkon Grubu
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.05),
                ),
              ),
              Icon(Icons.auto_awesome,
                  size: 40, color: theme.colorScheme.primary.withOpacity(0.5)),
              const Positioned(
                right: 10,
                top: 10,
                child: Icon(Icons.lock_outline, size: 20, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "ANILARINI ÖLÜMSÜZLEŞTİR",
            style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          Text(
            "Biletlerini saklamak, favori etkinliklerini takip etmek ve sana özel bir sanat günlüğü oluşturmak için giriş yap.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Hızlı Giriş Butonları
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => context.push('/login'),
                  child: const Text('GİRİŞ YAP'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.push('/phone-login'),
            child: Text('Telefon ile devam et',
                style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildArtisticActionList(final LoginState state, final ThemeData theme,
      final bool isGuest, final Color bg, final Color light, final Color dark) {
    return Column(
      children: [
        // Her zaman açık olan: Yardım & Destek
        _buildArtisticTile(
            theme,
            Icons.help_outline_outlined,
            'Yardım & Destek',
            'Sorularınız için bizimle iletişime geçin',
            const Color(0xFFFF9800),
            bg,
            light,
            dark,
            () => context.push('/help-support')),

        const SizedBox(height: 12),

        // Kilitli Özellik: Bilet Koleksiyonu
        _buildLockedTile(
            theme,
            Icons.confirmation_number_outlined,
            'Bilet Koleksiyonum',
            'Tüm biletlerin burada sergilenir',
            isGuest,
            bg,
            light,
            dark),

        const SizedBox(height: 12),

        // Kilitli Özellik: Favoriler
        _buildLockedTile(
            theme,
            Icons.favorite_border_rounded,
            'Beğendiğim Eserler',
            'İlham aldığın etkinlikler',
            isGuest,
            bg,
            light,
            dark),
      ],
    );
  }

// Kilitli Liste Elemanı Tasarımı
  Widget _buildLockedTile(
      final ThemeData theme,
      final IconData icon,
      final String title,
      final String subtitle,
      final bool isLocked,
      final Color bg,
      final Color light,
      final Color dark) {
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: isLocked ? () => context.push('/login') : null,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: _neuBox(bg, light, dark, borderRadius: 18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.withOpacity(0.1),
                child: Icon(icon, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (isLocked)
                const Icon(Icons.lock_outline_rounded,
                    size: 16, color: Colors.grey)
              else
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudioDecisionsList(
          final LoginState state,
          final ThemeData theme,
          final Color bg,
          final Color light,
          final Color dark) =>
      Column(
        children: [
          _buildArtisticTile(
              theme,
              Icons.logout_rounded,
              'Galeriden Ayrıl',
              'Oturumu sonlandır',
              const Color(0xFFFF9800),
              bg,
              light,
              dark,
              () => showSignOutDialog(context, ref)),
          const SizedBox(height: 12),
          _buildArtisticTile(
              theme,
              Icons.delete_forever_outlined,
              'Koleksiyonumu Sil',
              'Eserleri kaldır',
              const Color(0xFFF44336),
              bg,
              light,
              dark,
              () => showDeleteAccountDialog(context, ref, state.userId ?? '')),
        ],
      );

  Widget _buildArtisticTile(
          final ThemeData theme,
          final IconData icon,
          final String title,
          final String subtitle,
          final Color color,
          final Color bg,
          final Color light,
          final Color dark,
          final VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: _neuBox(bg, light, dark, borderRadius: 18),
          child: Row(children: [
            CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey))
                ])),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey),
          ]),
        ),
      );

  Widget _buildArtStat(
          final String label, final String value, final IconData icon) =>
      Column(children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ]);

  Widget _buildSectionHeader(final ThemeData theme, final String title) =>
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(title,
                style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey))),
      );

  BoxDecoration _neuBox(final Color bg, final Color light, final Color dark,
          {final double borderRadius = 15}) =>
      BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(color: dark, offset: const Offset(8, 8), blurRadius: 16),
          BoxShadow(color: light, offset: const Offset(-8, -8), blurRadius: 16)
        ],
      );

  _UserBadgeInfo _getUserBadge(final LoginState state) {
    if (state.userRole == 'admin')
      return const _UserBadgeInfo(
          label: 'BAŞ KÜRATÖR',
          icon: Icons.verified_user_rounded,
          color: Color(0xFFD4AF37));
    if (state.isGuest)
      return const _UserBadgeInfo(
          label: 'ZİYARETÇİ',
          icon: Icons.visibility_outlined,
          color: Colors.grey);
    return const _UserBadgeInfo(
        label: 'AKTİF KOLEKSİYONER',
        icon: Icons.brush_rounded,
        color: Color(0xFF4CAF93));
  }
}

class _UserBadgeInfo {
  final String label;
  final IconData icon;
  final Color color;

  const _UserBadgeInfo(
      {required this.label, required this.icon, required this.color});
}
