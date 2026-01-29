import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../providers/seats_provider.dart';

class SeatSelectionScreen extends ConsumerStatefulWidget {
  final String showId;
  final String eventId;
  final String customerId;

  const SeatSelectionScreen({
    super.key,
    required this.showId,
    required this.eventId,
    required this.customerId,
  });

  @override
  ConsumerState<SeatSelectionScreen> createState() =>
      _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends ConsumerState<SeatSelectionScreen> {
  @override
  Widget build(final BuildContext context) {
    // Screenshot 2'deki GoError'ı engellemek için watch işlemlerini en üstte yapıyoruz.
    final seatingAsync = ref.watch(
        eventSeatingProvider(eventId: widget.eventId, showId: widget.showId));
    final seatsStatusAsync = ref.watch(eventSeatsProvider(widget.eventId));
    final myTicketsAsync = ref.watch(myTicketsProvider(widget.customerId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Koltuk Seçimi',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: CustomAppBackground(
        child: SafeArea(
          child: seatingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (final err, final _) => Center(
                child: Text("Hata: $err",
                    style: const TextStyle(color: Colors.white))),
            data: (final seatingState) => Column(
              children: [
                _buildTopVisual(context),
                const _SeatLegend(),
                Expanded(
                  child: seatsStatusAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (final err, final _) => Center(
                        child: Text("Koltuklar yüklenemedi",
                            style: const TextStyle(color: Colors.white))),
                    data: (final statusData) =>
                        _buildInteractiveArea(seatingState, statusData),
                  ),
                ),
                // Fiyat paneli
                _BottomPriceCard(
                  seatingState: seatingState,
                  statusData: seatsStatusAsync.value ?? {},
                  customerId: widget.customerId,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _SeatFab(
        seatingState: seatingAsync.value,
        statusData: seatsStatusAsync.value,
        customerId: widget.customerId,
      ),
    );
  }

  Widget _buildTopVisual(final BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Container(
            width: context.screenWidth * 0.6,
            height: 4,
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                    color: context.primaryColor.withOpacity(0.5),
                    blurRadius: 10)
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text("SAHNE",
              style: TextStyle(
                  letterSpacing: 10, fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildInteractiveArea(
      final EventSeatingState state, final dynamic statusData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.1,
          maxScale: 2.0,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: state.layout.entries.map((final entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(entry.key,
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        ...entry.value.map((final seatId) => _SeatItem(
                              seatId: seatId,
                              info: (statusData is Map)
                                  ? statusData[seatId]
                                  : statusData.seatStatus[seatId],
                              eventId: widget.eventId,
                              customerId: widget.customerId,
                            )),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatItem extends ConsumerWidget {
  final String seatId;
  final Map<String, dynamic>? info;
  final String eventId;
  final String customerId;

  const _SeatItem(
      {required this.seatId,
      this.info,
      required this.eventId,
      required this.customerId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final status = info?['status'] ?? 'available';
    final isMyRes = info?['customerId'] == customerId;

    Color color = Colors.white10;
    if (status == 'available')
      color = Colors.green.withOpacity(0.4);
    else if (status == 'reserved')
      color = isMyRes ? Colors.blue : Colors.purple.withOpacity(0.6);
    else if (status == 'sold') color = Colors.red.withOpacity(0.2);

    return GestureDetector(
      onTap: (status == 'available' || isMyRes)
          ? () => ref.read(toggleSeatSelectionProvider(
                eventId: eventId,
                seatId: seatId,
                customerId: customerId,
                isAdding: status == 'available',
              ))
          : null,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isMyRes ? Colors.white : Colors.white12,
              width: isMyRes ? 2 : 1),
        ),
        child: Center(
          child: Text(seatId.substring(1),
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
      ),
    );
  }
}

class _BottomPriceCard extends StatelessWidget {
  final EventSeatingState seatingState;
  final dynamic statusData;
  final String customerId;

  const _BottomPriceCard(
      {required this.seatingState,
      required this.statusData,
      required this.customerId});

  @override
  Widget build(final BuildContext context) {
    final Map<String, dynamic> seatMap =
        (statusData is Map) ? statusData : (statusData.seatStatus ?? {});
    final selectedSeats = seatMap.entries
        .where((final e) =>
            e.value['customerId'] == customerId &&
            e.value['status'] == 'reserved')
        .map((final e) => e.key)
        .toList();

    final double price = double.tryParse(seatingState.event.price) ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("SEÇİLENLER",
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white54,
                        fontWeight: FontWeight.bold)),
                Text(
                    selectedSeats.isEmpty
                        ? "Seçim yok"
                        : selectedSeats.join(", "),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("TOPLAM",
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                      fontWeight: FontWeight.bold)),
              Text("${(selectedSeats.length * price).toStringAsFixed(2)} TL",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.greenAccent)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeatFab extends ConsumerWidget {
  final EventSeatingState? seatingState;
  final dynamic statusData;
  final String customerId;

  const _SeatFab(
      {this.seatingState, this.statusData, required this.customerId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (seatingState == null || statusData == null)
      return const SizedBox.shrink();

    final Map<String, dynamic> seatMap =
        (statusData is Map) ? statusData : (statusData.seatStatus ?? {});
    final mySelectedSeats = seatMap.entries
        .where((final e) =>
            e.value['customerId'] == customerId &&
            e.value['status'] == 'reserved')
        .map((final e) => e.key)
        .toList();

    if (mySelectedSeats.isEmpty) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () {},
      // Ödeme logic buraya gelecek
      label: const Text("ÖDEMEYE GEÇ"),
      icon: const Icon(Icons.payment),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(final BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legendItem(Colors.green, "Boş"),
        _legendItem(Colors.blue, "Sizin"),
        _legendItem(Colors.purple, "Dolu")
      ]));

  Widget _legendItem(final Color c, final String l) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: c.withOpacity(0.6), shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(l, style: const TextStyle(fontSize: 11, color: Colors.white70))
      ]));
}
