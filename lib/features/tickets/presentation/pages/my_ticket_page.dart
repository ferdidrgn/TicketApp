import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/tickets/presentation/pages/ticket_details_modal.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../providers/my_ticket_provider.dart';
import '../widgets/web/my_tickets_desktop_view.dart';

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

  @override
  Widget build(final BuildContext context) {
    super.build(context);

    // Masaüstünde (>=1024px) gerçek Firestore verisiyle çalışan, ayrı bir
    // "premium" web deneyimi kullanılır (bkz. _MyTicketsDesktopBody).
    // Mobil/tablet gövdesi aşağıda AYNEN kalır — bu görevin kapsamı sadece
    // masaüstü deneyimini eklemek, mobili yeniden yazmak değil.
    if (context.isDesktop)
      return MyTicketsDesktopPage(
        userId: widget.userId,
        onTicketTap: _showTicketDetails,
      );

    final ticketsAsync = ref.watch(myTicketsProvider(widget.userId));

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      title: 'Sanat Ajandan',
      subtitle: 'Unutulmaz anların koleksiyonu...',
      rightIcon: Icons.theater_comedy_rounded,
      isLoading: ticketsAsync.isLoading,
      customScrollController: scrollController,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        ambientColor: context.colors.primary.withOpacity(0.05),
        safeAreaTop: true,
      ),
      child: Column(
        children: [
          // Sayfa Başlığı ve Alt Başlığı
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl, AppSpacing.sm, AppSpacing.xxl, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sanat Ajandan',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Unutulmaz anların koleksiyonu...',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Tab Seçici
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl, vertical: AppSpacing.sm),
            child: _TabSelector(controller: _tabController),
          ),

          // Liste Alanı
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(myTicketsProvider(widget.userId)),
              color: context.colors.primary,
              child: ticketsAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  itemCount: 3,
                  itemBuilder: (final _, final __) => const ShimmerCard(),
                ),
                error: (final err, final stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: context.colors.error),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Biletlerin yüklenirken bir sorun oluştu.',
                            textAlign: TextAlign.center,
                            style: context.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(err.toString(),
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant)),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton.icon(
                          onPressed: () => ref
                              .invalidate(myTicketsProvider(widget.userId)),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (final tickets) {
                  if (tickets.isEmpty) return const _EmptyState();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _TicketList(
                        tickets: tickets.upcoming,
                        onTicketTap: _showTicketDetails,
                        scrollController: _tabController.index == 0
                            ? scrollController
                            : _upcomingFallbackController,
                      ),
                      _TicketList(
                        tickets: tickets.past,
                        isPast: true,
                        onTicketTap: _showTicketDetails,
                        scrollController: _tabController.index == 1
                            ? scrollController
                            : _pastFallbackController,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTicketDetails(final DetailedTicket ticket) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (final _) => TicketDetailsModal(ticket: ticket));
  }
}

class _TicketCard extends StatelessWidget {
  final DetailedTicket detailedTicket;
  final bool isPast;
  final VoidCallback onTap;

  const _TicketCard(
      {required this.detailedTicket, required this.onTap, this.isPast = false});

  @override
  Widget build(final BuildContext context) =>
      GestureDetector(onTap: onTap, child: _buildBaseCard(context));

