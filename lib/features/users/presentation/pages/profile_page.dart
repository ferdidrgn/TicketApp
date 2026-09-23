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

  // Sahne fotoğrafı — `home_page_web.dart`'taki `_HeroBackdropPhoto` ile
  // AYNI, doğrulanmış Unsplash hotlink'i (misafir hero'sunun arkaplanı,
  // giriş yapılmış kullanıcı için kendi `user.imageUrl`'i kullanılır).
  // Aynı görsel iki hero anında da kullanılarak marka dili tutarlı kalıyor.
  static const String _stageBackdropUrl =
      'https://images.unsplash.com/photo-1503095396549-807759245b35'
      '?auto=format&fit=crop&w=1600&q=80';

  // Hero'nun bir kereye mahsus giriş animasyonu — `_HeroBandState` ile
  // aynı teknik (fade + hafif kayma).
  late final AnimationController _heroEntranceController = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
  )..forward();

  Animation<double> get _heroFade => CurvedAnimation(
      parent: _heroEntranceController, curve: AppMotion.standard);

  /// `User.createdAt` Sanity'den ISO8601 string olarak gelir
  /// (`DateFormatter.parseDateString` bunu zaten ISO8601 düşüşüyle
  /// anlıyor). Ayrıştırılamazsa sessizce null döner — asla uydurma bir
  /// tarih gösterilmez.
  String? _memberSinceLabel(final String createdAt) {
    final date = DateFormatter.parseDateString(createdAt);
    if (date == null) return null;
    return DateFormat('d MMMM yyyy', 'tr').format(date);
  }

  @override
  void dispose() {
    _heroEntranceController.dispose();
    super.dispose();
  }

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
                                const SizedBox(height: AppSpacing.lg),
                                _buildHeroSection(isLoggedIn, userData),

                                const SizedBox(height: AppSpacing.huge),

                                _buildSectionLabel("GÖRÜNÜM"),
                                const ThemeSelectorCard(),
                                const SizedBox(height: AppSpacing.lg),
                                _buildSculptedTile(
                                  icon: Icons.settings_suggest_rounded,
                                  title: 'Ayarlar',
                                  subtitle:
                                      'İzinlerini ve uygulama tercihlerini yönet',
                                  color: Colors.blueGrey,
                                  onTap: () =>
                                      NavigationHandler.goToSettings(context),
                                ),

                                const SizedBox(height: AppSpacing.huge),

                                _buildSectionLabel("GEÇMİŞİM"),
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
                                  onTap: () =>
                                      NavigationHandler.goToFavorites(context),
                                ),

                                const SizedBox(height: AppSpacing.huge),

                                _buildSectionLabel("PROFİLİM"),
                                _buildSculptedTile(
                                  icon: Icons.edit_rounded,
                                  title: 'Profili Düzenle',
                                  subtitle:
                                      'Ad, fotoğraf, şehir ve iletişim bilgilerini güncelle',
                                  isLocked: !isLoggedIn,
                                  color: context.colors.primary,
                                  onTap: () => context.push(
                                      '/profile-edit/${userData?.id ?? ""}'),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _buildSculptedTile(
                                  icon: Icons.help_outline_rounded,
                                  title: 'Yardım ve Destek',
                                  subtitle: 'Sorularına hızlıca cevap bul',
                                  color: const Color(0xFF10B981),
                                  onTap: () =>
                                      NavigationHandler.goToHelpSupport(
                                          context),
                                ),

                                const SizedBox(height: AppSpacing.huge),

                                _buildSectionLabel("YASAL YÜKÜMLÜLÜKLER"),
                                _buildSculptedTile(
                                  icon: Icons.gavel_rounded,
                                  title: 'Yasal Bilgiler',
                                  subtitle:
                                      'Gizlilik politikası ve kullanım şartları',
                                  color: Colors.brown.shade400,
                                  onTap: () =>
                                      NavigationHandler.goToContracts(context),
                                ),

                                if (isLoggedIn) ...[
                                  const SizedBox(height: AppSpacing.huge),
                                  _buildSectionLabel("HESAP İŞLEMLERİ"),
                                  _buildSculptedTile(
                                    icon: Icons.logout_rounded,
                                    title: 'Çıkış Yap',
                                    subtitle:
                                        'Hesabından güvenle çıkış yap',
                                    color: Colors.orange.shade800,
                                    onTap: () =>
                                        showSignOutDialog(context, ref),
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

  // --- 🎬 MOBİL HERO — tam boy fotoğraf + karartma + üzerine gerçek
  // veriyle iğnelenmiş kimlik kartı. Teknik `home_page_web.dart`'taki
  // `_HeroBand`/`_HeroBackdropPhoto` ile AYNI: gerçek bir fotoğraf zemini
  // (giriş yapılmışsa kullanıcının kendi `user.imageUrl`'i, misafirse
  // `_stageBackdropUrl`), üzerine metnin her zaman okunur kalmasını
  // sağlayan bir karartma (scrim) ve onun üstünde gerçek verilerle
  // (ad, şehir, üyelik tarihi, bilet/favori sayıları) kurulu bir kimlik
  // bloğu. Uydurma istatistik YOK — hepsi `entity.User` alanlarından.
  Widget _buildHeroSection(
          final bool isLoggedIn, final entity.User? user) =>
      FadeTransition(
        opacity: _heroFade,
        child: SlideTransition(
          position: _heroFade.drive(
              Tween(begin: const Offset(0, 0.04), end: Offset.zero)),
          child: Container(
            height: isLoggedIn && user != null ? 440 : 400,
            decoration: BoxDecoration(
              borderRadius: AppRadius.asymLg,
              boxShadow: AppShadows.level5(
                  context.isDarkMode ? Colors.black : context.colors.shadow),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.asymLg,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeroBackdrop(
                      isLoggedIn && user != null ? user.imageUrl : null),
                  _buildHeroScrim(),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Align(
                      alignment: Alignment.bottomLeft,
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
      );

  /// Fotoğraf zemini — giriş yapılmışsa kullanıcının kendi fotoğrafı
  /// (bulanıklaştırılmış, tüm hero'yu dolduran bir atmosfer olarak),
  /// misafirse sabit bir sahne fotoğrafı. Ağ hatasında sessizce yüzey
  /// rengine düşer, asla kırık görsel göstermez.
  Widget _buildHeroBackdrop(final String? userPhotoUrl) {
    final String url =
        (userPhotoUrl != null && userPhotoUrl.isNotEmpty)
            ? userPhotoUrl
            : _stageBackdropUrl;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (final _, final __, final ___) =>
            ColoredBox(color: context.colors.surfaceVariant),
        loadingBuilder: (final _, final child, final progress) =>
            progress == null
                ? child
                : ColoredBox(color: context.colors.surfaceVariant),
      ),
    );
  }

  /// Metnin fotoğrafın üzerinde her zaman okunur kalmasını sağlayan
  /// karartma. Bilerek AÇIK temada bile koyu tutuluyor — altta sayfanın
  /// kendi (açık temada neredeyse beyaz olan) zeminine erimesine izin
  /// verilirse, üstündeki beyaz metin açık temada okunmaz hale gelirdi.
  Widget _buildHeroScrim() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.70),
              Colors.black.withOpacity(0.40),
              Colors.black.withOpacity(0.66),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      );

  Widget _buildHeroIdentityContent(final entity.User user) {
    final String? memberSince = _memberSinceLabel(user.createdAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          image: true,
          label: 'Profil fotoğrafı',
          child: Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.15),
              backgroundImage: user.imageUrl.isNotEmpty
                  ? NetworkImage(user.imageUrl)
                  : null,
              child: user.imageUrl.isEmpty
                  ? const Icon(Icons.person_rounded, color: Colors.white)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 2, width: 22, color: Colors.white70),
            const SizedBox(width: AppSpacing.sm),
            Text('HOŞ GELDİN',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 3)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${user.firstName} ${user.lastName}'.trim(),
          style: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 30,
                height: 1.05),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: 4,
          children: [
            if (user.city.isNotEmpty)
              _buildHeroMetaChip(Icons.place_rounded, user.city),
            if (memberSince != null)
              _buildHeroMetaChip(
                  Icons.calendar_today_rounded, 'Üyelik: $memberSince'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            _buildStat(Icons.confirmation_number_rounded, 'BİLET',
                '${user.ticketsId.length}'),
            const SizedBox(width: AppSpacing.xxl),
            _buildStat(Icons.favorite_rounded, 'OYUN',
                '${user.favoriteShows.length}'),
            const SizedBox(width: AppSpacing.xxl),
            _buildStat(Icons.star_rounded, 'SANATÇI',
                '${user.favoritePlayers.length}'),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroMetaChip(final IconData icon, final String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      );

  Widget _buildHeroGuestContent() {
    // Dark modda bile canlı kalacak renk seçimi
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
            Container(height: 2, width: 22, color: Colors.white70),
            const SizedBox(width: AppSpacing.sm),
            Text('PROFİLİN',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 3)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Henüz Giriş\nYapmadın',
          style: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 30,
                height: 1.05),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const SizedBox(
          width: 280,
          child: Text(
            'Biletlerini, favori oyunlarını ve profilini görmek için giriş yap.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          button: true,
          label: 'Giriş yap',
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
                elevation: 0,
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
              ),
              onPressed: () => NavigationHandler.goToLogin(context),
              child: const Text('Giriş Yap',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 0.5))),
        ),
      ],
    );
  }

  Widget _buildStat(
          final IconData icon, final String label, final String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Colors.white)),
          ],
        ),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
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
                          _buildDesktopHero(context, userData, isLoggedIn),
                          const SizedBox(height: AppSpacing.massive),
                          _buildDesktopSectionLabel('GÖRÜNÜM'),
                          const SizedBox(height: AppSpacing.lg),
                          const ThemeSelectorCard(),
                          const SizedBox(height: AppSpacing.md),
                          _buildDesktopTile(
                            context,
                            icon: Icons.settings_suggest_rounded,
                            title: 'Ayarlar',
                            subtitle:
                                'İzinlerini ve uygulama tercihlerini yönet',
                            onTap: () =>
                                NavigationHandler.goToSettings(context),
                          ),
                          const SizedBox(height: AppSpacing.huge),
                          _buildDesktopSectionLabel('GEÇMİŞİM'),
                          const SizedBox(height: AppSpacing.lg),
                          _buildDesktopTile(
                            context,
                            icon: Icons.confirmation_number_rounded,
                            title: 'Biletlerim',
                            subtitle:
                                'Geçmiş ve gelecek etkinliklerinin tüm biletleri',
                            isLocked: !isLoggedIn,
                            onTap: () => NavigationHandler.goToMyTickets(
                                context, userData?.id ?? ""),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildDesktopTile(
                            context,
                            icon: Icons.favorite_rounded,
                            title: 'Favorilerim',
                            subtitle:
                                'Favori oyunların, sahnelerin ve sanatçıların',
                            isLocked: !isLoggedIn,
                            onTap: () =>
                                NavigationHandler.goToFavorites(context),
                          ),
                          const SizedBox(height: AppSpacing.huge),
                          _buildDesktopSectionLabel('PROFİLİM'),
                          const SizedBox(height: AppSpacing.lg),
                          _buildDesktopTile(
                            context,
                            icon: Icons.edit_rounded,
                            title: 'Profili Düzenle',
                            subtitle:
                                'Ad, fotoğraf, şehir ve iletişim bilgilerini güncelle',
                            isLocked: !isLoggedIn,
                            onTap: () => context
                                .push('/profile-edit/${userData?.id ?? ""}'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildDesktopTile(
                            context,
                            icon: Icons.help_outline_rounded,
                            title: 'Yardım ve Destek',
                            subtitle: 'Sorularına hızlıca cevap bul',
                            onTap: () =>
                                NavigationHandler.goToHelpSupport(context),
                          ),
                          const SizedBox(height: AppSpacing.huge),
                          _buildDesktopSectionLabel('YASAL YÜKÜMLÜLÜKLER'),
                          const SizedBox(height: AppSpacing.lg),
                          _buildDesktopTile(
                            context,
                            icon: Icons.gavel_rounded,
                            title: 'Yasal Bilgiler',
                            subtitle: 'Gizlilik politikası ve kullanım şartları',
                            onTap: () =>
                                NavigationHandler.goToContracts(context),
                          ),
                          if (isLoggedIn) ...[
                            const SizedBox(height: AppSpacing.huge),
                            _buildDesktopSectionLabel('HESAP İŞLEMLERİ'),
                            const SizedBox(height: AppSpacing.lg),
                            _buildDesktopTile(
                              context,
                              icon: Icons.logout_rounded,
                              title: 'Çıkış Yap',
                              subtitle: 'Hesabından güvenle çıkış yap',
                              onTap: () => showSignOutDialog(context, ref),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildDesktopTile(
                              context,
                              icon: Icons.delete_forever_rounded,
                              title: 'Hesabı Sil',
                              subtitle:
                                  'Hesabını ve tüm verilerini kalıcı olarak sil',
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

  // --- 🎬 MASAÜSTÜ HERO — `home_page_web.dart`'taki `_HeroBand`/
  // `_HeroBackdropPhoto` ile AYNI teknik: tam boy gerçek fotoğraf zemini +
  // çift yönlü karartma + üzerine gerçek kullanıcı verisiyle kurulu bir
  // kimlik bloğu. Giriş yapılmışsa zemin kullanıcının kendi fotoğrafı,
  // misafirse `_stageBackdropUrl` (home hero'suyla AYNI, doğrulanmış
  // Unsplash görseli — marka dili tutarlı kalsın diye).
  Widget _buildDesktopHero(final BuildContext context,
          final entity.User? user, final bool isLoggedIn) =>
      Container(
        height: isLoggedIn && user != null ? 380 : 360,
        decoration: BoxDecoration(
          borderRadius: AppRadius.asymLg,
          border:
              Border.all(color: WebColors.darkBlueAccent.withOpacity(0.8)),
          boxShadow: AppShadows.level5(WebColors.primaryGold),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.asymLg,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildDesktopHeroBackdrop(
                  isLoggedIn && user != null ? user.imageUrl : null),
              _buildDesktopHeroScrim(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.massive),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: isLoggedIn && user != null
                      ? _buildDesktopHeroIdentity(user)
                      : _buildDesktopHeroGuest(context),
                ),
              ),
            ],
          ),
        ),
      );

  /// Mobil `_buildHeroBackdrop` ile AYNI mantık, sadece hata/yükleme
  /// düşüşü `WebColors.darkBlueSurface` — masaüstü kabuğu her zaman
  /// `WebColors` temalı, `context.colors` değil.
  Widget _buildDesktopHeroBackdrop(final String? userPhotoUrl) {
    final String url = (userPhotoUrl != null && userPhotoUrl.isNotEmpty)
        ? userPhotoUrl
        : _stageBackdropUrl;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (final _, final __, final ___) =>
            const ColoredBox(color: WebColors.darkBlueSurface),
        loadingBuilder: (final _, final child, final progress) =>
            progress == null
                ? child
                : const ColoredBox(color: WebColors.darkBlueSurface),
      ),
    );
  }

  Widget _buildDesktopHeroScrim() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.72),
              Colors.black.withOpacity(0.32),
              WebColors.darkBlueBackground.withOpacity(0.94),
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
            Container(height: 2, width: 26, color: WebColors.primaryGold),
            const SizedBox(width: AppSpacing.sm),
            const Text('HOŞ GELDİN',
                style: TextStyle(
                    color: WebColors.primaryGoldLight,
                    fontWeight: FontWeight.w700,
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
                fontSize: 38,
                height: 1.05),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
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
            const SizedBox(width: 28),
            _buildDesktopStat(Icons.favorite_rounded, 'OYUN',
                '${user.favoriteShows.length}'),
            const SizedBox(width: 28),
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
          Icon(icon, size: 14, color: WebColors.textSecondary),
          const SizedBox(width: 4),
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
              Icon(icon, size: 15, color: WebColors.primaryGoldLight),
              const SizedBox(width: 4),
              Text(value,
                  style: const TextStyle(
                      color: WebColors.whiteText,
                      fontWeight: FontWeight.w900,
                      fontSize: 20)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: WebColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ],
      );

  Widget _buildDesktopHeroGuest(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 2, width: 26, color: WebColors.primaryGold),
              const SizedBox(width: AppSpacing.sm),
              const Text('PROFİLİN',
                  style: TextStyle(
                      color: WebColors.primaryGoldLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 3)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Henüz Giriş Yapmadın',
            style: GoogleFonts.playfairDisplay(
              textStyle: const TextStyle(
                  color: WebColors.whiteText,
                  fontWeight: FontWeight.w700,
                  fontSize: 34,
                  height: 1.1),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const SizedBox(
            width: 380,
            child: Text(
              'Biletlerini, favori oyunlarını ve profilini görmek için giriş yap.',
              style: TextStyle(
                  color: WebColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 220,
            height: 50,
            child: Semantics(
              button: true,
              label: 'Giriş yap',
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.asymSm),
                  elevation: 0,
                  backgroundColor: WebColors.primaryGold,
                  foregroundColor: WebColors.whiteText,
                ),
                onPressed: () => NavigationHandler.goToLogin(context),
                child: const Text('Giriş Yap',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
          ),
        ],
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
