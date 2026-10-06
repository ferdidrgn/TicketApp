import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/core/util/date_formatter.dart';
import 'package:ticketapp/core/util/global_scroll_mixin.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../auth/presentation/widgets/sign_out_delete_handler.dart';
import '../../../settings/presentation/widgets/preference_widgets.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../../../users/domain/entities/user.dart' as entity;
import '../providers/user_provider.dart';
import '../widgets/spectator_record.dart';

/// PROFİLİM — üyenin "abone kartı".
///
/// Giriş yapmış kullanıcı: gerçek verilerle basılı bir abone kartı (ad,
/// şehir, üyelik tarihi; koçanında bilet / favori oyun / sanatçı sayıları)
/// ve sayfanın TEK birincil aksiyonu: koçandaki "Biletlerim" damgası.
/// Altında (varsa) sıradaki seansın bileti, sade bir hesap listesi, tema
/// seçici ve en altta oturum işlemleri.
///
/// Misafir: sahibinin beğendiği konser/kalabalık fotoğraflı hero +
/// "Giriş yap" damgası; biletler/favoriler kilitli satırlar.
///
/// - Mobil (<768): tek sütun, dikey bilet (koçan altta).
/// - Tablet (768–1023): yatay bilet (koçan sağda), altında iki sütun.
/// - Masaüstü (≥1024): kendi Scaffold'u, 1200px ızgara, 7/4 iki sütun.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

enum _Layout { mobile, tablet, desktop }

