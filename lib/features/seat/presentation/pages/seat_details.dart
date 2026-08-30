import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/button/back_button_glassmorphism.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../payments/data/services/free_ticket_service.dart';
import '../../../payments/data/services/payment_gateway_service.dart';
import '../../../payments/presentation/providers/payment_status_provider.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../widgets/purchase_success_dialog.dart';

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

  // 🛡️ MİSAFİR KONTROLÜ
  bool get _isGuest =>
      widget.customerId == 'guest' || widget.customerId.isEmpty;

  @override
  void dispose() {
    // 🔥 EKSİK OLAN KOLTUK SERBEST BIRAKMA:
    // Kullanıcı ödemeyi tamamlamadan bu ekrandan çıkarsa (geri tuşu, uygulamayı
    // kapatma, başka bir sekmeye geçme vb.), önceden 'reserved' koltuklar
    // SONSUZA KADAR kilitli kalıyordu — hiçbir yerde bu ekrandan çıkışta
    // otomatik bir "serbest bırak" çağrısı yoktu ve backend'de de süre
    // dolumu (TTL) mekanizması bulunmuyor. Bu, gerçek koltukların satışa
    // kapanmasına yol açan ciddi bir envanter kilitlenmesi hatasıydı.
    // Not: Bu sadece normal (dispose çağrılan) çıkışları kapsar; uygulama
    // çökmesi veya sekmenin aniden kapatılması gibi durumlar için hâlâ
    // sunucu tarafında bir TTL/temizlik mekanizması (örn. reservedAt alanına
    // bakan zamanlanmış bir Cloud Function) eklenmesi gerekiyor.
    if (!_isGuest) {
      try {
        final seats = ref.read(eventSeatsProvider(widget.eventId)).value ?? {};
        for (final entry in seats.entries) {
          if (entry.value['status'] == 'reserved' &&
              entry.value['customerId'] == widget.customerId) {
            ref
                .read(toggleSeatSelectionProvider(
              eventId: widget.eventId,
              seatId: entry.key,
              customerId: widget.customerId,
              isAdding: false,
            ).future)
                .catchError((final _) {});
          }
        }
      } catch (_) {
        // Dispose sırasında provider erişimi güvenli değilse sessizce geç;
        // koltuk her hâlükârda ana asenkron akış tamamlanınca serbest kalır.
      }
    }
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final seatsAsync = ref.watch(eventSeatsProvider(widget.eventId));
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final timerStream = ref.watch(reservationTimerProvider);

    return Scaffold(
      backgroundColor: BentoColors.canvas,
      appBar: _buildAppBar(timerStream.value ?? 600),
      body: eventAsync.when(
        data: (final event) => Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [BentoColors.card, BentoColors.canvas],
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
                    data: (final seatsStatus) => _SeatLayoutBuilder(
                      allSeatsData: event.seats,
                      liveStatus: seatsStatus,
                      processingSeats: _processingSeats,
                      customerId: widget.customerId,
                      onSeatTap: _handleSeatTap, // Tıklama fonksiyonu
                    ),
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: BentoColors.indigoLight)),
                    error: (final e, final _) => Center(
                        child: Text("Hata: $e",
                            style: const TextStyle(color: Colors.white))),
                  ),
                ),

                _buildPriceCard(seatsAsync, event.price),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: BentoColors.indigoLight)),
        error: (final e, final _) => Center(
            child: Text("Yüklenemedi: $e",
                style: const TextStyle(color: Colors.white))),
      ),
      floatingActionButton:
          _buildFab(seatsAsync.value ?? {}, eventAsync.value?.isFree ?? false),
    );
  }

  // 🔹 KOLTUK SEÇME MANTIĞI (GÜVENLİK EKLENDİ)
  Future<void> _handleSeatTap(
      final String seatId, final String status, final bool isMine) async {
    // 1. GÜVENLİK KONTROLÜ: Misafir ise işlem yapma, Login'e yönlendir
    if (_isGuest) {
      _showLoginDialog();
      return;
    }

    if (_processingSeats.contains(seatId)) return;

    setState(() => _processingSeats.add(seatId));
    try {
      await ref.read(toggleSeatSelectionProvider(
        eventId: widget.eventId,
        seatId: seatId,
        customerId: widget.customerId,
        isAdding: status == 'available',
      ).future);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("İşlem başarısız: $e")));
    } finally {
      if (mounted) setState(() => _processingSeats.remove(seatId));
    }
  }

  // 🔹 MİSAFİR İÇİN GİRİŞ YAP BUTONU
  Widget _buildFab(
      final Map<String, Map<String, dynamic>> seats, final bool isFree) {
    // Eğer misafirse ve bir şekilde seçim ekranındaysa, buton GİRİŞ YAP olsun
    if (_isGuest) {
      return FloatingActionButton.extended(
        onPressed: () => NavigationHandler.goToLogin(context),
        backgroundColor: Colors.amber,
        label: const Text("GİRİŞ YAP",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.login, color: Colors.black, size: 16),
      );
    }

    // Normal kullanıcı mantığı
    final mySelectedSeats = seats.entries
        .where((final e) =>
            e.value['customerId'] == widget.customerId &&
            e.value['status'] == 'reserved')
        .map((final e) => e.key)
        .toList();

    if (mySelectedSeats.isEmpty) return const SizedBox.shrink();

    // 🎁 Ücretsiz etkinlik: ödeme adımı tamamen atlanır, doğrudan talep edilir.
    if (isFree) {
      return FloatingActionButton.extended(
        onPressed: () => _claimFreeTicket(context, mySelectedSeats),
        backgroundColor: BentoColors.emerald,
        label: const Text("ÜCRETSİZ BİLETİNİ AL",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 18),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () => _showPaymentModal(context, mySelectedSeats),
      backgroundColor: Colors.white,
      label: const Text("ÖDEMEYE GEÇ",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.credit_card, color: Colors.black, size: 16),
    );
  }

  /// 🎁 ÜCRETSİZ BİLET TALEBİ:
  /// Ödeme sağlayıcısı yok — sunucu (functions/freeTickets/index.js)
  /// etkinliğin gerçekten ücretsiz olduğunu ve koltukların bu kullanıcı
  /// tarafından rezerve edildiğini doğrular, bileti oluşturur ve kullanıcının
  /// profilindeki telefon numarasına SMS ile bilgi gönderir. "Etkinlik
  /// başına en fazla 3" kuralı ayrıca kontrol edilmiyor çünkü koltuk
  /// rezervasyon adımı (attemptReservation) bunu zaten uyguluyor.
  Future<void> _claimFreeTicket(
      final BuildContext ctx, final List<String> seats) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final _) => const Center(
            child: CircularProgressIndicator(color: BentoColors.emerald)));

    try {
      await FreeTicketService.claim(eventId: widget.eventId, seatIds: seats);
      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(myTicketsProvider(widget.customerId));
        await _showPurchaseSuccessAfterLookup(seats: seats, total: 0);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$e"), backgroundColor: Colors.red));
      }
    }
  }

  // 🔹 MİSAFİR UYARI DİYALOGU
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (final ctx) => AlertDialog(
        backgroundColor: BentoColors.card,
        title: const Text("Giriş Yapmalısınız",
            style: TextStyle(color: Colors.white)),
        content: const Text(
            "Koltuk seçebilmek ve bilet alabilmek için lütfen giriş yapın.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text("İptal", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: BentoColors.indigoLight),
            onPressed: () {
              Navigator.pop(ctx);
              NavigationHandler.goToLogin(context);
            },
            child:
                const Text("GİRİŞ YAP", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // --- DİĞER YARDIMCI METODLAR (AYNI KALDI) ---

  void _showPaymentModal(
      final BuildContext context, final List<String> selectedSeats) async {
    final event = await ref.read(eventDetailProvider(widget.eventId).future);
    final unitPrice = double.tryParse(event.price) ?? 0.0;
    final totalPrice = selectedSeats.length * unitPrice;

    showModalBottomSheet(
      context: context,
      backgroundColor: BentoColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (final ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ödeme Yöntemi Seçin",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _paymentOption(
                  icon: Icons.credit_card,
                  title: "iyzico ile Öde",
                  subtitle: "Kredi / Banka Kartı",
                  onTap: () => _processGatewayPurchase(ctx, selectedSeats,
                      PaymentGatewayProvider.iyzico, totalPrice)),
              const SizedBox(height: 12),
              _paymentOption(
                  icon: Icons.credit_card,
                  title: "PayTR ile Öde",
                  subtitle: "Kredi / Banka Kartı",
                  onTap: () => _processGatewayPurchase(ctx, selectedSeats,
                      PaymentGatewayProvider.paytr, totalPrice)),
              const SizedBox(height: 12),
              _paymentOption(
                  icon: Icons.credit_card,
                  title: "Stripe ile Öde",
                  subtitle: "Uluslararası Kart",
                  onTap: () => _processGatewayPurchase(ctx, selectedSeats,
                      PaymentGatewayProvider.stripe, totalPrice)),
              const SizedBox(height: 12),
              _paymentOption(
                  icon: Icons.account_balance,
                  title: "Havale / EFT",
                  subtitle: "IBAN ile ödeme",
                  onTap: () => _processPurchase(ctx, selectedSeats, "iban",
                      totalPrice, event.stageId, event.showId)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentOption(
      {required final IconData icon,
      required final String title,
      required final String subtitle,
      required final VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(12),
      tileColor: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: BentoColors.indigoLight.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: BentoColors.indigoLight)),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
    );
  }

  Future<void> _processPurchase(
      final BuildContext ctx,
      final List<String> seats,
      final String method,
      final double total,
      final String stageId,
      final String showId) async {
    Navigator.pop(ctx);
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final _) =>
            const Center(child: CircularProgressIndicator(color: BentoColors.indigoLight)));

    try {
      await ref.read(purchaseActionProvider(
        eventId: widget.eventId,
        showId: showId,
        stageId: stageId,
        seatIds: seats,
        customerId: widget.customerId,
        paymentMethod: method,
        totalPrice: total,
      ).future);

      if (mounted) {
        Navigator.pop(context);
        await _showPurchaseSuccessAfterLookup(seats: seats, total: total);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
      }
    }
  }

  /// `card`/iban akışı başarıyla bitince en son oluşturulan bileti bulup
  /// başarı diyalogunu gösterir. Hem manuel (iban) hem de gerçek ödeme
  /// sağlayıcısı (kart) akışı tarafından ortak kullanılır.
  Future<void> _showPurchaseSuccessAfterLookup(
      {required final List<String> seats, required final double total}) async {
    // Yeni oluşturulan bileti bul. Bulunamazsa (ör. ağ gecikmesi) dialog
    // yine de "BİLETİ GÖR" butonu olmadan gösterilir.
    DetailedTicket? newTicket;
    try {
      final tickets =
          await ref.read(myTicketsProvider(widget.customerId).future);
      for (final t in tickets) {
        if (t.ticket.eventId != widget.eventId) continue;
        if (newTicket == null) {
          newTicket = t;
          continue;
        }
        final current = DateTime.tryParse(t.ticket.createdAt);
        final best = DateTime.tryParse(newTicket.ticket.createdAt);
        if (current != null && (best == null || current.isAfter(best))) {
          newTicket = t;
        }
      }
    } catch (_) {
      // Bilet detayını önceden gösteremezsek bile satın alma başarılı
      // olduğu için akışı kesmiyoruz.
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final _) => PurchaseSuccessDialog(
          ticket: newTicket,
          customerId: widget.customerId,
          seatCount: seats.length,
          totalPrice: total,
        ),
      );
    }
  }

  /// 💳 GERÇEK ÖDEME AKIŞI (iyzico/PayTR/Stripe):
  /// 1) Sunucuda (Cloud Functions) bir ödeme oturumu oluşturulur — tutar ve
  ///    koltuk rezervasyonu orada doğrulanır, client'a güvenilmez.
  /// 2) Sağlayıcının barındırılan ödeme sayfası harici tarayıcıda açılır.
  /// 3) `Payment/{paymentId}` Firestore dökümanı dinlenir; sağlayıcının
  ///    webhook'u ödemeyi doğrulayıp 'paid' yaptığında bilet SUNUCU
  ///    tarafında zaten oluşturulmuş olur (bkz. functions/payments/index.js
  ///    finalizePayment) — burada sadece güncel listeyi yeniden çekiyoruz.
  Future<void> _processGatewayPurchase(
      final BuildContext ctx,
      final List<String> seats,
      final PaymentGatewayProvider provider,
      final double total) async {
    Navigator.pop(ctx);
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final _) =>
            const Center(child: CircularProgressIndicator(color: BentoColors.indigoLight)));

    final PaymentSession session;
    try {
      session = await PaymentGatewayService.createSession(
        provider: provider,
        eventId: widget.eventId,
        seatIds: seats,
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$e"), backgroundColor: Colors.red));
      }
      return;
    }

    if (!mounted) return;
    Navigator.pop(context); // Yükleniyor dialogunu kapat

    final launched = await launchUrl(Uri.parse(session.checkoutUrl),
        mode: LaunchMode.externalApplication);
    if (!launched) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Ödeme sayfası açılamadı."),
            backgroundColor: Colors.red));
      }
      return;
    }

    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (final dialogCtx) => Consumer(
        builder: (final _, final consumerRef, final __) {
          final data =
              consumerRef.watch(paymentStatusStreamProvider(session.paymentId)).value;
          final status = data?['status'] as String?;
          if (status == 'paid' || status == 'failed') {
            WidgetsBinding.instance.addPostFrameCallback((final _) {
              if (Navigator.canPop(dialogCtx)) Navigator.pop(dialogCtx, status);
            });
          }
          return AlertDialog(
            backgroundColor: BentoColors.card,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: BentoColors.indigoLight),
                const SizedBox(height: 16),
                Text(
                  status == 'failed'
                      ? (data?['failureReason'] as String? ?? 'Ödeme başarısız.')
                      : 'Ödemeni tamamladıktan sonra buraya otomatik döneceğiz...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (!mounted) return;
    if (result == 'paid') {
      ref.invalidate(myTicketsProvider(widget.customerId));
      await _showPurchaseSuccessAfterLookup(seats: seats, total: total);
    } else if (result == 'failed') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Ödeme tamamlanamadı."), backgroundColor: Colors.red));
    }
  }

  Widget _buildPriceCard(
      final AsyncValue<Map<String, Map<String, dynamic>>> seatsAsync,
      final String priceStr) {
    final seats = seatsAsync.value ?? {};
    final unitPrice = double.tryParse(priceStr) ?? 0.0;
    final mySelected = seats.entries
        .where((final e) =>
            e.value['customerId'] == widget.customerId &&
            e.value['status'] == 'reserved')
        .map((final e) => e.key)
        .toList();
    return _BottomPriceCard(
        selectedSeats: mySelected, totalPrice: mySelected.length * unitPrice);
  }

  PreferredSizeWidget _buildAppBar(final int seconds) => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GlassmorphismBackButton(),
        title: const Text("Koltuk Seçimi",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                  child: Text(
                      "${(seconds / 60).floor()}:${(seconds % 60).toString().padLeft(2, '0')}",
                      style: const TextStyle(
                          color: BentoColors.indigoLight, fontWeight: FontWeight.bold))))
        ],
      );

  Widget _buildStageHeader() => Column(children: [
        const SizedBox(height: 20),
        Container(
            width: 200,
            height: 3,
            decoration: BoxDecoration(color: BentoColors.indigoLight, boxShadow: [
              BoxShadow(color: BentoColors.indigoLight.withOpacity(0.5), blurRadius: 10)
            ])),
        const SizedBox(height: 8),
        const Text("S A H N E",
            style: TextStyle(
                color: Colors.white38,
                letterSpacing: 8,
                fontSize: 10,
                fontWeight: FontWeight.bold))
      ]);
}

