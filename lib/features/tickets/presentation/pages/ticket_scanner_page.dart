import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/ticket_validation_service.dart';

/// 🎫 Kapıda bilet doğrulama ekranı — SADECE admin/curator rolündeki
/// hesaplar görebilir (bkz. Settings'teki giriş noktası + buradaki
/// ikinci savunma katmanı). Kamerayla bilet QR kodunu okutur, sunucu
/// tarafında (functions/tickets/index.js) doğrular; bir bilet en fazla
/// bir kez "geçerli" sayılır.
class TicketScannerPage extends ConsumerStatefulWidget {
  const TicketScannerPage({super.key});

  @override
  ConsumerState<TicketScannerPage> createState() => _TicketScannerPageState();
}

class _TicketScannerPageState extends ConsumerState<TicketScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  TicketValidationResult? _lastResult;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(final BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;
    final ticketId = capture.barcodes.first.rawValue;
    if (ticketId == null || ticketId.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _lastResult = null;
    });
    await _controller.stop();

    final result = await TicketValidationService.validate(ticketId);
    if (!mounted) return;
    setState(() => _lastResult = result);
  }

  Future<void> _scanAgain() async {
    setState(() {
      _lastResult = null;
      _isProcessing = false;
    });
    await _controller.start();
  }

  @override
  Widget build(final BuildContext context) {
    final isPrivileged = ref.watch(isUserPrivilegedProvider);

    if (!isPrivileged) {
      return Scaffold(
        backgroundColor: BentoColors.canvas,
        appBar: AppBar(
          backgroundColor: BentoColors.canvas,
          title: const Text('Bilet Kontrolü'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Bu ekrana erişim yetkin yok.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Bilet Kontrolü',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Tarama çerçevesi
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: BentoColors.indigoLight, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          if (_isProcessing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ResultSheet(
                result: _lastResult,
                onScanAgain: _scanAgain,
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  final TicketValidationResult? result;
  final VoidCallback onScanAgain;

  const _ResultSheet({required this.result, required this.onScanAgain});

  @override
  Widget build(final BuildContext context) {
    if (result == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        color: BentoColors.card,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: BentoColors.indigoLight)),
            SizedBox(width: 16),
            Text('Doğrulanıyor...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    final isValid = result!.status == TicketValidationStatus.valid;
    final color = isValid ? BentoColors.emerald : const Color(0xFFEF4444);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      decoration: BoxDecoration(
        color: BentoColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              isValid
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: color,
              size: 56),
          const SizedBox(height: 16),
          Text(
            isValid ? 'GEÇERLİ BİLET' : 'GİRİŞ REDDEDİLDİ',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            result!.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onScanAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: BentoColors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('TEKRAR TARA',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
