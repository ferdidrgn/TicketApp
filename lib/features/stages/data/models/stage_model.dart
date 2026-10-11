import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `Stage` dökümanı — backend alan adları birebir.
///
/// Koordinatlar `lat` / `long` ve **string** (ör. `"41.0082"`). Eski
/// `locationLat`/`locationLng` (num) yazımları okurken yedek; yazarken
/// yalnızca `lat`/`long` gider.
class StageModel {
  final String? createdAt, updatedAt;
  final String? id;
  final String? name;
  final String? imageUrl;
  final String? capacity;
  final String? description;
  final String? communication;
  final String? address;
  /// Firestore `lat` — string.
  final String? lat;
  /// Firestore `long` — string.
  final String? long;
  final List<String>? showsId;

  const StageModel({
    this.id,
    this.name,
    this.imageUrl,
    this.capacity,
    this.description,
    this.communication,
    this.address,
    this.lat,
    this.long,
    this.createdAt,
    this.updatedAt,
    this.showsId,
  });

  /// Domain / harita için sayısal enlem.
  double get locationLat => _parseCoord(lat);

  /// Domain / harita için sayısal boylam.
  double get locationLng => _parseCoord(long);

  static double _parseCoord(final String? raw) {
    if (raw == null) return 0;
    final String t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return 0;
    return double.tryParse(t) ?? 0;
  }

  /// Firestore'dan string | num | eski alan adlarını okur.
  static String? _coordFrom(
    final Map<String, dynamic> data, {
    required final String primary,
    required final String legacy,
  }) {
    final dynamic v = data[primary] ?? data[legacy];
    if (v == null) return null;
    if (v is String) return v;
    if (v is num) return v.toString();
    return v.toString();
  }

  factory StageModel.fromFirestore(final Map<String, dynamic> data) =>
      StageModel(
        id: data['_id'] as String?,
        name: data['name'] as String?,
        imageUrl: data['imageUrl'] as String?,
        capacity: data['capacity'] as String?,
        description: data['description'] as String?,
        communication: data['communication'] as String?,
        address: data['address'] as String?,
        lat: _coordFrom(data, primary: 'lat', legacy: 'locationLat'),
        long: _coordFrom(data, primary: 'long', legacy: 'locationLng'),
        createdAt: data['_createdAt'] is Timestamp
            ? (data['_createdAt'] as Timestamp).toDate().toIso8601String()
            : data['_createdAt']?.toString(),
        updatedAt: data['_updatedAt'] is Timestamp
            ? (data['_updatedAt'] as Timestamp).toDate().toIso8601String()
            : data['_updatedAt']?.toString(),
        showsId: (data['showsId'] as List?)?.map((e) => e.toString()).toList(),
      );

  Map<String, dynamic> toFirestore() => {
        '_id': id,
        'name': name,
        'imageUrl': imageUrl,
        'capacity': capacity,
        'description': description,
        'communication': communication,
        'address': address,
        'lat': lat ?? '',
        'long': long ?? '',
        'showsId': showsId ?? <String>[],
      };
}
