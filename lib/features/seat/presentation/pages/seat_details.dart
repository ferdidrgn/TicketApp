import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../providers/seats_provider.dart';

class SeatSelectionScreen extends ConsumerWidget {
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
  Widget build(final BuildContext context, final WidgetRef ref) {
    // 🎯 REAKTİF VERİLER (AsyncValue Yapısı)
    final seatingAsync =
        ref.watch(eventSeatingProvider(eventId: eventId, showId: showId));
    final seatsStatusAsync = ref.watch(eventSeatsProvider(eventId));
    final timerAsync = ref.watch(reservationTimerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Koltuk Seçimi',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          _TimerBadge(timerAsync: timerAsync),
        ],
      ),
      // Alt panel ve FAB için Async verilerin yüklenmesini bekliyoruz
      floatingActionButton: seatingAsync.whenOrNull(
        data: (final state) => seatsStatusAsync.whenOrNull(
          data: (final status) => _SeatFab(
            eventId: eventId,
            showId: showId,
            stageId: state.event.stageId,
            seatsStatus: status,
            customerId: customerId,
            seatPrice: double.tryParse(state.event.price) ?? 0,
          ),
        ),
      ),
      body: CustomAppBackground(
        child: SafeArea(
          child: seatingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (final err, final _) => Center(child: Text("Hata: $err")),
            data: (final state) => Column(
              children: [
                _buildStageVisual(),
                const _SeatLegend(),
                // Koltuk planı
                Expanded(
                  child: seatsStatusAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (final err, final _) => Text("Yükleme Hatası: $err"),
                    data: (final status) => _SeatLayoutContainer(
                      layout: state.layout,
                      status: status,
                      eventId: eventId,
                      customerId: customerId,
                    ),
                  ),
                ),
                // Fiyat Özeti
                seatsStatusAsync.whenOrNull(
                      data: (final status) => _BottomPriceCard(
                        status: status,
                        customerId: customerId,
                        price: double.tryParse(state.event.price) ?? 0,
                      ),
                    ) ??
                    const SizedBox.shrink(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStageVisual() => Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: const Column(
          children: [
            Divider(
                color: Colors.white24, thickness: 2, indent: 50, endIndent: 50),
            Text("SAHNE",
                style: TextStyle(
                    letterSpacing: 8, fontSize: 10, color: Colors.white54)),
          ],
        ),
      );
}

class _TimerBadge extends StatelessWidget {
  final AsyncValue<int> timerAsync;

  const _TimerBadge({required this.timerAsync});

  @override
  Widget build(final BuildContext context) {
    return timerAsync.when(
      data: (final time) => Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white12, borderRadius: BorderRadius.circular(20)),
        child: Center(
            child: Text("$time sn",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))),
      ),
      error: (final _, final __) => const SizedBox.shrink(),
      loading: () => const Padding(
          padding: EdgeInsets.only(right: 20),
          child: SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }
}

class _SeatLayoutContainer extends StatelessWidget {
  final Map<String, List<String>> layout;
  final Map<String, Map<String, dynamic>> status;
  final String eventId;
  final String customerId;

  const _SeatLayoutContainer(
      {required this.layout,
      required this.status,
      required this.eventId,
      required this.customerId});

  @override
  Widget build(final BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: layout.entries
            .map((final entry) => _SeatRow(
                  rowName: entry.key,
                  seats: entry.value,
                  status: status,
                  eventId: eventId,
                  customerId: customerId,
                ))
            .toList(),
      ),
    );
  }
}

class _SeatRow extends StatelessWidget {
  final String rowName;
  final List<String> seats;
  final Map<String, Map<String, dynamic>> status;
  final String eventId;
  final String customerId;

  const _SeatRow(
      {required this.rowName,
      required this.seats,
      required this.status,
      required this.eventId,
      required this.customerId});

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(rowName,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(width: 10),
          ...seats.map((final seatId) => _SeatItem(
                seatId: seatId,
                info: status[seatId],
                eventId: eventId,
                customerId: customerId,
              )),
        ],
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
      color = isMyRes ? Colors.blue : Colors.purple;
    else if (status == 'sold') color = Colors.white10;

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
        width: 35,
        height: 35,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isMyRes ? Colors.white : Colors.white10),
        ),
        child: Center(
          child: Text(seatId.substring(1),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
      ),
    );
  }
}

class _BottomPriceCard extends StatelessWidget {
  final Map<String, Map<String, dynamic>> status;
  final String customerId;
  final double price;

  const _BottomPriceCard(
      {required this.status, required this.customerId, required this.price});

  @override
  Widget build(final BuildContext context) {
    final selectedSeats = status.entries
        .where((final e) =>
            e.value['customerId'] == customerId &&
            e.value['status'] == 'reserved')
        .map((final e) => e.key)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("SEÇİLEN KOLTUKLAR",
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
  final String eventId;
  final String showId;
  final String stageId;
  final Map<String, Map<String, dynamic>> seatsStatus;
  final String customerId;
  final double seatPrice;

  const _SeatFab(
      {required this.eventId,
      required this.showId,
      required this.stageId,
      required this.seatsStatus,
      required this.customerId,
      required this.seatPrice});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final mySelectedSeats = seatsStatus.entries
        .where((final e) =>
            e.value['customerId'] == customerId &&
            e.value['status'] == 'reserved')
        .map((final e) => e.key)
        .toList();

    if (mySelectedSeats.isEmpty) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () => _showPaymentOptions(context, ref, mySelectedSeats),
      label: const Text("ÖDEMEYE GEÇ"),
      icon: const Icon(Icons.payment),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }

  void _showPaymentOptions(final BuildContext context, final WidgetRef ref,
      final List<String> selectedSeats) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (final _) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.white),
              title: const Text("Kredi Kartı ile Öde",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _confirmPurchase(context, ref, selectedSeats, 'credit_card');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmPurchase(final BuildContext context, final WidgetRef ref,
          final List<String> seats, final String method) =>
      showDialog(
        context: context,
        // Kullanıcı dışarı basıp kapatamasın, seçim yapsın
        barrierDismissible: false,
        builder: (final ctx) => CustomActionDialog(
          title: "ONAY",
          message:
              "${seats.length} adet bilet satın alınacaktır. Onaylıyor musunuz?",
          positiveText: "SATIN AL",
          onPositiveAction: () async {
            // Dialogu kapat (Loading dialogu açılacaksa çakışmasın)
            Navigator.pop(ctx);

            // İşlemi başlat
            await ref.read(purchaseActionProvider(
              eventId: eventId,
              showId: showId,
              stageId: stageId,
              seatIds: seats,
              customerId: customerId,
              paymentMethod: method,
              totalPrice: seats.length * seatPrice,
            ).future);

            if (context.mounted)
              NavigationHandler.goToMyTickets(context, customerId);
          },
          // 👇 EKSİK KISIMLAR TAMAMLANDI
          negativeText: "VAZGEÇ",
          onNegativeAction: () {
            Navigator.pop(ctx);
          },
        ),
      );
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(final BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _item(Colors.green, "Boş"),
        _item(Colors.blue, "Sizin"),
        _item(Colors.purple, "Dolu")
      ]));

  Widget _item(final Color c, final String l) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(l, style: const TextStyle(fontSize: 12, color: Colors.white70))
      ]));
}
