import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/base/base_page_wrapper.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/util/responsive_utils.dart';
import '../../../features/shows/domain/entities/show.dart';
import '../../../features/shows/presentation/widgets/detail/show_detail_actions.dart';
import '../../../features/shows/presentation/widgets/detail/sticky_aside.dart';
import '../../navigation/widgets/nav_handler.dart';
import '../optimized_cached_image.dart';
import '../theatre_show_card.dart';
import '../tiyatrol_hero.dart';
import 'ticket_kit.dart';
import 'ticket_listing.dart';

/// "KİM / NEREDE" SAYFALARI — oyuncu, sahne ve topluluk detayları için
/// ortak "tiyatro programı + künye bileti" iskeleti.
///
/// Oyun detayıyla (bkz. `show_detail_layouts.dart`) aynı ürün dili:
/// - Kimlik = fildişi bir künye bileti ([ProfileTicket]): marka şeridi +
///   tür (OYUNCU / SAHNE / TOPLULUK), gerçek fotoğraf, Playfair ad (perde
///   açılışıyla), gerçek alanlar; koçanda sayfanın TEK birincil aksiyonu.
/// - Program = temanın zemininde sakin bölümler (`ProgrammeSection`);
///   bağlı oyunlar bilet kartı / bilet satırı, seanslar koçan.
///
/// Üç gerçek kompozisyon ([ProfileDetailLayout]):
/// - masaüstü (≥1024): solda yapışkan künye bileti, sağda kayan program;
/// - tablet (768–1023): yatay bilet (koçan sağda), altında okuma sütunu;
/// - mobil (<768): dikey bilet + program, tek sütun.
///
/// Renkler temadan (`context.colors`, `TicketInk.accentOf`) — 5 tema korunur.

// ─────────────────────────────────────────────────────────────────────────
// Sayfa kabuğu
// ─────────────────────────────────────────────────────────────────────────

/// Web: kendi `Scaffold`'u (Material atası; `BasePageWrapper`'ın mobil
/// çatısı web'e bindirilmez). Mobil uygulama: `BasePageWrapper` —
/// geri tuşu/`PopScope`, durum çubuğu stili — ama başlık çubuğu, FAB ve
/// parçacık süsü kapalı; sayfa kendi geri/paylaş satırını çizer.
class ProfilePageShell extends StatelessWidget {
  final Widget child;
  const ProfilePageShell({super.key, required this.child});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final Widget stage =
        TicketStage(themed: true, spotlight: false, child: child);
    if (kIsWeb) {
      return Scaffold(backgroundColor: colors.surface, body: stage);
    }
    return BasePageWrapper(
      showBackButton: false,
      showFab: false,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: colors.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
        safeAreaBottom: false,
      ),
      child: stage,
    );
  }
}

/// Üstte sessiz ikonlar: geri (solda) + paylaş (sağda, sadece gerçek bir
/// paylaşım bağlantısı varsa).
class ProfileActionsRow extends StatelessWidget {
  final VoidCallback? onShare;
  final String shareLabel;

  const ProfileActionsRow({
    super.key,
    this.onShare,
    this.shareLabel = 'Paylaş',
  });

