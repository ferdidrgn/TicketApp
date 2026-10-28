import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';

/// Bir oyuna bırakılan yorum + puan. Belge kimliği `${userId}_${showId}` —
/// bir kullanıcı bir oyuna TEK yorum bırakır (düzenleyebilir/silebilir).
class Review extends Equatable {
  final String id;
  final String showId;
  final String userId;
  final String userName; // "Ayşe K."
  final String userImage;
  final int rating; // 1..5
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool hidden;
  final bool verified; // sunucu: bileti olan, telefonu dogrulanmis izleyici
  final String status; // published | pending | hidden

  const Review({
    required this.id,
    required this.showId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.rating,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.hidden,
    this.verified = false,
    this.status = 'published',
  });

  static String docId(final String userId, final String showId) =>
      '${userId}_$showId';

  factory Review.fromDoc(final String id, final Map<String, dynamic> d) {
    DateTime? ts(final dynamic v) => v is Timestamp
        ? v.toDate()
        : (v is String ? DateTime.tryParse(v) : null);
    final dynamic r = d['rating'];
    return Review(
      id: id,
      showId: (d['showId'] ?? '').toString(),
      userId: (d['userId'] ?? '').toString(),
      userName: (d['userName'] ?? '').toString(),
      userImage: (d['userImage'] ?? '').toString(),
      rating: r is num ? r.toInt().clamp(1, 5) : 1,
      text: (d['text'] ?? '').toString(),
      createdAt: ts(d['createdAt']),
      updatedAt: ts(d['updatedAt']),
      hidden: d['hidden'] == true,
      verified: d['verified'] == true,
      status: (d['status'] ?? (d['hidden'] == true ? 'hidden' : 'published')).toString(),
    );
  }

  @override
  List<Object?> get props =>
      [id, showId, userId, rating, text, updatedAt, hidden, verified, status];
}

/// Bir oyunun özet puanı.
class ReviewStat {
  final double average;
  final int count;
  final List<int> distribution; // [1★..5★]
  const ReviewStat(this.average, this.count, this.distribution);

  static const ReviewStat empty = ReviewStat(0, 0, [0, 0, 0, 0, 0]);

  static Map<String, ReviewStat> fromReviews(final Iterable<Review> reviews) {
    final Map<String, List<int>> by = {};
    for (final Review r in reviews) {
      if (r.hidden) continue;
      final List<int> dist = by.putIfAbsent(r.showId, () => [0, 0, 0, 0, 0]);
      dist[r.rating - 1]++;
    }
    return {
      for (final e in by.entries)
        e.key: () {
          final int n = e.value.fold(0, (a, b) => a + b);
          int sum = 0;
          for (int i = 0; i < 5; i++) {
            sum += e.value[i] * (i + 1);
          }
          return ReviewStat(n == 0 ? 0 : sum / n, n, e.value);
        }(),
    };
  }
}

/// Sunucu hatasi: [code] (ornek NOT_VERIFIED_ATTENDEE, PHONE_REQUIRED, REVIEW_LOCKED) + kullaniciya gosterilebilir mesaj.
class ReviewException implements Exception {
  final String code;
  final String message;
  const ReviewException(this.code, this.message);
  @override
  String toString() => message;
}

/// canReview sonucu.
class ReviewEligibility {
  final bool canReview;
  final String? code;
  final bool hasExisting;
  const ReviewEligibility(this.canReview, this.code, this.hasExisting);

  /// Hak yoksa kullaniciya gosterilecek aciklama.
  String get reason {
    switch (code) {
      case 'PHONE_REQUIRED':
        return 'Yorum yazabilmek için telefon numaranı doğrulaman gerekir.';
      case 'ACCOUNT_DELETION_PENDING':
        return 'Hesabın silinme sürecinde olduğu için yorum yazamazsın.';
      default:
        return 'Yorum yazabilmek için bu oyunu izlemiş olman gerekir.';
    }
  }
}

/// Firestore (okuma) + Cloud Functions (yazma/sikayet/engel) erisimi.
/// Review'a istemci YAZAMAZ (firestore.rules); tum yazimlar sunucu callable'laridir.
class ReviewRepository {
  final FirebaseFirestore _db;
  final FirebaseFunctions? _fnOverride;
  ReviewRepository([final FirebaseFirestore? db, final FirebaseFunctions? fn])
      : _db = db ?? FirebaseFirestore.instance,
        _fnOverride = fn;

  FirebaseFunctions get _fn =>
      _fnOverride ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('Review');

