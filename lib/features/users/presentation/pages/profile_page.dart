import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';
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
    final userDetail = ref.watch(userProvider).dataSingle;
    final theme = context.theme;
    final bool isUserLoggedIn = loginState.isLoggedIn;

    // Arka planı daha dolgun, gölgeleri daha belirgin yapıyoruz
    final Color bgColor = theme.colorScheme.surface;
    final Color lightShadow = context.isDarkMode
        ? Colors.white.withOpacity(0.1) // Karanlık modda biraz daha parlak ışık
        : Colors.white;
    final Color darkShadow = context.isDarkMode
        ? Colors.black.withOpacity(0.5) // Daha derin siyah gölge
        : Colors.grey.withOpacity(0.4);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomAppBackground(
        backgroundColor: bgColor,
        ambientColor: Colors.black,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: SafeArea(
            child: Column(
              children: [
                _buildArtisticHeader(theme, !isUserLoggedIn),
                const SizedBox(height: 40),
                if (isUserLoggedIn)
                  _buildNeumorphicPortrait(loginState, userDetail, theme,
                      bgColor, lightShadow, darkShadow)
                else
                  _buildSilentStageInvitation(
                      theme, bgColor, lightShadow, darkShadow),
                const SizedBox(height: 40),
                _buildSectionLabel(theme, "ATMOSFERİN IŞIĞI"),
                const ThemeSelectorCard(),
                const SizedBox(height: 40),
                _buildSectionLabel(theme, "RUHUN İZLERİ"),
                _buildSculptedTile(
                    theme: theme,
                    icon: Icons.auto_stories_rounded,
                    title: 'Tanıklık Günlüğü',
                    subtitle: 'Sahne tozunu yuttuğun tüm anların dökümü',
                    isLocked: !isUserLoggedIn,
                    color: const Color(0xFF6366F1),
                    // Daha canlı Indigo
                    bg: bgColor,
                    l: lightShadow,
                    d: darkShadow,
                    onTap: () =>
                        context.push('/my-tickets/${loginState.userId}')),
                const SizedBox(height: 20),
                _buildSculptedTile(
                    theme: theme,
                    icon: Icons.auto_awesome_mosaic_rounded,
                    title: 'İlham Galerisi',
                    subtitle: 'Zihninde yankılanan seçilmiş eserler',
                    isLocked: !isUserLoggedIn,
                    color: const Color(0xFFEC4899),
                    // Daha canlı Pink
                    bg: bgColor,
                    l: lightShadow,
                    d: darkShadow,
                    onTap: () => context.push('/favorites')),
                const SizedBox(height: 40),
                _buildSectionLabel(theme, "KİMLİK ATÖLYESİ"),
                _buildSculptedTile(
                    theme: theme,
                    icon: Icons.brush_rounded,
                    title: 'Fırça İzlerim',
                    subtitle: 'Kendi portreni ve sanatsal kimliğini yorumla',
                    isLocked: !isUserLoggedIn,
                    color: theme.colorScheme.primary,
                    bg: bgColor,
                    l: lightShadow,
                    d: darkShadow,
                    onTap: () =>
                        context.push('/profile-edit/${loginState.userId}')),
                const SizedBox(height: 20),
                _buildSculptedTile(
                    theme: theme,
                    icon: Icons.map_rounded,
                    title: 'Serüven Rehberi',
                    subtitle: 'Atölye kullanımı hakkında küratöre danış',
                    isLocked: false,
                    color: const Color(0xFF10B981),
                    // Daha canlı Emerald
                    bg: bgColor,
                    l: lightShadow,
                    d: darkShadow,
                    onTap: () => context.push('/help-support')),
                if (isUserLoggedIn) ...[
                  const SizedBox(height: 40),
                  _buildSectionLabel(theme, "SON DOKUNUŞLAR"),
                  _buildSculptedTile(
                      theme: theme,
                      icon: Icons.logout_rounded,
                      title: 'Atölyeyi Kapat',
                      subtitle: 'Serüveni şimdilik mühürle ve ayrıl',
                      isLocked: false,
                      color: Colors.orange.shade700,
                      bg: bgColor,
                      l: lightShadow,
                      d: darkShadow,
                      onTap: () => showSignOutDialog(context, ref)),
                ],
                _buildSoulReflection(theme),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- GELİŞTİRİLMİŞ TILE (Yazılar kalınlaştırıldı ve kontrast artırıldı) ---
  Widget _buildSculptedTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLocked,
    required Color color,
    required Color bg,
    required Color l,
    required Color d,
    VoidCallback? onTap,
  }) =>
      Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: GestureDetector(
          onTap: isLocked ? () => context.push('/login') : onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: _neuBox(bg, l, d, borderRadius: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: _neuBox(bg, l, d, borderRadius: 16, invert: true),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800, // Daha kalın font
                          fontSize: 16,
                          color: theme.colorScheme.onSurface, // Tam kontrast
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          // Okunabilir gri
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isLocked
                      ? Icons.lock_person_rounded
                      : Icons.chevron_right_rounded,
                  size: 24,
                  color: color.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      );

  // --- GELİŞTİRİLMİŞ PORTRE (Okunabilirlik Odaklı) ---
  Widget _buildNeumorphicPortrait(LoginState state, entity.User? user,
          ThemeData theme, Color bg, Color l, Color d) =>
      Container(
        padding: const EdgeInsets.all(32),
        decoration: _neuBox(bg, l, d, borderRadius: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: _neuBox(bg, l, d, borderRadius: 100, invert: true),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage: NetworkImage(state.photoUrl ?? ''),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              (state.displayName ?? 'İSİMSİZ ŞAHİT').toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: theme.colorScheme.onSurface,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user?.city ?? "Bilinmeyen Şehir",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(theme, 'HAFIZA', '${user?.ticketsId.length ?? 0}'),
                _buildStat(theme, 'ŞAHİTLİK', '12'),
                _buildStat(theme, 'DİKKAT', '8.9'),
              ],
            ),
          ],
        ),
      );

  Widget _buildStat(ThemeData theme, String label, String value) =>
      Column(children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.primary.withOpacity(0.8),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ]);

  Widget _buildSectionLabel(ThemeData theme, String text) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 16, top: 8),
        child: Text(
          text,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
            fontSize: 12, // Biraz büyütüldü
            letterSpacing: 3,
          ),
        ),
      ));

  // --- DAHA KESKİN GÖLGELİ NEUBOX ---
  BoxDecoration _neuBox(final Color bg, final Color l, final Color d,
          {final double borderRadius = 15, final bool invert = false}) =>
      BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: invert
            ? [
                BoxShadow(
                    color: d,
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                    spreadRadius: 1),
                BoxShadow(
                    color: l,
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                    spreadRadius: 1),
              ]
            : [
                BoxShadow(
                    color: d,
                    offset: const Offset(10, 10), // Gölge mesafesi artırıldı
                    blurRadius: 20,
                    spreadRadius: 2),
                BoxShadow(
                    color: l,
                    offset: const Offset(-10, -10),
                    blurRadius: 20,
                    spreadRadius: 2),
              ],
      );

