import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/features/appTools/presentation/pages/help_support_page.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../auth/presentation/widgets/sign_out_delete_handler.dart';
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
        TickerProviderStateMixin,
        ProfileSnackBarHandler,
        ProfileSignOutHandler,
        ProfileDeleteAccountHandler,
        ProfilePhoneLinkHandler,
        ProfileGoogleLinkHandler {
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

    // Neumorphic Gölgeler için Renk Hesaplama
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
                // 🎨 SANATSAL BAŞLIK - ORJİNAL BOYUT
                _buildArtisticHeader(theme, !isUserLoggedIn),

                const SizedBox(height: 32),

                // 🖼️ TUVAL PORTRE (Orjinal boyut korundu)
                if (isUserLoggedIn)
                  _buildCanvasPortraitCard(
                      loginState, theme, bgColor, lightShadow, darkShadow)
                else
                  _buildGalleryInvitation(
                      theme, bgColor, lightShadow, darkShadow),

                const SizedBox(height: 32),

                // 🎨 PALET SEÇİCİ
                _buildSectionHeader(theme, "TUVAL RENKLERİ"),
                ThemeSelectorCard(),

                const SizedBox(height: 32),

                // 📜 KOLEKSİYON DEFTERİ
                _buildSectionHeader(theme, "KOLEKSİYON DEFTERİ"),

                // 🖼️ SANATSAL BUTONLAR
                _buildArtisticActionList(loginState, theme, !isUserLoggedIn,
                    bgColor, lightShadow, darkShadow),

                const SizedBox(height: 32),

                // 🖌️ ATÖLYE KARARLARI
                _buildSectionHeader(theme, "ATÖLYE KARARLARI"),

                // ⚙️ GÜVENLİK BUTONLARI (Liste)
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

  // 🎨 SANATSAL BAŞLIK - Orjinal düzen
  Widget _buildArtisticHeader(final ThemeData theme, final bool isGuest) =>
      Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.08),
            ),
            child: Icon(Icons.palette_outlined,
                size: 28, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'ESTETİK HAFIZA • SENİN BAŞYAPITIN',
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
                : 'Görmenin Değil,\nTanık Olmanın Sanatı',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 28,
              height: 1.1,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
        ],
      );

  // 🖼️ TUVAL PORTRE KARTI
  Widget _buildCanvasPortraitCard(final LoginState state, final ThemeData theme,
      final Color bg, final Color light, final Color dark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _neuBox(bg, light, dark, borderRadius: 28),
      child: Column(
        children: [
          // Altın Çerçeveli Portre
          Stack(
            alignment: Alignment.center,
            children: [
              // Altın çerçeve efekti
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 3,
                  ),
                ),
              ),

              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
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
          const SizedBox(height: 20),

          // Sanatçı İmzası
          Text(
            (state.displayName ?? 'Anonim Sanatçı').toUpperCase(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontFamily: 'PlayfairDisplay',
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            state.email ?? 'sanatci@galeri.com',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          // Sergi Etiketi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Text(
              'AKTİF KOLEKSİYONER',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sergi İstatistikleri
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: bg.withOpacity(0.5),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildArtStat('Etkinlik Biletleri', '12',
                    Icons.confirmation_number_outlined),
                _buildArtStat('Koleksiyon', '42', Icons.auto_awesome_mosaic),
                _buildArtStat('Puan', '8.9', Icons.star_rate_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 GALERİ DAVET KARTI
  Widget _buildGalleryInvitation(final ThemeData theme, final Color bg,
      final Color light, final Color dark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _neuBox(bg, light, dark, borderRadius: 28),
      child: Column(
        children: [
          Icon(Icons.museum_outlined,
              size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          const Text('Galeriye Hoş Geldin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Koleksiyonun henüz başlamadı',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            child: const Text('GALERİYE KATIL'),
          ),
        ],
      ),
    );
  }

  // 📜 SANATSAL İŞLEVLER LİSTESİ
  // 📜 SANATSAL İŞLEVLER LİSTESİ - FAVORİ VE HELP EKLENDİ
  Widget _buildArtisticActionList(final LoginState state, final ThemeData theme,
      final bool isGuest, final Color bg, final Color light, final Color dark) {
    return Column(
      children: [
        if (!isGuest) ...[
          _buildArtisticTile(
            theme,
            Icons.edit_outlined,
            'Portremi Düzenle',
            'Sanatçı profilimi güncelle',
            const Color(0xFF9C27B0),
            bg,
            light,
            dark,
            () => context.push('/profile-edit/${state.userId}'),
          ),
          const SizedBox(height: 12),
          _buildArtisticTile(
            theme,
            Icons.confirmation_number_outlined,
            'Bilet Koleksiyonum',
            'Etkinlik biletlerimi gör',
            const Color(0xFF4CAF50),
            bg,
            light,
            dark,
            () => context.push('/my-tickets/${state.userId}'),
          ),
          const SizedBox(height: 12),
          _buildArtisticTile(
            theme,
            Icons.favorite_outlined,
            'Favori Eserlerim',
            'Beğendiğim tablolar',
            const Color(0xFFE91E63),
            bg,
            light,
            dark,
            () => context.push('/favorites'),
          ),
          const SizedBox(height: 12),
        ],
        _buildArtisticTile(
          theme,
          Icons.settings_outlined,
          'Galeri Ayarları',
          'Görünüm ve tercihler',
          const Color(0xFF2196F3),
          bg,
          light,
          dark,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (final _) => const AppSettingsPage())),
        ),
        const SizedBox(height: 12),
        _buildArtisticTile(
          theme,
          Icons.help_outline_outlined,
          'Yardım & Destek',
          'Sorularınız için',
          const Color(0xFFFF9800),
          bg,
          light,
          dark,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (final _) => const HelpSupportPage())),
        ),
      ],
    );
  }

  // 🖌️ ATÖLYE KARARLARI LİSTESİ
  Widget _buildStudioDecisionsList(
      final LoginState state,
      final ThemeData theme,
      final Color bg,
      final Color light,
      final Color dark) {
    return Column(
      children: [
        if (state.isGuest) ...[
          _buildArtisticTile(
            theme,
            Icons.save_outlined,
            'Koleksiyonumu Kaydet',
            'Google ile bağlan',
            const Color(0xFF4285F4),
            bg,
            light,
            dark,
            () => handleGoogleLink(context, ref),
          ),
          const SizedBox(height: 12),
        ],
        _buildArtisticTile(
          theme,
          Icons.logout_rounded,
          'Galeriden Ayrıl',
          'Oturumu sonlandır',
          const Color(0xFFFF9800),
          bg,
          light,
          dark,
          () => showSignOutDialog(context, ref),
        ),
        const SizedBox(height: 12),
        _buildArtisticTile(
          theme,
          Icons.delete_forever_outlined,
          'Koleksiyonumu Sil',
          'Tüm eserleri kaldır',
          const Color(0xFFF44336),
          bg,
          light,
          dark,
          () => showDeleteAccountDialog(context, ref, state.userId ?? ''),
        ),
      ],
    );
  }

  // 🎨 YARDIMCI WIDGET'LAR

  BoxDecoration _neuBox(final Color bg, final Color light, final Color dark,
      {final double borderRadius = 15, final bool isPressed = false}) {
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isPressed
          ? [
              // İçe gömülme efekti
              BoxShadow(
                  color: dark,
                  offset: const Offset(3, 3),
                  blurRadius: 5,
                  spreadRadius: -1),
              BoxShadow(
                  color: light,
                  offset: const Offset(-3, -3),
                  blurRadius: 5,
                  spreadRadius: -1),
            ]
          : [
              // Dışa kabarma efekti
              BoxShadow(
                  color: dark, offset: const Offset(8, 8), blurRadius: 16),
              BoxShadow(
                  color: light, offset: const Offset(-8, -8), blurRadius: 16),
            ],
    );
  }

  Widget _buildArtisticTile(
    final ThemeData theme,
    final IconData icon,
    final String title,
    final String subtitle,
    final Color color,
    final Color bg,
    final Color light,
    final Color dark,
    final VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _neuBox(bg, light, dark, borderRadius: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtStat(
      final String label, final String value, final IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.withOpacity(0.1),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 18, color: Colors.grey.withOpacity(0.7)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(final ThemeData theme, final String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 12),
        child: Text(title,
            style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: Colors.grey)),
      ),
    );
  }
}
