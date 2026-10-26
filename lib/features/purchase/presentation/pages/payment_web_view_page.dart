import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/purchase_entities.dart';
import '../providers/seat_purchase_controller.dart';

/// Ödeme sayfasından dönüş: iyzico → `iyzicoCallback` → `SITE_URL/odeme-sonuc`.
/// Bu yönlendirme WebView içinde YAKALANIR (sayfa yüklenmeden); karar
/// `durum` parametresine değil `Order` belgesine göre verilir.
class PaymentReturn {
  final String? orderId;
  final String? status; // basarili | hata (yalnızca ipucu)

  const PaymentReturn({this.orderId, this.status});
}

/// Bir adres ödeme dönüş sayfası mı? (https + bilinen site alanı +
/// `/odeme-sonuc`.) Test edilebilsin diye üst düzey ve saf.
PaymentReturn? parsePaymentReturn(final Uri uri) {
  if (uri.scheme != 'https') {
    return null;
  }
  if (!_trustedHosts.contains(uri.host)) {
    return null;
  }
  if (uri.path != kPurchaseResultPath &&
      uri.path != '$kPurchaseResultPath/') {
    return null;
  }
  return PaymentReturn(
      orderId: uri.queryParameters['order'],
      status: uri.queryParameters['durum']);
}

const Set<String> _trustedHosts = {
  'tiyatrol-web.web.app',
  'tiyatrol-web.firebaseapp.com',
  'tiyatrol.web.app',
  'tiyatrol.firebaseapp.com',
  'tiyatroekip.web.app',
  'tiyatroekip.firebaseapp.com',
};

/// Uygulama içi güvenli ödeme sayfası (yalnızca mobil; web'de
/// `url_launcher` kullanılır).
class PaymentWebViewPage extends StatefulWidget {
  final PaymentSession session;

  const PaymentWebViewPage({super.key, required this.session});

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _done = false;

  void _finish(final PaymentReturn r) {
    if (_done || !mounted) {
      return;
    }
    _done = true;
    Navigator.of(context).pop(r);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (final p) {
          if (mounted) {
            setState(() => _progress = p);
          }
        },
        onNavigationRequest: (final req) {
          final uri = Uri.tryParse(req.url);
          if (uri == null) {
            return NavigationDecision.prevent;
          }
          final ret = parsePaymentReturn(uri);
          if (ret != null) {
            _finish(ret);
            return NavigationDecision.prevent;
          }
          // Yalnızca web adresleri; intent:/market:/file: vb. engellenir.
          if (uri.scheme != 'https' &&
              uri.scheme != 'http' &&
              uri.scheme != 'about' &&
              uri.scheme != 'data') {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onUrlChange: (final change) {
          final uri = Uri.tryParse(change.url ?? '');
          final ret = uri == null ? null : parsePaymentReturn(uri);
          if (ret != null) {
            _finish(ret);
          }
        },
      ));
    final s = widget.session;
    if (s.paymentPageUrl != null) {
      _controller.loadRequest(Uri.parse(s.paymentPageUrl!));
    } else if (s.checkoutFormContent != null) {
      _controller.loadHtmlString(s.checkoutFormContent!);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: 'Ödemeden çık',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: cs.primary),
              const SizedBox(width: AppSpacing.xs + 2),
              const Text('Güvenli ödeme'),
            ],
          ),
          bottom: _progress > 0 && _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                      value: _progress / 100, minHeight: 2),
                )
              : null,
        ),
        body: SafeArea(child: WebViewWidget(controller: _controller)),
      ),
    );
  }
}
