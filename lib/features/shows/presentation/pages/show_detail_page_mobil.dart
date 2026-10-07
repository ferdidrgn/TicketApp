import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/util/global_scroll_mixin.dart';
import 'package:ticketapp/features/chatbot/presentation/widgets/show_chat_bubble_button.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_detail_provider.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../auth/presentation/providers/auth_provider.dart'
    show currentUserIdProvider;
import '../widgets/detail/show_detail_actions.dart';
import '../widgets/detail/show_detail_data.dart';
import '../widgets/detail/show_detail_layouts.dart';
import '../widgets/detail/show_detail_mobile_layout.dart';

/// OYUN DETAYI — MOBİL UYGULAMA (Android/iOS, telefon + tablet).
///
/// Keşfet dili: gerçek afiş (Hero), yumuşak Material bilgi yüzeyi, TEK
/// birincil "Bilet al". Ad/sanat afişte; koçan kimliği yok. Seanslar
/// satın alma adımı olduğu için programda durur. Paylaş/favori üstte
/// sessiz ikonlar.
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

  late final Animation<double> _ticketIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.55, curve: AppMotion.standard));
  late final Animation<double> _headline = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.2, 1.0, curve: AppMotion.dramatic));
  late final Animation<double> _details = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.55, 1.0, curve: AppMotion.standard));

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
    // Afiş Hero ilk karede durur; yazılar uçuş biter bitmez açılır.
    // Shimmer yok — iskelet Hero hedefini geciktirip geçişi öldürüyordu.
    if (!_entranceStarted) {
      _entranceStarted = true;
      if (_reduceMotion) {
        _entrance.value = 1;
      } else {
        _entrance.forward();
      }
    }
  }

  @override
  void dispose() {
    // `scrollController` GlobalScrollMixin tarafından dispose ediliyor.
    // (Önceden burada bir kez daha dispose ediliyordu → mixin'in
    // removeListener'ı dispose edilmiş controller'a çağrılıyordu.)
    _entrance.dispose();
    _scrolled.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }
    _scrolled.value = scrollController.offset > 280;
  }

  /// "Bilet al" → seanslar (koltuk seçimi seansın koçanından başlar).
  void _scrollToSessions() {
    final BuildContext? target = _sessionsKey.currentContext;
    if (target == null) {
      return;
    }
    Scrollable.ensureVisible(
      target,
      duration: _reduceMotion ? Duration.zero : AppMotion.slow,
      curve: AppMotion.dramatic,
      alignment: 0.08,
    );
  }

  Future<void> _openExternal(final String url) async {
    if (_openingExternal) {
      return;
    }
    setState(() => _openingExternal = true);
    await openExternalTickets(context, url);
    if (!mounted) {
      return;
    }
    setState(() => _openingExternal = false);
  }

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
        tear: const AlwaysStoppedAnimation<double>(0),
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
    final String previewTitle =
        TiyatrolHeroFlight.field(context, 'title') ?? '';
    final String previewImage =
        TiyatrolHeroFlight.field(context, 'imageUrl') ?? '';
    final loadedState = detailAsync.value;
    final ShowDetailData? loaded =
        loadedState == null ? null : ShowDetailData.from(loadedState);
    final ShowDetailData data = loaded ??
        ShowDetailData.preview(
          id: widget.showId,
          name: previewTitle,
          imageUrl: previewImage,
        );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (final didPop, final _) {
        if (!didPop) NavigationHandler.smartGoBack(context);
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: detailAsync.hasError && loaded == null
            ? SafeArea(
                child: ShowDetailError(
                  onRetry: () =>
                      ref.invalidate(showDetailProvider(widget.showId)),
                ),
              )
            : ShowDetailMobileLayout(
                args: _args(data),
                scrolled: _scrolled,
                contentReady: loaded != null,
              ),
      ),
    );
  }
}