  @override
  Widget build(final BuildContext context) => Row(
        children: [
          const ShowBackButton(),
          const Spacer(),
          if (onShare != null)
            ShowQuietIconButton(
              icon: Icons.ios_share_rounded,
              label: shareLabel,
              onPressed: onShare,
            ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Künye bileti
// ─────────────────────────────────────────────────────────────────────────

/// Künye biletinin hangi kompozisyonda basıldığı.
/// - [stacked]: mobil — dikey bilet, fotoğraf küçük (portre) ya da bant.
/// - [aside]: masaüstü yapışkan panel — dikey bilet, büyük fotoğraf.
/// - [banner]: tablet — yatay bilet, fotoğraf solda, koçan sağda.
enum ProfileTicketLayout { stacked, aside, banner }

/// Kimlik bileti. Gövde: marka şeridi + [kind], gerçek fotoğraf, ad
/// (perde açılışıyla), isteğe bağlı [tagline] (oyuncunun sözü ya da
/// sahnenin adresi), [fields]. Koçan: [stubFields] + TEK birincil
/// [action]; aksiyon yoksa kimliğe özgü barkod basılır.
///
/// Giriş koreografisi (sayfanın tek hareket anı): bilet aşağıdan gelir →
/// ad soldan sağa açılır → alanlar belirir. Azaltılmış harekette statik.
class ProfileTicket extends StatefulWidget {
  final ProfileTicketLayout layout;
  final String kind;
  final String name;
  final String imageUrl;
  final String imageLabel;

  /// Fotoğraf portre mi (oyuncu) yoksa yatay mı (sahne, topluluk).
  final bool portrait;
  final IconData placeholderIcon;

  final String? tagline;

  /// [tagline] bir alıntı mı (Playfair italik, tırnaklı).
  final bool taglineIsQuote;

  final List<Widget> fields;
  final List<Widget> stubFields;
  final Widget? action;

  /// Barkod tohumu (kimliğin gerçek id'si).
  final String seed;

  /// Liste kartından uçan paylaşılmış fotoğraf etiketi.
  final String? heroTag;

  const ProfileTicket({
    super.key,
    required this.layout,
    required this.kind,
    required this.name,
    required this.imageUrl,
    required this.imageLabel,
    required this.seed,
    this.heroTag,
    this.portrait = false,
    this.placeholderIcon = Icons.theater_comedy_outlined,
    this.tagline,
    this.taglineIsQuote = false,
    this.fields = const [],
    this.stubFields = const [],
    this.action,
  });

  @override
  State<ProfileTicket> createState() => _ProfileTicketState();
}

class _ProfileTicketState extends State<ProfileTicket>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final Animation<double> _ticketIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.55, curve: AppMotion.standard));
  late final Animation<double> _headlineIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.3, 0.9, curve: AppMotion.dramatic));
  late final Animation<double> _detailsIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.55, 1.0, curve: AppMotion.standard));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _entrance.value = 1;
    } else if (!_started) {
      _entrance.forward();
    }
    _started = true;
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Widget _headline(final double size) => Semantics(
        header: true,
        child: AuthWipeReveal(
          reveal: _headlineIn,
          child: Text(widget.name, style: TicketInk.headline(size)),
        ),
      );

  Widget? _tagline(final double size) {
    final String text = widget.tagline?.trim() ?? '';
    if (text.isEmpty) return null;
    return FadeTransition(
      opacity: _detailsIn,
      child: widget.taglineIsQuote
          ? Text(
              '“$text”',
              style: GoogleFonts.playfairDisplay(
                color: TicketInk.inkSoft(0.78),
                fontSize: size,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            )
          : Text(
              text,
              style: TextStyle(
                color: TicketInk.inkSoft(0.72),
                fontSize: size - 1,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
    );
  }

  Widget? _fieldsRow(final List<Widget> fields) {
    if (fields.isEmpty) return null;
    return FadeTransition(
      opacity: _detailsIn,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.lg),
            Expanded(child: fields[i]),
          ],
        ],
      ),
    );
  }

  Widget _photo({final double? width, final double? height}) => _ProfilePhoto(
        url: widget.imageUrl,
        label: widget.imageLabel,
        icon: widget.placeholderIcon,
        width: width,
        height: height,
        heroTag: widget.heroTag,
      );

  Widget _body(final BuildContext context) {
    final Widget strip = TicketHeaderStrip(kind: widget.kind);
    final Widget? fieldsRow = _fieldsRow(widget.fields);

    switch (widget.layout) {
      case ProfileTicketLayout.stacked:
        final Widget? stackedTag = _tagline(15);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              strip,
              const SizedBox(height: AppSpacing.xl),
              if (widget.portrait)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _photo(width: 96, height: 128),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _headline(28),
                          if (stackedTag != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            stackedTag,
                          ],
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                _photo(height: 176),
                const SizedBox(height: AppSpacing.xl),
                _headline(30),
                if (stackedTag != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  stackedTag,
                ],
              ],
              if (fieldsRow != null) ...[
                const SizedBox(height: AppSpacing.lg),
                fieldsRow,
              ],
            ],
          ),
        );

      case ProfileTicketLayout.aside:
        final Widget? asideTag = _tagline(17);
        final double screenH = MediaQuery.sizeOf(context).height;
        final double photoH = widget.portrait
            ? (screenH * 0.36).clamp(220.0, 340.0)
            : (screenH * 0.24).clamp(160.0, 230.0);
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              strip,
              const SizedBox(height: AppSpacing.xl),
              _photo(height: photoH),
              const SizedBox(height: AppSpacing.xl),
              _headline(34),
              if (asideTag != null) ...[
                const SizedBox(height: AppSpacing.md),
                asideTag,
              ],
              if (fieldsRow != null) ...[
                const SizedBox(height: AppSpacing.lg),
                fieldsRow,
              ],
            ],
          ),
        );

      case ProfileTicketLayout.banner:
        final Widget? bannerTag = _tagline(16);
        return ConstrainedBox(
          // Koçan gövdenin yüksekliğine uyar; kısa bir gövdede koçandaki
          // aksiyon sıkışmasın.
          constraints: const BoxConstraints(minHeight: 260),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                strip,
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.portrait
                        ? _photo(width: 144, height: 192)
                        : _photo(width: 200, height: 132),
                    const SizedBox(width: AppSpacing.xxl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _headline(32),
                          if (bannerTag != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            bannerTag,
                          ],
                          if (fieldsRow != null) ...[
                            const SizedBox(height: AppSpacing.xl),
                            fieldsRow,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _stub() {
    final Widget closing =
        widget.action ?? TicketBarcode(seed: widget.seed, height: 36);

    if (widget.layout == ProfileTicketLayout.banner) {
      // Yatay biletin koçanı gövdenin yüksekliğini alır.
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final field in widget.stubFields) ...[
              FadeTransition(opacity: _detailsIn, child: field),
              const SizedBox(height: AppSpacing.md),
            ],
            if (widget.stubFields.isNotEmpty)
              const SizedBox(height: AppSpacing.xs),
            closing,
          ],
        ),
      );
    }

    final Widget? fieldsRow = _fieldsRow(widget.stubFields);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fieldsRow != null) ...[
            fieldsRow,
            const SizedBox(height: AppSpacing.lg),
          ],
          closing,
        ],
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final bool vertical = widget.layout != ProfileTicketLayout.banner;
    return FadeTransition(
      opacity: _ticketIn,
      child: AnimatedBuilder(
        animation: _ticketIn,
        builder: (final context, final child) => Transform.translate(
          offset: Offset(0, (1 - _ticketIn.value) * 40),
          child: child,
        ),
        child: AdmitTicket(
          direction: vertical ? Axis.vertical : Axis.horizontal,
          stubExtent: 260,
          shadows: AppShadows.level4(TicketInk.ink),
          body: _body(context),
          stub: _stub(),
        ),
      ),
    );
  }
}