  Widget _buildBaseCard(final BuildContext context) {
    final dateInfo =
        DateFormatter.formatForEventCard(detailedTicket.event?.date ?? '');
    final colors = context.colors;

    return Semantics(
      button: true,
      label: (isPast ? 'Geçmiş bilet: ' : 'Yaklaşan bilet: ') +
          (detailedTicket.show?.name ?? 'Sanat Eseri'),
      child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        // "Sahne Köşesi" imzası: bu sayfadaki tek, en yüksek değerli kart
        // türü (bilet) için bilinçli aksan.
        borderRadius: AppRadius.asymLg,
        boxShadow: AppShadows.level2(colors.primary),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.asymLg,
        child: IntrinsicHeight(
          child: Row(
            children: [
              _ArtDateSidebar(
                day: dateInfo['day'] ?? '00',
                month: (dateInfo['monthName'] ?? '---').toUpperCase(),
                isPast: isPast,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detailedTicket.show?.name ?? 'Sanat Eseri',
                          style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color:
                                  isPast ? colors.outline : colors.onSurface)),
                      const SizedBox(height: AppSpacing.md),
                      _ArtInfoLine(
                          icon: Icons.castle_rounded,
                          text: detailedTicket.stage?.name ?? 'Sahne'),
                      const Spacer(),
                      const Divider(height: AppSpacing.xl, thickness: 0.5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isPast ? "SERGİLENDİ" : "SAHNELENİYOR",
                              style: context.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800,
                                  color: colors.primary)),
                          Icon(Icons.arrow_forward_rounded,
                              size: 18, color: colors.outline),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _ArtDateSidebar extends StatelessWidget {
  final String day;
  final String month;
  final bool isPast;
  final bool isMagic;

  const _ArtDateSidebar(
      {required this.day,
      required this.month,
      required this.isPast,
      this.isMagic = false});

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;
    return Container(
      width: 75,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Geçmiş biletler için gri bir Material yedeği yerine, temanın
          // kendi nötr (outline) tonları kullanılıyor — hangi temada
          // görünürse görünsün sayfanın rengiyle aynı ailede kalır.
          colors: isMagic
              ? [themeColors.primary, themeColors.tertiary]
              : (isPast
                  ? [themeColors.outline, themeColors.outlineVariant]
                  : [
                      themeColors.primary,
                      themeColors.primary.withOpacity(0.7)
                    ]),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotatedBox(
            quarterTurns: 3,
            child: Text(month,
                style: TextStyle(
                    color: themeColors.onPrimary.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(day,
              style: TextStyle(
                  color: themeColors.onPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _TabSelector extends StatelessWidget {
  final TabController controller;

  const _TabSelector({required this.controller});

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;
    return Container(
      height: 58,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: themeColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: themeColors.outlineVariant.withOpacity(0.3)),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: LinearGradient(
            colors: [themeColors.primary, themeColors.primaryContainer],
          ),
          boxShadow: AppShadows.level1(themeColors.primary),
        ),
        labelColor: themeColors.onPrimary,
        unselectedLabelColor: themeColors.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.auto_awesome, size: 16),
                SizedBox(width: 8),
                Text("Sıradakiler")
              ])),
          Tab(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.history_edu, size: 16),
                SizedBox(width: 8),
                Text("Anılar")
              ])),
        ],
      ),
    );
  }
}

class _ArtInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isBold;

  const _ArtInfoLine(
      {required this.icon, required this.text, this.isBold = false});

  @override
  Widget build(final BuildContext context) => Row(
        children: [
          Icon(icon,
              size: 14,
              color: context.colors.onSurfaceVariant.withOpacity(0.6)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}

class _TicketList extends StatelessWidget {
  final List<DetailedTicket> tickets;
  final bool isPast;
  final Function(DetailedTicket) onTicketTap;
  final ScrollController scrollController;

  const _TicketList({
    required this.tickets,
    required this.onTicketTap,
    required this.scrollController,
    this.isPast = false,
  });

  @override
  Widget build(final BuildContext context) => ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl, AppSpacing.sm, AppSpacing.xxl, 120),
        physics: const BouncingScrollPhysics(),
        itemCount: tickets.length,
        itemBuilder: (final context, final index) => _TicketCard(
          detailedTicket: tickets[index],
          isPast: isPast,
          onTap: () => onTicketTap(tickets[index]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Henüz bilet yok',
                child: Icon(Icons.confirmation_number_outlined,
                    size: 60, color: context.colors.outline),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text("Henüz hiç biletin yok",
                  style: context.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Sahneyi keşfetmeye ne dersin?",
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () => NavigationHandler.goToDiscover(context),
                icon: const Icon(Icons.explore_rounded),
                label: const Text('OYUNLARI KEŞFET'),
              ),
            ],
          ),
        ),
      );
}
