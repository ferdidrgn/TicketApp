import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/util/comminucation_actions.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/tickets/presentation/providers/my_ticket_provider.dart';
import '../../../features/users/presentation/providers/user_provider.dart';
import '../../widgets/footers/web_mega_footer.dart';
import '../../widgets/sahne/sahne_kit.dart';
import 'nav_handler.dart';
import 'web_site_header.dart';

/// HESABIM bölümünün sayfaları (web).
enum WebAccountSection { tickets, favorites, campaigns, help, contracts }

/// WEB HESAP KABUĞU — Biletlerim, Favorilerim, Kampanyalar, Yardım ve Yasal
/// sayfalarının ortak iskeleti. Gerçek bir site gibi: üstte site başlığı,
/// ekmek kırıntısı + sayfa başlığı, solda yapışkan hesap menüsü, ortada
/// içerik, (isteğe bağlı) sağda yapışkan özet, altta mega altbilgi.
///
/// Dar pencerede (<1000) menü yatay çiplere iner ve özet içeriğin üstüne
/// geçer. Mobil uygulama bu iskeleti kullanmaz.
class WebAccountShell extends ConsumerStatefulWidget {
  final WebAccountSection current;
  final String title;
  final String? subtitle;

  /// Başlığın sağındaki isteğe bağlı eylem (ör. arama alanı).
  final Widget? headerTrailing;

  /// Yapışkan sağ özet. Geniş ekranda sağ sütun, dar ekranda içeriğin üstü.
  final Widget? aside;
  final Widget child;

  /// İçerik sütununun azami genişliği (okuma sayfaları için sınırlanır).
  final double? contentMaxWidth;

  const WebAccountShell({
    super.key,
    required this.current,
    required this.title,
    required this.child,
    this.subtitle,
    this.headerTrailing,
    this.aside,
    this.contentMaxWidth,
  });

  @override
  ConsumerState<WebAccountShell> createState() => _WebAccountShellState();
}

