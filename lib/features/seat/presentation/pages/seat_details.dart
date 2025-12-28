import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/features/events/presentation/providers/event_notifier.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../events/presentation/providers/event_state.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';

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
      if (mounted) {
        // mounted kontrolü eklemek her zaman iyidir
        ref.initializeEventNotifier(
            eventId: widget.eventId,
            showId: widget.showId,
            customerId: widget.customerId);

        // Kullanıcının mevcut biletlerini limit kontrolü için yükle
        if (widget.customerId.isNotEmpty)
          ref
              .read(ticketProvider.notifier)
              .loadTicketsAndDetailsByCustomerId(widget.customerId);
      }
    });
  }

  EventNotifier get notifier => ref.read(eventProvider.notifier);

  @override
  Widget build(final BuildContext context) {
    final state = ref.watch(eventProvider);
    final loginState =
        ref.watch(loginProvider); // HATA ÇÖZÜMÜ: Eksik identifier eklendi.

    // Dinleyici: Hata mesajları ve başarı durumları için
    ref.listen<EventState>(eventProvider, (final previous, final next) {
      if (next.errorMessage != null &&
          previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
      if (next.isTimeUp && (previous?.isTimeUp == false)) _showTimeUpDialog();
      if (next.paymentSuccessful && (previous?.paymentSuccessful == false)) {
        _showPaymentSuccessDialog();
        notifier.resetPaymentSuccess();
      }
    });

    if (state.seatLayout.isEmpty && state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _buildStageImage(),
          _buildSelectionInfo(state),
          _buildSeatLegend(),
          const SizedBox(height: 10),
          Expanded(child: _buildSeatLayout(state)),
        ],
      ),
      floatingActionButton: _buildFab(state, loginState.isLoggedIn),
    );
  }

  // --- 🛠️ REFACTORED WIDGETS ---

  Widget _buildFab(final EventState state, final bool isLoggedIn) {
    if (!isLoggedIn) {
      return FloatingActionButton.extended(
        onPressed: () => context.push('/login'),
        label: const Text('Giriş Yap ve Bilet Al'),
        icon: const Icon(Icons.login),
      );
    }

    if (!state.hasSelectedSeats) return const SizedBox.shrink();

    final isProcessing = state.processingSeats.isNotEmpty || state.isLoading;

    return FloatingActionButton.extended(
      onPressed:
          isProcessing ? null : () => _checkConstraintsAndOpenPayment(state),
      label: Text(isProcessing
          ? 'İşlem yapılıyor...'
          : 'Ödemeye Geç (${state.totalPrice.toStringAsFixed(2)} TL)'),
      icon: isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.payment),
      backgroundColor: isProcessing ? Colors.grey : null,
    );
  }

  Widget _buildSeat(final String seatId, final EventState state) {
    final seatInfo = state.seatStatus[seatId];
    final status = seatInfo?['status'] ?? 'available';
    final isMyReservation = (seatInfo?['customerId'] == state.customerId);
    final isSeatProcessing = state.processingSeats.contains(seatId);

    Color seatColor = Colors.green;
    if (status == 'sold')
      seatColor = Colors.black12;
    else if (status == 'reserved')
      seatColor = isMyReservation ? Colors.blue : Colors.purple;

    final bool canTap =
        (status == 'available' || (status == 'reserved' && isMyReservation)) &&
            !isSeatProcessing;

    return GestureDetector(
      onTap: canTap
          ? () {
              if (state.customerId.isNotEmpty) {
                notifier.toggleSeatSelection(seatId);
              } else {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Koltuk seçmek için lütfen giriş yapın.")));
              }
            }
          : null,
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
                      strokeWidth: 2, color: Colors.white))
              : Text(seatId.substring(1),
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
    );
  }

  // --- 🔐 BUSINESS LOGIC ---

  Future<void> _checkConstraintsAndOpenPayment(
      final EventState stateSnapshot) async {
    final loginState = ref.read(loginProvider);

    if (!loginState.isLoggedIn) {
      await context.push('/login');
      return;
    }

    final String dName = loginState.displayName ?? '';
    if (dName.isEmpty || dName == 'Kullanıcı' || dName == 'Ziyaretçi') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Profilinizden ad-soyad girmelisiniz.")));
      await context.push('/profile-edit/${loginState.userId}');
      return;
    }

    final ticketsState = ref.read(ticketProvider);
    final existingCount = ticketsState.dataList
            ?.where((final t) => t.eventId == widget.eventId)
            .length ??
        0;

    if ((existingCount + stateSnapshot.selectedSeats.length) > 3) {
      await _showLimitErrorDialog();
      return;
    }

    await _showPaymentMethods(stateSnapshot);
  }

  // --- ℹ️ OTHER UI HELPERS (Kısaltılmış) ---
  Widget _buildStageImage() => SizedBox(
      width: double.infinity,
      height: 160,
      child: Image.asset('assets/images/stage_diagram.jpg', fit: BoxFit.cover));

  Widget _buildSelectionInfo(final EventState s) => Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
          'Seçilen: ${s.selectedSeats.join(", ")} | Toplam: ${s.totalPrice} TL',
          style: const TextStyle(fontWeight: FontWeight.bold)));

  Widget _buildSeatLegend() =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legendItem(Colors.green, "Boş"),
        _legendItem(Colors.blue, "Sizin"),
        _legendItem(Colors.purple, "Dolu")
      ]);

  Widget _legendItem(final Color c, final String l) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: [
        Container(width: 12, height: 12, color: c),
        const SizedBox(width: 4),
        Text(l, style: const TextStyle(fontSize: 12))
      ]));

  Widget _buildSeatLayout(final EventState state) => Container(
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
                      children: state.seatLayout.entries.map((final entry) {
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

  Widget _buildSeatRow(
    final String row,
    final List<String> seats,
    final EventState state,
  ) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Satırı ortala
          children: [
            SizedBox(
              width: 30,
              child: Text(row,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            // Her koltuk için _buildSeat çağır
            ...seats.map((final seatId) => _buildSeat(seatId, state)),
          ],
        ),
      );

  // 🚨 Bu bir fonksiyondur, sınıfın içine ekle
  Future<void> _showLimitErrorDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Kullanıcı dışarı tıklayıp kapatamasın
      builder: (final BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Bilet Limiti'),
            ],
          ),
          content: const Text(
            'Bu etkinlik için toplamda en fazla 3 bilet alabilirsiniz. Lütfen seçtiğiniz koltuk sayısını kontrol edin.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
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
      builder: (final context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isFree ? 'Etkinlik Ücretsiz' : 'Ödeme Yöntemi Seçin',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
      ),
    );

    if (selectedMethod != null) {
      final confirmed = await _showConfirmationDialog();
      if (confirmed ?? false) {
        if (!mounted) return;
        Navigator.pop(context);
        // snapshot yerine direkt o anki güncel state'i gönder
        await notifier.processPayment(selectedMethod, ref.read(eventProvider));
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
  }) =>
      InkWell(
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

  Future<bool?> _showConfirmationDialog() => showDialog<bool>(
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

  void _showTimeUpDialog() => showDialog(
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

  void _showPaymentSuccessDialog() => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final context) => Dialog(
          elevation: 8.0,
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            constraints: const BoxConstraints(maxWidth: 400),
            // Geniş ekranlarda yayılmasın
            child: Column(
              mainAxisSize: MainAxisSize.min, // İçeriğe göre boyutu ayarla
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ödeme Başarılı',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ödemeniz başarıyla tamamlandı. Biletleriniz ilgili bölüme eklendi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      // Önce dialog'u kapat, sonra anasayfaya git
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .popUntil((final route) => route.isFirst);
                    },
                    child: const Text('Biletlerim',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .popUntil((final route) => route.isFirst);
                    },
                    child: const Text('Anasayfa'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