// --- 🪄 SESSİZ SAHNE DAVETİYESİ (YENİ METAFOR) ---
  Widget _buildSilentStageInvitation(final ThemeData theme, final Color bg,
          final Color l, final Color d) =>
      Container(
        padding: const EdgeInsets.all(40),
        decoration: _neuBox(bg, l, d, borderRadius: 32),
        child: Column(
          children: [
            Icon(Icons.theater_comedy_rounded,
                size: 56, color: theme.colorScheme.primary.withOpacity(0.4)),
            const SizedBox(height: 24),
            const Text("SAHNE ŞİMDİLİK SESSİZ",
                style: TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
            const SizedBox(height: 12),
            const Text(
                "Işıkları açmak ve kendi hikayeni başlatmak için galerinin anahtarını teslim al.",
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey, fontSize: 12, height: 1.6)),
            const SizedBox(height: 32),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () => context.push('/login'),
                child: const Text("SAHNEYİ UYANDIR",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 2))),
          ],
        ),
      );

  Widget _buildArtisticHeader(final ThemeData theme, final bool isGuest) =>
      Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _neuBox(theme.colorScheme.surface,
                Colors.white.withOpacity(0.05), Colors.black.withOpacity(0.2),
                borderRadius: 100),
            child: Icon(Icons.auto_awesome,
                size: 32, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('DENEYİM KÜRATÖRÜ',
              style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 5, fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 12),
          Text(
            isGuest ? 'Kendi Hikayeni\nKaleme Al' : 'Tanıklığın\nKarakterindir',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5),
          ),
        ],
      );

  Widget _buildSoulReflection(final ThemeData theme) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const Text(
              "UNUTMA; GERÇEK SANAT ESERİ,\nİNSANIN KENDİ HAYATIDIR.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                  height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              "Tanık olduğun her sahne, ruhundaki o büyük yapbozun bir parçasıdır.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  height: 1.5),
            ),
          ],
        ),
      );
}
