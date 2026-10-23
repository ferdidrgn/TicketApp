import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../core/util/responsive_utils.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/global_error_widget.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../auth/presentation/providers/auth_provider.dart'
    show currentUserIdProvider;
import '../../../chatbot/presentation/widgets/show_chat_bubble_button.dart';
import '../providers/show_detail_provider.dart';
import '../widgets/detail/show_detail_actions.dart';
import '../widgets/detail/show_detail_data.dart';
import '../widgets/detail/show_detail_layouts.dart';
import '../widgets/detail/show_detail_mobile_layout.dart';
import '../widgets/detail/show_detail_skeleton.dart';

/// OYUN DETAYI — WEB. "Tiyatro programı + bilet", üç gerçek kompozisyon:
/// - masaüstü (≥1024): iki bölmeli kalıcı ayrım — solda yapışkan oyun
///   bileti (afiş, ad, alanlar; koçanda en yakın seans + fiyat + TEK
///   birincil aksiyon), sağda kayan program; footer tam genişlikte.
/// - tablet (768–1023): yatay bilet (koçan sağda, aksiyon koçanda), altında
///   ortalanmış okuma sütununda program.
/// - dar (<768): mobil düzen — afiş bandı + dikey bilet + yapışkan alt
///   bilet çubuğu.
///
/// `BasePageWrapper` kullanılmıyor (web'de mobil çatıyı bindiriyordu); bu
/// yüzden sayfa kendi `Scaffold`'unu kurar — Material atası olmadan
/// InkWell/TextField çöker.
class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage>
    with TickerProviderStateMixin, GlobalScrollMixin {
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final AnimationController _tear =
      AnimationController(vsync: this, duration: AppMotion.normal);

  late final Animation<double> _ticketIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.55, curve: AppMotion.standard));
  late final Animation<double> _headline = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.3, 0.9, curve: AppMotion.dramatic));
  late final Animation<double> _details = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.55, 1.0, curve: AppMotion.standard));
  late final Animation<double> _tearCurve =
      CurvedAnimation(parent: _tear, curve: Curves.easeInCubic);

  final ValueNotifier<bool> _scrolled = ValueNotifier(false);
  final GlobalKey _sessionsKey = GlobalKey();

  bool _reduceMotion = false;
  bool _entranceStarted = false;
  bool _scrollToEventsHandled = false;
  bool _openingExternal = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion) _entrance.value = 1;
  }

  @override
  void dispose() {
    // `scrollController` GlobalScrollMixin tarafından dispose ediliyor.
    _entrance.dispose();
    _tear.dispose();
    _scrolled.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    _scrolled.value = scrollController.offset > 280;
  }

  void _startEntrance() {
    if (_entranceStarted || !mounted) return;
    _entranceStarted = true;
    if (_reduceMotion) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  /// Sezon takviminden ("?scrollTo=etkinlikler" ile) gelindiyse, sayfa
  /// hazır olur olmaz seanslar bölümüne kaydırır. Görseller yüklenirken
  /// yerleşim biraz kayabileceği için kısa bir gecikmeyle tekrar dener.
  void _maybeScrollToEvents() {
    if (_scrollToEventsHandled || !mounted) return;
    final scrollTo = GoRouterState.of(context).uri.queryParameters['scrollTo'];
    if (scrollTo != 'etkinlikler') return;
    _scrollToEventsHandled = true;

    _scrollToSessions();
    Future.delayed(AppMotion.normal, _scrollToSessions);
  }

  /// "Bilet al" → seanslar (koltuk seçimi seansın koçanından başlar).
  void _scrollToSessions() {
    if (!mounted) return;
    final BuildContext? target = _sessionsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: _reduceMotion ? Duration.zero : AppMotion.slow,
      curve: AppMotion.dramatic,
      alignment: 0.06,
    );
  }

  Future<void> _openExternal(final String url) async {
    if (_openingExternal) return;
    setState(() => _openingExternal = true);
    final Future<void> tearing =
        _reduceMotion ? Future<void>.value() : _tear.forward(from: 0);
    await openExternalTickets(context, url);
    await tearing;
    if (!mounted) return;
    setState(() => _openingExternal = false);
    if (_reduceMotion) {
      _tear.value = 0;
    } else {
      _tear.reverse();
    }
  }

  /// Önceden web'de seans satırlarının hiç `onTap`'i yoktu — bilet almanın
  /// tek yolu kopuktu. Mobil ile aynı akış: koltuk seçimi (misafir →
  /// "guest", koltuk ekranı bunu kendisi ele alıyor).
  void _goToSeats(final ShowSession session) {
    final userId = ref.read(currentUserIdProvider) ?? "guest";
    NavigationHandler.goToSeatSelection(
        context, widget.showId, session.event.id, userId);
  }

  ShowDetailViewArgs _args(final ShowDetailData data) => ShowDetailViewArgs(
        data: data,
        controller: scrollController,
        sessionsKey: _sessionsKey,
        ticketIn: _ticketIn,
        headline: _headline,
        details: _details,
        tear: _tearCurve,
        onBuy: _scrollToSessions,
        onExternal: () => _openExternal(data.show.externalTicketUrl),
        externalBusy: _openingExternal,
        onSelectSession: _goToSeats,
        footer: const Footer(),
        // Gösteriye özel SSS sohbet balonu — yerel anahtar kelime
        // eşleştirmesi, ağ çağrısı yok (bkz. ShowFaqMatcher).
        chatBubble: ShowChatBubbleButton(
            showId: data.show.id, showName: data.show.name),
      );

  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(showDetailProvider(widget.showId));
    final double width = MediaQuery.sizeOf(context).width;
    final bool desktop = width >= ResponsiveUtils.tabletBreakpoint;
    final bool tablet = !desktop && width >= ResponsiveUtils.mobileBreakpoint;

    final Widget body = detailAsync.when(
      loading: () => ShowDetailSkeleton(twoPane: desktop),
      error: (final err, final stack) => GlobalErrorWidget(
        message: err.toString(),
        onRetry: () => ref.invalidate(showDetailProvider(widget.showId)),
      ),
      data: (final state) {
        final data = ShowDetailData.from(state);
        WidgetsBinding.instance.addPostFrameCallback((final _) {
          _startEntrance();
          _maybeScrollToEvents();
        });
        final args = _args(data);
        if (desktop) return ShowDetailTwoPaneLayout(args: args);
        if (tablet) return ShowDetailBannerLayout(args: args);
        return ShowDetailMobileLayout(args: args, scrolled: _scrolled);
      },
    );

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: TicketStage(themed: true, child: body),
    );
  }
}
