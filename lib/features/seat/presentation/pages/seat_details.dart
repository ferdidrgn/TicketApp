import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/features/events/presentation/providers/event_provider.dart';
import 'package:ticketapp/features/seat/presentation/providers/seats_provider.dart';

class SeatSelectionPage extends ConsumerWidget {
  final String showId;
  final String eventId;
  final String userId;

  const SeatSelectionPage({
    super.key,
    required this.showId,
    required this.eventId,
    required this.userId,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final seatingAsync = ref.watch(eventSeatingProvider(eventId: eventId, showId: showId));
    final seatStatusStream = ref.watch(eventSeatsProvider(eventId));

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Koltuk Seçimi")),
      body: seatingAsync.when(
        data: (final state) => Column(
          children: [
            _buildStageIndicator(context),
            Expanded(
              child: seatStatusStream.when(
                data: (final liveSeats) => _buildInteractiveMap(context, ref, state, liveSeats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (final e, final _) => Center(child: Text("Hata: $e")),
              ),
            ),
            _buildBottomAction(context, ref, seatStatusStream.value ?? {}),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final e, final _) => Center(child: Text("Sistem Hatası: $e")),
      ),
    );
  }

  // 🔥 Çift Yönlü Scroll ve Zoom Özelliği (Overflow Çözümü)
  Widget _buildInteractiveMap(
      final BuildContext context,
      final WidgetRef ref,
      final EventSeatingState state,
      final Map<String, Map<String, dynamic>> liveSeats) {

    // 3 Bilet Sınırı Kontrolü
    int myCount = 0;
    liveSeats.forEach((key, value) {
      if (value['customerId'] == userId && (value['status'] == 'reserved' || value['status'] == 'sold')) myCount++;
    });
    final bool canSelectMore = myCount < 3;

    return InteractiveViewer(
      constrained: false, // Taşmaya izin ver (Scroll için)
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.5,
      maxScale: 2.5,
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column( // Sıraları (A, B, C) alt alta dizer
          children: state.layout.entries.map((final entry) {
            return Row( // Koltukları yan yana dizer
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRowLabel(context, entry.key),
                ...entry.value.map((final seatId) {
                  final seatInfo = liveSeats[seatId] ?? {'status': 'available', 'customerId': null};
                  return _SeatWidget(
                    seatId: seatId!,
                    status: seatInfo['status'],
                    isMine: seatInfo['customerId'] == userId,
                    onTap: () => _handleTap(context, ref, seatId, seatInfo['status'], seatInfo['customerId'] == userId, canSelectMore),
                  );
                }),
                _buildRowLabel(context, entry.key),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, String seatId, String status, bool isMine, bool canSelectMore) async {
    if (status == 'available' && canSelectMore) {
      await ref.read(toggleSeatSelectionProvider(eventId: eventId, seatId: seatId, customerId: userId, isAdding: true).future);
    } else if (status == 'reserved' && isMine) {
      await ref.read(toggleSeatSelectionProvider(eventId: eventId, seatId: seatId, customerId: userId, isAdding: false).future);
    } else if (!canSelectMore && status == 'available') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maksimum 3 bilet alabilirsiniz.")));
    }
  }

  Widget _buildRowLabel(BuildContext context, String label) => Container(
    width: 30,
    alignment: Alignment.center,
    child: Text(label, style: context.textTheme.labelLarge?.copyWith(color: context.primaryColor)),
  );

  Widget _buildStageIndicator(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 20),
    width: context.screenWidth * 0.6,
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: context.primaryColor, width: 3)),
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [context.primaryColor.withOpacity(0.2), Colors.transparent]),
    ),
    child: const Center(child: Text("SAHNE", style: TextStyle(letterSpacing: 8, fontWeight: FontWeight.bold))),
  );

  Widget _buildBottomAction(BuildContext context, WidgetRef ref, Map<String, Map<String, dynamic>> liveSeats) {
    final myReserved = liveSeats.entries.where((e) => e.value['customerId'] == userId && e.value['status'] == 'reserved').toList();
    if (myReserved.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.colors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(child: Text("${myReserved.length} Koltuk Seçildi", style: context.textTheme.titleMedium)),
            ElevatedButton(
              onPressed: () => _onPurchase(ref, myReserved.map((e) => e.key).toList()),
              child: const Text("ÖDEMEYE GEÇ"),
            ),
          ],
        ),
      ),
    );
  }

  void _onPurchase(WidgetRef ref, List<String> seatIds) {
    // purchaseAction logic...
  }
}

class _SeatWidget extends StatelessWidget {
  final String seatId;
  final String status;
  final bool isMine;
  final VoidCallback onTap;

  const _SeatWidget({required this.seatId, required this.status, required this.isMine, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    Color color = Colors.grey.shade800;
    if (status == 'available') color = Colors.green.shade400;
    if (status == 'sold') color = Colors.red.shade900;
    if (status == 'reserved' && isMine) color = context.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(4),
        width: 35,
        height: 35,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), border: isMine ? Border.all(color: Colors.white, width: 2) : null),
        child: Center(child: Text(seatId, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
      ),
    );
  }
}