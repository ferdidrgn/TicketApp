import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Importları kontrol et
import '../../../events/presentation/providers/event_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';

class SeatSelectionPage extends ConsumerStatefulWidget {
  final String showId;
  final String eventId;
  final String customerId;

  const SeatSelectionPage({
    super.key,
    required this.showId,
    required this.eventId,
    required this.customerId,
  });

  @override
  ConsumerState<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends ConsumerState<SeatSelectionPage> {
  final Set<String> _processingSeats = {};

  @override
  Widget build(BuildContext context) {
    final seatsAsync = ref.watch(eventSeatsProvider(widget.eventId));
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final timerStream = ref.watch(reservationTimerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: _buildAppBar(timerStream.value ?? 600),
      body: eventAsync.when(
        data: (event) => Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [Color(0xFF1A1A2E), Color(0xFF0A0A12)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildStageHeader(),
                const _SeatLegend(),

                // 🪑 KOLTUK ALANI
                Expanded(
                  child: seatsAsync.when(
                    data: (seatsStatus) => _SeatLayoutBuilder(
                      // Senin verine göre: event.seats içinde tüm koltuklar var
                      allSeatsData: event.seats,
                      liveStatus: seatsStatus,
                      processingSeats: _processingSeats,
                      customerId: widget.customerId,
                      onSeatTap: _handleSeatTap,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
                    error: (e, _) => Center(child: Text("Hata: $e", style: const TextStyle(color: Colors.white))),
                  ),
                ),

                _buildPriceCard(seatsAsync, event.price),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
        error: (e, _) => Center(child: Text("Yüklenemedi: $e", style: const TextStyle(color: Colors.white))),
      ),
      floatingActionButton: _buildFab(seatsAsync.value ?? {}),
    );
  }

  // ... (Geri kalan yardımcı fonksiyonlar aynı: _handleSeatTap, _buildPriceCard vb.)
  // Kodun uzamaması için buraya sadece DEĞİŞEN KRİTİK PARÇAYI yazıyorum.
  // Yukarıdaki importları ve Class yapısını koru, _handleSeatTap vb. metodlarını silme.

  Widget _buildPriceCard(AsyncValue<Map<String, Map<String, dynamic>>> seatsAsync, String priceStr) {
    final seats = seatsAsync.value ?? {};
    final unitPrice = double.tryParse(priceStr) ?? 0.0;

    final mySelected = seats.entries
        .where((e) => e.value['customerId'] == widget.customerId && e.value['status'] == 'reserved')
        .map((e) => e.key).toList();

    return _BottomPriceCard(selectedSeats: mySelected, totalPrice: mySelected.length * unitPrice);
  }

  Future<void> _handleSeatTap(String seatId, String status, bool isMine) async {
    if (_processingSeats.contains(seatId)) return;
    setState(() => _processingSeats.add(seatId));
    try {
      await ref.read(toggleSeatSelectionProvider(
        eventId: widget.eventId, seatId: seatId, customerId: widget.customerId, isAdding: status == 'available',
      ).future);
    } finally {
      if (mounted) setState(() => _processingSeats.remove(seatId));
    }
  }

  PreferredSizeWidget _buildAppBar(int seconds) => AppBar(
    backgroundColor: Colors.transparent, elevation: 0,
    leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => context.pop()),
    title: const Text("Koltuk Seçimi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text("${(seconds / 60).floor()}:${(seconds % 60).toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold))))],
  );

  Widget _buildStageHeader() => Column(
    children: [
      const SizedBox(height: 20),
      Container(width: 200, height: 3, decoration: BoxDecoration(color: Colors.cyan, boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.5), blurRadius: 10)])),
      const SizedBox(height: 8),
      const Text("S A H N E", style: TextStyle(color: Colors.white38, letterSpacing: 8, fontSize: 10, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildFab(Map<String, Map<String, dynamic>> seats) {
    final myCount = seats.values.where((s) => s['customerId'] == widget.customerId && s['status'] == 'reserved').length;
    if (myCount == 0) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      onPressed: () {}, backgroundColor: Colors.white,
      label: const Text("ÖDEMEYE GEÇ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
    );
  }
}

// =================================================================
// 🔥 İŞTE BÜTÜN OLAYI ÇÖZEN YENİ WIDGET 🔥
// Veriyi (A1, A10, B2...) alır, A ve B diye ayırır, sıraya dizer.
// =================================================================
class _SeatLayoutBuilder extends StatelessWidget {
  final Map<String, dynamic> allSeatsData; // Senin "seats" objen
  final Map<String, Map<String, dynamic>> liveStatus; // Canlı durumlar
  final Set<String> processingSeats;
  final String customerId;
  final Function(String, String, bool) onSeatTap;

  const _SeatLayoutBuilder({
    required this.allSeatsData,
    required this.liveStatus,
    required this.processingSeats,
    required this.customerId,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. ADIM: Düz haritayı (A1, A10, B1) gruplara ayır (Row A: [A1, A10], Row B: [B1])
    final Map<String, List<String>> rows = {};

    // Veriyi gez ve grupla
    allSeatsData.keys.forEach((seatId) {
      // "A1" -> Harf kısmı "A", Sayı kısmı "1"
      final String rowLetter = seatId.replaceAll(RegExp(r'[0-9]'), '');

      if (!rows.containsKey(rowLetter)) {
        rows[rowLetter] = [];
      }
      rows[rowLetter]!.add(seatId);
    });

    // 2. ADIM: Satırları Alfabetik Sırala (A, B, C...)
    final sortedRowKeys = rows.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: sortedRowKeys.map((rowKey) {
            // 3. ADIM: O satırdaki koltukları NUMARAYA göre sırala (A1, A2, ... A10)
            final List<String> seatsInThisRow = rows[rowKey]!;

            seatsInThisRow.sort((a, b) {
              // Sadece sayıları çek: "A12" -> 12
              final int aNum = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final int bNum = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              return aNum.compareTo(bNum);
            });

            // 4. ADIM: Satırı Çiz
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Satır Harfi (A, B, C)
                  SizedBox(
                    width: 30,
                    child: Text(rowKey, style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),

                  // O satırdaki koltukları yan yana diz
                  ...seatsInThisRow.map((seatId) {
                    // Canlı veriden durumu çek, yoksa varsayılan 'available'
                    final statusData = liveStatus[seatId] ?? allSeatsData[seatId] ?? {};
                    final String status = statusData['status'] ?? 'available';
                    final String? ownerId = statusData['customerId'];

                    return _SeatItem(
                      seatId: seatId,
                      status: status,
                      isMine: ownerId == customerId,
                      isProcessing: processingSeats.contains(seatId),
                      onTap: () => onSeatTap(seatId, status, ownerId == customerId),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ... (Alt bileşenler: _SeatItem, _SeatLegend, _BottomPriceCard AYNI ŞEKİLDE DEVAM EDİYOR)
class _SeatItem extends StatelessWidget {
  final String seatId;
  final String status;
  final bool isMine;
  final bool isProcessing;
  final VoidCallback onTap;

  const _SeatItem({required this.seatId, required this.status, required this.isMine, required this.isProcessing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.white.withOpacity(0.1);
    if (status == 'sold') color = Colors.white10;
    else if (status == 'reserved') color = isMine ? Colors.blueAccent : Colors.purple;
    else if (status == 'available') color = Colors.green.withOpacity(0.5);

    // Sadece numarayı göster (A1 -> 1)
    final seatNum = seatId.replaceAll(RegExp(r'[^0-9]'), '');

    return GestureDetector(
      onTap: isProcessing || status == 'sold' ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36, height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isMine ? Colors.white : Colors.transparent, width: 1.5),
        ),
        child: Center(
          child: isProcessing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(seatNum, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _item(Colors.green.withOpacity(0.5), "Boş"),
      _item(Colors.blueAccent, "Sizin"),
      _item(Colors.purple, "Dolu"),
      _item(Colors.white10, "Satılmış"),
    ]),
  );
  Widget _item(Color c, String t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(t, style: const TextStyle(fontSize: 11, color: Colors.white60)),
    ]),
  );
}

class _BottomPriceCard extends StatelessWidget {
  final List<String> selectedSeats;
  final double totalPrice;
  const _BottomPriceCard({required this.selectedSeats, required this.totalPrice});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text("SEÇİLENLER", style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
          Text(selectedSeats.isEmpty ? "Seçim yok" : selectedSeats.join(", "), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Text("${totalPrice.toStringAsFixed(2)} TL", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.greenAccent)),
      ]),
    );
  }
}