/// Bilete basılı gerçek fotoğraf (Firebase). Yoksa kağıt tonunda sade bir
/// yer tutucu — görsel uydurulmaz.
class _ProfilePhoto extends StatelessWidget {
  final String url;
  final String label;
  final IconData icon;
  final double? width;
  final double? height;
  final String? heroTag;

  const _ProfilePhoto({
    required this.url,
    required this.label,
    required this.icon,
    this.width,
    this.height,
    this.heroTag,
  });

  @override
  Widget build(final BuildContext context) {
    final bool hasImage = url.trim().isNotEmpty;
    Widget image = hasImage
        ? Semantics(
            image: true,
            label: label,
            child: OptimizedCachedImage(
              imageUrl: url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              borderRadius: 0,
            ),
          )
        : Center(
            child: Icon(icon, size: 40, color: TicketInk.inkSoft(0.35)),
          );
    if (heroTag != null && heroTag!.isNotEmpty) {
      image = TiyatrolHero(tag: heroTag!, child: image);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: TicketInk.inkSoft(0.08),
          child: image,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Sayfa kompozisyonu
// ─────────────────────────────────────────────────────────────────────────

class ProfileDetailLayout extends StatefulWidget {
  final ScrollController controller;
  final Widget actions;
  final Widget Function(ProfileTicketLayout layout) ticket;

  /// [compact] → dar mobil: oyunlar bilet satırı, metin katlanır.
  final Widget Function(bool compact) programme;

  /// Web'de sayfa sonu footer'ı; mobil uygulamada null.
  final Widget? footer;

  const ProfileDetailLayout({
    super.key,
    required this.controller,
    required this.actions,
    required this.ticket,
    required this.programme,
    this.footer,
  });

  @override
  State<ProfileDetailLayout> createState() => _ProfileDetailLayoutState();
}

class _ProfileDetailLayoutState extends State<ProfileDetailLayout> {
  final GlobalKey _rowKey = GlobalKey();
  static const double _top = AppSpacing.huge;

  List<Widget> _tail(final double bottomInset) => [
        if (widget.footer != null)
          SliverToBoxAdapter(child: widget.footer)
        else
          SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.massive + bottomInset)),
      ];

  Widget _twoPane(final double width) {
    final bool roomy = width >= 1280;
    final double side = roomy ? AppSpacing.massive : AppSpacing.xxxl;
    final double asideWidth = roomy ? 400.0 : 360.0;
    final double gap = roomy ? 72.0 : AppSpacing.massive;

    return CustomScrollView(
      controller: widget.controller,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(side, _top, side, AppSpacing.section),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Row(
                  key: _rowKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: asideWidth,
                      child: StickyAside(
                        controller: widget.controller,
                        rowKey: _rowKey,
                        contentTop: _top,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            widget.actions,
                            const SizedBox(height: AppSpacing.lg),
                            widget.ticket(ProfileTicketLayout.aside),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Padding(
                            // İkon satırının altından, biletle aynı hizada.
                            padding: const EdgeInsets.only(top: 64),
                            child: widget.programme(false),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ..._tail(0),
      ],
    );
  }

  Widget _banner(final double bottomInset) => CustomScrollView(
        controller: widget.controller,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      widget.actions,
                      const SizedBox(height: AppSpacing.lg),
                      widget.ticket(ProfileTicketLayout.banner),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                  AppSpacing.section, AppSpacing.xxl, AppSpacing.section),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: widget.programme(false),
                ),
              ),
            ),
          ),
          ..._tail(bottomInset),
        ],
      );

  Widget _stacked(final double width, final double bottomInset) =>
      CustomScrollView(
        controller: widget.controller,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      widget.actions,
                      const SizedBox(height: AppSpacing.md),
                      widget.ticket(ProfileTicketLayout.stacked),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.massive, AppSpacing.xl, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: widget.programme(width < 600),
                ),
              ),
            ),
          ),
          if (widget.footer != null)
            const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.section)),
          ..._tail(bottomInset),
        ],
      );

  @override
  Widget build(final BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return LayoutBuilder(
      builder: (final context, final constraints) {
        final double width = constraints.maxWidth;
        if (width >= ResponsiveUtils.tabletBreakpoint) return _twoPane(width);
        if (width >= ResponsiveUtils.mobileBreakpoint) {
          return _banner(bottomInset);
        }
        return _stacked(width, bottomInset);
      },
    );
  }
}

