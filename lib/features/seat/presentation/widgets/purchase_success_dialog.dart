import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../tickets/presentation/pages/ticket_details_modal.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';

/// Satın alma sonrası gösterilen ekran. Eski davranış sadece bir onay
/// mesajı + "Anasayfa"/"Biletlerim" butonu gösteriyordu; bu artık
/// kullanıcıyı doğrudan biletinin QR kodunu (mevcut TicketDetailsModal)
/// görmeye yönlendiren bir aksiyon da sunuyor, ki bilet gerçekten "elinde"
/// hissettirsin.
class PurchaseSuccessDialog extends StatefulWidget {
  final DetailedTicket? ticket;
  final String customerId;
  final int seatCount;
  final double totalPrice;

  const PurchaseSuccessDialog({
    super.key,
    required this.ticket,
    required this.customerId,
    required this.seatCount,
    required this.totalPrice,
  });

  @override
  State<PurchaseSuccessDialog> createState() => _PurchaseSuccessDialogState();
}

class _PurchaseSuccessDialogState extends State<PurchaseSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showTicket(final BuildContext context) {
    final ticket = widget.ticket;
    if (ticket == null) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (final _) => TicketDetailsModal(ticket: ticket),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Colors.greenAccent, size: 56),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Biletin Hazır! 🎉',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.seatCount} koltuk • ${widget.totalPrice.toStringAsFixed(2)} TL\n'
                'Ödeme onaylandı, sahne seni bekliyor.',
                style: const TextStyle(
                    color: Colors.white60, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              if (widget.ticket != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showTicket(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.qr_code_rounded, color: Colors.black),
                    label: const Text('BİLETİ GÖR (QR)',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => NavigationHandler.goToHome(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('ANA SAYFA',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => NavigationHandler.goToMyTickets(
                          context, widget.customerId),
                      child: const Text('TÜM BİLETLERİM',
                          style: TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
