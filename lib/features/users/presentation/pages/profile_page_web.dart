import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/web_mega_footer.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../shared/widgets/sahne/sketch.dart' show SkPencilLine;
import '../../../auth/presentation/widgets/sign_out_delete_handler.dart';
import '../../../settings/presentation/widgets/preference_widgets.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../../domain/entities/user.dart' as entity;
import '../providers/user_provider.dart';
import '../widgets/spectator_record.dart';

/// PROFİL / HESAP MERKEZİ — WEB. Mağaza "hesabım" düzeni: solda üye kartı +
/// bölüm gezinmesi (sayaçlı), ortada sıradaki oyun, yaklaşan biletler,
/// favoriler, seyirci karnesi ve görünüm; sağda kaydırırken yapışkan kalan
/// hesap özeti (iletişim, düzenle, oturum). Mobil profil sayfasından AYRIDIR.
/// Başlık kabuktaki site başlığından gelir.
class ProfilePageWeb extends ConsumerStatefulWidget {
  const ProfilePageWeb({super.key});

  @override
  ConsumerState<ProfilePageWeb> createState() => _ProfilePageWebState();
}

class _ProfilePageWebState extends ConsumerState<ProfilePageWeb>
    with
        ProfileSnackBarHandler,
        ProfileSignOutHandler,
        ProfileDeleteAccountHandler {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _rowKey = GlobalKey();
  final GlobalKey _panelKey = GlobalKey();
  final ValueNotifier<double> _stick = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateSticky);
  }

  @override
  void dispose() {
    _scroll.removeListener(_updateSticky);
    _scroll.dispose();
    _stick.dispose();
    super.dispose();
  }

  void _updateSticky() {
    final RenderObject? row = _rowKey.currentContext?.findRenderObject();
    final RenderObject? panel = _panelKey.currentContext?.findRenderObject();
    if (row is! RenderBox ||
        panel is! RenderBox ||
        !row.attached ||
        !panel.attached) {
      return;
    }
    final double rowTop = row.localToGlobal(Offset.zero).dy;
    final double travel = row.size.height - panel.size.height;
    final double v = (24 - rowTop).clamp(0.0, travel < 0 ? 0.0 : travel);
    if ((v - _stick.value).abs() > 0.5) _stick.value = v;
  }

  String? _since(final String createdAt) {
    final DateTime? d = DateFormatter.parseDateString(createdAt);
    if (d == null) return null;
    return '${kMonthsTr[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<entity.User?> async = ref.watch(userProfileProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSticky());

    return Scaffold(
      backgroundColor: cs.surface,
      body: SingleChildScrollView(
        controller: _scroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(builder: (final context, final box) {
              final double w = box.maxWidth;
              final double gutter = Sk.gutter(w);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 28, gutter, 0),
                    child: async.when(
                      loading: () => _skeleton(w - 2 * gutter),
                      error: (final e, final s) => SkEmpty(
                        icon: Icons.cloud_off_rounded,
                        title: 'Profilin yüklenemedi',
                        message:
                            'Hesap bilgilerine ulaşamadık. İnternet bağlantını kontrol edip tekrar dene.',
                        actionLabel: 'Tekrar dene',
                        onAction: () => ref.invalidate(userProfileProvider),
                      ),
                      data: (final user) => user == null
                          ? _guest(context, w - 2 * gutter)
                          : _member(context, user, w - 2 * gutter),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 72),
            const WebMegaFooter(),
          ],
        ),
      ),
    );
  }

  Widget _skeleton(final double w) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkBone(width: 320, height: 40, radius: 12),
          const SizedBox(height: 24),
          Wrap(spacing: 24, runSpacing: 24, children: [
            SkBone(width: w >= 1100 ? 280 : w, height: 360, radius: 20),
            SkBone(
                width: w >= 1100 ? w - 280 - 24 : w, height: 360, radius: 20),
          ]),
        ],
      );

  // ─── Misafir ───────────────────────────────────────────────────────────────

  Widget _guest(final BuildContext context, final double w) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool wide = w >= 900;
    final Widget invite = SkSoftCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 34, color: cs.primary),
          const SizedBox(height: 16),
          Text('Sahne senin için hazır',
              style: Sk.display(context, size: 34, height: 1.1)),
          const SizedBox(height: 8),
          const SkPencilLine(width: 110),
          const SizedBox(height: 10),
          Text(
              'Biletlerin, favori oyunların ve sıradaki seansın tek yerde. '
              'Devam etmek için giriş yap.',
              style: Sk.ui(context,
                  size: 15.5,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w500,
                  height: 1.5)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => NavigationHandler.goToLogin(context),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Giriş yap'),
            style: FilledButton.styleFrom(
                minimumSize: const Size(200, 52),
                shape: const StadiumBorder()),
          ),
        ],
      ),
    );
    final Widget side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _linksCard(context, null),
        const SizedBox(height: 24),
        _appearance(context),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 6, child: invite),
                const SizedBox(width: 32),
                Expanded(flex: 5, child: side),
              ])
            : Column(children: [invite, const SizedBox(height: 24), side]),
      ],
    );
  }

  // ─── Üye ───────────────────────────────────────────────────────────────────

  Widget _member(
      final BuildContext context, final entity.User user, final double w) {
    final bool desktop = w >= 1100;
    final bool tablet = w >= 720;
    final AsyncValue<List<DetailedTicket>> tickets =
        user.ticketsId.isEmpty
            ? const AsyncData(<DetailedTicket>[])
            : ref.watch(myTicketsProvider(user.id));
    final List<DetailedTicket> all = tickets.value ?? const [];
    final List<DetailedTicket> upcoming = _sorted(all.upcoming);

    final Widget nav = _MemberCard(
      user: user,
      since: _since(user.createdAt),
      upcoming: upcoming.length,
      onTickets: () => NavigationHandler.goToMyTickets(context, user.id),
      onFavorites: () => NavigationHandler.goToFavorites(context),
      onEdit: () => context.push('/profile-edit/${user.id}'),
    );

    final Widget main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Greeting(user: user),
        const SizedBox(height: 24),
        _Stats(
          tickets: user.ticketsId.length,
          upcoming: upcoming.length,
          favorites: user.favoriteShows.length +
              user.favoriteStages.length +
              user.favoritePlayers.length,
          onTickets: () => NavigationHandler.goToMyTickets(context, user.id),
          onFavorites: () => NavigationHandler.goToFavorites(context),
        ),
        const SizedBox(height: 40),
        _NextUp(
          loading: tickets.isLoading && !tickets.hasValue,
          upcoming: upcoming,
          onTickets: () => NavigationHandler.goToMyTickets(context, user.id),
          onDiscover: () => NavigationHandler.goToDiscover(context),
        ),
        _FavoriteShows(
          ids: user.favoriteShows,
          width: desktop ? w - 280 - 340 - 64 : w,
        ),
        const SizedBox(height: 40),
        SpectatorRecord(userId: user.id, hasTickets: user.ticketsId.isNotEmpty),
        const SizedBox(height: 16),
        _appearance(context),
      ],
    );

    final Widget summary = Column(
      key: _panelKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccountSummary(
          user: user,
          onEdit: () => context.push('/profile-edit/${user.id}'),
          onSignOut: () => showSignOutDialog(context, ref),
          onDelete: () => showDeleteAccountDialog(context, ref, user.id),
        ),
        const SizedBox(height: 20),
        _linksCard(context, user),
      ],
    );

    if (desktop) {
      return Row(
        key: _rowKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 280, child: nav),
          const SizedBox(width: 32),
          Expanded(child: main),
          const SizedBox(width: 32),
          SizedBox(
            width: 340,
            child: ValueListenableBuilder<double>(
              valueListenable: _stick,
              builder: (final _, final dy, final child) =>
                  Transform.translate(offset: Offset(0, dy), child: child),
              child: summary,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        nav,
        const SizedBox(height: 28),
        main,
        const SizedBox(height: 28),
        tablet
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _AccountSummary(
                  user: user,
                  onEdit: () => context.push('/profile-edit/${user.id}'),
                  onSignOut: () => showSignOutDialog(context, ref),
                  onDelete: () =>
                      showDeleteAccountDialog(context, ref, user.id),
                )),
                const SizedBox(width: 24),
                Expanded(child: _linksCard(context, user)),
              ])
            : Column(children: [
                _AccountSummary(
                  user: user,
                  onEdit: () => context.push('/profile-edit/${user.id}'),
                  onSignOut: () => showSignOutDialog(context, ref),
                  onDelete: () =>
                      showDeleteAccountDialog(context, ref, user.id),
                ),
                const SizedBox(height: 20),
                _linksCard(context, user),
              ]),
      ],
    );
  }

  List<DetailedTicket> _sorted(final List<DetailedTicket> list) {
    final List<DetailedTicket> out = [
      for (final DetailedTicket t in list)
        if (DateFormatter.parseDateString(t.dateText) != null) t,
    ];
    out.sort((final a, final b) => DateFormatter.parseDateString(a.dateText)!
        .compareTo(DateFormatter.parseDateString(b.dateText)!));
    return out;
  }

  Widget _appearance(final BuildContext context) => SkSoftCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkSectionHead(
                title: 'Görünüm', subtitle: 'Tema ve vurgu rengi'),
            const SizedBox(height: 18),
            const ThemeStylePicker(compact: false),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => NavigationHandler.goToSettings(context),
              icon: const Icon(Icons.palette_outlined, size: 18),
              label: const Text('Tema rengini seç'),
            ),
          ],
        ),
      );

  /// Hızlı bağlantılar — misafirde giriş gerektirenler kilitli.
  Widget _linksCard(final BuildContext context, final entity.User? user) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool inn = user != null;
    Widget row(final IconData icon, final String label, final VoidCallback tap,
            {final bool locked = false}) =>
        Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.selectionClick();
              tap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Row(children: [
                Icon(icon, size: 21, color: cs.onSurfaceVariant),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(label,
                        style: Sk.ui(context,
                            size: 14.5, weight: FontWeight.w700))),
                Icon(locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
                    size: 20, color: cs.outline),
              ]),
            ),
          ),
        );
    void login() => NavigationHandler.goToLogin(context);
    return SkSoftCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 6),
            child: Text('Hesap ve destek',
                style: Sk.display(context, size: 20, height: 1.1)),
          ),
          row(Icons.favorite_border_rounded, 'Favorilerim',
              inn ? () => NavigationHandler.goToFavorites(context) : login,
              locked: !inn),
          row(Icons.tune_rounded, 'Ayarlar',
              () => NavigationHandler.goToSettings(context)),
          row(Icons.theater_comedy_outlined, 'Tanıtımı yeniden izle',
              () => context.push('/onboarding')),
          row(Icons.help_outline_rounded, 'Yardım ve destek',
              () => NavigationHandler.goToHelpSupport(context)),
          row(Icons.gavel_rounded, 'Yasal bilgiler',
              () => NavigationHandler.goToContracts(context)),
        ],
      ),
    );
  }
}

