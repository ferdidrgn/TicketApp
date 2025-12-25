import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// 1. CUSTOM LOADING DIALOG (Sessizce Sahne Hazırlanıyor)
// ============================================================
class CustomLoadingDialog extends StatefulWidget {
  final String message;

  const CustomLoadingDialog({super.key, required this.message});

  @override
  State<CustomLoadingDialog> createState() => _CustomLoadingDialogState();
}

class _CustomLoadingDialogState extends State<CustomLoadingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    HapticFeedback.lightImpact(); // Sahne hazırlığı başlıyor (Hafif tık)
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => PopScope(
        canPop: false, // Kullanıcı geri tuşuyla loading'i kapatamasın
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  // Daha sanatsal kavis
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(strokeWidth: 3),
                    const SizedBox(height: 20),
                    Text(widget.message, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// ============================================================
// 2. CUSTOM SUCCESS DIALOG (Büyük Alkış / Başarı)
// ============================================================
class CustomSuccessDialog extends StatefulWidget {
  final String message;
  final VoidCallback? onConfirm; // Opsiyonel yaptık, hata vermez

  const CustomSuccessDialog({super.key, required this.message, this.onConfirm});

  @override
  State<CustomSuccessDialog> createState() => _CustomSuccessDialogState();
}

class _CustomSuccessDialogState extends State<CustomSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  void _handleConfirm() {
    HapticFeedback.mediumImpact(); // Başarı hissi (Net vuruş)
    _controller.reverse().then((final _) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onConfirm?.call(); // Varsa çalıştırır, yoksa hata vermez
      }
    });
  }

  @override
  Widget build(final BuildContext context) => PopScope(
        onPopInvokedWithResult: (final didPop, final result) {
          if (!didPop) _handleConfirm();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.green.shade100, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 70),
                  const SizedBox(height: 16),
                  const Text("BAŞARILI",
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text(widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                    ),
                    child: const Text("TAMAM",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// ============================================================
// 3. CUSTOM ERROR DIALOG (Hatalı Perde / Uyarı)
// ============================================================
class CustomErrorDialog extends StatefulWidget {
  final String message;
  final VoidCallback? onConfirm;

  const CustomErrorDialog({super.key, required this.message, this.onConfirm});

  @override
  State<CustomErrorDialog> createState() => _CustomErrorDialogState();
}

class _CustomErrorDialogState extends State<CustomErrorDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  void _handleErrorClose() {
    HapticFeedback.heavyImpact(); // Hata uyarısı (Güçlü vuruş)
    _controller.reverse().then((final _) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onConfirm?.call();
      }
    });
  }

  @override
  Widget build(final BuildContext context) => PopScope(
        onPopInvokedWithResult: (final didPop, final result) {
          if (!didPop) _handleErrorClose();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.red.shade100, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.red, size: 70),
                  const SizedBox(height: 16),
                  const Text("HATA!",
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 2,
                          color: Colors.red)),
                  const SizedBox(height: 8),
                  Text(widget.message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handleErrorClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("TEKRAR DENE"),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
