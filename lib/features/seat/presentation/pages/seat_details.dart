import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';

import '../../../events/presentation/providers/event_notifier.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) {
        ref.initializeEventNotifier(
          eventId: widget.eventId,
          showId: widget.showId,
          customerId: widget.customerId,
        );
        if (widget.customerId.isNotEmpty) {
          ref
              .read(ticketProvider.notifier)
              .loadTicketsAndDetailsByCustomerId(widget.customerId);
        }
      }
    });
  }

  EventNotifier get notifier => ref.read(eventProvider.notifier);

  @override
  Widget build(final BuildContext context) {
    final state = ref.watch(eventProvider);
    final loginState = ref.watch(loginProvider);
    final theme = context.theme;

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Koltuk Seçimi',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
      // FAB Location ayarı alt panelin üzerine binmemesi için önemli
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFab(state, loginState.isLoggedIn),
      body: CustomAppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildStageImage(),
              _buildSelectionInfo(state),
              _buildSeatLegend(),
              const SizedBox(height: 10),
              // 🚀 Eski stabil layout yapısına geri dönüldü
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSeatLayout(state),
                ),
              ),
              // Bottom Card alanı için boşluk
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- 🛠️ REFACTORED WIDGETS (Orijinal Mantık) ---

  Widget _buildStageImage() => Container(
        height: 140,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child:
            Image.asset('assets/images/stage_diagram.jpg', fit: BoxFit.contain),
      );

  Widget _buildSelectionInfo(final EventState s) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('Seçilen: ${s.selectedSeats.join(", ")}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Text('${s.totalPrice.toStringAsFixed(2)} TL',
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.greenAccent,
                    fontSize: 18)),
          ],
        ),
      );

  Widget _buildSeatLegend() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(Colors.green, "Boş"),
          _legendItem(Colors.blue, "Sizin"),
          _legendItem(Colors.purple, "Dolu"),
        ],
      );

  Widget _legendItem(final Color c, final String l) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                    color: c, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 6),
            Text(l,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      );

  Widget _buildSeatLayout(final EventState state) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black26, // Arka plan şeffaf koyu
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('SAHNE',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white70,
                        letterSpacing: 4)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: state.seatLayout.entries.map((final entry) {
                      return _buildSeatRow(entry.key, entry.value, state);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildSeatRow(
          final String row, final List<String> seats, final EventState state) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              child: Text(row,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white60)),
            ),
            ...seats.map((final seatId) => _buildSeat(seatId, state)),
          ],
        ),
      );

  Widget _buildSeat(final String seatId, final EventState state) {
    final seatInfo = state.seatStatus[seatId];
    final status = seatInfo?['status'] ?? 'available';
    final isMyRes = (seatInfo?['customerId'] == state.customerId);
    final isProcessing = state.processingSeats.contains(seatId);

    // Orijinal Renkler
    Color seatColor = Colors.green;
    if (status == 'sold')
      seatColor = Colors.white10;
    else if (status == 'reserved')
      seatColor = isMyRes ? Colors.blue : Colors.purple;

    final bool canTap =
        (status == 'available' || (status == 'reserved' && isMyRes)) &&
            !isProcessing;

    return GestureDetector(
      onTap: canTap ? () => notifier.toggleSeatSelection(seatId) : null,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isMyRes ? Colors.white : Colors.transparent, width: 1.5),
        ),
        child: Center(
          child: isProcessing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(seatId.substring(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // --- FAB & Business Logic ---

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
      label: Text(isProcessing ? 'İşleniyor...' : 'Ödemeye Geç'),
      icon: isProcessing
          ? const CircularProgressIndicator()
          : const Icon(Icons.payment),
      backgroundColor: isProcessing ? Colors.grey : null,
    );
  }

  // ... (Geri kalan Diyaloglar ve İş Mantığı aynı kalacak şekilde)
  // _checkConstraintsAndOpenPayment, _showLimitErrorDialog, _showPaymentMethods vb.
  // Eski kodundaki divalogları buraya direkt yapıştırabilirsin.

  Future<void> _checkConstraintsAndOpenPayment(
      final EventState stateSnapshot) async {
    final loginState = ref.read(loginProvider);
    if (!loginState.isLoggedIn) {
      context.push('/login');
      return;
    }

    final ticketsState = ref.read(ticketProvider);
    final existingCount = ticketsState.dataList
            ?.where((t) => t.eventId == widget.eventId)
            .length ??
        0;

    if ((existingCount + stateSnapshot.selectedSeats.length) > 3) {
      _showLimitErrorDialog();
      return;
    }
    _showPaymentMethods(stateSnapshot);
  }

  void _showLimitErrorDialog() => showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
            title: const Text("Limit Aşıldı"),
            content: const Text("En fazla 3 bilet alabilirsiniz."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Tamam"))
            ],
          ));

  Future<void> _showPaymentMethods(EventState s) async {
    final method = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                    title: const Text("Kredi Kartı"),
                    onTap: () => Navigator.pop(ctx, "card")),
                ListTile(
                    title: const Text("EFT"),
                    onTap: () => Navigator.pop(ctx, "iban")),
                const SizedBox(height: 20),
              ],
            ));
    if (method != null) await notifier.processPayment(method, s);
  }

  void _showTimeUpDialog() => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
            title: const Text("Süre Doldu"),
            content: const Text("İşleminiz zaman aşımına uğradı."),
            actions: [
              TextButton(
                  onPressed: () => context.go('/'), child: const Text("Tamam"))
            ],
          ));

  void _showPaymentSuccessDialog() => showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
            title: const Text("Başarılı"),
            content: const Text("Biletleriniz hazır!"),
            actions: [
              TextButton(
                  onPressed: () => context.go('/'), child: const Text("Kapat"))
            ],
          ));
}