// ═══ Sol: üye kartı + gezinme ═════════════════════════════════════════════════

class _Avatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double size;
  const _Avatar(
      {required this.imageUrl, required this.name, required this.size});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String initials = name
        .split(RegExp(r'\s+'))
        .where((final p) => p.isNotEmpty)
        .take(2)
        .map((final p) => p.characters.first.toUpperCase())
        .join();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primaryContainer,
            border: Border.all(color: cs.surface, width: 3)),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: imageUrl.startsWith('http')
            ? SkImage(
                url: imageUrl,
                width: size,
                height: size,
                alignment: const Alignment(0, -0.3),
                fallbackIcon: Icons.person_rounded)
            : Text(initials.isEmpty ? '?' : initials,
                style: Sk.display(context,
                    size: size * 0.38, color: cs.onPrimaryContainer)),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final entity.User user;
  final String? since;
  final int upcoming;
  final VoidCallback onTickets;
  final VoidCallback onFavorites;
  final VoidCallback onEdit;

  const _MemberCard({
    required this.user,
    required this.since,
    required this.upcoming,
    required this.onTickets,
    required this.onFavorites,
    required this.onEdit,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String name = '${user.firstName} ${user.lastName}'.trim();
    final int favs = user.favoriteShows.length +
        user.favoriteStages.length +
        user.favoritePlayers.length;

    Widget item(final IconData icon, final String label, final int? count,
            final VoidCallback? tap,
            {final bool selected = false}) =>
        Semantics(
          button: tap != null,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: MouseRegion(
            cursor: tap == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: tap == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      tap();
                    },
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? cs.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(icon,
                      size: 21,
                      color: selected
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label,
                        style: Sk.ui(context,
                            size: 14.5,
                            color: selected ? cs.onPrimaryContainer : null,
                            weight:
                                selected ? FontWeight.w800 : FontWeight.w700)),
                  ),
                  if (count != null)
                    Text('$count',
                        style: Sk.ui(context,
                            size: 13,
                            color: selected
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                            weight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        );

    return SkSoftCard(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
              child: _Avatar(
                  imageUrl: user.imageUrl,
                  name: name.isEmpty ? user.eMail : name,
                  size: 88)),
          const SizedBox(height: 14),
          Text(name.isEmpty ? 'TiyatRol üyesi' : name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Sk.display(context, size: 24, height: 1.15)),
          if (since != null) ...[
            const SizedBox(height: 4),
            Text('$since tarihinden beri üye',
                textAlign: TextAlign.center,
                style: Sk.ui(context,
                    size: 12.5,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w600)),
          ],
          const SizedBox(height: 18),
          item(Icons.dashboard_outlined, 'Genel bakış', null, null,
              selected: true),
          item(Icons.confirmation_number_outlined, 'Biletlerim',
              user.ticketsId.length, onTickets),
          item(Icons.favorite_border_rounded, 'Favorilerim', favs, onFavorites),
          item(Icons.edit_outlined, 'Profili düzenle', null, onEdit),
        ],
      ),
    );
  }
}

