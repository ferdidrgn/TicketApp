import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/features/events/presentation/providers/event_provider.dart';
import 'package:ticketapp/features/seat/presentation/providers/seats_provider.dart';
import 'package:ticketapp/features/seat/presentation/providers/processing_seats_provider.dart';

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
    // 🔥 Generator tabanlı provider'lar
    final seatingAsync = ref.watch(eventSeatingProvider(eventId: eventId, showId: showId));
    final liveSeatsStream = ref.watch(eventSeatsProvider(eventId));

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Koltuk Seçimi", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [_buildRemainingTicketsBadge(liveSeatsStream.value ?? {})],
      ),
      body: seatingAsync.when(
        data: (final state) => Column(
          children: [
            _buildStageArea(context),
            const _SeatLegend(),
            const SizedBox(height: 8),
            // 🔥 MERKEZİ KOLTUK HARİTASI
            Expanded(
              child: liveSeatsStream.when(
                data: (final liveSeats) => _buildInteractiveMap(context, ref, state, liveSeats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (final e, final _) => Center(child: Text("Koltuklar yüklenemedi: $e")),
              ),
            ),
            // 🔥 ALT ÖDEME BARI
            _buildBottomPaymentBar(context, ref, liveSeatsStream.value ?? {}),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final e, final _) => Center(child: Text("Etkinlik verisi alınamadı: $e")),
      ),
    );
  }

  // 🔥 SIRALARI DİKEY (A, B, C ALT ALTA), KOLTUKLARI YATAY DİZEN YAPI
  Widget _buildInteractiveMap(
      final BuildContext context, final WidgetRef ref, final dynamic state, final Map<String, Map<String, dynamic>> liveSeats) {

    final processingSeats = ref.watch(processingSeatsProvider);
    final myCount = _calculateMyCount(liveSeats);

    return InteractiveViewer(
      constrained: false, // 🔥 635px taşma hatasını çözen kritik ayar
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.1,
      maxScale: 2.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 150),
        child: Column( // 🎯 SIRALAR (A, B, C) ALT ALTA DİZİLİR
          mainAxisSize: MainAxisSize.min,
          children: state.layout.entries.map<Widget>((final entry) {
            final rowName = entry.key; // 'A', 'B' vb.
            final seatIds = entry.value as List<String>;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row( // 🎯 KOLTUKLAR (A1, A2...) YAN YANA DİZİLİR
                mainAxisSize: MainAxisSize.min,
                children: [
                  _rowLabel(rowName), // Sol Sıra İsmi
                  ...seatIds.map((final seatId) {
                    final status = liveSeats[seatId]?['status'] ?? 'available';
                    final isMine = liveSeats[seatId]?['customerId'] == userId;
                    final isProcessing = processingSeats.contains(seatId);

                    return _SeatItem(
                      seatId: seatId,
                      status: status,
                      isMine: isMine,
                      isProcessing: isProcessing,
                      onTap: () => _handleTap(ref, seatId, status, isMine, myCount, context),
                    );
                  }),
                  _rowLabel(rowName), // Sağ Sıra İsmi
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 🎯 TIKLAMA LOGIC (LOADING + 3 BİLET KONTROLÜ)
  Future<void> _handleTap(final WidgetRef ref, final String id, final String status, final bool mine, final int count, final BuildContext context) async {
    if (status == 'available' && count >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("En fazla 3 bilet alabilirsiniz!"), backgroundColor: Colors.red),
      );
      return;
    }

    if (status == 'available' || (status == 'reserved' && mine)) {
      final notifier = ref.read(processingSeatsProvider.notifier);
      notifier.add(id); // 🔥 Koltuk bazlı loading başlat

      try {
        await ref.read(toggleSeatSelectionProvider(
          eventId: eventId,
          seatId: id,
          customerId: userId,
          isAdding: status == 'available',
        ).future);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
        }
      } finally {
        notifier.remove(id); // 🔥 Loading bitir
      }
    }
  }

  int _calculateMyCount(final Map<String, Map<String, dynamic>> seats) =>
      seats.values.where((final s) => s['customerId'] == userId && (s['status'] == 'reserved' || s['status'] == 'sold')).length;

  // 🏷️ ÜST KISIMDAKİ HAK GÖSTERGESİ
  Widget _buildRemainingTicketsBadge(final Map<String, Map<String, dynamic>> liveSeats) {
    final remaining = 3 - _calculateMyCount(liveSeats);
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
      child: Chip(
        label: Text("$remaining/3 Hak", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: remaining > 0 ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
      ),
    );
  }

  Widget _rowLabel(final String label) => SizedBox(
    width: 30,
    child: Center(child: Text(label, style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 12))),
  );

  Widget _buildStageArea(final BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      children: [
        Container(
          width: context.screenWidth * 0.6,
          height: 4,
          decoration: BoxDecoration(
            color: context.primaryColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: context.primaryColor.withOpacity(0.5), blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 8),
        const Text("SAHNE", style: TextStyle(letterSpacing: 10, fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  // 💳 ALT ÖDEME BARI
  Widget _buildBottomPaymentBar(final BuildContext context, final WidgetRef ref, final Map<String, Map<String, dynamic>> liveSeats) {
    final selectedSeats = liveSeats.entries
        .where((final e) => e.value['customerId'] == userId && e.value['status'] == 'reserved')
        .map((final e) => e.key)
        .toList();

    if (selectedSeats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${selectedSeats.length} Koltuk Seçildi", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(selectedSeats.join(", "), style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                // TODO: Satın alma sayfasına yönlendir
              },
              child: const Text("ÖDEMEYE GEÇ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 🎨 KOLTUK TASARIMI (LOADING + ANİMASYON)
// ============================================================

class _SeatItem extends StatelessWidget {
  final String seatId;
  final String status;
  final bool isMine;
  final bool isProcessing;
  final VoidCallback onTap;

  const _SeatItem({required this.seatId, required this.status, required this.isMine, required this.isProcessing, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    // Profesyonel Renk Paleti
    Color color = Colors.green.withOpacity(0.3); // Boş
    if (status == 'sold') color = Colors.white10; // Satılmış
    else if (status == 'reserved') color = isMine ? Colors.blueAccent : Colors.purple.withOpacity(0.4);

    return GestureDetector(
      onTap: isProcessing || (status == 'reserved' && !isMine) || status == 'sold' ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: isProcessing ? Colors.orange.withOpacity(0.5) : color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isMine ? Colors.white : Colors.white12, width: isMine ? 2 : 1),
          boxShadow: isMine ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8)] : null,
        ),
        child: Center(
          child: isProcessing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(seatId, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// ============================================================
// 🎨 LEGEND (RENK AÇIKLAMALARI)
// ============================================================

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();
  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _item(Colors.green, "Boş"),
        _item(Colors.blueAccent, "Sizin"),
        _item(Colors.purple, "Dolu"),
        _item(Colors.white30, "Satılmış"),
      ],
    ),
  );
  Widget _item(final Color c, final String t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(children: [CircleAvatar(radius: 4, backgroundColor: c), const SizedBox(width: 6), Text(t, style: const TextStyle(fontSize: 11, color: Colors.white60))]),
  );
}