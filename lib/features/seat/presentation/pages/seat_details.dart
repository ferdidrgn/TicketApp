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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventProvider);
    final loginState = ref.watch(loginProvider);
    final theme = context.theme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Koltuk Seçimi',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          _buildTimerChip(state.formattedTime),
        ],
      ),
      floatingActionButton: _buildFab(state, loginState.isLoggedIn),
      body: CustomAppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 🖼️ Üst Kısım: Sahne Görseli ve Bilgi
              _buildTopSection(),
              _buildSeatLegend(),

              // 🚀 Orta Kısım: Koltuk Planı (Scroll Edilebilir Alan)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Text("SAHNE",
                          style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 8,
                              color: Colors.white54,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildSeatGrid(state),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 💳 Alt Kısım: Seçilen Koltuklar ve Fiyat Kartı
              _buildBottomInfoCard(state, theme),
              const SizedBox(height: 80), // FAB için boşluk
            ],
          ),
        ),
      ),
    );
  }

  // --- UI BİLEŞENLERİ ---

  Widget _buildTopSection() => Column(
        children: [
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Image.asset('assets/images/stage_diagram.jpg',
                fit: BoxFit.contain),
          ),
        ],
      );

  Widget _buildTimerChip(String time) => Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(time,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      );

  Widget _buildSeatLegend() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(Colors.green, "Boş"),
            _legendItem(Colors.blue, "Sizin"),
            _legendItem(Colors.purple, "Dolu"),
          ],
        ),
      );

  Widget _legendItem(Color c, String l) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(l,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      );

  Widget _buildSeatGrid(EventState state) => Column(
        children: state.seatLayout.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 30,
                  child: Text(entry.key,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white38)),
                ),
                ...entry.value.map((seatId) => _buildSeatItem(seatId, state)),
              ],
            ),
          );
        }).toList(),
      );

  Widget _buildSeatItem(String seatId, EventState state) {
    final seatInfo = state.seatStatus[seatId];
    final status = seatInfo?['status'] ?? 'available';
    final isMyRes = (seatInfo?['customerId'] == state.customerId);
    final isProcessing = state.processingSeats.contains(seatId);

    Color color = Colors.green.withOpacity(0.6);
    if (status == 'sold')
      color = Colors.white10;
    else if (status == 'reserved')
      color = isMyRes ? Colors.blue : Colors.purple;

    return GestureDetector(
      onTap: (!isProcessing && (status == 'available' || isMyRes))
          ? () => ref.read(eventProvider.notifier).toggleSeatSelection(seatId)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isMyRes
              ? [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 8)]
              : null,
          border: Border.all(
              color: isMyRes ? Colors.white : Colors.white10, width: 1),
        ),
        child: Center(
          child: isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
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

  Widget _buildBottomInfoCard(EventState state, ThemeData theme) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white10),
        ),
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
                  const SizedBox(height: 4),
                  Text(
                    state.selectedSeats.isEmpty
                        ? "Henüz seçim yok"
                        : state.selectedSeats.join(", "),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                Text("${state.totalPrice.toStringAsFixed(2)} TL",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.greenAccent)),
              ],
            ),
          ],
        ),
      );

  Widget _buildFab(EventState state, bool isLoggedIn) {
    if (!isLoggedIn || !state.hasSelectedSeats) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      onPressed: state.isLoading ? null : () => _handlePayment(state),
      label: Text(state.isLoading ? 'İşleniyor...' : 'ÖDEMEYE GEÇ'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  // --- MANTIKSAL METODLAR ---

  void _handlePayment(EventState state) {
    // Senin mevcut _showPaymentMethods mantığını buraya ekle
    _showPaymentMethods(state);
  }

  Future<void> _showPaymentMethods(EventState s) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
                padding: EdgeInsets.all(20),
                child: Text("ÖDEME YÖNTEMİ",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))),
            ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.white),
                title: const Text("Kredi Kartı",
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, "card")),
            ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.white),
                title: const Text("EFT/Havale",
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, "iban")),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
    if (method != null)
      ref.read(eventProvider.notifier).processPayment(method, s);
  }
}
