import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String? id;
  final String? createdAt, updatedAt;
  final String? customerId;
  final String? showId, stageId, eventId;
  final String? orderPrice, orderMethod;
  final List<String>? buySeats;
  final bool? isPast;
  final String? showName, showImageUrl, stageName, eventDate;
  final String? paymentStatus, usedAt, cancelledAt;

  const TicketModel({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.customerId,
    this.showId,
    this.stageId,
    this.eventId,
    this.orderMethod,
    this.orderPrice,
    this.buySeats,
    this.isPast,
    this.showName,
    this.showImageUrl,
    this.stageName,
    this.eventDate,
    this.paymentStatus,
    this.usedAt,
    this.cancelledAt,
  });

  /// Zaman damgası -> ISO metin. Timestamp UTC'ye çevrilir (saat dilimi
  /// kaybolmasın; "Alış" saati Europe/Istanbul'a buradan çevrilir). Sunucunun
  /// `toISOString()` metni, sayı (ms) ve `{seconds}` biçimi de okunur.
  static String? _ts(final Object? v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate().toUtc().toIso8601String();
    if (v is DateTime) return v.toUtc().toIso8601String();
    if (v is num) {
      return DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true)
          .toIso8601String();
    }
    if (v is Map && v['seconds'] is num) {
      return DateTime.fromMillisecondsSinceEpoch(
              ((v['seconds'] as num) * 1000).toInt(),
              isUtc: true)
          .toIso8601String();
    }
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  /// Tür-dayanıklı metin: sunucu/eski istemci sayı ya da metin yazmış olabilir.
  static String? _s(final Object? v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    return null;
  }

  static bool? _b(final Object? v) {
    if (v is bool) return v;
    if (v is String) return v == 'true' ? true : (v == 'false' ? false : null);
    return null;
  }

  /// Seans tarihi: uygulamanın metin biçimi ("15.11.2026,22:00") aynen kalır;
  /// elle Timestamp girilmişse yerel ISO metne çevrilir.
  static String? _eventDate(final Object? v) =>
      v is Timestamp ? v.toDate().toIso8601String() : _s(v);

  /// Firestore'dan güvenli okuma. HİÇBİR alan türü istisna fırlatmaz:
  /// sunucu (Admin SDK) ve eski istemci belgeleri farklı tür yazmış olabilir.
  factory TicketModel.fromFirestore(final Map<String, dynamic> data) =>
      TicketModel(
        id: _s(data['_id']),
        createdAt: _ts(data['_createdAt']) ?? _ts(data['createdAt']),
        updatedAt: _ts(data['_updatedAt']) ?? _ts(data['updatedAt']),
        customerId: _s(data['customerId']),
        showId: _s(data['showId']),
        stageId: _s(data['stageId']),
        eventId: _s(data['eventId']),
        orderMethod: _s(data['orderMethod']),
        orderPrice: _s(data['orderPrice']),
        buySeats: data['buySeats'] is List
            ? (data['buySeats'] as List).map((e) => e.toString()).toList()
            : null,
        isPast: _b(data['isPast']),
        showName: _s(data['showName']),
        showImageUrl: _s(data['showImageUrl']),
        stageName: _s(data['stageName']),
        eventDate: _eventDate(data['eventDate']),
        paymentStatus: _s(data['paymentStatus']),
        usedAt: _ts(data['usedAt']),
        cancelledAt: _ts(data['cancelledAt']),
      );
}
