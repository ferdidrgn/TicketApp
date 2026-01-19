import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

/// 🔍 Global SEO Service
/// Web dışında otomatik devre dışı kalır
final class SeoService {
  const SeoService._();

  static void set({
    required final String title,
    final String? description,
  }) {
    if (!kIsWeb) return;

    html.document.title = title;

    if (description == null) return;

    final meta = html.document.querySelector('meta[name="description"]');

    if (meta != null)
      meta.setAttribute('content', description);
    else {
      final newMeta = html.MetaElement()
        ..name = 'description'
        ..content = description;

      html.document.head?.append(newMeta);
    }
  }
}
