import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/features/events/presentation/providers/event_provider.dart';
import 'package:ticketapp/features/shows/presentation/providers/show_provider.dart';
import 'package:ticketapp/features/users/presentation/providers/user_provider.dart';
import 'package:ticketapp/shared/widgets/admin_guard.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';
import 'package:ticketapp/shared/widgets/card/shimmer_card.dart';

class CuratorSeatingAuditPage extends ConsumerStatefulWidget {
  final String? eventId;
  final String? showId;

  const CuratorSeatingAuditPage({
    super.key,
    this.eventId,
    this.showId,
  });

  @override
  ConsumerState<CuratorSeatingAuditPage> createState() =>
      _CuratorSeatingAuditPageState();
}

class _CuratorSeatingAuditPageState
    extends ConsumerState<CuratorSeatingAuditPage> {
  String? _currentEventId;
  String? _currentShowId;
  String? _focusedSeatId;

  @override
  void initState() {
    super.initState();
    _currentEventId = widget.eventId;
    _currentShowId = widget.showId;

    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (_currentEventId == null)
        _showShowSelectionSheet();
      else
        _initializeAudit();
    });
  }

  void _initializeAudit() {
    if (_currentEventId != null && _currentShowId != null)
      ref.read(eventProvider.notifier).initializeWithParams(
            eventId: _currentEventId!,
            showId: _currentShowId!,
            customerId: "ADMIN_OPERATOR",
          );
  }

  @override
  Widget build(final BuildContext context) {
    final eventState = ref.watch(eventProvider);
    final theme = context.theme;

    if (_currentEventId == null)
      return AdminGuard(
        child: Scaffold(
          body: CustomAppBackground(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.theater_comedy,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Lütfen bir seans seçiniz..."),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _showShowSelectionSheet,
                    child: const Text("ESER SEÇ"),
                  )
                ],
              ),
            ),
          ),
        ),
      );

    return AdminGuard(
      child: Scaffold(
        body: CustomAppBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildAuditHeader(theme, eventState),
                _buildOccupancyBar(eventState),
                const SizedBox(height: 10),

                // 🚀 KOLTUK PLANI ALANI
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildStageVisual(theme),
                        Expanded(
                          child: InteractiveViewer(
                            boundaryMargin: const EdgeInsets.all(20),
                            minScale: 0.5,
                            maxScale: 2.0,
                            child: Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: _buildInteractiveGrid(eventState),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 👤 ALT PANEL: DETAYLAR VEYA GÖSTERGE
                if (_focusedSeatId != null)
                  _buildOccupantDetailCard(eventState, theme)
                else
                  _buildAuditLegend(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI BİLEŞENLERİ ---

  Widget _buildAuditHeader(final ThemeData theme, final state) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _showShowSelectionSheet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("OPERASYON PANELİ",
                        style: TextStyle(
                            fontWeight: FontWeight.w900, letterSpacing: 2)),
                    Text(
                        state.isLoading
                            ? "Yükleniyor..."
                            : "Seans: ${state.eventDate['date'] ?? 'Canlı'}",
                        style: const TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            IconButton(
                icon: const Icon(Icons.swap_horizontal_circle_outlined),
                onPressed: _showShowSelectionSheet),
          ],
        ),
      );

  Widget _buildOccupancyBar(final state) {
    int soldCount = state.seatStatus.values
        .where((final s) => s != null && s['status'] == 'sold')
        .length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Satılan Koltuk:",
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          Text("$soldCount / ${state.seatStatus.length}",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInteractiveGrid(final state) => Column(
        children: state.seatLayout.entries.map<Widget>((final entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                    width: 30,
                    child: Text(entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                ...entry.value.map<Widget>((final seatId) {
                  final info = state.seatStatus[seatId];
                  final isSold = info?['status'] == 'sold';
                  final isFocused = _focusedSeatId == seatId;

                  return GestureDetector(
                    onTap: () => setState(() => _focusedSeatId = seatId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSold ? Colors.redAccent : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isFocused ? Colors.white : Colors.white10,
                            width: isFocused ? 2 : 1),
                      ),
                      child: Center(
                        child: Text(seatId.substring(1),
                            style: TextStyle(
                                color: isSold ? Colors.white : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      );

  Widget _buildOccupantDetailCard(final eventState, final ThemeData theme) {
    final seatData = eventState.seatStatus[_focusedSeatId];
    final String? uid = seatData?['customerId'];
    final bool isSold = seatData?['status'] == 'sold';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: _neuBox(theme),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Koltuk $_focusedSeatId",
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 20)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: isSold ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(isSold ? "SATILDI" : "MÜSAİT",
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 30),
          if (isSold && uid != null)
            _UserDetailFetcher(uid: uid, key: ValueKey(uid))
          else
            const Text("Bu koltuk şu an müsait.",
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStageVisual(final ThemeData theme) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
                height: 4,
                width: 100,
                decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 4),
            const Text("SAHNE",
                style: TextStyle(
                    fontSize: 9, letterSpacing: 4, color: Colors.grey)),
          ],
        ),
      );

  Widget _buildAuditLegend() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(Colors.white10, "Müsait"),
            const SizedBox(width: 20),
            _legend(Colors.redAccent, "Dolu"),
          ],
        ),
      );

  Widget _legend(final Color c, final String t) => Row(children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: c, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(t, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]);

  BoxDecoration _neuBox(final ThemeData theme) => BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(8, 8),
              blurRadius: 16),
          BoxShadow(
              color: Colors.white.withOpacity(0.05),
              offset: const Offset(-8, -8),
              blurRadius: 16),
        ],
      );

  // --- MODALLAR ---

  void _showShowSelectionSheet() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (final context) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
              color: context.theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2))),
              const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text("DENETLENECEK ESERİ SEÇİN",
                      style: TextStyle(
                          fontWeight: FontWeight.w900, letterSpacing: 2))),
              Expanded(
                child: Consumer(builder: (final context, final ref, final _) {
                  final shows = ref.watch(showProvider).dataList;
                  return ListView.builder(
                    itemCount: shows?.length ?? 0,
                    itemBuilder: (final context, final index) {
                      final show = shows![index];
                      return ListTile(
                        leading: const Icon(Icons.theater_comedy),
                        title: Text(show.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () => _showEventSelectionSheet(show.id),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      );

  void _showEventSelectionSheet(final String showId) => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (final context) => Container(
          decoration: BoxDecoration(
              color: context.theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32))),
          child: Consumer(builder: (final context, final ref, final _) {
            final events = ref
                .watch(eventProvider)
                .dataList
                ?.where((final e) => e.showId == showId)
                .toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text("AKTİF SEANS SEÇİMİ",
                        style: TextStyle(fontWeight: FontWeight.w900))),
                if (events == null || events.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text("Aktif seans bulunamadı."))
                else
                  ...events
                      .map((final e) => ListTile(
                            leading: const Icon(Icons.event_seat),
                            title: Text(e.date ?? "Tarih Belirtilmemiş"),
                            onTap: () {
                              setState(() {
                                _currentEventId = e.id;
                                _currentShowId = showId;
                                _focusedSeatId = null;
                              });
                              Navigator.pop(context);
                              Navigator.pop(context);
                              _initializeAudit();
                            },
                          ))
                      .toList(),
                const SizedBox(height: 32),
              ],
            );
          }),
        ),
      );
}

