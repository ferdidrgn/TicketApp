import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'geo_guard.dart';

class GeoHit {
  final double lat;
  final double lng;
  final String label;
  const GeoHit(this.lat, this.lng, this.label);
}

/// ÜCRETSİZ adres → koordinat: OpenStreetMap Nominatim.
///
/// - API anahtarı/ödeme yok. Kullanım politikası: saniyede en çok 1 istek,
///   toplu sorgu yok, sonuçlar saklanmalı. Burada SADECE yönetici formdaki
///   "Adresten konum bul" düğmesine bastığında TEK istek gider; sonuç
///   Firestore'a yazılır (bir daha sorgulanmaz).
/// - Sadece Türkiye (`countrycodes=tr`) ve yalnızca `GeoGuard` kutusundaki
///   sonuçlar döner.
abstract final class NominatimGeocoder {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: kIsWeb ? null : {'User-Agent': 'TiyatRol-Admin/1.0'},
  ));

  static Future<List<GeoHit>> search(final String query) async {
    final String q = query.trim();
    if (q.length < 4) return const [];
    final Response<dynamic> res = await _dio.get<dynamic>(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'q': q,
        'format': 'jsonv2',
        'limit': 5,
        'countrycodes': 'tr',
        'accept-language': 'tr',
      },
    );
    final dynamic data = res.data;
    if (data is! List) return const [];
    final List<GeoHit> hits = [];
    for (final dynamic item in data) {
      if (item is! Map) continue;
      final double? lat = double.tryParse('${item['lat']}');
      final double? lng = double.tryParse('${item['lon']}');
      if (lat == null || lng == null || !GeoGuard.inTurkey(lat, lng)) continue;
      hits.add(GeoHit(lat, lng, '${item['display_name'] ?? ''}'));
    }
    return hits;
  }
}