class _WebAccountShellState extends ConsumerState<WebAccountShell> {
  final GlobalKey _rowKey = GlobalKey();

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const WebSiteHeader(),
            LayoutBuilder(builder: (final context, final box) {
              final double w = box.maxWidth;
              final double gutter = Sk.gutter(w);
              final bool side = w >= 1000;
              final bool wideAside = widget.aside != null && w >= 1240;

              Widget content = widget.child;
              if (widget.contentMaxWidth != null) {
                content = Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: widget.contentMaxWidth!),
                    child: content,
                  ),
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Sk.maxWidth + 112),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, AppSpacing.xl, gutter,
                        AppSpacing.section),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Crumbs(title: widget.title),
                          const SizedBox(height: AppSpacing.lg),
                          _TitleBand(
                            title: widget.title,
                            subtitle: widget.subtitle,
                            trailing: widget.headerTrailing,
                            compact: w < 700,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          if (!side) ...[
                            _NavChips(current: widget.current),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          if (!wideAside && widget.aside != null) ...[
                            widget.aside!,
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          Row(
                            key: _rowKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (side) ...[
                                SizedBox(
                                  width: 232,
                                  child: StickyBox(
                                    containerKey: _rowKey,
                                    top: AppSpacing.lg,
                                    child: _Sidebar(current: widget.current),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xxl + 4),
                              ],
                              Expanded(child: content),
                              if (wideAside) ...[
                                const SizedBox(width: AppSpacing.xxl + 4),
                                SizedBox(
                                  width: 300,
                                  child: StickyBox(
                                    containerKey: _rowKey,
                                    top: AppSpacing.lg,
                                    child: widget.aside!,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const WebMegaFooter(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Başlık bölümü
// ─────────────────────────────────────────────────────────────────────────

class _Crumbs extends StatelessWidget {
  final String title;
  const _Crumbs({required this.title});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle base =
        Sk.ui(context, size: 13, color: cs.onSurfaceVariant);
    Widget sep() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right_rounded,
              size: 16, color: cs.onSurfaceVariant),
        );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _CrumbLink(
            label: 'Ana sayfa',
            style: base,
            onTap: () => NavigationHandler.goToHome(context)),
        sep(),
        Text('Hesabım', style: base),
        sep(),
        Text(title,
            style: base.copyWith(
                color: cs.onSurface, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _CrumbLink extends StatelessWidget {
  final String label;
  final TextStyle style;
  final VoidCallback onTap;
  const _CrumbLink(
      {required this.label, required this.style, required this.onTap});

  @override
  Widget build(final BuildContext context) => Semantics(
        link: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Text(label,
                style: style.copyWith(decoration: TextDecoration.underline)),
          ),
        ),
      );
}

class _TitleBand extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool compact;

  const _TitleBand({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.compact,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title,
              style: Sk.display(context, size: compact ? 30 : 42, height: 1.05)),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle!,
              style: Sk.ui(context,
                  size: 15,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w500,
                  height: 1.5)),
        ],
      ],
    );
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: trailing == null || compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                if (trailing != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  trailing!,
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: text),
                const SizedBox(width: AppSpacing.xl),
                trailing!,
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Hesap menüsü
// ─────────────────────────────────────────────────────────────────────────

class _NavEntry {
  final WebAccountSection section;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int? count;
  const _NavEntry(this.section, this.label, this.icon, this.onTap, {this.count});
}

List<_NavEntry> _entries(final BuildContext context, final WidgetRef ref) {
  final bool loggedIn = ref.watch(isLoggedInProvider);
  final String uid = ref.watch(currentUserIdProvider) ?? '';
  final int upcoming = loggedIn && uid.isNotEmpty
      ? (ref.watch(myTicketsProvider(uid)).value?.upcoming.length ?? 0)
      : 0;
  final int favorites = loggedIn
      ? (() {
          final u = ref.watch(userProfileProvider).value;
          if (u == null) return 0;
          return u.favoriteShows.length +
              u.favoriteStages.length +
              u.favoritePlayers.length;
        })()
      : 0;
  return [
    _NavEntry(
      WebAccountSection.tickets,
      'Biletlerim',
      Icons.confirmation_number_outlined,
      () => loggedIn && uid.isNotEmpty
          ? NavigationHandler.goToMyTickets(context, uid)
          : NavigationHandler.goToLogin(context),
      count: upcoming == 0 ? null : upcoming,
    ),
    _NavEntry(
      WebAccountSection.favorites,
      'Favorilerim',
      Icons.favorite_border_rounded,
      () => NavigationHandler.goToFavorites(context),
      count: favorites == 0 ? null : favorites,
    ),
    _NavEntry(
      WebAccountSection.campaigns,
      'Kampanyalar',
      Icons.local_offer_outlined,
      () => NavigationHandler.goToCampaigns(context),
    ),
    _NavEntry(
      WebAccountSection.help,
      'Yardım ve destek',
      Icons.support_agent_rounded,
      () => NavigationHandler.goToHelpSupport(context),
    ),
    _NavEntry(
      WebAccountSection.contracts,
      'Yasal bilgiler',
      Icons.description_outlined,
      () => NavigationHandler.goToContracts(context),
    ),
  ];
}

class _Sidebar extends ConsumerWidget {
  final WebAccountSection current;
  const _Sidebar({required this.current});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<_NavEntry> entries = _entries(context, ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: cs.outlineVariant),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                child: Text('HESABIM',
                    style: Sk.ui(context,
                        size: 11,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w800,
                        letterSpacing: 1.8)),
              ),
              for (final _NavEntry e in entries)
                _SideItem(entry: e, selected: e.section == current),
              Divider(height: AppSpacing.xl, color: cs.outlineVariant),
              _SideItem(
                entry: _NavEntry(
                  WebAccountSection.contracts,
                  'Profil ve ayarlar',
                  Icons.tune_rounded,
                  () => NavigationHandler.goToProfile(context),
                ),
                selected: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SideHelp(),
      ],
    );
  }
}

class _SideItem extends StatelessWidget {
  final _NavEntry entry;
  final bool selected;
  const _SideItem({required this.entry, required this.selected});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fg = selected ? cs.onPrimaryContainer : cs.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: entry.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? cs.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: selected ? null : entry.onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          hoverColor: cs.onSurface.withValues(alpha: 0.05),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(entry.icon,
                      size: 20,
                      color: selected ? cs.onPrimaryContainer : cs.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(entry.label,
                        style: Sk.ui(context,
                            size: 14.5,
                            color: fg,
                            weight:
                                selected ? FontWeight.w800 : FontWeight.w600)),
                  ),
                  if (entry.count != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.onPrimaryContainer.withValues(alpha: 0.14)
                            : cs.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text('${entry.count}',
                          style: Sk.ui(context,
                              size: 12,
                              color: selected
                                  ? cs.onPrimaryContainer
                                  : cs.onPrimary,
                              weight: FontWeight.w800)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SideHelp extends StatelessWidget {
  const _SideHelp();

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yardıma mı ihtiyacın var?',
              style: Sk.ui(context, size: 14, weight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xs),
          Text('Bilet, ödeme ya da hesap için bize yaz.',
              style: Sk.ui(context,
                  size: 13,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w500,
                  height: 1.4)),
          const SizedBox(height: AppSpacing.sm),
          WebTextAction(
            label: 'E-posta gönder',
            icon: Icons.mail_outline_rounded,
            onTap: () => TiyatrolCommunicationActions.sendEmail(),
          ),
        ],
      ),
    );
  }
}

/// Dar pencerede menünün yerini alan yatay çipler.
class _NavChips extends ConsumerWidget {
  final WebAccountSection current;
  const _NavChips({required this.current});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<_NavEntry> entries = _entries(context, ref);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (final _, final __) => const SizedBox(width: 8),
        itemBuilder: (final context, final i) => SkChip(
          label: entries[i].label,
          icon: entries[i].icon,
          count: entries[i].count,
          selected: entries[i].section == current,
          onTap: entries[i].onTap,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Ortak parçalar
// ─────────────────────────────────────────────────────────────────────────

/// Çerçeveli düz yüzey (site kartı).
class WebPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const WebPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.color,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

/// Boş / hata / giriş gerekli durumu: ikon, başlık, açıklama, tek eylem.
class WebStatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const WebStatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return WebPanel(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.section),
      child: Semantics(
        container: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      color: cs.primaryContainer, shape: BoxShape.circle),
                  child: Icon(icon, color: cs.onPrimaryContainer, size: 28),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(title,
                    textAlign: TextAlign.center,
                    style: Sk.display(context, size: 24)),
                const SizedBox(height: AppSpacing.sm),
                Text(message,
                    textAlign: TextAlign.center,
                    style: Sk.ui(context,
                        size: 14.5,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w500,
                        height: 1.55)),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(160, 48)),
                    child: Text(actionLabel!),
                  ),
                ],
                if (secondaryLabel != null && onSecondary != null)
                  TextButton(
                      onPressed: onSecondary, child: Text(secondaryLabel!)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// İkon + metin, alt çizgisiz sessiz eylem (48dp dokunma alanı).
class WebTextAction extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool danger;

  const WebTextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.danger = false,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color c = onTap == null
        ? cs.onSurfaceVariant.withValues(alpha: 0.5)
        : (danger ? cs.error : cs.primary);
    return PressScale(
      onTap: onTap,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(label,
                  style: Sk.ui(context,
                      size: 13.5, color: c, weight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sayfa kaydırılırken [containerKey] kutusunun içinde, görünümün üstüne
/// [top] kadar yakın yapışan kutu. Yalnız boyama kaydırılır (yerleşim
/// değişmez): kaydırma uzunluğu etkilenmez, tıklamalar doğru yere gider.
class StickyBox extends StatefulWidget {
  final GlobalKey containerKey;
  final double top;
  final Widget child;

  const StickyBox({
    super.key,
    required this.containerKey,
    required this.child,
    this.top = 16,
  });

  @override
  State<StickyBox> createState() => _StickyBoxState();
}

class _StickyBoxState extends State<StickyBox> {
  ScrollableState? _scrollable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollable = Scrollable.maybeOf(context);
  }

  @override
  Widget build(final BuildContext context) => _StickyRender(
        containerKey: widget.containerKey,
        top: widget.top,
        position: _scrollable?.position,
        viewport: _scrollable?.context.findRenderObject() as RenderBox?,
        child: widget.child,
      );
}

class _StickyRender extends SingleChildRenderObjectWidget {
  final GlobalKey containerKey;
  final double top;
  final ScrollPosition? position;
  final RenderBox? viewport;

  const _StickyRender({
    required this.containerKey,
    required this.top,
    required this.position,
    required this.viewport,
    required super.child,
  });

  @override
  RenderObject createRenderObject(final BuildContext context) =>
      _RenderSticky(containerKey, top, position, viewport);

  @override
  void updateRenderObject(
      final BuildContext context, final _RenderSticky renderObject) {
    renderObject
      ..containerKey = containerKey
      ..top = top
      ..viewport = viewport
      ..position = position;
  }
}

class _RenderSticky extends RenderShiftedBox {
  _RenderSticky(this._containerKey, this._top, this._position, this._viewport)
      : super(null);

  GlobalKey _containerKey;
  double _top;
  ScrollPosition? _position;
  RenderBox? _viewport;
  bool _attached = false;

  set containerKey(final GlobalKey v) {
    _containerKey = v;
    markNeedsPaint();
  }

  set top(final double v) {
    if (_top == v) return;
    _top = v;
    markNeedsPaint();
  }

  set viewport(final RenderBox? v) => _viewport = v;

  set position(final ScrollPosition? v) {
    if (identical(v, _position)) return;
    if (_attached) _position?.removeListener(markNeedsPaint);
    _position = v;
    if (_attached) _position?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(final PipelineOwner owner) {
    super.attach(owner);
    _attached = true;
    _position?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _position?.removeListener(markNeedsPaint);
    _attached = false;
    super.detach();
  }

  @override
  void performLayout() {
    final RenderBox? c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(constraints.loosen().copyWith(minWidth: constraints.minWidth),
        parentUsesSize: true);
    size = constraints.constrain(c.size);
    (c.parentData! as BoxParentData).offset = Offset.zero;
  }

  double _shift() {
    final RenderBox? c = child;
    final RenderBox? v = _viewport;
    final RenderObject? ro = _containerKey.currentContext?.findRenderObject();
    if (c == null || v == null || ro is! RenderBox) return 0;
    if (!ro.attached || !ro.hasSize || !v.attached || !hasSize) return 0;
    try {
      final double containerTop = ro.localToGlobal(Offset.zero, ancestor: v).dy;
      final double selfTop = localToGlobal(Offset.zero, ancestor: v).dy;
      final double maxShift =
          (containerTop + ro.size.height) - selfTop - c.size.height;
      final double want = _top - selfTop;
      if (maxShift <= 0 || want <= 0) return 0;
      return want < maxShift ? want : maxShift;
    } catch (_) {
      return 0;
    }
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    final RenderBox? c = child;
    if (c == null) return;
    context.paintChild(c, offset + Offset(0, _shift()));
  }

  @override
  bool hitTestChildren(final BoxHitTestResult result,
      {required final Offset position}) {
    final RenderBox? c = child;
    if (c == null) return false;
    return result.addWithPaintOffset(
      offset: Offset(0, _shift()),
      position: position,
      hitTest: (final BoxHitTestResult r, final Offset p) =>
          c.hitTest(r, position: p),
    );
  }

  @override
  void applyPaintTransform(final RenderBox child, final Matrix4 transform) {
    transform.translate(0.0, _shift());
  }
}
