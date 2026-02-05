import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

/// 🔍 Professional SEO Service
///
/// FEATURES:
/// - Basic meta tags (title, description)
/// - Open Graph tags (Facebook, LinkedIn, WhatsApp)
/// - Twitter Cards
/// - Canonical URL
/// - Structured data (JSON-LD)
///
/// Web dışında otomatik devre dışı kalır
final class SeoService {
  const SeoService._();

  /// 🎯 Temel SEO Güncelleme
  static void set({
    required final String title,
    final String? description,
    final String? imageUrl,
    final String? canonicalUrl,
    final String? author,
    final String? keywords,
    final SeoType type = SeoType.website,
  }) {
    if (!kIsWeb) return;

    try {
      // 1. Sayfa Başlığı
      html.document.title = title;

      // 2. Meta Description
      if (description != null)
        _updateMetaTag('name', 'description', description);

      // 3. Keywords
      if (keywords != null) _updateMetaTag('name', 'keywords', keywords);

      // 4. Author
      if (author != null) _updateMetaTag('name', 'author', author);

      // 5. Open Graph Tags (Facebook, WhatsApp, LinkedIn)
      _updateMetaTag('property', 'og:title', title);
      if (description != null)
        _updateMetaTag('property', 'og:description', description);

      if (imageUrl != null) {
        _updateMetaTag('property', 'og:image', imageUrl);
        _updateMetaTag('property', 'og:image:alt', title);
      }
      if (canonicalUrl != null)
        _updateMetaTag('property', 'og:url', canonicalUrl);

      _updateMetaTag('property', 'og:type', type.value);
      _updateMetaTag('property', 'og:site_name', 'TiyatRol');
      _updateMetaTag('property', 'og:locale', 'tr_TR');

      // 6. Twitter Cards
      _updateMetaTag('name', 'twitter:card', 'summary_large_image');
      _updateMetaTag('name', 'twitter:title', title);
      if (description != null)
        _updateMetaTag('name', 'twitter:description', description);

      if (imageUrl != null) _updateMetaTag('name', 'twitter:image', imageUrl);

      _updateMetaTag('name', 'twitter:site', '@tiyatrol');

      // 7. Canonical URL
      if (canonicalUrl != null) _updateCanonicalLink(canonicalUrl);

      if (kDebugMode) print('✅ SEO updated: $title');
    } catch (e) {
      if (kDebugMode) print('⚠️ SEO update error: $e');
    }
  }

  /// 🎭 Show/Event için özel SEO
  static void setForShow({
    required final String title,
    required final String description,
    required final String imageUrl,
    required final String url,
    final DateTime? eventDate,
    final String? location,
    final String? price,
  }) {
    set(
      title: 'TiyatRol - $title',
      description: description,
      imageUrl: imageUrl,
      canonicalUrl: url,
      type: SeoType.article,
    );

    // Structured Data (JSON-LD) for Google rich snippets
    if (eventDate != null) {
      _addStructuredData({
        '@context': 'https://schema.org',
        '@type': 'Event',
        'name': title,
        'description': description,
        'image': imageUrl,
        'url': url,
        'startDate': eventDate.toIso8601String(),
        if (location != null)
          'location': {
            '@type': 'Place',
            'name': location,
          },
        if (price != null)
          'offers': {
            '@type': 'Offer',
            'price': price,
            'priceCurrency': 'TRY',
          },
      });
    }
  }

  /// 👤 Player/Actor için özel SEO
  static void setForPlayer({
    required final String name,
    required final String bio,
    required final String imageUrl,
    required final String url,
  }) {
    set(
      title: 'TiyatRol - $name',
      description: bio,
      imageUrl: imageUrl,
      canonicalUrl: url,
      type: SeoType.profile,
    );

    // Structured Data for Person
    _addStructuredData({
      '@context': 'https://schema.org',
      '@type': 'Person',
      'name': name,
      'description': bio,
      'image': imageUrl,
      'url': url,
    });
  }

  /// 🏟️ Stage/Venue için özel SEO
  static void setForStage({
    required final String name,
    required final String description,
    required final String imageUrl,
    required final String url,
    final String? address,
  }) {
    set(
      title: 'TiyatRol - $name',
      description: description,
      imageUrl: imageUrl,
      canonicalUrl: url,
      type: SeoType.website,
    );

    // Structured Data for Place
    _addStructuredData({
      '@context': 'https://schema.org',
      '@type': 'Place',
      'name': name,
      'description': description,
      'image': imageUrl,
      'url': url,
      if (address != null) 'address': address,
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Meta tag oluştur veya güncelle
  static void _updateMetaTag(
    final String attribute,
    final String attributeValue,
    final String content,
  ) {
    if (!kIsWeb) return;

    final selector = 'meta[$attribute="$attributeValue"]';
    html.MetaElement? meta =
        html.document.querySelector(selector) as html.MetaElement?;

    if (meta == null) {
      // Yoksa oluştur
      meta = html.MetaElement();
      meta.setAttribute(attribute, attributeValue);
      html.document.head?.append(meta);
    }

    // İçeriği güncelle
    meta.content = content;
  }

  /// Canonical link güncelle
  static void _updateCanonicalLink(final String url) {
    if (!kIsWeb) return;

    final selector = 'link[rel="canonical"]';
    html.LinkElement? link =
        html.document.querySelector(selector) as html.LinkElement?;

    if (link == null) {
      link = html.LinkElement();
      link.rel = 'canonical';
      html.document.head?.append(link);
    }

    link.href = url;
  }

  /// Structured Data (JSON-LD) ekle
  static void _addStructuredData(final Map<String, dynamic> data) {
    if (!kIsWeb) return;

    try {
      // Eski script'i kaldır
      final oldScript =
          html.document.querySelector('script[type="application/ld+json"]');
      oldScript?.remove();

      // Yeni script ekle
      final script = html.ScriptElement()
        ..type = 'application/ld+json'
        ..text = _jsonEncode(data);

      html.document.head?.append(script);
    } catch (e) {
      if (kDebugMode) print('⚠️ Structured data error: $e');
    }
  }

  /// Basit JSON encoder (dart:convert kullanmadan)
  static String _jsonEncode(final Map<String, dynamic> map) {
    final buffer = StringBuffer('{');
    var first = true;

    map.forEach((final key, final value) {
      if (!first) buffer.write(',');
      first = false;

      buffer.write('"$key":');

      if (value is String)
        buffer.write('"${_escapeJson(value)}"');
      else if (value is Map)
        buffer.write(_jsonEncode(value as Map<String, dynamic>));
      else
        buffer.write(value.toString());
    });

    buffer.write('}');
    return buffer.toString();
  }

  /// JSON string escape
  static String _escapeJson(final String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// Tüm SEO meta tag'lerini temizle (örn. logout'ta)
  static void clear() {
    if (!kIsWeb) return;

    html.document.title = 'TiyatRol';

    // Tüm meta tag'leri kaldır
    final metas = html.document
        .querySelectorAll('meta[property^="og:"], meta[name^="twitter:"]');
    for (final meta in metas) meta.remove();
  }
}

/// SEO Content Type
enum SeoType {
  website('website'),
  article('article'),
  profile('profile'),
  video('video.other');

  const SeoType(this.value);

  final String value;
}
