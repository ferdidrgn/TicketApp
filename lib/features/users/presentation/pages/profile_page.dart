import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
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
  // Gölgeler ve renkler için getter'lar tanımlayarak metot parametrelerini azalttık
  Color get _lightShadow =>
      context.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white;

  Color get _darkShadow => context.isDarkMode
      ? Colors.black.withOpacity(0.5)
      : Colors.grey.withOpacity(0.4);

  Color get _bgColor => context.colors.surface;

  @override
  Widget build(final BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final userDetail = ref.watch(userProvider).dataSingle;
    final bool isUserLoggedIn = loginState.isLoggedIn;

    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomAppBackground(
        backgroundColor: _bgColor,
        ambientColor: Colors.black,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(25),
          child: SafeArea(
            child: Column(
              children: [
                _buildArtisticHeader(!isUserLoggedIn),
                const SizedBox(height: 32),

                // 1. KİMLİK PORTRESİ VEYA SESSİZ SAHNE DAVETİ
                if (isUserLoggedIn)
                  _buildNeumorphicPortrait(loginState, userDetail)
                else
                  _buildSilentStageInvitation(),

                const SizedBox(height: 40),

                // 2. ATMOSFER VE AYARLAR
                _buildSectionLabel("ATMOSFER VE TEKNİK"),
                const ThemeSelectorCard(),
                const SizedBox(height: 16),
                _buildSculptedTile(
                  icon: Icons.settings_suggest_rounded,
                  title: 'Atölye Ayarları',
                  subtitle: 'Bildirimler, dil ve teknik tercihler',
                  color: Colors.blueGrey,
                  onTap: () => context.push('/settings'),
                ),

                const SizedBox(height: 40),

                // 3. RUHUN İZLERİ
                _buildSectionLabel("RUHUN İZLERİ"),
                _buildSculptedTile(
                  icon: Icons.auto_stories_rounded,
                  title: 'Tanıklık Günlüğü',
                  subtitle: 'Sahne tozunu yuttuğun tüm anların dökümü',
                  isLocked: !isUserLoggedIn,
                  color: const Color(0xFF6366F1),
                  onTap: () => context.push('/my-tickets/${loginState.userId}'),
                ),
                const SizedBox(height: 16),
                _buildSculptedTile(
                  icon: Icons.auto_awesome_mosaic_rounded,
                  title: 'İlham Galerisi',
                  subtitle: 'Zihninde yankılanan seçilmiş eserler',
                  isLocked: !isUserLoggedIn,
                  color: const Color(0xFFEC4899),
                  onTap: () => context.push('/favorites'),
                ),

                const SizedBox(height: 40),

                // 4. KİMLİK ATÖLYESİ
                _buildSectionLabel("KİMLİK ATÖLYESİ"),

                _buildSculptedTile(
                  icon: Icons.brush_rounded,
                  title: 'Fırça İzlerim',
                  subtitle: 'Kendi portreni ve sanatsal kimliğini yorumla',
                  isLocked: !isUserLoggedIn,
                  color: context.colors.primary,
                  onTap: () =>
                      context.push('/profile-edit/${loginState.userId}'),
                ),
                const SizedBox(height: 16),
                _buildSculptedTile(
                  icon: Icons.map_rounded,
                  title: 'Serüven Rehberi',
                  subtitle: 'Soruların için küratörle temas kur',
                  color: const Color(0xFF10B981),
                  onTap: () => context.push('/help-support'),
                ),

                const SizedBox(height: 40),

                // 5. ATÖLYE YASALARI
                _buildSectionLabel("YASAL YÜKÜMLÜLÜKLER"),
                _buildSculptedTile(
                  icon: Icons.gavel_rounded,
                  title: 'Atölye Sözleşmesi',
                  subtitle: 'Kullanım şartları ve KVKK rehberi',
                  color: Colors.brown.shade400,
                  onTap: () => context.push('/contracts'),
                ),

                // 6. SİSTEMSEL KARARLAR
                if (isUserLoggedIn) ...[
                  const SizedBox(height: 40),
                  _buildSectionLabel("SON DOKUNUŞLAR"),
                  _buildSculptedTile(
                    icon: Icons.logout_rounded,
                    title: 'Atölyeyi Kapat',
                    subtitle: 'Serüveni şimdilik mühürle ve ayrıl',
                    color: Colors.orange.shade800,
                    onTap: () => showSignOutDialog(context, ref),
                  ),
                  const SizedBox(height: 16),
                  _buildSculptedTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Koleksiyonu Yak',
                    subtitle: 'Tüm izlerini ve hatıralarını kalıcı olarak sil',
                    color: Colors.red.shade900,
                    onTap: () => showDeleteAccountDialog(
                        context, ref, loginState.userId!),
                  ),
                ],

                _buildSoulReflection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MODÜLER YARDIMCI METOTLAR (Parametresiz ve Optimize) ---

  Widget _buildSculptedTile({
    required final IconData icon,
    required final String title,
    required final String subtitle,
    final bool isLocked = false,
    required final Color color,
    required final VoidCallback onTap,
  }) =>
      Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: GestureDetector(
          onTap: isLocked ? () => context.push('/login') : onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: _neuBox(borderRadius: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: _neuBox(borderRadius: 16, invert: true),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: context.colors.onSurface,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.colors.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Icon(
                    isLocked
                        ? Icons.lock_person_rounded
                        : Icons.chevron_right_rounded,
                    size: 24,
                    color: color.withOpacity(0.8)),
              ],
            ),
          ),
        ),
      );

  Widget _buildNeumorphicPortrait(
          final LoginState state, final entity.User? user) =>
      Container(
        padding: const EdgeInsets.all(32),
        decoration: _neuBox(borderRadius: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: _neuBox(borderRadius: 100, invert: true),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: context.colors.primary.withOpacity(0.1),
                backgroundImage: NetworkImage(state.photoUrl ?? ''),
              ),
            ),
            const SizedBox(height: 24),
            Text((state.displayName ?? 'İSİMSİZ ŞAHİT').toUpperCase(),
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: context.colors.onSurface,
                    letterSpacing: 2)),
            const SizedBox(height: 6),
            Text(user?.city ?? "Bilinmeyen Şehir",
                style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            const SizedBox(height: 32),
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

  Widget _buildStat(final String label, final String value) =>
      Column(children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: context.colors.onSurface)),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: context.colors.primary.withOpacity(0.8),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
      ]);

  Widget _buildSectionLabel(final String text) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 16, top: 8),
        child: Text(text,
            style: TextStyle(
                color: context.isDarkMode
                    ? context.colors.onPrimary
                    : context.colors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 3)),
      ));

  BoxDecoration _neuBox(
          {final double borderRadius = 15, final bool invert = false}) =>
      BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: invert
            ? [
                BoxShadow(
                    color: _darkShadow,
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                    spreadRadius: 1),
                BoxShadow(
                    color: _lightShadow,
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                    spreadRadius: 1),
              ]
            : [
                BoxShadow(
                    color: _darkShadow,
                    offset: const Offset(10, 10),
                    blurRadius: 20,
                    spreadRadius: 2),
                BoxShadow(
                    color: _lightShadow,
                    offset: const Offset(-10, -10),
                    blurRadius: 20,
                    spreadRadius: 2),
              ],
      );

  Widget _buildSilentStageInvitation() {
    // Dark modda bile canlı kalacak renk seçimi
    final Color buttonColor = context.isDarkMode
        ? context.colors.primaryContainer // Koyu modda daha tok ve canlı durur
        : context.colors.primary;

    // Butonun üzerindeki yazı rengi
    final Color buttonTextColor = context.isDarkMode
        ? context.colors.onPrimaryContainer
        : context.colors.onPrimary;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: _neuBox(borderRadius: 32),
      child: Column(
        children: [
          Icon(Icons.theater_comedy_rounded,
              size: 56, color: context.colors.primary.withOpacity(0.4)),
          const SizedBox(height: 24),
          const Text("SAHNE ŞİMDİLİK SESSİZ",
              style: TextStyle(
                  letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 12),
          const Text(
              "Işıkları açmak ve kendi hikayeni başlatmak için galerinin anahtarını teslim al.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.6)),
          const SizedBox(height: 32),

          // BUTON GÜNCELLEMESİ
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
              ),
              onPressed: () => context.push('/login'),
              child: const Text("SAHNEYİ UYANDIR",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 2))),
        ],
      ),
    );
  }

  Widget _buildArtisticHeader(final bool isGuest) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _neuBox(borderRadius: 100),
            child: Icon(Icons.auto_awesome,
                size: 32, color: context.colors.primary.withOpacity(0.4)),
          ),
          const SizedBox(height: 24),
          Text('DENEYİM KÜRATÖRÜ',
              style: context.textTheme.labelMedium?.copyWith(
                  letterSpacing: 5, fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 12),
          Text(
              isGuest
                  ? 'Kendi Hikayeni\nKaleme Al'
                  : 'Tanıklığın\nKarakterindir',
              textAlign: TextAlign.center,
              style: context.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: -0.5)),
        ],
      );

  Widget _buildSoulReflection() => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const Text("UNUTMA; GERÇEK SANAT ESERİ,\nİNSANIN KENDİ HAYATIDIR.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 2,
                    height: 1.5)),
            const SizedBox(height: 12),
            Text(
                "Tanık olduğun her sahne, ruhundaki o büyük yapbozun bir parçasıdır.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.5)),
          ],
        ),
      );
}