class _ProfilePageState extends ConsumerState<ProfilePage>
    with
        ProfileSnackBarHandler,
        ProfileSignOutHandler,
        ProfileDeleteAccountHandler,
        ProfilePhoneLinkHandler,
        ProfileGoogleLinkHandler,
        GlobalScrollMixin {
  /// Sahibinin onayladığı TEK dış fotoğraf istisnası (misafir hero'su).
  static const String _stageBackdropUrl =
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819'
      '?auto=format&fit=crop&w=1800&q=85';

  String? _memberSinceLabel(final String createdAt) {
    final date = DateFormatter.parseDateString(createdAt);
    if (date == null) return null;
    final String locale =
        Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'tr';
    return DateFormat('MMMM yyyy', locale).format(date);
  }

  @override
  void onLoadMore() {}

  void _retry() => ref.invalidate(userProfileProvider);

  @override
  Widget build(final BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    if (context.isDesktop) return _buildDesktopPage(context, userProfileAsync);

    final _Layout layout = context.isTablet ? _Layout.tablet : _Layout.mobile;
    final double gutter =
        layout == _Layout.tablet ? AppSpacing.xxxl : AppSpacing.lg;

    return BasePageWrapper(
      showBackButton: false,
      showFab: true,
      // İskeleti sayfa kendisi çiziyor; `true` verilirse BasePageWrapper
      // içeriği yükleme boyunca görünmez tutuyor.
      isLoading: false,
      customScrollController: scrollController,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
      ),
      child: TicketStage(
        themed: true,
        spotlight: false,
        child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: layout == _Layout.tablet ? 860 : double.infinity),
          child: CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    gutter, AppSpacing.lg, gutter, AppSpacing.xxl),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _compactContent(userProfileAsync, layout),
                  ),
                ),
              ),
              if (kIsWeb) const SliverToBoxAdapter(child: Footer()),
              // Alt navigasyon çubuğunun altında içerik kalmasın.
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Mobil / tablet
  // ─────────────────────────────────────────────────────────────────────

  List<Widget> _compactContent(
      final AsyncValue<entity.User?> async, final _Layout layout) {
    final bool tablet = layout == _Layout.tablet;
    return async.when(
      loading: () => [
        _heading(),
        const SizedBox(height: AppSpacing.xxl),
        _ProfileSkeleton(horizontal: tablet),
      ],
      error: (final err, final stack) => [
        _heading(),
        const SizedBox(height: AppSpacing.xxl),
        _errorNotice(),
        const SizedBox(height: AppSpacing.huge),
        _generalGroup(null),
      ],
      data: (final user) {
        if (user == null) {
          return [
            _GuestHero(
              imageUrl: _stageBackdropUrl,
              wide: tablet,
              onLogin: () => NavigationHandler.goToLogin(context),
            ),
            const SizedBox(height: AppSpacing.huge),
            if (tablet)
              _twoColumns(
                left: [_accountSection(null)],
                right: [_appearanceSection(compact: false)],
              )
            else ...[
              _accountSection(null),
              const SizedBox(height: AppSpacing.huge),
              _appearanceSection(compact: true),
            ],
          ];
        }
        return [
          _heading(),
          const SizedBox(height: AppSpacing.xxl),
          _pass(user, horizontal: tablet),
          const SizedBox(height: AppSpacing.huge),
          _NextShowSection(
            user: user,
            onOpen: () => NavigationHandler.goToMyTickets(context, user.id),
          ),
          _record(user),
          if (tablet)
            _twoColumns(
              left: [_accountSection(user)],
              right: [
                _appearanceSection(compact: false),
                const SizedBox(height: AppSpacing.huge),
                _sessionSection(user),
              ],
            )
          else ...[
            _accountSection(user),
            const SizedBox(height: AppSpacing.huge),
            _appearanceSection(compact: true),
            const SizedBox(height: AppSpacing.huge),
            _sessionSection(user),
          ],
        ];
      },
    );
  }

  Widget _twoColumns(
          {required final List<Widget> left,
          required final List<Widget> right}) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: left),
          ),
          const SizedBox(width: AppSpacing.xxxl),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: right),
          ),
        ],
      );

  // ─────────────────────────────────────────────────────────────────────
  // Ortak parçalar
  // ─────────────────────────────────────────────────────────────────────

  Widget _heading({final String? lede}) =>
      PreferencePageHeading(title: 'Profilim', lede: lede);

  Widget _pass(final entity.User user, {required final bool horizontal}) =>
      _SeasonPass(
        user: user,
        memberSince: _memberSinceLabel(user.createdAt),
        horizontal: horizontal,
        onTickets: () => NavigationHandler.goToMyTickets(context, user.id),
      );

  Widget _record(final entity.User user) => SpectatorRecord(
        userId: user.id,
        hasTickets: user.ticketsId.isNotEmpty,
      );

  Widget _errorNotice() => Align(
        alignment: Alignment.centerLeft,
        child: TicketNotice(
          label: 'BAĞLANTI',
          title: 'Profilin yüklenemedi',
          message: 'Hesap bilgilerine ulaşamadık. İnternet bağlantını '
              'kontrol edip tekrar dene.',
          actionLabel: 'Tekrar dene',
          actionIcon: Icons.refresh_rounded,
          onAction: _retry,
        ),
      );

  /// Hesap listesi. Misafirde (user == null) biletler/favoriler kilitli ve
  /// girişe götürür; "Profili düzenle" gösterilmez.
  Widget _accountSection(final entity.User? user) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PreferenceSectionTitle('Hesabım'),
          _generalGroup(user),
        ],
      );

  Widget _generalGroup(final entity.User? user) {
    final bool loggedIn = user != null;
    void login() => NavigationHandler.goToLogin(context);
    return PreferenceGroup(
      children: [
        if (!loggedIn)
          PreferenceRow(
            icon: Icons.confirmation_number_outlined,
            title: 'Biletlerim',
            subtitle: 'Giriş yapınca biletlerin burada',
            locked: true,
            onTap: login,
          ),
        PreferenceRow(
          icon: Icons.favorite_border_rounded,
          title: 'Favorilerim',
          subtitle: loggedIn
              ? 'Favori oyunların, sahnelerin ve sanatçıların'
              : 'Giriş yapınca favorilerin burada',
          locked: !loggedIn,
          onTap: loggedIn
              ? () => NavigationHandler.goToFavorites(context)
              : login,
        ),
        if (loggedIn)
          PreferenceRow(
            icon: Icons.edit_outlined,
            title: 'Profili düzenle',
            subtitle: 'Ad, fotoğraf, şehir ve telefon',
            onTap: () => context.push('/profile-edit/${user!.id}'),
          ),
        PreferenceRow(
          icon: Icons.tune_rounded,
          title: 'Ayarlar',
          subtitle: 'Tema rengi, dil ve izinler',
          onTap: () => NavigationHandler.goToSettings(context),
        ),
        PreferenceRow(
          icon: Icons.theater_comedy_outlined,
          title: 'Tanıtımı yeniden izle',
          subtitle: 'Üç perdelik kısa tur ve tema seçimi',
          onTap: () => context.push('/onboarding'),
        ),
        PreferenceRow(
          icon: Icons.help_outline_rounded,
          title: 'Yardım ve destek',
          subtitle: 'Sorularına hızlıca cevap bul',
          onTap: () => NavigationHandler.goToHelpSupport(context),
        ),
        PreferenceRow(
          icon: Icons.gavel_rounded,
          title: 'Yasal bilgiler',
          subtitle: 'Gizlilik politikası ve kullanım şartları',
          onTap: () => NavigationHandler.goToContracts(context),
        ),
      ],
    );
  }

  /// Tema seçici (sahibinin en sevdiği özellik) + vurgu rengine kısa yol.
  Widget _appearanceSection({required final bool compact}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PreferenceSectionTitle('Görünüm'),
          ThemeStylePicker(compact: compact),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => NavigationHandler.goToSettings(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: context.colors.primary,
              ),
              icon: const Icon(Icons.palette_outlined, size: 18),
              label: const Text(
                'Tema rengini seç',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );

  /// Oturum işlemleri — en altta, sayfanın birincil aksiyonundan uzakta.
  Widget _sessionSection(final entity.User user) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PreferenceSectionTitle('Oturum'),
          PreferenceGroup(
            children: [
              PreferenceRow(
                icon: Icons.logout_rounded,
                title: 'Çıkış yap',
                subtitle: 'Bu cihazdaki oturumunu kapat',
                trailing: const SizedBox.shrink(),
                onTap: () => showSignOutDialog(context, ref),
              ),
              PreferenceRow(
                icon: Icons.delete_outline_rounded,
                title: 'Hesabı sil',
                subtitle: 'Hesabın ve tüm verilerin kalıcı olarak silinir',
                destructive: true,
                trailing: const SizedBox.shrink(),
                onTap: () => showDeleteAccountDialog(context, ref, user.id),
              ),
            ],
          ),
        ],
      );

  // ─────────────────────────────────────────────────────────────────────
  // Masaüstü / web
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDesktopPage(final BuildContext context,
      final AsyncValue<entity.User?> userProfileAsync) {
    final List<Widget> content = userProfileAsync.when(
      loading: () => [
        _heading(),
        const SizedBox(height: AppSpacing.massive),
        const _ProfileSkeleton(horizontal: true),
      ],
      error: (final err, final stack) => [
        _heading(),
        const SizedBox(height: AppSpacing.massive),
        _desktopColumns(
          left: [_errorNotice()],
          right: [_accountSection(null)],
        ),
      ],
      data: (final user) {
        if (user == null) {
          return [
            _GuestHero(
              imageUrl: _stageBackdropUrl,
              wide: true,
              onLogin: () => NavigationHandler.goToLogin(context),
            ),
            const SizedBox(height: AppSpacing.section),
            _desktopColumns(
              left: [_appearanceSection(compact: false)],
              right: [_accountSection(null)],
            ),
          ];
        }
        return [
          _heading(lede: 'Abone kartın, biletlerin ve tercihlerin.'),
          const SizedBox(height: AppSpacing.massive),
          _desktopColumns(
            left: [
              _pass(user, horizontal: true),
              const SizedBox(height: AppSpacing.section),
              _record(user),
              _appearanceSection(compact: false),
            ],
            right: [
              _NextShowSection(
                user: user,
                onOpen: () =>
                    NavigationHandler.goToMyTickets(context, user.id),
              ),
              _accountSection(user),
              const SizedBox(height: AppSpacing.huge),
              _sessionSection(user),
            ],
          ),
        ];
      },
    );

    // Kabuk içindeki sayfa da kendi Material atasını kurar (diğer web
    // sayfalarıyla aynı desen).
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: TicketStage(
        themed: true,
        spotlight: false,
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xxxl,
                      AppSpacing.massive, AppSpacing.xxxl, AppSpacing.section),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: content,
                  ),
                ),
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _desktopColumns(
          {required final List<Widget> left,
          required final List<Widget> right}) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: left),
          ),
          const SizedBox(width: AppSpacing.section),
          Expanded(
            flex: 4,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: right),
          ),
        ],
      );
}