// 🪑 KOLTUK DÜZENİ WIDGET'LARI (Öncekiyle Aynı - Hatasız)
class _SeatLayoutBuilder extends StatelessWidget {
  final Map<String, dynamic> allSeatsData;
  final Map<String, Map<String, dynamic>> liveStatus;
  final Set<String> processingSeats;
  final String customerId;
  final Function(String, String, bool) onSeatTap;

  const _SeatLayoutBuilder(
      {required this.allSeatsData,
      required this.liveStatus,
      required this.processingSeats,
      required this.customerId,
      required this.onSeatTap});

  @override
  Widget build(final BuildContext context) {
    final Map<String, List<String>> rows = {};
    allSeatsData.keys.forEach((final seatId) {
      final String rowLetter = seatId.replaceAll(RegExp(r'[0-9]'), '');
      if (!rows.containsKey(rowLetter)) rows[rowLetter] = [];
      rows[rowLetter]!.add(seatId);
    });

    final sortedRowKeys = rows.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: sortedRowKeys.map((final rowKey) {
            final List<String> seatsInThisRow = rows[rowKey]!;
            seatsInThisRow.sort((final a, final b) {
              final int aNum =
                  int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final int bNum =
                  int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              return aNum.compareTo(bNum);
            });

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                      width: 30,
                      child: Text(rowKey,
                          style: const TextStyle(
                              color: Colors.white24,
                              fontWeight: FontWeight.bold,
                              fontSize: 16))),
                  ...seatsInThisRow.map((final seatId) {
                    final statusData =
                        liveStatus[seatId] ?? allSeatsData[seatId] ?? {};
                    final String status = statusData['status'] ?? 'available';
                    final String? ownerId = statusData['customerId'];
                    return _SeatItem(
                      seatId: seatId,
                      status: status,
                      isMine: ownerId == customerId,
                      isProcessing: processingSeats.contains(seatId),
                      onTap: () =>
                          onSeatTap(seatId, status, ownerId == customerId),
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

class _SeatItem extends StatelessWidget {
  final String seatId;
  final String status;
  final bool isMine;
  final bool isProcessing;
  final VoidCallback onTap;

  const _SeatItem(
      {required this.seatId,
      required this.status,
      required this.isMine,
      required this.isProcessing,
      required this.onTap});

  @override
  Widget build(final BuildContext context) {
    Color color = Colors.white.withOpacity(0.1);
    if (status == 'sold')
      color = Colors.white10;
    else if (status == 'reserved')
      color = isMine ? Colors.blueAccent : Colors.purple;
    else if (status == 'available') color = Colors.green.withOpacity(0.5);
    final seatNum = seatId.replaceAll(RegExp(r'[^0-9]'), '');

    return GestureDetector(
      onTap: isProcessing || status == 'sold' ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isMine ? Colors.white : Colors.transparent, width: 1.5)),
        child: Center(
            child: isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(seatNum,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold))),
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend({super.key});

  @override
  Widget build(final BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _item(Colors.green.withOpacity(0.5), "Boş"),
        _item(Colors.blueAccent, "Sizin"),
        _item(Colors.purple, "Dolu"),
        _item(Colors.white10, "Satılmış")
      ]));

  Widget _item(final Color c, final String t) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(t, style: const TextStyle(fontSize: 11, color: Colors.white60))
      ]));
}

class _BottomPriceCard extends StatelessWidget {
  final List<String> selectedSeats;
  final double totalPrice;

  const _BottomPriceCard(
      {required this.selectedSeats, required this.totalPrice});

  @override
  Widget build(final BuildContext context) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10)),
      child: Row(children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              const Text("SEÇİLENLER",
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
                  overflow: TextOverflow.ellipsis)
            ])),
        Text("${totalPrice.toStringAsFixed(2)} TL",
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.greenAccent))
      ]));
}