/// [key]'li bölümü görünür alana kaydırır (koçandaki "... gör" aksiyonu).
void profileScrollTo(final BuildContext context, final GlobalKey key) {
  final BuildContext? target = key.currentContext;
  if (target == null) return;
  final bool reduce = MediaQuery.of(context).disableAnimations;
  Scrollable.ensureVisible(
    target,
    duration: reduce ? Duration.zero : AppMotion.slow,
    curve: AppMotion.dramatic,
    alignment: 0.06,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Program parçaları
// ─────────────────────────────────────────────────────────────────────────

/// Oyuncunun/topluluğun `nowShowsId` gibi ELLE tutulan "sahnede" listesini
/// canlı takvimle (`activeShowsProvider` — gelecek etkinliği olan ya da
/// harici satıştaki oyunlar) çapraz kontrol eder. Listede olup artık
/// aktif olmayan oyunlar SESSİZCE KAYBOLMAZ, geçmişe taşınır.
/// [liveActive] henüz yüklenmediyse (null) liste olduğu gibi kalır.
({List<Show> active, List<Show> past}) splitShowsByLiveActivity({
  required final List<Show> claimedActive,
  required final List<Show> past,
  required final List<Show>? liveActive,
}) {
  if (liveActive == null) return (active: claimedActive, past: past);
  final Set<String> liveIds = liveActive.map((final s) => s.id).toSet();
  final List<Show> active = [];
  final List<Show> demoted = [];
  for (final show in claimedActive) {
    (liveIds.contains(show.id) ? active : demoted).add(show);
  }
  final Set<String> seen = active.map((final s) => s.id).toSet();
  final List<Show> merged = [];
  for (final show in [...demoted, ...past]) {
    if (seen.add(show.id)) merged.add(show);
  }
  return (active: active, past: merged);
}

/// Bağlı oyunlar: dar mobilde bilet satırları ([ShowTicketRow]), daha
/// genişte paylaşılan bilet koçanı kartı ([TheatreShowCard]) ızgarası.
class ProfileShowsBlock extends StatelessWidget {
  final List<Show> shows;
  final bool compact;

  const ProfileShowsBlock(
      {super.key, required this.shows, required this.compact});

  void _open(final BuildContext context, final Show show) =>
      NavigationHandler.goToShow(context, show.id, show.name);

  @override
  Widget build(final BuildContext context) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < shows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            ShowTicketRow(
              key: ValueKey('profile-show-${shows[i].id}'),
              show: shows[i],
              onTap: () => _open(context, shows[i]),
            ),
          ],
        ],
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Kartların kalkma/gölge efekti kırpılmasın.
      clipBehavior: Clip.none,
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      itemCount: shows.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 232,
        mainAxisSpacing: AppSpacing.xl,
        crossAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (final context, final i) => TheatreShowCard(
        key: ValueKey('profile-card-${shows[i].id}'),
        show: shows[i],
        heroFrom: 'profile',
        onTap: () => _open(context, shows[i]),
      ),
    );
  }
}