// ═════════════════════════════════════════════════════════════════════════
// Abone kartı
// ═════════════════════════════════════════════════════════════════════════

/// Üyenin fiziksel abone kartı: gövdede kimlik (gerçek ad, şehir, üyelik
/// tarihi, üye koduna özgü barkod), koçanda sayılar + "Biletlerim" damgası.
class _SeasonPass extends StatefulWidget {
  final entity.User user;
  final String? memberSince;
  final bool horizontal;
  final VoidCallback onTickets;

  const _SeasonPass({
    required this.user,
    required this.memberSince,
    required this.horizontal,
    required this.onTickets,
  });

  @override
  State<_SeasonPass> createState() => _SeasonPassState();
}

class _SeasonPassState extends State<_SeasonPass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final Animation<double> _nameReveal =
      CurvedAnimation(parent: _entrance, curve: AppMotion.dramatic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final entity.User user = widget.user;
    final String fullName = '${user.firstName} ${user.lastName}'.trim();
    final String name = fullName.isEmpty ? 'TiyatRol üyesi' : fullName;
    final String city = user.city.trim();
    final bool horizontal = widget.horizontal;

    final Widget body = Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const TicketHeaderStrip(kind: 'ABONE KARTI'),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _Avatar(imageUrl: user.imageUrl, name: fullName, size: 60),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Semantics(
                  header: true,
                  child: AuthWipeReveal(
                    reveal: _nameReveal,
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TicketInk.headline(horizontal ? 30 : 26),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (city.isNotEmpty || widget.memberSince != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.xxl,
              runSpacing: AppSpacing.md,
              children: [
                if (city.isNotEmpty) TicketField(label: 'ŞEHİR', value: city),
                if (widget.memberSince != null)
                  TicketField(label: 'ÜYELİK', value: widget.memberSince!),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 180,
            child: TicketBarcode(seed: user.id, height: 26),
          ),
        ],
      ),
    );

    final Widget stub = Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment:
            horizontal ? MainAxisAlignment.center : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: horizontal ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TicketField(
                    label: 'BİLET', value: '${user.ticketsId.length}'),
              ),
              Expanded(
                child: TicketField(
                    label: 'OYUN', value: '${user.favoriteShows.length}'),
              ),
              Expanded(
                child: TicketField(
                    label: 'SANATÇI',
                    value: '${user.favoritePlayers.length}'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TicketStampButton(
            label: 'Biletlerim',
            leading: const Icon(Icons.confirmation_number_outlined),
            onTap: widget.onTickets,
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: 'Abone kartı',
      child: AdmitTicket(
        direction: horizontal ? Axis.horizontal : Axis.vertical,
        stubExtent: 260,
        shadows: AppShadows.level2(TicketInk.ink),
        body: body,
        stub: stub,
      ),
    );
  }
}

