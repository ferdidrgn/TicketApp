import 'package:cloud_firestore/cloud_firestore.dart';
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
    );
  }

  @override
  List<Object?> get props =>
      [id, showId, userId, rating, text, updatedAt, hidden];
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

/// Firestore erişimi (yorumlar + şikâyetler).
class ReviewRepository {
  final FirebaseFirestore _db;
  ReviewRepository([final FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('Review');

  Future<List<Review>> byShow(final String showId) async {
    final snap = await _col.where('showId', isEqualTo: showId).get();
    final list = [for (final d in snap.docs) Review.fromDoc(d.id, d.data())];
    list.sort((a, b) => (b.createdAt ?? DateTime(2000))
        .compareTo(a.createdAt ?? DateTime(2000)));
    return list;
  }

  Future<List<Review>> byUser(final String userId) async {
    final snap = await _col.where('userId', isEqualTo: userId).get();
    return [for (final d in snap.docs) Review.fromDoc(d.id, d.data())];
  }

  /// Tüm (gizli olmayan) yorumlar — kart puanları ve "en çok beğenilenler".
  Future<List<Review>> recent({final int limit = 600}) async {
    final snap = await _col.limit(limit).get();
    return [
      for (final d in snap.docs)
        if (d.data()['hidden'] != true) Review.fromDoc(d.id, d.data()),
    ];
  }

  Future<void> upsert({
    required final String userId,
    required final String showId,
    required final String userName,
    required final String userImage,
    required final int rating,
    required final String text,
  }) async {
    final ref = _col.doc(Review.docId(userId, showId));
    final existing = await ref.get();
    final Map<String, dynamic> data = {
      'showId': showId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'rating': rating.clamp(1, 5),
      'text': text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!existing.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['hidden'] = false;
      await ref.set(data);
    } else {
      await ref.update(data);
    }
  }

  Future<void> delete(final String reviewId) => _col.doc(reviewId).delete();

  Future<void> setHidden(final String reviewId, final bool hidden) =>
      _col.doc(reviewId).update({'hidden': hidden});

  /// Şikâyet: kullanıcı başına yorum başına tek belge.
  Future<void> report(final String reviewId, final String userId) =>
      _db.collection('ReviewReport').doc('${reviewId}_$userId').set({
        'reviewId': reviewId,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