/// Arşiv (geçmiş oyunlar): hafif bilet satırları, genişte iki sütun.
class ProfileArchiveBlock extends StatelessWidget {
  final List<Show> shows;
  const ProfileArchiveBlock({super.key, required this.shows});

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final constraints) {
          final double maxW = constraints.maxWidth;
          final bool twoColumns = maxW >= 560;
          final double itemW = twoColumns
              ? ((maxW - AppSpacing.lg) / 2).floorToDouble()
              : maxW;
          return Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              for (final show in shows)
                SizedBox(
                  width: itemW,
                  child: ShowTicketRow(
                    key: ValueKey('profile-archive-${show.id}'),
                    show: show,
                    onTap: () => NavigationHandler.goToShow(
                        context, show.id, show.name),
                  ),
                ),
            ],
          );
        },
      );
}

/// Boş bölüm için sade not: ne olduğunu söyleyen tek cümle (+ isteğe
/// bağlı tek bağlantı).
class ProfileQuietNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const ProfileQuietNote({
    super.key,
    required this.icon,
    required this.text,
    this.action,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: colors.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: context.textTheme.bodyLarge
                    ?.copyWith(color: colors.onSurfaceVariant, height: 1.5),
              ),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.xs),
                action!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Temanın vurgusunda, 48dp yüksekliğinde sade metin bağlantısı (tema
/// zemininde — kağıt üstü için `TicketTextLink`).
class ProfileTextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const ProfileTextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(final BuildContext context) {
    final ButtonStyle style = TextButton.styleFrom(
      foregroundColor: context.colors.primary,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );
    return icon == null
        ? TextButton(onPressed: onTap, style: style, child: Text(label))
        : TextButton.icon(
            onPressed: onTap,
            style: style,
            icon: Icon(icon, size: 20),
            label: Text(label),
          );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Hata / bulunamadı
// ─────────────────────────────────────────────────────────────────────────

/// Profil yüklenemediğinde: geri satırı + koçanı kopmuş bilet. Kayıt yoksa
/// ("... bulunamadı") yeniden denemek anlamsız → oyunlara yönlendirir;
/// bağlantı sorunu ise "Tekrar dene".
class ProfileErrorView extends StatelessWidget {
  final Object error;
  final String notFoundTitle;
  final String failedTitle;
  final VoidCallback onRetry;

  const ProfileErrorView({
    super.key,
    required this.error,
    required this.notFoundTitle,
    required this.failedTitle,
    required this.onRetry,
  });

  @override
  Widget build(final BuildContext context) {
    final bool notFound = error.toString().contains('bulunamadı');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileActionsRow(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: notFound
                    ? TicketNotice(
                        label: 'BULUNAMADI',
                        title: notFoundTitle,
                        message: 'Bağlantı eskimiş ya da kayıt kaldırılmış '
                            'olabilir. Sahnedeki oyunlara göz atabilirsin.',
                        actionLabel: 'Oyunlara göz at',
                        actionIcon: Icons.theater_comedy_rounded,
                        onAction: () =>
                            NavigationHandler.goToDiscover(context),
                      )
                    : TicketNotice(
                        label: 'BAĞLANTI SORUNU',
                        title: failedTitle,
                        message: 'Bilgiler şu an getirilemedi. '
                            'Bağlantını kontrol edip tekrar dene.',
                        actionLabel: 'Tekrar dene',
                        actionIcon: Icons.refresh_rounded,
                        onAction: onRetry,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