/// Profil fotoğrafı; yoksa (ya da yüklenemezse) vurgu renginde baş harfler.
class _Avatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double size;

  const _Avatar({
    required this.imageUrl,
    required this.name,
    required this.size,
  });

  static String _initials(final String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((final p) => p.isNotEmpty)
        .take(2);
    return parts.map((final p) {
      final String c = p.substring(0, 1);
      return c == 'i' ? 'İ' : c.toUpperCase();
    }).join();
  }

  @override
  Widget build(final BuildContext context) {
    final String initials = _initials(name);
    final Widget fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TicketInk.accentOf(context),
        shape: BoxShape.circle,
      ),
      child: initials.isEmpty
          ? Icon(Icons.person_rounded,
              color: TicketInk.onAccentOf(context), size: size * 0.5)
          : Text(
              initials,
              style: GoogleFonts.playfairDisplay(
                color: TicketInk.onAccentOf(context),
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
              ),
            ),
    );

    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: TicketInk.inkSoft(0.18), width: 1.2),
        ),
        child: imageUrl.startsWith('http')
            ? OptimizedCachedImage(
                imageUrl: imageUrl,
                width: size,
                height: size,
                isCircular: true,
                errorBuilder: (final _, final __, final ___) => fallback,
              )
            : fallback,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Sıradaki seans
