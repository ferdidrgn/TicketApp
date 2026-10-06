import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/util/global_scroll_mixin.dart';
import 'package:ticketapp/features/chatbot/presentation/widgets/show_chat_bubble_button.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_detail_provider.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../auth/presentation/providers/auth_provider.dart'
    show currentUserIdProvider;
import '../widgets/detail/show_detail_actions.dart';
import '../widgets/detail/show_detail_data.dart';
import '../widgets/detail/show_detail_layouts.dart';
import '../widgets/detail/show_detail_skeleton.dart';
import '../../../../shared/widgets/ticket/stage_entrance.dart';
import '../../../../shared/widgets/ticket/wipe_on_return.dart';

/// OYUN DETAYI — MOBİL UYGULAMA (Android/iOS, telefon + tablet).
///
/// Editoryal oyun detayı: sinematik afiş, Playfair başlık (perde açılışı),
/// broşür program (seanslar = yırtılabilir koçanlar). TEK birincil aksiyon
/// yapışkan altta "Bilet al" damgası. Paylaş/favori üstte sessiz ikonlar.
///
/// Büyük tablette (≥1024) web ile aynı iki bölmeli düzen.
class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage>
    with TickerProviderStateMixin, GlobalScrollMixin, ReplayWipeOnReturn {
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

  /// Afiş bandı geçildi mi — üst ikonların zemini buna göre değişir.
  final ValueNotifier<bool> _scrolled = ValueNotifier(false);
  final GlobalKey _sessionsKey = GlobalKey();

  bool _reduceMotion = false;
  bool _entranceStarted = false;
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
    // (Önceden burada bir kez daha dispose ediliyordu → mixin'in
    // removeListener'ı dispose edilmiş controller'a çağrılıyordu.)
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

  @override
  void replayWipe() {
    if (!mounted || _reduceMotion) return;
    _entrance
      ..reset()
      ..forward();
  }

  /// "Bilet al" → seanslar (koltuk seçimi seansın koçanından başlar).
  void _scrollToSessions() {
    final BuildContext? target = _sessionsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: _reduceMotion ? Duration.zero : AppMotion.slow,
      curve: AppMotion.dramatic,
      alignment: 0.08,
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

  void _goToSeats(final ShowSession session) {
    // Auth'dan gelen UID'yi doğrudan alıyoruz (misafir: koltuk ekranı
    // "guest" kimliğini kendisi ele alıyor).
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
        // Gösteriye özel SSS sohbet balonu — yerel anahtar kelime
        // eşleştirmesi, ağ çağrısı yok (bkz. ShowFaqMatcher).
        chatBubble: ShowChatBubbleButton(
            showId: data.show.id, showName: data.show.name),
      );

  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(showDetailProvider(widget.showId));
    final colors = context.colors;
    final bool twoPane = context.isDesktop;

    return BasePageWrapper(
      showBackButton: false,
      // Yukarı-kaydır FAB'ı yapışkan alt çubukla çakışıyordu; kaldırıldı.
      showFab: false,
      customScrollController: scrollController,
      isLoading: detailAsync.isLoading && !detailAsync.hasValue,
      shimmerSkeleton: ShowDetailSkeleton(twoPane: twoPane),
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: colors.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
        // Afiş durum çubuğunun altına uzanır; güvenli alanı düzen kendisi
        // uygular (üst ikonlar + alt çubuk).
        safeAreaTop: false,
        safeAreaBottom: false,
      ),
      child: detailAsync.when(
        loading: () => ShowDetailSkeleton(twoPane: twoPane),
        error: (final err, final stack) => SafeArea(
          child: ShowDetailError(
            onRetry: () => ref.invalidate(showDetailProvider(widget.showId)),
          ),
        ),
        data: (final state) {
          final data = ShowDetailData.from(state);
          WidgetsBinding.instance
              .addPostFrameCallback((final _) => _startEntrance());
          final Widget page = twoPane
              ? SafeArea(child: ShowDetailTwoPaneLayout(args: _args(data)))
              : ShowDetailStackedLayout(
                  args: _args(data),
                  scrolled: _scrolled,
                  heroPoster: true,
                );
          return StageEntrance(
            imageUrl: data.show.imageUrl,
            label: data.show.name,
            child: page,
          );
        },
      ),
    );
  }
}
