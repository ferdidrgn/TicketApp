import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/data/providers/event/event_notifier.dart';
import '../../../../data/providers/event/event_provider.dart';
import '../../../../data/providers/event/event_state.dart';

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
  void initState() {
    super.initState();
    // Widget build edilmeden önce state'i initialize et
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      ref.initializeEventNotifier(
        eventId: widget.eventId,
        showId: widget.showId,
        customerId: widget.customerId,
      );
    });
  }

  @override
  Widget build(final BuildContext context) {
    final state = ref.watch(eventNotifierProvider);
    final notifier = ref.read(eventNotifierProvider.notifier);

    // Hata mesajı listener
    ref.listen<SeatSelectionState>(
      eventNotifierProvider,
      (final previous, final next) {
        if (next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage!)),
          );
        }

        // Süre dolduğunda dialog göster
        if (next.isTimeUp && (previous?.isTimeUp == false)) {
          _showTimeUpDialog();
        }

        // Ödeme başarılı olduğunda dialog göster
        if (next.paymentSuccessful && (previous?.paymentSuccessful == false)) {
          _showPaymentSuccessDialog();
        }
      },
    );

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koltuk Seçimi'),
        actions: [
          // Kalan süre göstergesi
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                state.formattedTime,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sahne görseli
          _buildStageImage(),
          const SizedBox(height: 20),

          // Seçim bilgileri
          _buildSelectionInfo(state),
          const SizedBox(height: 10),

          // Koltuk göstergesi
          _buildSeatLegend(),
          const SizedBox(height: 20),

          // Koltuk düzeni
          Expanded(child: _buildSeatLayout(state, notifier)),
        ],
      ),
      floatingActionButton: state.hasSelectedSeats
          ? FloatingActionButton.extended(
              onPressed: state.processingSeats
                      .isEmpty // 'processingSeats' e göre Buton devre dışı

                  ? () => _showPaymentBottomSheet(state, notifier)
                  : null,

              label: state.processingSeats
                      .isEmpty // Buton etiketini duruma göre değiştir
                  ? Text(
                      'Ödemeye Geç (${state.totalPrice.toStringAsFixed(2)} TL)')
                  : const Text('Koltuk güncelleniyor...'),
              // İşlem sırasında metni değiştir

              icon: state.processingSeats.isEmpty //İkonu duruma göre değiştir
                  ? const Icon(Icons.payment)
                  : SizedBox(
                      width: 20, // Küçük bir spinner
                      height: 20,
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    ),

              backgroundColor: state.processingSeats
                      .isEmpty //İşlem devam ederken butonun rengini soluklaştır
                  ? Theme.of(context).floatingActionButtonTheme.backgroundColor
                  : Colors.grey.shade600,
            )
          : null,
    );
  }

  Widget _buildStageImage() {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Image.asset('assets/images/stage_diagram.jpg', fit: BoxFit.cover),
    );
  }

  Widget _buildSelectionInfo(final SeatSelectionState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'Seçilen Koltuklar: ${state.selectedSeats.join(", ")}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            'Toplam Fiyat: ${state.totalPrice.toStringAsFixed(2)} TL',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _legendItem(Colors.green, "Boş"),
          const SizedBox(width: 10),
          _legendItem(Colors.blue, "Seçili"),
          const SizedBox(width: 10),
          _legendItem(Colors.black12, "Satılmış"),
          const SizedBox(width: 10),
          _legendItem(Colors.purple, "Başka Sepette"),
        ],
      ),
    );
  }

  Widget _legendItem(final Color color, final String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildSeatLayout(
      final SeatSelectionState state, final EventNotifier notifier) {
    if (state.seatStatus.isEmpty)
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Koltuklar yükleniyor...'),
          ],
        ),
      );

    final seatsByRow = _groupSeatsFromStatus(
        state.seatStatus.cast<String, Map<String, dynamic>?>());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Sahne etiketi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.grey[400],
            child: const Center(
              child: Text(
                'SAHNE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Koltuk satırları
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: seatsByRow.entries.map((final entry) {
                      return _buildSeatRow(
                        entry.key,
                        entry.value,
                        state,
                        notifier,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ seatStatus'tan koltukları grupla (seatLayout yerine)
  Map<String, List<String>> _groupSeatsFromStatus(
    final Map<String, Map<String, dynamic>?> seatStatus,
  ) {
    final seatsByRow = <String, List<String>>{};

    // 1. Koltukları row'lara göre grupla
    for (final seatId in seatStatus.keys) {
      if (seatId.isEmpty) continue;

      final row = seatId[0]; // İlk karakter row (A, B, C, ...)
      seatsByRow.putIfAbsent(row, () => []).add(seatId);
    }

    // 2. Row'ları alfabetik sırala (A, B, C, ...)
    final sortedRows = seatsByRow.keys.toList()..sort();

    final result = <String, List<String>>{};

    // 3. Her row içindeki koltukları NUMERIC olarak sırala
    for (final row in sortedRows) {
      final seats = seatsByRow[row]!;

      // ✅ Numeric sorting - A1, A2, A3, ..., A10, A11
      seats.sort((final a, final b) {
        // Koltuk numarasını çıkar (A1 -> 1, A10 -> 10)
        final numA = int.tryParse(a.substring(1)) ?? 0;
        final numB = int.tryParse(b.substring(1)) ?? 0;
        return numA.compareTo(numB);
      });

      result[row] = seats;
    }

    return result;
  }

  Widget _buildSeatRow(
    final String row,
    final List<String> seats,
    final SeatSelectionState state,
    final EventNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              row,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...seats.map((final seatId) => _buildSeat(seatId, state, notifier)),
        ],
      ),
    );
  }

  Widget _buildSeat(
    final String seatId,
    final SeatSelectionState state,
    final EventNotifier notifier,
  ) {
    final seatInfo = state.seatStatus[seatId];
    final status = seatInfo?['status'] ?? 'available';
    final reservedById = seatInfo?['customerId'];

    final isSelected = state.selectedSeats.contains(seatId);
    final isMyReservation = reservedById == state.customerId;
    final isAvailable =
        status == 'available' || (status == 'reserved' && isMyReservation);

    // Bu koltuk şu anda işlemde mi?
    final bool isSeatProcessing = state.processingSeats.contains(seatId);

    Color seatColor;
    if (status == 'sold')
      seatColor = Colors.black12;
    else if (isSelected)
      seatColor = Colors.blue;
    else if (status == 'reserved' && !isMyReservation)
      seatColor = Colors.purple;
    else
      seatColor = Colors.green;

    // YENİ: Tıklanabilirlik durumu
    // Koltuk hem "müsait" OLMALI hem de "işlemde OLMAMALI"
    final bool canTap = isAvailable && !isSeatProcessing;

    return GestureDetector(
      // Sadece 'canTap' true ise tıkla
      onTap: canTap ? () => notifier.toggleSeatSelection(seatId) : null,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          // YENİ: 'isSeatProcessing' true ise yazı yerine spinner göster
          child: isSeatProcessing
              ? const SizedBox(
                  width: 20, // Spinner boyutunu ayarla
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  seatId.substring(1), // Koltuk numarası
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        ),
      ),
    );
  }

  void _showPaymentBottomSheet(
    final SeatSelectionState state,
    final EventNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (final context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ödeme Bilgileri',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Seçilen Koltuklar: ${state.selectedSeats.join(", ")}'),
              Text('Tarih: ${state.eventDate?['date'] ?? ''}'),
              Text('Saat: ${state.eventDate?['time'] ?? ''}'),
              Text(
                'Toplam: ${state.totalPrice.toStringAsFixed(2)} TL',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showPaymentMethods(notifier),
                  child: const Text('Ödeme Yöntemi Seç'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPaymentMethods(final EventNotifier notifier) async {
    final selectedMethod = await showDialog<String>(
      context: context,
      builder: (final context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Ödeme Yöntemi Seçin',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPaymentOption(
                context,
                icon: Icons.account_balance_wallet,
                color: Colors.green.shade600,
                label: 'Google Play',
                onTap: () => Navigator.pop(context, 'google_play'),
              ),
              const SizedBox(height: 8),
              _buildPaymentOption(
                context,
                icon: Icons.credit_card,
                color: Colors.blue.shade600,
                label: 'Kredi Kartı',
                onTap: () => Navigator.pop(context, 'credit_card'),
              ),
              const SizedBox(height: 8),
              _buildPaymentOption(
                context,
                icon: Icons.account_balance,
                color: Colors.orange.shade700,
                label: 'IBAN / Banka',
                onTap: () => Navigator.pop(context, 'iban'),
              ),
              const SizedBox(height: 8),
              _buildPaymentOption(
                context,
                icon: Icons.coffee,
                color: Colors.brown.shade600,
                label: 'Kahve Ismarlama ☕ (Ücretsiz Etkinlik)',
                onTap: () => Navigator.pop(context, 'free_coffee'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedMethod != null) {
      final confirmed = await _showConfirmationDialog();
      if (confirmed ?? false) {
        Navigator.pop(context); // bottom sheet’i kapat
        await notifier.processPayment(selectedMethod);
      }
    }
  }

  /// 🔹 Tekrarlanan ödeme seçenekleri için yardımcı widget
  Widget _buildPaymentOption(
    final BuildContext context, {
    required final IconData icon,
    required final Color color,
    required final String label,
    required final VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (final context) {
        return AlertDialog(
          title: const Text('Onay'),
          content: const Text('Ödeme işlemini onaylıyor musunuz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hayır'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) {
        return AlertDialog(
          title: const Text('İşlem Süresi Doldu'),
          content: const Text('Rezervasyonlarınız iptal edildi.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((final route) => route.isFirst);
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) {
        return AlertDialog(
          title: const Text('Ödeme Başarılı'),
          content: const Text('Ödemeniz başarıyla tamamlandı.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((final route) => route.isFirst);
              },
              child: const Text('Anasayfa'),
            ),
            TextButton(
              onPressed: () {
                // Biletlerim sayfasına git
                Navigator.of(context).popUntil((final route) => route.isFirst);
                // Navigator.pushNamed(context, '/tickets');
              },
              child: const Text('Biletlerim'),
            ),
          ],
        );
      },
    );
  }
}
