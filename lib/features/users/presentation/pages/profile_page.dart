import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import '../../../../shared/widgets/card/theme_selector_card.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../auth/presentation/widgets/sign_out_delete_handler.dart';
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
    final userDetail = ref.watch(userProvider).dataSingle;
    final theme = context.theme;
    final bool isUserLoggedIn = loginState.isLoggedIn;

    final Color bgColor = theme.colorScheme.surface;
    final Color lightShadow =
        context.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white;
    final Color darkShadow = context.isDarkMode
        ? Colors.black.withOpacity(0.4)
        : Colors.grey.withOpacity(0.3);

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: SafeArea(
          child: Column(
            children: [
              // 1. GÖRKEMLİ ÜST KISIM (İkon ve Sanatsal Başlık)
              _buildArtisticHeader(theme, !isUserLoggedIn),
              const SizedBox(height: 32),

              // 2. KİMLİK PORTRESİ VEYA DAVETİYE
              if (isUserLoggedIn)
                _buildPortraitCard(loginState, userDetail, theme, bgColor,
                    lightShadow, darkShadow)
              else
                _buildGalleryInvitation(
                    theme, bgColor, lightShadow, darkShadow),

              const SizedBox(height: 32),

              // 3. TUVAL RENKLERİ (Tema Seçici Kartın - 3 Butonlu Eski Hali)
              _buildSectionHeader(theme, "TUVAL RENKLERİ"),
              const ThemeSelectorCard(),

              const SizedBox(height: 32),

              // 4. KOLEKSİYON DEFTERİ (Metaforik Butonlar)
              _buildSectionHeader(theme, "KOLEKSİYON DEFTERİ"),
              _buildTile(
                  theme,
                  Icons.history_edu_outlined,
                  'Hafıza Kayıtlarım',
                  'Tanık olduğun sahnelerin dökümü',
                  !isUserLoggedIn,
                  const Color(0xFF4CAF50),
                  bgColor,
                  lightShadow,
                  darkShadow,
                  onTap: () =>
                      context.push('/my-tickets/${loginState.userId}')),
              const SizedBox(height: 12),
              _buildTile(
                  theme,
                  Icons.auto_awesome_mosaic_outlined,
                  'İlham Odası',
                  'Ruhuna dokunan favori başyapıtlar',
                  !isUserLoggedIn,
                  const Color(0xFF9C27B0),
                  bgColor,
                  lightShadow,
                  darkShadow,
                  onTap: () => context.push('/favorites')),

              const SizedBox(height: 32),

              // 5. ATÖLYE AYARLARI
              _buildSectionHeader(theme, "ATÖLYE AYARLARI"),
              _buildTile(
                  theme,
                  Icons.brush_outlined,
                  'Fırça Darbelerim',
                  'Profilini ve portreni yeniden yorumla',
                  !isUserLoggedIn,
                  theme.colorScheme.primary,
                  bgColor,
                  lightShadow,
                  darkShadow,
                  onTap: () =>
                      context.push('/profile-edit/${loginState.userId}')),
              const SizedBox(height: 12),
              _buildTile(
                  theme,
                  Icons.map_outlined,
                  'Sanat Rehberi',
                  'Soruların için küratörle iletişime geç',
                  false,
                  const Color(0xFFFF9800),
                  bgColor,
                  lightShadow,
                  darkShadow,
                  onTap: () => context.push('/help-support')),
              const SizedBox(height: 12),
              _buildTile(
                  theme,
                  Icons.gavel_outlined,
                  'Atölye Sözleşmesi',
                  'Yasal haklar ve kurallar rehberi',
                  false,
                  Colors.blueGrey,
                  bgColor,
                  lightShadow,
                  darkShadow,
                  onTap: () => context.push('/legal')),

              // 6. ATÖLYE KARARLARI (Sadece giriş yapmışsa görünür)
              if (isUserLoggedIn) ...[
                const SizedBox(height: 32),
                _buildSectionHeader(theme, "ATÖLYE KARARLARI"),
                _buildTile(
                    theme,
                    Icons.logout_rounded,
                    'Galeriyi Terk Et',
                    'Oturumu güvenle sonlandır',
                    false,
                    Colors.orange,
                    bgColor,
                    lightShadow,
                    darkShadow,
                    onTap: () => showSignOutDialog(context, ref)),
                const SizedBox(height: 12),
                _buildTile(
                    theme,
                    Icons.delete_forever_outlined,
                    'Koleksiyonu İmha Et',
                    'Tüm eserleri ve kayıtları kalıcı olarak sil',
                    false,
                    Colors.red,
                    bgColor,
                    lightShadow,
                    darkShadow,
                    onTap: () => showDeleteAccountDialog(
                        context, ref, loginState.userId!)),
              ],

              // 7. ANLAMLI KAPANIŞ
              _buildClosingQuote(theme),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // --- 🎨 YARDIMCI METODLAR ---

  Widget _buildArtisticHeader(final ThemeData theme, final bool isGuest) =>
      Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 5)
                ]),
            child: Icon(Icons.palette_outlined,
                size: 40, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 20),
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
                ?.copyWith(fontWeight: FontWeight.w900, fontSize: 28),
          ),
        ],
      );

  Widget _buildPortraitCard(
          final LoginState state,
          final entity.User? user,
          final ThemeData theme,
          final Color bg,
          final Color l,
          final Color d) =>
      Container(
        padding: const EdgeInsets.all(24),
        decoration: _neuBox(bg, l, d, borderRadius: 28),
        child: Column(
          children: [
            CircleAvatar(
                radius: 55,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage: NetworkImage(state.photoUrl ?? '')),
            const SizedBox(height: 20),
            Text((state.displayName ?? 'SANATSEVER').toUpperCase(),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (user?.city != null)
              Text(user!.city,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Biletler', '${user?.ticketsId.length ?? 0}'),
                _buildStat('Eserler', '42'),
                _buildStat('Puan', '8.9'),
              ],
            ),
          ],
        ),
      );

  Widget _buildTile(
          final ThemeData theme,
          final IconData icon,
          final String title,
          final String subtitle,
          final bool isLocked,
          final Color color,
          final Color bg,
          final Color l,
          final Color d,
          {final VoidCallback? onTap}) =>
      Opacity(
        opacity: isLocked ? 0.4 : 1.0,
        child: GestureDetector(
          onTap: isLocked ? () => context.push('/login') : onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: _neuBox(bg, l, d, borderRadius: 20),
            child: Row(
              children: [
                CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(icon, color: color, size: 20)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ]),
                ),
                Icon(
                    isLocked
                        ? Icons.lock_person_outlined
                        : Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey),
              ],
            ),
          ),
        ),
      );

  Widget _buildClosingQuote(final ThemeData theme) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const Text(
              "\"Sanat, ruhun üzerindeki günlük yaşamın tozunu siler.\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text("- Pablo Picasso",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: theme.colorScheme.primary.withOpacity(0.7))),
          ],
        ),
      );

  Widget _buildGalleryInvitation(final ThemeData theme, final Color bg,
          final Color l, final Color d) =>
      Container(
        padding: const EdgeInsets.all(32),
        decoration: _neuBox(bg, l, d, borderRadius: 28),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome, size: 40, color: Colors.grey),
            const SizedBox(height: 24),
            const Text("ANILARINI ÖLÜMSÜZLEŞTİR",
                style:
                    TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
                onPressed: () => context.push('/login'),
                child: const Text("GALERİYE KATIL")),
          ],
        ),
      );

  Widget _buildStat(final String label, final String value) =>
      Column(children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ]);

  Widget _buildSectionHeader(final ThemeData theme, final String title) =>
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
          child: Text(title,
              style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
        ),
      );

  BoxDecoration _neuBox(final Color bg, final Color l, final Color d,
          {final double borderRadius = 15}) =>
      BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(color: d, offset: const Offset(8, 8), blurRadius: 16),
          BoxShadow(color: l, offset: const Offset(-8, -8), blurRadius: 16),
        ],
      );
}
