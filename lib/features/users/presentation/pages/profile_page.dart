import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/core/util/date_formatter.dart';
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
  static const String _stageBackdropUrl =
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819'
      '?auto=format&fit=crop&w=1800&q=85';

  late final AnimationController _heroEntranceController = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
  )..forward();

  Animation<double> get _heroFade => CurvedAnimation(
      parent: _heroEntranceController, curve: AppMotion.standard);

  late final AnimationController _particlesController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  String? _memberSinceLabel(final String createdAt) {
    final date = DateFormatter.parseDateString(createdAt);
    if (date == null) return null;
    return DateFormat('d MMMM yyyy', 'tr').format(date);
  }

  @override
  void dispose() {
    _heroEntranceController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  void onLoadMore() {}

  @override
  Widget build(final BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

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
        ambientColor: context.colors.shadow.withOpacity(0.05),
      ),
      child: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final err, final stack) => Center(child: Text("Hata: $err")),
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
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: AppSpacing.lg),
                        _buildPageKicker(),
                        const SizedBox(height: AppSpacing.md),
                        _buildHeroSection(isLoggedIn, userData),
                        const SizedBox(height: AppSpacing.huge),
                        _buildSectionLabel("GÖRÜNÜM", Icons.palette_rounded),
                        const ThemeSelectorCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSculptedTile(
                          icon: Icons.settings_suggest_rounded,
                          title: 'Ayarlar',
                          subtitle: 'İzinlerini ve uygulama tercihlerini yönet',
                          color: Colors.blueGrey,
                          onTap: () => NavigationHandler.goToSettings(context),
                        ),
                        const SizedBox(height: AppSpacing.huge),
                        _buildSectionLabel(
                            "GEÇMİŞİM", Icons.history_edu_rounded),
                        _buildSculptedTile(
                          icon: Icons.confirmation_number_rounded,
                          title: 'Biletlerim',
                          subtitle:
                              'Geçmiş ve gelecek etkinliklerinin tüm biletleri',
                          isLocked: !isLoggedIn,
                          color: const Color(0xFF6366F1),
                          onTap: () => NavigationHandler.goToMyTickets(
                              context, userData?.id ?? ""),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSculptedTile(
                          icon: Icons.favorite_rounded,
                          title: 'Favorilerim',
                          subtitle:
                              'Favori oyunların, sahnelerin ve sanatçıların',
                          isLocked: !isLoggedIn,
                          color: const Color(0xFFEC4899),
                          onTap: () => NavigationHandler.goToFavorites(context),
                        ),
                        const SizedBox(height: AppSpacing.huge),
                        _buildSectionLabel("PROFİLİM", Icons.person_rounded),
                        _buildSculptedTile(
                          icon: Icons.edit_rounded,
                          title: 'Profili Düzenle',
                          subtitle:
                              'Ad, fotoğraf, şehir ve iletişim bilgilerini güncelle',
                          isLocked: !isLoggedIn,
                          color: context.colors.primary,
                          onTap: () => context
                              .push('/profile-edit/${userData?.id ?? ""}'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSculptedTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Yardım ve Destek',
                          subtitle: 'Sorularına hızlıca cevap bul',
                          color: const Color(0xFF10B981),
                          onTap: () =>
                              NavigationHandler.goToHelpSupport(context),
                        ),
                        const SizedBox(height: AppSpacing.huge),
                        _buildSectionLabel(
                            "YASAL YÜKÜMLÜLÜKLER", Icons.gavel_rounded),
                        _buildSculptedTile(
                          icon: Icons.gavel_rounded,
                          title: 'Yasal Bilgiler',
                          subtitle: 'Gizlilik politikası ve kullanım şartları',
                          color: Colors.brown.shade400,
                          onTap: () => NavigationHandler.goToContracts(context),
                        ),
                        if (isLoggedIn) ...[
                          const SizedBox(height: AppSpacing.huge),
                          _buildSectionLabel(
                              "HESAP İŞLEMLERİ", Icons.manage_accounts_rounded),
                          _buildSculptedTile(
                            icon: Icons.logout_rounded,
                            title: 'Çıkış Yap',
                            subtitle: 'Hesabından güvenle çıkış yap',
                            color: Colors.orange.shade800,
                            onTap: () => showSignOutDialog(context, ref),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildSculptedTile(
                            icon: Icons.delete_forever_rounded,
                            title: 'Hesabı Sil',
                            subtitle:
                                'Hesabını ve tüm verilerini kalıcı olarak sil',
                            color: Colors.red.shade900,
                            onTap: () => showDeleteAccountDialog(
                                context, ref, userData.id),
                          ),
                        ],
                        _buildSoulReflection(),
                        const SizedBox(height: 120),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageKicker() => Row(
        children: [
          Container(height: 2, width: 18, color: context.colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'PROFİLİM',
            style: TextStyle(
              color: context.colors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              fontSize: 11,
            ),
          ),
        ],
      );

  Widget _buildStatDivider() => Container(
        width: 1,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        color: context.colors.onSurface.withOpacity(0.15),
      );

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
              onTap:
                  isLocked ? () => NavigationHandler.goToLogin(context) : onTap,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.shadow.withOpacity(0.15),
                      offset: const Offset(6, 6),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
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
                                  color:
                                      context.colors.onSurface.withOpacity(0.7),
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

  // --- 🎨 TEMİZLENMİŞ & OPTİMİZE EDİLMİŞ 3D BENTO HERO ---
  Widget _buildHeroSection(final bool isLoggedIn, final entity.User? user) =>
      FadeTransition(
        opacity: _heroFade,
        child: SlideTransition(
          position: _heroFade
              .drive(Tween(begin: const Offset(0, 0.04), end: Offset.zero)),
          child: SizedBox(
            height: isLoggedIn && user != null ? 540 : 490,
            child: Stack(
              children: [
                // Arka Mozaik Katman 1 (Turuncu/Pembe)
                Positioned(
                  top: 10,
                  right: -10,
                  width: 220,
                  height: 250,
                  child: Transform.rotate(
                    angle: 0.1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orangeAccent.withOpacity(0.7),
                            Colors.pinkAccent.withOpacity(0.5)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(36),
                      ),
                    ),
                  ),
                ),
                // Arka Mozaik Katman 2 (Turkuaz/Mavi)
                Positioned(
                  top: 40,
                  left: -15,
                  width: 190,
                  height: 210,
                  child: Transform.rotate(
                    angle: -0.08,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.cyan.withOpacity(0.6),
                            Colors.indigo.withOpacity(0.4)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ),
                // Ön Odak Kartı
                Align(
                  alignment: Alignment.center,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        height: isLoggedIn && user != null ? 500 : 455,
                        decoration: BoxDecoration(
                          color: context.colors.surface.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 220,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(30)),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      isLoggedIn &&
                                              user != null &&
                                              user.imageUrl.isNotEmpty
                                          ? user.imageUrl
                                          : _stageBackdropUrl,
                                      fit: BoxFit.cover,
                                    ),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            context.colors.surface
                                                .withOpacity(0.8),
                                            context.colors.surface,
                                          ],
                                          stops: const [0.3, 0.8, 1.0],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: isLoggedIn && user != null
                                    ? _buildHeroIdentityContent(user)
                                    : _buildHeroGuestContent(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildHeroIdentityContent(final entity.User user) {
    final String? memberSince = _memberSinceLabel(user.createdAt);
    final String fullName = '${user.firstName} ${user.lastName}'.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                    color: context.colors.primary, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('HOŞ GELDİN',
                style: TextStyle(
                    color: context.colors.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 3)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          fullName.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: context.colors.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              height: 1.0),
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: 4,
          children: [
            if (user.city.isNotEmpty)
              _buildHeroMetaChip(Icons.place_rounded, user.city),
            if (memberSince != null)
              _buildHeroMetaChip(
                  Icons.calendar_today_rounded, 'Üyelik: $memberSince'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(height: 1, color: context.colors.onSurface.withOpacity(0.08)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildEditorialStat(Icons.confirmation_number_rounded, 'BİLET',
                '${user.ticketsId.length}'),
            _buildStatDivider(),
            _buildEditorialStat(
                Icons.favorite_rounded, 'OYUN', '${user.favoriteShows.length}'),
            _buildStatDivider(),
            _buildEditorialStat(Icons.star_rounded, 'SANATÇI',
                '${user.favoritePlayers.length}'),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroMetaChip(final IconData icon, final String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.colors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      );

  Widget _buildHeroGuestContent() {
    final Color buttonColor = context.isDarkMode
        ? context.colors.primaryContainer
        : context.colors.primary;
    final Color buttonTextColor = context.isDarkMode
        ? context.colors.onPrimaryContainer
        : context.colors.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                    color: context.colors.primary, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('İLK PERDE',
                style: TextStyle(
                    color: context.colors.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 3)),
          ],
        ),
        const SizedBox(height: 6),
        Text('SAHNE SENİN\nİÇİN HAZIR',
            style: TextStyle(
                color: context.colors.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 26,
                height: 1.0)),
        const SizedBox(height: 6),
        Text('Biletlerini ve favori oyunlarını yönetmek için hemen giriş yap.',
            style: TextStyle(
                color: context.colors.onSurface.withOpacity(0.62),
                fontSize: 12,
                height: 1.4)),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
              elevation: 0,
              backgroundColor: buttonColor,
              foregroundColor: buttonTextColor,
            ),
            onPressed: () => NavigationHandler.goToLogin(context),
            child: const Text('Giriş Yap',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorialStat(
          final IconData icon, final String label, final String value) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13, color: context.colors.primary.withOpacity(0.85)),
              const SizedBox(width: 4),
              Text(value,
                  style: TextStyle(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 1.5)),
        ],
      );

  Widget _buildSectionLabel(final String text, final IconData icon) => Padding(
        padding: const EdgeInsets.only(
            left: AppSpacing.xs, bottom: AppSpacing.lg, top: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 16, color: context.colors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(text,
                style: TextStyle(
                    color: context.isDarkMode
                        ? context.colors.onPrimary
                        : context.colors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 3)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    context.colors.primary.withOpacity(0.25),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ],
        ),
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
                  height: 1.5),
            ),
          ],
        ),
      );

  // --- MASAÜSTÜ GÖRÜNÜMÜ ---
  Widget _buildDesktopPage(final BuildContext context,
          final AsyncValue<entity.User?> userProfileAsync) =>
      ColoredBox(
        color: WebColors.darkBlueBackground,
        child: Stack(
          children: [
            Positioned.fill(
                child:
                    _ProfileAmbientParticles(animation: _particlesController)),
            userProfileAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: WebColors.primaryGold)),
              error: (final err, final stack) => Center(
                  child: Text('Hata: $err',
                      style: const TextStyle(color: WebColors.whiteText))),
              data: (final userData) {
                final bool isLoggedIn = userData != null;
                return ListView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildDesktopHero(context, userData, isLoggedIn),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxxl, vertical: 56),
                          child: Column(
                            children: [
                              _buildDesktopSectionLabel(
                                  'GÖRÜNÜM', Icons.palette_rounded),
                              const SizedBox(height: AppSpacing.lg),
                              const ThemeSelectorCard(),
                              const SizedBox(height: AppSpacing.md),
                              _buildDesktopTile(context,
                                  icon: Icons.settings_suggest_rounded,
                                  title: 'Ayarlar',
                                  subtitle:
                                      'İzinlerini ve uygulama tercihlerini yönet',
                                  onTap: () =>
                                      NavigationHandler.goToSettings(context)),
                              const SizedBox(height: AppSpacing.huge),
                              _buildDesktopSectionLabel(
                                  'GEÇMİŞİM', Icons.history_edu_rounded),
                              const SizedBox(height: AppSpacing.lg),
                              _buildDesktopTileGrid([
                                _buildDesktopTile(context,
                                    icon: Icons.confirmation_number_rounded,
                                    title: 'Biletlerim',
                                    subtitle:
                                        'Geçmiş ve gelecek etkinliklerinin tüm biletleri',
                                    isLocked: !isLoggedIn,
                                    onTap: () =>
                                        NavigationHandler.goToMyTickets(
                                            context, userData?.id ?? "")),
                                _buildDesktopTile(context,
                                    icon: Icons.favorite_rounded,
                                    title: 'Favorilerim',
                                    subtitle:
                                        'Favori oyunların, sahnelerin ve sanatçıların',
                                    isLocked: !isLoggedIn,
                                    onTap: () =>
                                        NavigationHandler.goToFavorites(
                                            context)),
                              ]),
                              const SizedBox(height: AppSpacing.huge),
                              _buildDesktopSectionLabel(
                                  'PROFİLİM', Icons.person_rounded),
                              const SizedBox(height: AppSpacing.lg),
                              _buildDesktopTileGrid([
                                _buildDesktopTile(context,
                                    icon: Icons.edit_rounded,
                                    title: 'Profili Düzenle',
                                    subtitle:
                                        'Ad, fotoğraf, şehir ve iletişim bilgilerini güncelle',
                                    isLocked: !isLoggedIn,
                                    onTap: () => context.push(
                                        '/profile-edit/${userData?.id ?? ""}')),
                                _buildDesktopTile(context,
                                    icon: Icons.help_outline_rounded,
                                    title: 'Yardım ve Destek',
                                    subtitle: 'Sorularına hızlıca cevap bul',
                                    onTap: () =>
                                        NavigationHandler.goToHelpSupport(
                                            context)),
                              ]),
                              const SizedBox(height: AppSpacing.huge),
                              _buildDesktopSectionLabel(
                                  'YASAL YÜKÜMLÜLÜKLER', Icons.gavel_rounded),
                              const SizedBox(height: AppSpacing.lg),
                              _buildDesktopTile(context,
                                  icon: Icons.gavel_rounded,
                                  title: 'Yasal Bilgiler',
                                  subtitle:
                                      'Gizlilik politikası ve kullanım şartları',
                                  onTap: () =>
                                      NavigationHandler.goToContracts(context)),
                              if (isLoggedIn) ...[
                                const SizedBox(height: AppSpacing.huge),
                                _buildDesktopSectionLabel('HESAP İŞLEMLERİ',
                                    Icons.manage_accounts_rounded),
                                const SizedBox(height: AppSpacing.lg),
                                _buildDesktopTileGrid([
                                  _buildDesktopTile(context,
                                      icon: Icons.logout_rounded,
                                      title: 'Çıkış Yap',
                                      subtitle: 'Hesabından güvenle çıkış yap',
                                      onTap: () =>
                                          showSignOutDialog(context, ref)),
                                  _buildDesktopTile(context,
                                      icon: Icons.delete_forever_rounded,
                                      title: 'Hesabı Sil',
                                      subtitle:
                                          'Hesabını ve tüm verilerini kalıcı olarak sil',
                                      onTap: () => showDeleteAccountDialog(
                                          context, ref, userData.id)),
                                ]),
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
          ],
        ),
      );

  Widget _buildDesktopTileGrid(final List<Widget> tiles) {
    if (tiles.length == 1) return tiles.first;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i != 0) const SizedBox(width: AppSpacing.lg),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }

  Widget _buildDesktopHero(final BuildContext context, final entity.User? user,
          final bool isLoggedIn) =>
      SizedBox(
        height: isLoggedIn && user != null ? 660 : 620,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildDesktopHeroBackdrop(
                isLoggedIn && user != null ? user.imageUrl : null),
            _buildDesktopHeroScrim(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.4),
                  radius: 1.3,
                  colors: [Color(0x55E8B84B), Colors.transparent],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.massive, 0, AppSpacing.massive, 64),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: isLoggedIn && user != null
                        ? _buildDesktopHeroIdentity(user)
                        : _buildDesktopHeroGuest(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildDesktopHeroBackdrop(final String? userPhotoUrl) {
    final String url = (userPhotoUrl != null && userPhotoUrl.isNotEmpty)
        ? userPhotoUrl
        : _stageBackdropUrl;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const ColoredBox(color: WebColors.darkBlueSurface),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const ColoredBox(color: WebColors.darkBlueSurface),
    );
  }

  Widget _buildDesktopHeroScrim() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.75),
              Colors.black.withOpacity(0.35),
              WebColors.darkBlueBackground.withOpacity(0.96),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      );

  Widget _buildDesktopHeroIdentity(final entity.User user) {
    final String? memberSince = _memberSinceLabel(user.createdAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 3, width: 30, color: WebColors.primaryGold),
            const SizedBox(width: AppSpacing.sm),
            const Text('GALA PREMİER LOUNGE',
                style: TextStyle(
                    color: WebColors.primaryGoldLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 3)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${user.firstName} ${user.lastName}'.trim(),
          style: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
                color: WebColors.whiteText,
                fontWeight: FontWeight.w700,
                fontSize: 44,
                height: 1.05),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xl,
          runSpacing: 4,
          children: [
            if (user.city.isNotEmpty)
              _buildDesktopHeroMetaChip(Icons.place_rounded, user.city),
            if (memberSince != null)
              _buildDesktopHeroMetaChip(
                  Icons.calendar_today_rounded, 'Üyelik: $memberSince'),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            _buildDesktopStat(Icons.confirmation_number_rounded, 'BİLET',
                '${user.ticketsId.length}'),
            _buildStatDivider(),
            _buildDesktopStat(
                Icons.favorite_rounded, 'OYUN', '${user.favoriteShows.length}'),
            _buildStatDivider(),
            _buildDesktopStat(Icons.star_rounded, 'SANATÇI',
                '${user.favoritePlayers.length}'),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopHeroMetaChip(final IconData icon, final String label) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: WebColors.primaryGoldLight),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: WebColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      );

  Widget _buildDesktopStat(
          final IconData icon, final String label, final String value) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: WebColors.primaryGoldLight),
              const SizedBox(width: 5),
              Text(value,
                  style: const TextStyle(
                      color: WebColors.whiteText,
                      fontWeight: FontWeight.w900,
                      fontSize: 22)),
            ],
          ),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  color: WebColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
        ],
      );

  Widget _buildDesktopHeroGuest(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 3, width: 30, color: WebColors.primaryGold),
              const SizedBox(width: AppSpacing.sm),
              const Text('İLK PERDE',
                  style: TextStyle(
                      color: WebColors.primaryGoldLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 3)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sahne Senin İçin Hazır',
            style: GoogleFonts.playfairDisplay(
              textStyle: const TextStyle(
                  color: WebColors.whiteText,
                  fontWeight: FontWeight.w700,
                  fontSize: 40,
                  height: 1.1),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const SizedBox(
            width: 420,
            child: Text(
              'Biletlerini, favori oyunlarını ve sahnede yerini almak için hemen giriş yap.',
              style: TextStyle(
                  color: WebColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 230,
            height: 52,
            child: Semantics(
              button: true,
              label: 'Giriş yap',
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.asymSm),
                  elevation: 4,
                  backgroundColor: WebColors.primaryGold,
                  foregroundColor: WebColors.whiteText,
                ),
                onPressed: () => NavigationHandler.goToLogin(context),
                child: const Text('Giriş Yap',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5)),
              ),
            ),
          ),
        ],
      );

  Widget _buildDesktopSectionLabel(final String text, final IconData icon) =>
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: WebColors.goldButtonGradient,
              borderRadius: AppRadius.asymSm,
              boxShadow: [
                BoxShadow(
                    color: WebColors.primaryGold.withOpacity(0.35),
                    blurRadius: 14),
              ],
            ),
            child: Icon(icon, color: WebColors.darkBlueBackground, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(text,
              style: const TextStyle(
                  color: WebColors.whiteText,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 2)),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  WebColors.primaryGold.withOpacity(0.4),
                  Colors.transparent
                ]),
              ),
            ),
          ),
        ],
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
                    color: WebColors.darkBlueAccent.withOpacity(0.8), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: WebColors.primaryGold.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: WebColors.primaryGold, size: 20),
                  ),
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
                height: 1.5),
          ),
        ],
      );
}

class _ProfileAmbientParticles extends StatelessWidget {
  final Animation<double> animation;

  const _ProfileAmbientParticles({required this.animation});

  @override
  Widget build(final BuildContext context) {
    final random = math.Random(42);
    final size = MediaQuery.of(context).size;
    return Stack(
      children: List.generate(15, (final i) {
        final x = random.nextDouble() * size.width;
        final baseY = random.nextDouble() * size.height;
        return AnimatedBuilder(
          animation: animation,
          builder: (final context, final _) {
            final y = baseY + math.sin(animation.value * math.pi * 2 + i) * 30;
            return Positioned(
                left: x,
                top: y,
                child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: WebColors.primaryGold)));
          },
        );
      }),
    );
  }
}
