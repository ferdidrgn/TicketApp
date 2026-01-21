import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/event_notifier.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../events/presentation/providers/event_state.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';

class SeatSelectionScreen extends ConsumerStatefulWidget {
  final String showId;
  final String eventId;
  final String customerId;

  const SeatSelectionScreen(
      {super.key,
      required this.showId,
      required this.eventId,
      required this.customerId});

  @override
  ConsumerState<SeatSelectionScreen> createState() =>
      _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends ConsumerState<SeatSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      ref.initializeEventNotifier(
          eventId: widget.eventId,
          showId: widget.showId,
          customerId: widget.customerId);
      if (widget.customerId.isNotEmpty)
        ref
            .read(ticketProvider.notifier)
            .loadTicketsAndDetailsByCustomerId(widget.customerId);
    });
  }

  @override
  Widget build(final BuildContext context) {
    final state = ref.watch(eventProvider);

    // 🔔 State Dinleyicileri (Loading, Error, Success)
    _setupListeners();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(state.formattedTime),
      floatingActionButton: _SeatFab(state: state, eventId: widget.eventId),
      body: CustomAppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopVisual(),
              const _SeatLegend(),
              Expanded(child: _SeatLayoutContainer(state: state)),
              _BottomPriceCard(state: state),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _setupListeners() {
    ref.listen<EventState>(eventProvider, (final prev, final next) {
      if (next.isLoading && !prev!.isLoading)
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (final _) => const CustomLoadingDialog(
                message: "Biletleriniz Hazırlanıyor..."));
      else if (!next.isLoading && prev!.isLoading) Navigator.of(context).pop();

      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        showDialog(
            context: context,
            builder: (final _) =>
                CustomErrorDialog(message: next.errorMessage!));
      }

      if (next.paymentSuccessful && !prev!.paymentSuccessful) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (final ctx) => CustomActionDialog(
            title: "İŞLEM TAMAM!",
            message: "Biletleriniz başarıyla oluşturuldu.",
            positiveText: "BİLETLERİM",
            negativeText: "ANASAYFA",
            onPositiveAction: () =>
                NavigationHandler.goToMyTickets(context, widget.customerId),
            onNegativeAction: () => NavigationHandler.goToHome(context),
          ),
        );
        ref.read(eventProvider.notifier).resetPaymentSuccess();
      }
    });
  }

  PreferredSizeWidget _buildAppBar(final String time) => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Koltuk Seçimi',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white12, borderRadius: BorderRadius.circular(20)),
            child: Center(
                child: Text(time,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))),
          )
        ],
      );

  Widget _buildTopVisual() => Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child:
            Image.asset('assets/images/stage_diagram.jpg', fit: BoxFit.contain),
      );
}

// ============================================================
// 🚀 ÖZEL BİLEŞENLER (MODÜLER YAPI)
// ============================================================

class _SeatLayoutContainer extends StatelessWidget {
  final EventState state;

  const _SeatLayoutContainer({required this.state});

  @override
  Widget build(final BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white10)),
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
                child: _SeatGrid(state: state),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatGrid extends ConsumerWidget {
  final EventState state;

  const _SeatGrid({required this.state});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return Column(
      children: state.seatLayout.entries.map((final entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  width: 30,
                  child: Text(entry.key,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white38))),
              ...entry.value.map(
                  (final seatId) => _SeatItem(seatId: seatId, state: state)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SeatItem extends ConsumerWidget {
  final String seatId;
  final EventState state;

  const _SeatItem({required this.seatId, required this.state});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
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
          border: Border.all(color: isMyRes ? Colors.white : Colors.white10),
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
}

class _BottomPriceCard extends StatelessWidget {
  final EventState state;

  const _BottomPriceCard({required this.state});

  @override
  Widget build(final BuildContext context) {
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
                    state.selectedSeats.isEmpty
                        ? "Seçim yok"
                        : state.selectedSeats.join(", "),
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
  }
}

// ============================================================
// 🔐 GÜVENLİK VE LİMİT KONTROLLÜ FAB
// ============================================================

class _SeatFab extends ConsumerWidget {
  final EventState state;
  final String eventId;

  const _SeatFab({required this.state, required this.eventId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    final tickets = ref.watch(ticketProvider).dataList ?? [];

    // 1. Daha önce alınan biletleri say
    final existingTicketsCount =
        tickets.where((final t) => t.eventId == eventId).length;
    final selectedCount = state.selectedSeats.length;

    // 2. Limit Kontrolü (Toplam 3'ü geçemez)
    final bool isOverLimit = (existingTicketsCount + selectedCount) > 3;

    // 3. Genel Geçerlilik (Kullanıcı doğrulanmış mı?)
    final bool isUserValid = isLoggedIn && currentUser != null;
    final bool canProcess = isUserValid &&
        !state.isLoading &&
        state.hasSelectedSeats &&
        !isOverLimit;

    if (!isLoggedIn) {
      return FloatingActionButton.extended(
          onPressed: () => NavigationHandler.goToLogin(context),
          label: const Text('Giriş Yap'),
          icon: const Icon(Icons.login));
    }

    if (!state.hasSelectedSeats) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: canProcess ? () => _handlePayment(context, ref, state) : null,
      backgroundColor: isOverLimit
          ? Colors.red.shade900
          : (canProcess ? Colors.white : Colors.grey.shade800),
      foregroundColor: canProcess ? Colors.black : Colors.white24,
      label: Text(state.isLoading
          ? 'İşleniyor...'
          : (isOverLimit
              ? 'Limit Aşıldı (Max 3)'
              : (isUserValid ? 'ÖDEMEYE GEÇ' : 'Doğrulanıyor...'))),
      icon: Icon(
          isOverLimit
              ? Icons.warning
              : (isUserValid ? Icons.arrow_forward_ios : Icons.person_off),
          size: 16),
    );
  }

  void _handlePayment(
      final BuildContext context, final WidgetRef ref, final EventState s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (final ctx) => SafeArea(
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
                onTap: () => _process(ctx, ref, s, "card")),
            ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.white),
                title: const Text("EFT/Havale",
                    style: TextStyle(color: Colors.white)),
                onTap: () => _process(ctx, ref, s, "iban")),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _process(final BuildContext ctx, final WidgetRef ref, final EventState s,
      final String method) {
    // Önce BottomSheet'i kapat
    Navigator.pop(ctx);

    // 🛡️ SON ONAY DİALOGU
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (final dialogContext) => CustomActionDialog(
        title: "SON ONAY",
        message:
            "${s.selectedSeats.length} koltuk için ${s.totalPrice.toStringAsFixed(2)} TL ödeme yapılacaktır. Onaylıyor musunuz?",
        positiveText: "EVET, SATIN AL",
        negativeText: "VAZGEÇ",
        icon: Icons.shopping_cart_checkout_rounded,
        iconColor: Colors.blueAccent,
        onPositiveAction: () =>
            ref.read(eventProvider.notifier).processPayment(method, s),
        onNegativeAction: () {
          // Kullanıcı vazgeçti, bir şey yapmaya gerek yok (Dialog zaten kapandı)
        },
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _item(Colors.green, "Boş"),
          _item(Colors.blue, "Sizin"),
          _item(Colors.purple, "Dolu"),
        ]),
      );

  Widget _item(final Color c, final String l) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(l, style: const TextStyle(fontSize: 12, color: Colors.white70))
        ]),
      );
}