// ═════════════════════════════════════════════════════════════════════════

/// Kullanıcının en yakın gelecek seansı (gerçek bilet verisi,
/// `myTicketsProvider`). Hiç bileti yoksa ya da veri gelmezse kendini
/// gizler — bu ikincil bir bilgi, sayfayı hata ekranına çevirmez.
class _NextShowSection extends ConsumerWidget {
  final entity.User user;
  final VoidCallback onOpen;

  const _NextShowSection({required this.user, required this.onOpen});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (user.ticketsId.isEmpty) return const SizedBox.shrink();
    final async = ref.watch(myTicketsProvider(user.id));

    Widget framed(final Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const PreferenceSectionTitle('Sıradaki oyunun'),
            child,
            const SizedBox(height: AppSpacing.huge),
          ],
        );

    return async.when(
      loading: () => framed(const TicketRowSkeleton(height: 88)),
      error: (final err, final stack) => const SizedBox.shrink(),
      data: (final tickets) {
        DetailedTicket? next;
        DateTime? nextAt;
        for (final t in tickets.upcoming) {
          final String title = t.show?.name.trim() ?? '';
          if (title.isEmpty) continue;
          final DateTime? d = DateFormatter.parseDateString(t.event?.date);
          if (d == null) continue;
          if (nextAt == null || d.isBefore(nextAt)) {
            next = t;
            nextAt = d;
          }
        }
        if (next == null || nextAt == null) return const SizedBox.shrink();
        final String stage = next.stage?.name.trim() ?? '';
        return framed(
          SessionTicketRow(
            title: next.show!.name.trim(),
            dateTime: nextAt,
            extraLabel: stage.isEmpty ? null : 'SAHNE',
            extraValue: stage.isEmpty ? null : stage,
            onTap: onOpen,
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Misafir hero'su
// ═════════════════════════════════════════════════════════════════════════

/// Sahibinin beğendiği konser/kalabalık fotoğrafı + tek aksiyon: giriş.
class _GuestHero extends StatelessWidget {
  final String imageUrl;
  final bool wide;
  final VoidCallback onLogin;

  const _GuestHero({
    required this.imageUrl,
    required this.wide,
    required this.onLogin,
  });

  @override
  Widget build(final BuildContext context) {
    const Widget fallback = ColoredBox(color: TicketInk.ink);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: wide ? 440 : 400,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (final _, final __, final ___) => fallback,
                loadingBuilder: (final _, final child, final progress) =>
                    progress == null ? child : fallback,
              ),
            ),
            // Fotoğraf karartması: metin her temada fotoğrafın üstünde
            // okunur kalsın diye sabit siyah (tema rengi değil).
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.88),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.all(wide ? AppSpacing.massive : AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Sahne senin için hazır',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: prefFluid(context, 32, 48),
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Biletlerin, favori oyunların ve sıradaki seansın '
                        'tek yerde. Devam etmek için giriş yap.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: wide ? 260 : double.infinity,
                        child: TicketStampButton(
                          label: 'Giriş yap',
                          leading: const Icon(Icons.login_rounded),
                          onTap: onLogin,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// İskelet
// ═════════════════════════════════════════════════════════════════════════

class _ProfileSkeleton extends StatelessWidget {
  final bool horizontal;

  const _ProfileSkeleton({required this.horizontal});

  @override
  Widget build(final BuildContext context) => ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShimmerLoading(
              width: double.infinity,
              height: horizontal ? 250 : 400,
              borderRadius: AppRadius.md,
            ),
            const SizedBox(height: AppSpacing.huge),
            const ShimmerLoading(
                width: 160, height: 26, borderRadius: AppRadius.xs),
            const SizedBox(height: AppSpacing.md),
            const ShimmerLoading(
              width: double.infinity,
              height: 64 * 4,
              borderRadius: AppRadius.md,
            ),
          ],
        ),
      );
}