// ═══ Orta ════════════════════════════════════════════════════════════════════

class _Greeting extends StatelessWidget {
  final entity.User user;
  const _Greeting({required this.user});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String first = user.firstName.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(first.isEmpty ? 'Hesabım' : 'Merhaba, $first',
              style: Sk.display(context, size: 38, height: 1.1)),
        ),
        const SizedBox(height: 6),
        const SkPencilLine(width: 120),
        const SizedBox(height: 8),
        Text('Biletlerin, favorilerin ve tercihlerin tek yerde.',
            style: Sk.ui(context,
                size: 15.5,
                color: cs.onSurfaceVariant,
                weight: FontWeight.w500)),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  final int tickets, upcoming, favorites;
  final VoidCallback onTickets, onFavorites;
  const _Stats({
    required this.tickets,
    required this.upcoming,
    required this.favorites,
    required this.onTickets,
    required this.onFavorites,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool narrow = MediaQuery.sizeOf(context).width < 640;
    Widget tile(final IconData icon, final int n, final String label,
            final VoidCallback tap) =>
        Expanded(
          child: PressScale(
            semanticLabel: '$n $label',
            onTap: tap,
            child: Container(
              padding: EdgeInsets.all(narrow ? 12 : 18),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(children: [
                if (!narrow) ...[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: cs.primaryContainer, shape: BoxShape.circle),
                    child: Icon(icon, size: 21, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$n',
                          style: Sk.display(context, size: 26, height: 1.05)),
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 12.5,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        );
    final SizedBox gap = SizedBox(width: narrow ? 8 : 14);
    return Row(children: [
      tile(Icons.confirmation_number_outlined, tickets, 'bilet', onTickets),
      gap,
      tile(Icons.event_available_outlined, upcoming, 'yaklaşan', onTickets),
      gap,
      tile(Icons.favorite_border_rounded, favorites, 'favori', onFavorites),
    ]);
  }
}

class _NextUp extends StatelessWidget {
  final bool loading;
  final List<DetailedTicket> upcoming;
  final VoidCallback onTickets;
  final VoidCallback onDiscover;
  const _NextUp({
    required this.loading,
    required this.upcoming,
    required this.onTickets,
    required this.onDiscover,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    Widget body;
    if (loading) {
      body = const SkBone(height: 200, radius: 20);
    } else if (upcoming.isEmpty) {
      body = SkSoftCard(
        padding: const EdgeInsets.all(8),
        child: SkEmpty(
          icon: Icons.event_busy_outlined,
          title: 'Yaklaşan biletin yok',
          message: 'Bir sonraki oyunu seç, koltuğunu ayırt.',
          actionLabel: 'Oyunlara göz at',
          onAction: onDiscover,
        ),
      );
    } else {
      final DetailedTicket next = upcoming.first;
      final DateTime at = DateFormatter.parseDateString(next.dateText)!;
      body = Semantics(
        button: true,
        label: 'Sıradaki oyun: ${next.showTitle}',
        excludeSemantics: true,
        child: PressScale(
          onTap: onTickets,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(children: [
                SizedBox(
                  width: MediaQuery.sizeOf(context).width < 640 ? 104 : 150,
                  child: SkImage(
                      url: next.show?.imageUrl ?? '',
                      alignment: Alignment.topCenter),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(
                        MediaQuery.sizeOf(context).width < 640 ? 14 : 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkBadge(label: skDayPhrase(at), accent: true),
                        const SizedBox(height: 12),
                        Text(next.showTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Sk.display(context, size: 26, height: 1.15)),
                        const SizedBox(height: 6),
                        Text(
                            '${skDateTime(at)}'
                            '${next.stageTitle.isEmpty ? '' : ' · ${next.stageTitle}'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Sk.ui(context,
                                size: 14,
                                color: cs.onSurfaceVariant,
                                weight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Biletimi gör',
                              style: Sk.ui(context,
                                  size: 14,
                                  color: cs.primary,
                                  weight: FontWeight.w800)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 18, color: cs.primary),
                        ]),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkSectionHead(
          title: 'Sıradaki oyunun',
          actionLabel: upcoming.length > 1 ? 'Tüm biletler' : null,
          onAction: onTickets,
        ),
        const SizedBox(height: 16),
        body,
        if (upcoming.length > 1) ...[
          const SizedBox(height: 14),
          for (final DetailedTicket t in upcoming.skip(1).take(3))
            _UpcomingRow(t: t, onTap: onTickets),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  final DetailedTicket t;
  final VoidCallback onTap;
  const _UpcomingRow({required this.t, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DateTime at = DateFormatter.parseDateString(t.dateText)!;
    return Semantics(
      button: true,
      label: '${t.showTitle}, ${skDateTime(at)}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                  width: 44,
                  height: 58,
                  child: SkImage(
                      url: t.show?.imageUrl ?? '',
                      alignment: Alignment.topCenter)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.showTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 14.5, weight: FontWeight.w800)),
                  Text(skDateTime(at),
                      style: Sk.ui(context,
                          size: 12.5,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.outline),
          ]),
        ),
      ),
    );
  }
}

class _FavoriteShows extends ConsumerWidget {
  final List<String> ids;
  final double width;
  const _FavoriteShows({required this.ids, required this.width});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (ids.isEmpty) return const SizedBox.shrink();
    final AsyncValue<List<Show>> async = ref.watch(showsByIdsProvider(ids));
    final List<Show> shows = async.value ?? const [];
    if (async.hasValue && shows.isEmpty) return const SizedBox.shrink();

    const double gap = 18;
    final int cols = (width / 150).floor().clamp(2, 5);
    final double cw = (width - gap * (cols - 1)) / cols;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        SkSectionHead(
          title: 'Favori oyunların',
          actionLabel: 'Tümü',
          onAction: () => NavigationHandler.goToFavorites(context),
        ),
        const SizedBox(height: 16),
        if (async.isLoading && !async.hasValue)
          Wrap(spacing: gap, runSpacing: gap, children: [
            for (int i = 0; i < cols; i++)
              SkBone(width: cw, height: cw * 1.5, radius: 14),
          ])
        else
          Wrap(spacing: gap, runSpacing: 22, children: [
            for (final Show s in shows.take(cols * 2))
              SizedBox(
                width: cw,
                child: PressScale(
                  semanticLabel: s.name,
                  onTap: () => NavigationHandler.goToShow(
                      context, s.id, s.name,
                      imageUrl: s.imageUrl, title: s.name),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 2 / 3,
                        child: SkImage(
                            url: s.imageUrl,
                            radius: 14,
                            alignment: Alignment.topCenter),
                      ),
                      const SizedBox(height: 8),
                      Text(s.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 14, weight: FontWeight.w800, height: 1.25)),
                    ],
                  ),
                ),
              ),
          ]),
      ],
    );
  }
}

// ═══ Sağ: hesap özeti ═══════════════════════════════════════════════════════

class _AccountSummary extends StatelessWidget {
  final entity.User user;
  final VoidCallback onEdit;
  final VoidCallback onSignOut;
  final VoidCallback onDelete;
  const _AccountSummary({
    required this.user,
    required this.onEdit,
    required this.onSignOut,
    required this.onDelete,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    Widget line(final IconData icon, final String label, final String value) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 19, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Sk.ui(context,
                          size: 11.5,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w700)),
                  Text(value.trim().isEmpty ? 'Eklenmemiş' : value.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 14.5,
                          color: value.trim().isEmpty
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                          weight: FontWeight.w700)),
                ],
              ),
            ),
          ]),
        );
    return SkSoftCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hesap özeti', style: Sk.display(context, size: 22, height: 1.1)),
          const SizedBox(height: 10),
          line(Icons.mail_outline_rounded, 'E-POSTA', user.eMail),
          line(Icons.phone_outlined, 'TELEFON', user.phoneNumber),
          line(Icons.location_on_outlined, 'ŞEHİR', user.city),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Profili düzenle'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder()),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Çıkış yap'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder()),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Hesabı sil'),
          ),
        ],
      ),
    );
  }
}
