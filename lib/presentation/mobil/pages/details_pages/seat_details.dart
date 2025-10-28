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
      if (mounted)
        // mounted kontrolü eklemek her zaman iyidir
        ref.initializeEventNotifier(
            eventId: widget.eventId,
            showId: widget.showId,
            customerId: widget.customerId);
    });
  }

  // Notifier'a erişimi kolaylaştır
  EventNotifier get notifier => ref.read(eventProvider.notifier);

  @override
  Widget build(final BuildContext context) {
    final state = ref.watch(eventProvider);

    // --- DÜZELTME 2: SNACKBAR SORUNU ÇÖZÜMÜ ---
    ref.listen<EventState>(
      eventProvider,
      (final previous, final next) {
        // Sadece 'errorMessage' null'dan farklı bir değere AYARLANDIĞINDA göster.
        if (next.errorMessage != null &&
            previous?.errorMessage != next.errorMessage) {
          // Mevcut snackbar'ları temizle ve yenisini göster
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage!)),
          );
        }
        // --- DÜZELTME 2 SONU ---

        // Süre dolduğunda dialog göster
        if (next.isTimeUp && (previous?.isTimeUp == false)) _showTimeUpDialog();

        // Ödeme başarılı olduğunda dialog göster
        if (next.paymentSuccessful && (previous?.paymentSuccessful == false)) {
          _showPaymentSuccessDialog();
          // Başarı durumunu notifier'da sıfırla ki tekrar gösterilmesin
          notifier.resetPaymentSuccess();
        }
      },
    );

    // Yükleme durumu: layout boş VE isLoading true ise
    // (isLoading: false ve layout boş ise veri gelmemiş/hata demektir)
    if (state.seatLayout.isEmpty && state.isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Yükleme bitmiş ama layout hala boşsa (veri yoksa)
    if (state.seatLayout.isEmpty && !state.isLoading) {
      return Scaffold(
          appBar: AppBar(title: const Text('Koltuk Seçimi')),
          body: const Center(child: Text('Koltuk planı yüklenemedi.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koltuk Seçimi'),
        actions: [
          Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(state.formattedTime,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))))
        ],
      ),
      body: Column(
        children: [
          _buildStageImage(),
          const SizedBox(height: 20),
          _buildSelectionInfo(state),
          const SizedBox(height: 10),
          _buildSeatLegend(),
          const SizedBox(height: 20),
          Expanded(child: _buildSeatLayout(state)),
          // notifier parametresi kaldırıldı
        ],
      ),
      floatingActionButton: state.hasSelectedSeats
          ? FloatingActionButton.extended(
              // Butona basıldığında state'in en güncel anlık görüntüsünü al
              onPressed: (state.processingSeats.isEmpty && !state.isLoading)
                  ? () => _showPaymentBottomSheet(ref.read(eventProvider))
                  : null,
              label: (state.processingSeats.isEmpty && !state.isLoading)
                  ? Text(
                      'Ödemeye Geç (${state.totalPrice.toStringAsFixed(2)} TL)')
                  : const Text('Koltuk güncelleniyor...'),
              icon: (state.processingSeats.isEmpty && !state.isLoading)
                  ? const Icon(Icons.payment)
                  : const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    ),
              backgroundColor: (state.processingSeats.isEmpty &&
                      !state.isLoading)
                  ? Theme.of(context).floatingActionButtonTheme.backgroundColor
                  : Colors.grey.shade600,
            )
          : null,
    );
  }

  Widget _buildStageImage() => SizedBox(
      width: double.infinity,
      height: 200,
      child: Image.asset('assets/images/stage_diagram.jpg', fit: BoxFit.cover));

  Widget _buildSelectionInfo(final EventState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text('Seçilen Koltuklar: ${state.selectedSeats.join(", ")}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 5),
          // --- FİYAT DÜZELTMESİ ARTIK BURADA GÖRÜNECEK ---
          Text(
            'Toplam Fiyat: ${state.totalPrice.toStringAsFixed(2)} TL',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        mainAxisAlignment: MainAxisAlignment.center, // Ortala
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
                color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildSeatLayout(final EventState state) {
    // state.seatLayout zaten hesaplanmış ve state içinde
    final seatsByRow = state.seatLayout;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200], // Rengi biraz açtım
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6))),
              child: const Center(
                child: Text('SAHNE',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87)),
              )),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    // Her satır için _buildSeatRow çağır
                    children: seatsByRow.entries.map((final entry) {
                      return _buildSeatRow(entry.key, entry.value, state);
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

  Widget _buildSeatRow(
    final String row,
    final List<String> seats,
    final EventState state,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Satırı ortala
        children: [
          SizedBox(
            width: 30,
            child:
                Text(row, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          // Her koltuk için _buildSeat çağır
          ...seats.map((final seatId) => _buildSeat(seatId, state)),
        ],
      ),
    );
  }

  Widget _buildSeat(
    final String seatId,
    final EventState state,
  ) {
    final seatInfo = state.seatStatus[seatId];
    final status = seatInfo?['status'] ?? 'available';
    final reservedById = seatInfo?['customerId'];

    final isSelected = state.selectedSeats.contains(seatId);
    final isMyReservation = reservedById == state.customerId;
    final isAvailable =
        status == 'available' || (status == 'reserved' && isMyReservation);

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

    // Satılmış veya başkası tarafından rezerve edilmişse tıklanamaz
    final bool canTap =
        (status == 'available' || isMyReservation) && !isSeatProcessing;

    return GestureDetector(
      // Tıklama olayını doğrudan notifier'a gönder
      onTap: canTap ? () => notifier.toggleSeatSelection(seatId) : null,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
            color: seatColor, borderRadius: BorderRadius.circular(8)),
        child: Center(
          child: isSeatProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Text(seatId.substring(1), // Sadece koltuk numarasını göster
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
        ),
      ),
    );
  }

  // 'stateSnapshot' alır
  void _showPaymentBottomSheet(final EventState stateSnapshot) {
    // Not: 'notifier'ı burada tekrar almamıza gerek yok, en üstte tanımladık.

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (final context) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              MediaQuery.of(context).viewInsets.bottom + 20), // Klavye için
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ödeme Bilgileri',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Snapshot'tan veriler okunuyor
              Text(
                  'Seçilen Koltuklar: ${stateSnapshot.selectedSeats.join(", ")}'),
              // --- FİYAT DÜZELTMESİ İLE BURASI DOĞRU GELECEK ---
              Text('Tarih: ${stateSnapshot.eventDate?['date'] ?? '...'}'),
              Text('Saat: ${stateSnapshot.eventDate?['time'] ?? '...'}'),
              const SizedBox(height: 8),
              Text('Toplam: ${stateSnapshot.totalPrice.toStringAsFixed(2)} TL',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Snapshot'ı bir sonraki fonksiyona aktar
                  onPressed: () => _showPaymentMethods(stateSnapshot),
                  child: const Text('Ödeme Yöntemi Seç'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 'stateSnapshot' parametresini alır ve 'processPayment'a aktarır
  Future<void> _showPaymentMethods(final EventState stateSnapshot) async {
    // Fiyata göre dinamik seçenekleri belirle
    final bool isFree = stateSnapshot.totalPrice <= 0;

    final selectedMethod = await showDialog<String>(
      context: context,
      builder: (final context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isFree ? 'Etkinlik Ücretsiz' : 'Ödeme Yöntemi Seçin',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fiyatlı bilet seçenekleri
              if (!isFree) ...[
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
              ],

              // Ücretsiz bilet seçenekleri
              if (isFree) ...[
                _buildPaymentOption(
                  context,
                  icon: Icons.coffee,
                  color: Colors.brown.shade600,
                  label: 'Kahve Ismarla ☕',
                  onTap: () => Navigator.pop(context, 'free_coffee'),
                ),
                const SizedBox(height: 8),
                _buildPaymentOption(
                  context,
                  icon: Icons.confirmation_number_outlined,
                  color: Colors.grey.shade600,
                  label: 'Ücretsiz Bilet Al',
                  onTap: () => Navigator.pop(context, 'free_ticket'),
                ),
              ]
            ],
          ),
        );
      },
    );

    if (selectedMethod != null) {
      final confirmed = await _showConfirmationDialog();
      if (confirmed ?? false) {
        if (!mounted) return; // Async sonrası context kontrolü
        Navigator.pop(context); // bottom sheet’i kapat
        await notifier.processPayment(selectedMethod, stateSnapshot);
      }
    }
  }

  /// Tekrarlanan ödeme seçenekleri için yardımcı widget
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
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right, color: color)
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
                child: const Text('Hayır')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Evet')),
          ],
        );
      },
    );
  }

  void _showTimeUpDialog() {
    if (!mounted) return; // Dialog göstermeden önce context'i kontrol et
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) {
        return AlertDialog(
          title: const Text('İşlem Süresi Doldu'),
          content: const Text(
              'Rezervasyonlarınız iptal edildi. Anasayfaya yönlendirileceksiniz.'),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .popUntil((final route) => route.isFirst);
                },
                child: const Text('Tamam')),
          ],
        );
      },
    );
  }

  void _showPaymentSuccessDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final context) {
        return AlertDialog(
          title: const Text('Ödeme Başarılı'),
          content: const Text('Ödemeniz başarıyla tamamlandı.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context)
                    .popUntil((final route) => route.isFirst),
                child: const Text('Anasayfa')),
            TextButton(
                onPressed: () => Navigator.of(context)
                    .popUntil((final route) => route.isFirst),
                child: const Text('Biletlerim')),
          ],
        );
      },
    );
  }
}
