import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/tickets/presentation/pages/ticket_details_modal.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../providers/my_ticket_provider.dart';
import '../widgets/wallet_ticket.dart';
import '../widgets/web/my_tickets_desktop_view.dart';

/// BİLETLERİM — bilet cüzdanı. Mobil/tablette iki sekme (Yaklaşan /
/// Geçmiş) altında gerçek bilet koçanları; masaüstünde (≥1024) ayrı,
/// iki sütunlu web düzeni (`MyTicketsDesktopPage`). Bilete dokununca
/// bilet "anı" açılır: QR'lı giriş bileti.
class MyTicketPage extends ConsumerStatefulWidget {
  final String userId;

  const MyTicketPage({super.key, required this.userId});

  @override
  ConsumerState<MyTicketPage> createState() => _MyTicketPageState();
}

class _MyTicketPageState extends ConsumerState<MyTicketPage>
    with
        SingleTickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        GlobalScrollMixin {
  late final TabController _tabController;

  // 🔥 DÜZELTME: GlobalScrollMixin'in tek `scrollController`'ı önceden HER
  // İKİ `_TicketList`e (Sıradakiler + Anılar) birden veriliyordu. TabBarView
  // komşu sekmeyi de canlı tutar (PageView'ın varsayılan cache davranışı),
  // yani iki ListView AYNI ANDA aynı controller'a bağlanmaya çalışıyor —
  // Flutter bunu "ScrollController attached to multiple scroll views"
  // hatasıyla reddedip sayfayı çökertiyordu (hem yaklaşan hem geçmiş bileti
  // olan HER kullanıcı için garanti bir çökme). Gerçek/paylaşılan
  // controller (BasePageWrapper'ın FAB/scroll davranışı için) artık SADECE
  // o an görünen sekmeye veriliyor; diğeri kendi tek kullanımlık
  // controller'ını kullanıyor.
  final ScrollController _upcomingFallbackController = ScrollController();
  final ScrollController _pastFallbackController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void onLoadMore() => debugPrint("Daha fazla bilet yükleniyor...");

  @override
  void dispose() {
    _tabController.dispose();
    _upcomingFallbackController.dispose();
    _pastFallbackController.dispose();
    super.dispose();
  }

  void _retry() => ref.invalidate(myTicketsProvider(widget.userId));

  @override
  Widget build(final BuildContext context) {
    super.build(context);

    // Masaüstünde (>=1024px) gerçek Firestore verisiyle çalışan, ayrı bir
    // web düzeni kullanılır (bkz. MyTicketsDesktopPage).
    if (context.isDesktop)
      return MyTicketsDesktopPage(
        userId: widget.userId,
        onTicketTap: _showTicketDetails,
      );

    final ticketsAsync = ref.watch(myTicketsProvider(widget.userId));
    final tickets = ticketsAsync.value;
    final bool tablet = context.isTablet;
    final double gutter = tablet ? AppSpacing.xxxl : AppSpacing.lg;

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      title: 'Biletlerim',
      // İskeleti bu sayfa kendisi çiziyor; `true` verilirse BasePageWrapper
      // içeriği yükleme boyunca görünmez tutuyor ve iskelet hiç görünmüyordu.
      isLoading: false,
      customScrollController: scrollController,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        ambientColor: context.colors.primary.withOpacity(0.04),
        safeAreaTop: true,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: tablet ? 760 : double.infinity),
          child: Column(
            children: [
              if (tickets == null || tickets.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      gutter, AppSpacing.xs, gutter, AppSpacing.md),
                  child: _TabSelector(
                    controller: _tabController,
                    upcomingCount: tickets?.upcoming.length,
                    pastCount: tickets?.past.length,
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(myTicketsProvider(widget.userId)),
                  color: context.colors.primary,
                  child: ticketsAsync.when(
                    loading: () => ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                          gutter, AppSpacing.sm, gutter, AppSpacing.xxl),
                      itemCount: 4,
                      separatorBuilder: (final _, final __) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (final _, final __) =>
                          WalletTicketSkeleton(large: tablet),
                    ),
                    error: (final err, final stack) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: AppSpacing.massive),
                        TicketsErrorState(onRetry: _retry),
                      ],
                    ),
                    data: (final tickets) {
                      if (tickets.isEmpty)
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: AppSpacing.massive),
                            TicketsEmptyState(),
                          ],
                        );

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _TicketList(
                            tickets: tickets.upcoming,
                            gutter: gutter,
                            large: tablet,
                            onTicketTap: _showTicketDetails,
                            scrollController: _tabController.index == 0
                                ? scrollController
                                : _upcomingFallbackController,
                            empty: const TicketsEmptyState(
                              title: 'Yaklaşan biletin yok',
                              message: 'Geçmiş biletlerin "Geçmiş" '
                                  'sekmesinde. Yeni bir oyun için göz at.',
                            ),
                          ),
                          _TicketList(
                            tickets: tickets.past,
                            gutter: gutter,
                            large: tablet,
                            onTicketTap: _showTicketDetails,
                            scrollController: _tabController.index == 1
                                ? scrollController
                                : _pastFallbackController,
                            empty: const TicketsEmptyState(
                              title: 'Henüz geçmiş biletin yok',
                              message: 'İzlediğin oyunların biletleri seanstan '
                                  'sonra burada saklanır.',
                              showCta: false,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTicketDetails(final DetailedTicket ticket) {
    HapticFeedback.mediumImpact();
    if (context.isDesktop) {
      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (final _) => TicketDetailsDialog(ticket: ticket),
      );
      return;
    }
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (final _) => TicketDetailsModal(ticket: ticket));
  }
}

class _TabSelector extends StatelessWidget {
  final TabController controller;
  final int? upcomingCount;
  final int? pastCount;

  const _TabSelector({
    required this.controller,
    required this.upcomingCount,
    required this.pastCount,
  });

  String _label(final String name, final int? count) =>
      count == null || count == 0 ? name : '$name  $count';

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    return TabBar(
      controller: controller,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: cs.primary, width: 2.5),
      ),
      labelColor: cs.onSurface,
      unselectedLabelColor: cs.onSurfaceVariant,
      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      dividerColor: cs.outlineVariant,
      tabs: [
        Tab(height: 48, text: _label('Yaklaşan', upcomingCount)),
        Tab(height: 48, text: _label('Geçmiş', pastCount)),
      ],
    );
  }
}

class _TicketList extends StatelessWidget {
  final List<DetailedTicket> tickets;
  final Function(DetailedTicket) onTicketTap;
  final ScrollController scrollController;
  final double gutter;
  final bool large;
  final Widget empty;

  const _TicketList({
    required this.tickets,
    required this.onTicketTap,
    required this.scrollController,
    required this.gutter,
    required this.large,
    required this.empty,
  });

  @override
  Widget build(final BuildContext context) {
    if (tickets.isEmpty)
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [const SizedBox(height: AppSpacing.xxxl), empty],
      );

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(gutter, AppSpacing.sm, gutter, 120),
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      itemCount: tickets.length,
      separatorBuilder: (final _, final __) =>
          SizedBox(height: large ? AppSpacing.xl : AppSpacing.lg),
      itemBuilder: (final context, final index) => WalletTicket(
        key: ValueKey('ticket-${tickets[index].ticket.id}'),
        ticket: tickets[index],
        large: large,
        onTap: () => onTicketTap(tickets[index]),
      ),
    );
  }
}