// 🔥 GERÇEK VERİ ÇEKEN WIDGET (REFACTOR EDİLDİ)
class _UserDetailFetcher extends ConsumerStatefulWidget {
  final String uid;

  const _UserDetailFetcher({required this.uid, super.key});

  @override
  ConsumerState<_UserDetailFetcher> createState() => _UserDetailFetcherState();
}

class _UserDetailFetcherState extends ConsumerState<_UserDetailFetcher> {
  late Future<dynamic> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = ref.read(getUserByIdUseCaseProvider).call(widget.uid);
  }

  @override
  Widget build(final BuildContext context) => FutureBuilder<dynamic>(
        future: _userFuture,
        builder: (final context, final snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const ShimmerLoading();
          final result = snapshot.data;
          if (result == null) return const Text("Veri alınamadı");

          return result.fold(
            (final failure) => Text("Hata: ${failure.message}"),
            (final user) => Column(
              children: [
                CircleAvatar(
                    radius: 30,
                    backgroundImage: user.imageUrl.isNotEmpty
                        ? NetworkImage(user.imageUrl)
                        : null,
                    child: user.imageUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null),
                const SizedBox(height: 8),
                Text("${user.firstName} ${user.lastName}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Text(user.phoneNumber,
                    style: const TextStyle(color: Colors.blue, fontSize: 13)),
              ],
            ),
          );
        },
      );
}
