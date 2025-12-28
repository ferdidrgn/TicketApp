import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
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
              // 1. GÖRKEMLİ ÜST KISIM
              _buildArtisticHeader(theme, !isUserLoggedIn),
              const SizedBox(height: 32),

              // 2. KİMLİK PORTRESİ VEYA SESSİZ SAHNE DAVETİ
              if (isUserLoggedIn)
                _buildNeumorphicPortrait(loginState, userDetail, theme, bgColor,
                    lightShadow, darkShadow)
              else
                _buildSilentStageInvitation(
                    theme, bgColor, lightShadow, darkShadow),

              const SizedBox(height: 40),

              // 3. IŞIK VE RENK AYARLARI
              _buildSectionLabel(theme, "ATMOSFERİN IŞIĞI"),
              const ThemeSelectorCard(),

              const SizedBox(height: 40),

              // 4. DENEYİM ARŞİVİ
              _buildSectionLabel(theme, "RUHUN İZLERİ"),
              _buildSculptedTile(
                  theme,
                  Icons.auto_stories_rounded,
                  'Tanıklık Günlüğü',
                  'Sahne tozunu yuttuğun tüm anların dökümü',
                  !isUserLoggedIn,
                  const Color(0xFF5D3FD3),
                  bgColor,
                  lightShadow,
                  darkShadow,
                  onTap: () =>
                      context.push('/my-tickets/${loginState.userId}')),
              const SizedBox(height: 16),
              _buildSculptedTile(
                  theme,
                  Icons.auto_awesome_mosaic_rounded,
                  'İlham Galerisi',
                  'Zihninde yankılanan seçilmiş eserler',
                  !isUserLoggedIn,
                  const Color(0xFFFF007F),
                  bgColor,
                  lightShadow,
                  darkShadow,
                  onTap: () => context.push('/favorites')),

              const SizedBox(height: 40),

              // 5. YARATICI ARAÇLAR
              _buildSectionLabel(theme, "KİMLİK ATÖLYESİ"),
              _buildSculptedTile(
                  theme,
                  Icons.brush_rounded,
                  'Fırça İzlerim',
                  'Kendi portreni ve sanatsal kimliğini yorumla',
                  !isUserLoggedIn,
                  theme.colorScheme.primary,
                  bgColor,
                  lightShadow,
                  darkShadow,
                  onTap: () =>
                      context.push('/profile-edit/${loginState.userId}')),
              const SizedBox(height: 16),
              _buildSculptedTile(
                  theme,
                  Icons.map_rounded,
                  'Serüven Rehberi',
                  'Atölye kullanımı hakkında küratöre danış',
                  false,
                  const Color(0xFF00A36C),
                  bgColor,
                  lightShadow,
                  darkShadow,
                  onTap: () => context.push('/help-support')),
              const SizedBox(height: 16),
              _buildSculptedTile(
                  theme,
                  Icons.gavel_rounded,
                  'Atölye Yasaları',
                  'Sanatsever topluluğunun etik ve yasal kuralları',
                  false,
                  Colors.blueGrey,
                  bgColor,
                  lightShadow,
                  darkShadow,
                  onTap: () => context.push('/legal')),

              // 6. SİSTEMSEL KARARLAR
              if (isUserLoggedIn) ...[
                const SizedBox(height: 40),
                _buildSectionLabel(theme, "SON DOKUNUŞLAR"),
                _buildSculptedTile(
                    theme,
                    Icons.logout_rounded,
                    'Atölyeyi Kapat',
                    'Serüveni şimdilik mühürle ve ayrıl',
                    false,
                    Colors.orange,
                    bgColor,
                    lightShadow,
                    darkShadow,
                    onTap: () => showSignOutDialog(context, ref)),
                const SizedBox(height: 16),
                _buildSculptedTile(
                    theme,
                    Icons.delete_forever_rounded,
                    'Koleksiyonu Yak',
                    'Tüm izlerini ve hatıralarını kalıcı olarak sil',
                    false,
                    Colors.red,
                    bgColor,
                    lightShadow,
                    darkShadow,
                    onTap: () => showDeleteAccountDialog(
                        context, ref, loginState.userId!)),
              ],

              // 7. RUH ÖĞRETİSİ
              _buildSoulReflection(theme),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

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

  // --- 🛠️ GIRINTILI ÇIKINTILI (NEUMORPHIC) TASARIMLAR ---
  Widget _buildSculptedTile(
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
            decoration: _neuBox(bg, l, d, borderRadius: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: _neuBox(bg, l, d, borderRadius: 14, invert: true),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500)),
                      ]),
                ),
                Icon(
                    isLocked
                        ? Icons.lock_person_outlined
                        : Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      );

  Widget _buildNeumorphicPortrait(
          final LoginState state,
          final entity.User? user,
          final ThemeData theme,
          final Color bg,
          final Color l,
          final Color d) =>
      Container(
        padding: const EdgeInsets.all(32),
        decoration: _neuBox(bg, l, d, borderRadius: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: _neuBox(bg, l, d, borderRadius: 100, invert: true),
              child: CircleAvatar(
                  radius: 55,
                  backgroundImage: NetworkImage(state.photoUrl ?? '')),
            ),
            const SizedBox(height: 24),
            Text((state.displayName ?? 'İSİMSİZ ŞAHİT').toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(user?.city ?? "Bilinmeyen Şehir",
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('HAFIZA', '${user?.ticketsId.length ?? 0}'),
                _buildStat('ŞAHİTLİK', '12'),
                _buildStat('DİKKAT', '8.9'),
              ],
            ),
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

  Widget _buildStat(final String label, final String value) =>
      Column(children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
      ]);

  Widget _buildSectionLabel(final ThemeData theme, final String text) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16, top: 8),
          child: Text(text,
              style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 3)),
        ),
      );

  BoxDecoration _neuBox(final Color bg, final Color l, final Color d,
          {final double borderRadius = 15, final bool invert = false}) =>
      BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: invert
            ? [
                BoxShadow(
                    color: d,
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                    spreadRadius: 0.5),
                BoxShadow(
                    color: l,
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                    spreadRadius: 0.5),
              ]
            : [
                BoxShadow(color: d, offset: const Offset(8, 8), blurRadius: 16),
                BoxShadow(
                    color: l, offset: const Offset(-8, -8), blurRadius: 16),
              ],
      );
}
