import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web: `.ics` içeriğini dosya olarak indirtir (Apple Takvim, iCloud, Outlook
/// masaüstü ve diğer takvim uygulamaları bu dosyayı açar).
Future<bool> downloadIcs(final String filename, final String content) async {
  try {
    final web.Blob blob = web.Blob(
      <JSAny>[content.toJS].toJS,
      web.BlobPropertyBag(type: 'text/calendar;charset=utf-8'),
    );
    final String url = web.URL.createObjectURL(blob);
    final web.HTMLAnchorElement a = web.HTMLAnchorElement()
      ..href = url
      ..download = filename;
    a.click();
    web.URL.revokeObjectURL(url);
    return true;
  } catch (_) {
    return false;
  }
}
