import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/core/util/global_scroll_mixin.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/card/theme_selector_card.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../auth/presentation/widgets/sign_out_delete_handler.dart';
import '../../../users/domain/entities/user.dart' as entity;
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
        ProfileGoogleLinkHandler,
        GlobalScrollMixin {
  // Gölgeler ve renkler için getter'lar tanımlayarak metot parametrelerini azalttık.
  // Tema paletindeki `surface`/`shadow` tonlarından türetilir — ham
  // `Colors.grey`/`Colors.black` yok.
  Color get _lightShadow => context.isDarkMode
      ? context.colors.onSurface.withOpacity(0.08)
      : context.colors.surface;

  Color get _darkShadow => context.isDarkMode
      ? context.colors.shadow.withOpacity(0.5)
      : context.colors.shadow.withOpacity(0.35);

  Color get _bgColor => context.colors.surface;

  @override
  void onLoadMore() {}

  @override
  Widget build(final BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    // 🖥️ Masaüstü/web: mobil zırhı (gradient başlık, FAB, parçacık
    // arkaplanı) tamamen atlanır, kendi sade web kabuğu kullanılır.
    if (context.isDesktop) {
      return _buildDesktopPage(context, userProfileAsync);
    }

    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return BasePageWrapper(
        showBackButton: false,
        showFab: true,
        rightIcon: Icons.auto_awesome,
        isLoading: userProfileAsync.isLoading,
        customScrollController: scrollController,
        layoutConfig: BasePageLayoutConfig(
            backgroundColor: context.colors.surface,
            ambientColor: context.colors.shadow.withOpacity(0.05)),
        child: userProfileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (final err, final stack) =>
                Center(child: Text("Hata: $err")),
            data: (final userData) {
              final bool isLoggedIn = userData != null;

              return Center(
                  child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: isLargeScreen ? 1100 : double.infinity),
                      child: CustomScrollView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(25),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                const SizedBox(height: AppSpacing.xl),
                                _buildArtisticHeader(!isLoggedIn),

                                if (isLoggedIn)
                                  _buildNeumorphicPortrait(userData)
                                else
                                  _buildSilentStageInvitation(),

                                const SizedBox(height: AppSpacing.huge),

                                _buildSectionLabel("ATMOSFER VE TEKNİK"),
                                const ThemeSelectorCard(),
                                const SizedBox(height: AppSpacing.lg),
                                _buildSculptedTile(
                                  icon: Icons.settings_suggest_rounded,
                                  title: 'Atölye Ayarları',
                                  subtitle:
                                      'Bildirimler, dil ve teknik tercihler',
                                  color: Colors.blueGrey,
                                  onTap: () =>
                                      NavigationHandler.goToSettings(context),
                                ),

                                const SizedBox(height: AppSpacing.huge),

                                _buildSectionLabel("RUHUN İZLERİ"),
                                _buildSculptedTile(
                                  icon: Icons.auto_stories_rounded,
                                  title: 'Tanıklık Günlüğü',
                                  subtitle:
                                      'Sahne tozunu yuttuğun tüm anların dökümü',
                                  isLocked: !isLoggedIn,
                                  color: const Color(0xFF6366F1),
                                  onTap: () => NavigationHandler.goToMyTickets(
                                      context, userData?.id ?? ""),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _buildSculptedTile(
                                  icon: Icons.auto_awesome_mosaic_rounded,
                                  title: 'İlham Galerisi',
                                  subtitle:
                                      'Zihninde yankılanan seçilmiş eserler',
                                  isLocked: !isLoggedIn,
                                  color: const Color(0xFFEC4899),
                                  onTap: () =>
                                      NavigationHandler.goToFavorites(context),
                                ),

                                const SizedBox(height: AppSpacing.huge),

                                _buildSectionLabel("KİMLİK ATÖLYESİ"),
                                _buildSculptedTile(
                                  icon: Icons.brush_rounded,
                                  title: 'Fırça İzlerim',
                                  subtitle:
                                      'Kendi portreni ve sanatsal kimliğini yorumla',
                                  isLocked: !isLoggedIn,
                                  color: context.colors.primary,
                                  onTap: () => context.push(
                                      '/profile-edit/${userData?.id ?? ""}'),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _buildSculptedTile(
                                  icon: Icons.map_rounded,
                                  title: 'Serüven Rehberi',
                                  subtitle:
                                      'Soruların için küratörle temas kur',
                                  color: const Color(0xFF10B981),
                                  onTap: () =>
                                      NavigationHandler.goToHelpSupport(
                                          context),
                                ),

                                const SizedBox(height: AppSpacing.huge),

                                _buildSectionLabel("YASAL YÜKÜMLÜLÜKLER"),
                                _buildSculptedTile(
                                  icon: Icons.gavel_rounded,
                                  title: 'Atölye Sözleşmesi',
                                  subtitle: 'Kullanım şartları ve KVKK rehberi',
                                  color: Colors.brown.shade400,
                                  onTap: () =>
                                      NavigationHandler.goToContracts(context),
                                ),

                                if (isLoggedIn) ...[
                                  const SizedBox(height: AppSpacing.huge),
                                  _buildSectionLabel("SON DOKUNUŞLAR"),
                                  _buildSculptedTile(
                                    icon: Icons.logout_rounded,
                                    title: 'Atölyeyi Kapat',
                                    subtitle:
                                        'Serüveni şimdilik mühürle ve ayrıl',
                                    color: Colors.orange.shade800,
                                    onTap: () =>
                                        showSignOutDialog(context, ref),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildSculptedTile(
                                    icon: Icons.delete_forever_rounded,
                                    title: 'Koleksiyonu Yak',
                                    subtitle:
                                        'Tüm izlerini ve hatıralarını kalıcı olarak sil',
                                    color: Colors.red.shade900,
                                    onTap: () => showDeleteAccountDialog(
                                        context, ref, userData.id),
                                  ),
                                ],

                                _buildSoulReflection(),
                                const SizedBox(height: 120),
                                // Scroll rahatlığı için pay
                              ]),
                            ),
                          ),
                        ],
                      )));
            }));
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
      Semantics(
        button: true,
        label: isLocked ? '$title (kilitli). $subtitle' : '$title. $subtitle',
        child: Opacity(
          opacity: isLocked ? 0.5 : 1.0,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: isLocked
                  ? () => NavigationHandler.goToLogin(context)
                  : onTap,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: _neuBox(borderRadius: AppRadius.lg),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration:
                          _neuBox(borderRadius: AppRadius.md, invert: true),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(width: AppSpacing.xl),
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
                          const SizedBox(height: AppSpacing.xs),
                          Text(subtitle,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.onSurface
                                      .withOpacity(0.7),
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
          ),
        ),
      );

  Widget _buildNeumorphicPortrait(final entity.User user) => Container(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        decoration: _neuBox(borderRadius: AppRadius.xl),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: _neuBox(borderRadius: AppRadius.pill, invert: true),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: context.colors.primary.withOpacity(0.1),
                backgroundImage: NetworkImage(user.imageUrl),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text('${user.firstName} ${user.lastName}'.toUpperCase().trim(),
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: context.colors.onSurface,
                    letterSpacing: 2)),
            const SizedBox(height: 6),
            Text(user.city,
                style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            const SizedBox(height: AppSpacing.xxxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('HAFIZA', '${user.ticketsId.length}'),
                _buildStat('ŞAHİTLİK', '${user.favoriteShows.length}'),
                _buildStat('DİKKAT', '${user.favoritePlayers.length}'),
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
        padding: const EdgeInsets.only(
            left: AppSpacing.xs, bottom: AppSpacing.lg, top: AppSpacing.sm),
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
          {final double borderRadius = AppRadius.sm,
          final bool invert = false}) =>
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
      padding: const EdgeInsets.all(AppSpacing.huge),
      decoration: _neuBox(borderRadius: AppRadius.xl),
      child: Column(
        children: [
          Icon(Icons.theater_comedy_rounded,
              size: 56, color: context.colors.primary.withOpacity(0.4)),
          const SizedBox(height: AppSpacing.xxl),
          const Text("SAHNE ŞİMDİLİK SESSİZ",
              style: TextStyle(
                  letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: AppSpacing.md),
          Text(
              "Işıkları açmak ve kendi hikayeni başlatmak için galerinin anahtarını teslim al.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.6)),
          const SizedBox(height: AppSpacing.xxxl),

          // BUTON GÜNCELLEMESİ
          Semantics(
            button: true,
            label: 'Sahneyi uyandır, giriş yap',
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  elevation: 0,
                  backgroundColor: buttonColor,
                  foregroundColor: buttonTextColor,
                ),
                onPressed: () => NavigationHandler.goToLogin(context),
                child: const Text("SAHNEYİ UYANDIR",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 2))),
          ),
        ],
      ),
    );
  }

  Widget _buildArtisticHeader(final bool isGuest) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: _neuBox(borderRadius: AppRadius.pill),
            child: Icon(Icons.auto_awesome,
                size: 32, color: context.colors.primary.withOpacity(0.4)),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('DENEYİM KÜRATÖRÜ',
              style: context.textTheme.labelMedium?.copyWith(
                  letterSpacing: 5,
                  fontSize: 10,
                  color: context.colors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.md),
            Text(
                "Tanık olduğun her sahne, ruhundaki o büyük yapbozun bir parçasıdır.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: context.colors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.5)),
          ],
        ),
      );

  // --- 🖥️ MASAÜSTÜ / WEB KABUĞU ---
  // Aynı provider verisi, aynı navigasyon/sign-out/delete akışları; sadece
  // mobil "neumorphic" kabuğun yerini sade, WebColors temalı bir kabuk alır.
  Widget _buildDesktopPage(
    final BuildContext context,
    final AsyncValue<entity.User?> userProfileAsync,
  ) =>
      ColoredBox(
        color: WebColors.darkBlueBackground,
        child: userProfileAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: WebColors.primaryGold)),
          error: (final err, final stack) => Center(
            child: Text('Hata: $err',
                style: const TextStyle(color: WebColors.whiteText)),
          ),
          data: (final userData) {
            final bool isLoggedIn = userData != null;
            return ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxxl, vertical: 56),
                      child: Column(
                        children: [
                          _buildDesktopHeader(!isLoggedIn),
                          const SizedBox(height: AppSpacing.xxxl),
                          if (isLoggedIn)
                            _buildDesktopPortrait(userData)
                          else
                            _buildDesktopInvitation(context),
                          const SizedBox(height: AppSpacing.massive),
                          _buildDesktopSectionLabel('ATMOSFER VE TEKNİK'),
                          const SizedBox(height: AppSpacing.lg),
                          const ThemeSelectorCard(),
                          const SizedBox(height: AppSpacing.md),
                          _buildDesktopTile(
                            context,
                            icon: Icons.settings_suggest_rounded,
                            title: 'Atölye Ayarları',
                            subtitle: 'Bildirimler, dil ve teknik tercihler',
                            onTap: () =>
                                NavigationHandler.goToSettings(context),
                          ),
                          const SizedBox(height: AppSpacing.huge),
                          _buildDesktopSectionLabel('RUHUN İZLERİ'),
                          const SizedBox(height: AppSpacing.lg),
                          _buildDesktopTile(
                            context,
                            icon: Icons.auto_stories_rounded,
                            title: 'Tanıklık Günlüğü',
                            subtitle:
                                'Sahne tozunu yuttuğun tüm anların dökümü',
                            isLocked: !isLoggedIn,
                            onTap: () => NavigationHandler.goToMyTickets(
                                context, userData?.id ?? ""),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildDesktopTile(
                            context,
                            icon: Icons.auto_awesome_mosaic_rounded,
                            title: 'İlham Galerisi',
                            subtitle: 'Zihninde yankılanan seçilmiş eserler',
                            isLocked: !isLoggedIn,
                            onTap: () =>
                                NavigationHandler.goToFavorites(context),
                          ),
                          const SizedBox(height: AppSpacing.huge),
                          _buildDesktopSectionLabel('KİMLİK ATÖLYESİ'),
                          const SizedBox(height: AppSpacing.lg),
                          _buildDesktopTile(
                            context,
                            icon: Icons.brush_rounded,
                            title: 'Fırça İzlerim',
                            subtitle:
                                'Kendi portreni ve sanatsal kimliğini yorumla',
                            isLocked: !isLoggedIn,
                            onTap: () => context
                                .push('/profile-edit/${userData?.id ?? ""}'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildDesktopTile(
                            context,
                            icon: Icons.map_rounded,
                            title: 'Serüven Rehberi',
                            subtitle: 'Soruların için küratörle temas kur',
                            onTap: () =>
                                NavigationHandler.goToHelpSupport(context),
                          ),
                          const SizedBox(height: AppSpacing.huge),
                          _buildDesktopSectionLabel('YASAL YÜKÜMLÜLÜKLER'),
                          const SizedBox(height: AppSpacing.lg),
                          _buildDesktopTile(
                            context,
                            icon: Icons.gavel_rounded,
                            title: 'Atölye Sözleşmesi',
                            subtitle: 'Kullanım şartları ve KVKK rehberi',
                            onTap: () =>
                                NavigationHandler.goToContracts(context),
                          ),
                          if (isLoggedIn) ...[
                            const SizedBox(height: AppSpacing.huge),
                            _buildDesktopSectionLabel('SON DOKUNUŞLAR'),
                            const SizedBox(height: AppSpacing.lg),
                            _buildDesktopTile(
                              context,
                              icon: Icons.logout_rounded,
                              title: 'Atölyeyi Kapat',
                              subtitle: 'Serüveni şimdilik mühürle ve ayrıl',
                              onTap: () => showSignOutDialog(context, ref),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildDesktopTile(
                              context,
                              icon: Icons.delete_forever_rounded,
                              title: 'Koleksiyonu Yak',
                              subtitle:
                                  'Tüm izlerini ve hatıralarını kalıcı olarak sil',
                              onTap: () => showDeleteAccountDialog(
                                  context, ref, userData.id),
                            ),
                          ],
                          const SizedBox(height: 56),
                          _buildDesktopReflection(),
                          const SizedBox(height: AppSpacing.huge),
                        ],
                      ),
                    ),
                  ),
                ),
                const Footer(),
              ],
            );
          },
        ),
      );

  Widget _buildDesktopHeader(final bool isGuest) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DENEYİM KÜRATÖRÜ',
              style: TextStyle(
                  color: WebColors.textTertiary,
                  letterSpacing: 4,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            isGuest ? 'Kendi Hikayeni Kaleme Al' : 'Tanıklığın Karakterindir',
            style: const TextStyle(
                color: WebColors.whiteText,
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -0.5),
          ),
        ],
      );

  Widget _buildDesktopPortrait(final entity.User user) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: WebColors.cardGradient,
          borderRadius: AppRadius.asymLg,
          border:
              Border.all(color: WebColors.darkBlueAccent.withOpacity(0.8)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: WebColors.darkBlueAccent,
              backgroundImage: NetworkImage(user.imageUrl),
            ),
            const SizedBox(width: AppSpacing.xxl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user.firstName} ${user.lastName}'.trim(),
                      style: const TextStyle(
                          color: WebColors.whiteText,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(user.city,
                      style: const TextStyle(
                          color: WebColors.primaryGoldLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
            _buildDesktopStat('HAFIZA', '${user.ticketsId.length}'),
            const SizedBox(width: 24),
            _buildDesktopStat('ŞAHİTLİK', '${user.favoriteShows.length}'),
            const SizedBox(width: 24),
            _buildDesktopStat('DİKKAT', '${user.favoritePlayers.length}'),
          ],
        ),
      );

  Widget _buildDesktopStat(final String label, final String value) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: WebColors.whiteText,
                  fontWeight: FontWeight.w900,
                  fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: WebColors.textTertiary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ],
      );

  Widget _buildDesktopInvitation(final BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        decoration: BoxDecoration(
          gradient: WebColors.cardGradient,
          borderRadius: AppRadius.asymLg,
          border:
              Border.all(color: WebColors.darkBlueAccent.withOpacity(0.8)),
        ),
        child: Column(
          children: [
            const Icon(Icons.theater_comedy_rounded,
                size: 44, color: WebColors.primaryGold),
            const SizedBox(height: AppSpacing.lg),
            const Text('SAHNE ŞİMDİLİK SESSİZ',
                style: TextStyle(
                    color: WebColors.whiteText,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
            const SizedBox(height: 10),
            const Text(
                'Işıkları açmak ve kendi hikayeni başlatmak için galerinin anahtarını teslim al.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: WebColors.textSecondary,
                    fontSize: 12,
                    height: 1.6)),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: 260,
              height: 50,
              child: Semantics(
                button: true,
                label: 'Sahneyi uyandır, giriş yap',
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.asymSm),
                    elevation: 0,
                    backgroundColor: WebColors.primaryGold,
                    foregroundColor: WebColors.whiteText,
                  ),
                  onPressed: () => NavigationHandler.goToLogin(context),
                  child: const Text('SAHNEYİ UYANDIR',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildDesktopSectionLabel(final String text) => Text(
        text,
        style: const TextStyle(
            color: WebColors.primaryGoldLight,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 3),
      );

  Widget _buildDesktopTile(
    final BuildContext context, {
    required final IconData icon,
    required final String title,
    required final String subtitle,
    final bool isLocked = false,
    required final VoidCallback onTap,
  }) =>
      Semantics(
        button: true,
        label: isLocked ? '$title (kilitli). $subtitle' : '$title. $subtitle',
        child: Opacity(
          opacity: isLocked ? 0.5 : 1.0,
          child: InkWell(
            onTap:
                isLocked ? () => NavigationHandler.goToLogin(context) : onTap,
            borderRadius: AppRadius.asymSm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: 18),
              decoration: BoxDecoration(
                color: WebColors.darkBlueSurface,
                borderRadius: AppRadius.asymSm,
                border: Border.all(
                    color: WebColors.darkBlueAccent.withOpacity(0.8),
                    width: 1),
              ),
              child: Row(
                children: [
                  Icon(icon, color: WebColors.primaryGold, size: 22),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: WebColors.whiteText,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: const TextStyle(
                                color: WebColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(
                      isLocked
                          ? Icons.lock_person_rounded
                          : Icons.chevron_right_rounded,
                      color: WebColors.textTertiary,
                      size: 20),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildDesktopReflection() => Column(
        children: const [
          Text('UNUTMA; GERÇEK SANAT ESERİ,\nİNSANIN KENDİ HAYATIDIR.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: WebColors.whiteText,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                  height: 1.5)),
          SizedBox(height: 10),
          Text(
              'Tanık olduğun her sahne, ruhundaki o büyük yapbozun bir parçasıdır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: WebColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  height: 1.5)),
        ],
      );
}