  Future<Map<String, dynamic>> _call(final String name, final Map<String, dynamic> data) async {
    try {
      final r = await _fn.httpsCallable(name).call<dynamic>(data);
      final d = r.data;
      return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      final det = e.details;
      final String code = det is Map && det['code'] is String ? det['code'] as String : e.code;
      throw ReviewException(code, mapErrorMessage(e.code, code, e.message));
    }
  }

  /// Sunucu hata kodunu kullanici mesajina cevirir (test edilebilir).
  static String mapErrorMessage(final String grpcCode, final String code, final String? serverMessage) {
    switch (code) {
      case 'NOT_VERIFIED_ATTENDEE':
        return 'Yorum yazabilmek için bu oyunu izlemiş olman gerekir.';
      case 'PHONE_REQUIRED':
        return 'Yorum için telefon numaranı doğrulamalısın.';
      case 'ACCOUNT_DELETION_PENDING':
        return 'Hesabın silinme sürecinde olduğu için bu işlem yapılamıyor.';
      case 'REVIEW_LOCKED':
        return 'Bu yorum moderasyon incelemesinde; şu an değiştirilemez.';
    }
    if (grpcCode == 'resource-exhausted') return 'Çok sık işlem yaptın. Biraz sonra tekrar dene.';
    if (grpcCode == 'invalid-argument' && serverMessage != null && serverMessage.isNotEmpty) return serverMessage;
    return 'İşlem tamamlanamadı. Bağlantını kontrol edip tekrar dene.';
  }

  /// Gorunur (hidden==false) yorumlar; [uid] verilirse kullanicinin kendi (gizli/bekleyen olsa da) yorumu da eklenir.
  Future<List<Review>> byShow(final String showId, {final String? uid}) async {
    final snap = await _col
        .where('showId', isEqualTo: showId)
        .where('hidden', isEqualTo: false)
        .get();
    final list = [for (final d in snap.docs) Review.fromDoc(d.id, d.data())];
    if (uid != null && uid.isNotEmpty && !list.any((final r) => r.userId == uid)) {
      try {
        final mine = await _col.doc(Review.docId(uid, showId)).get();
        if (mine.exists) list.add(Review.fromDoc(mine.id, mine.data()!));
      } catch (_) {/* okunamazsa yok say */}
    }
    list.sort((a, b) => (b.createdAt ?? DateTime(2000))
        .compareTo(a.createdAt ?? DateTime(2000)));
    return list;
  }

  Future<List<Review>> byUser(final String userId) async {
    final snap = await _col.where('userId', isEqualTo: userId).get();
    return [for (final d in snap.docs) Review.fromDoc(d.id, d.data())];
  }

  /// Tum gorunur yorumlar - kart puanlari ve "en cok begenilenler".
  Future<List<Review>> recent({final int limit = 600}) async {
    final snap = await _col.where('hidden', isEqualTo: false).limit(limit).get();
    return [for (final d in snap.docs) Review.fromDoc(d.id, d.data())];
  }

  /// Yorum hakki (telefon + gecmis bilet) - sunucu karar verir.
  Future<ReviewEligibility> canReview(final String showId) async {
    final r = await _call('canReview', {'showId': showId});
    return ReviewEligibility(r['canReview'] == true, r['code'] as String?, r['existing'] != null);
  }

  /// Olustur/guncelle (sunucu: bilet, telefon, metin suzgeci, hiz siniri). Donus: yayinlandi mi (false = incelemede).
  Future<bool> submit({required final String showId, required final int rating, required final String text}) async {
    final r = await _call('submitReview', {'showId': showId, 'rating': rating.clamp(1, 5), 'text': text.trim()});
    return r['pending'] != true;
  }

  Future<void> deleteMine(final String showId) => _call('deleteMyReview', {'showId': showId});

  /// Yonetici (admin) gizleme; mobilde yalniz gizleme (geri acma web panelinden).
  Future<void> adminHide(final String reviewId) => _call('adminModerate', {
        'reviewId': reviewId,
        'action': 'hide',
        'reason': 'Uygulamadan yönetici gizlemesi',
      });

  /// Sikayet (sunucu: 3 farkli dogrulanmis kullanici -> otomatik gizleme).
  Future<void> report(final String reviewId, {final String reason = 'diger', final String detail = ''}) =>
      _call('reportContent', {'type': 'review', 'id': reviewId, 'reason': reason, 'detail': detail});

  Future<void> blockUser(final String uid) => _call('blockUser', {'uid': uid});
  Future<void> unblockUser(final String uid) => _call('unblockUser', {'uid': uid});

  /// Engellenen kullanici kimlikleri (User/{me}/blocks).
  Future<Set<String>> blockedIds(final String myUid) async {
    final snap = await _db.collection('User').doc(myUid).collection('blocks').get();
    return {for (final d in snap.docs) d.id};
  }
}
