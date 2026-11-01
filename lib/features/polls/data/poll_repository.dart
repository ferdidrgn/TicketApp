import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';

/// Anket seçeneği (sunucu `adminCreatePoll` kimlik üretir: o1..o6).
class PollOption extends Equatable {
  final String id;
  final String label;
  final String? showId;
  const PollOption({required this.id, required this.label, this.showId});

  @override
  List<Object?> get props => [id, label, showId];
}

/// F-5 anketi. `Poll` herkese okunur; istemci YAZAMAZ (firestore.rules) — oy yalnız `votePoll` callable'ı.
class Poll extends Equatable {
  final String id;
  final String question;
  final List<PollOption> options;
  final Map<String, int> counts;
  final int totalVotes;
  final String status; // active | closed
  final DateTime? startsAt;
  final DateTime? endsAt;

  const Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.counts,
    required this.totalVotes,
    required this.status,
    required this.startsAt,
    required this.endsAt,
  });

  factory Poll.fromDoc(final String id, final Map<String, dynamic> d) {
    DateTime? ts(final dynamic v) => v is Timestamp ? v.toDate() : null;
    final List<PollOption> opts = <PollOption>[
      for (final dynamic o in (d['options'] as List<dynamic>? ?? const <dynamic>[]))
        if (o is Map && o['id'] is String)
          PollOption(
            id: o['id'] as String,
            label: (o['label'] ?? '') as String,
            showId: o['showId'] is String ? o['showId'] as String : null,
          ),
    ];
    final Map<String, int> counts = <String, int>{
      if (d['counts'] is Map)
        for (final MapEntry<dynamic, dynamic> e in (d['counts'] as Map).entries)
          e.key.toString(): (e.value is num ? (e.value as num).toInt() : 0),
    };
    return Poll(
      id: id,
      question: (d['question'] ?? '') as String,
      options: opts,
      counts: counts,
      totalVotes: d['totalVotes'] is num ? (d['totalVotes'] as num).toInt() : 0,
      status: (d['status'] ?? 'closed') as String,
      startsAt: ts(d['startsAt']),
      endsAt: ts(d['endsAt']),
    );
  }

  /// Oy kabul ediyor mu (durum + tarih penceresi).
  bool isOpen([final DateTime? now]) {
    final DateTime t = now ?? DateTime.now();
    if (status != 'active') return false;
    if (startsAt != null && startsAt!.isAfter(t)) return false;
    if (endsAt != null && !t.isBefore(endsAt!)) return false;
    return true;
  }

  int countOf(final String optionId) => counts[optionId] ?? 0;

  /// Yüzde (0-100, yuvarlanmış); oy yoksa 0.
  int percentOf(final String optionId) =>
      totalVotes <= 0 ? 0 : ((countOf(optionId) / totalVotes) * 100).round();

  @override
  List<Object?> get props => [id, question, options, counts, totalVotes, status, startsAt, endsAt];
}

class PollException implements Exception {
  final String code;
  final String message;
  const PollException(this.code, this.message);
  @override
  String toString() => message;
}

class PollRepository {
  final FirebaseFirestore _db;
  final FirebaseFunctions? _fnOverride;
  PollRepository([final FirebaseFirestore? db, final FirebaseFunctions? fn])
      : _db = db ?? FirebaseFirestore.instance,
        _fnOverride = fn;

  FirebaseFunctions get _fn => _fnOverride ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Sunucu hata kodunu kullanıcı mesajına çevirir (test edilebilir).
  static String mapErrorMessage(final String grpcCode, final String code, final String? serverMessage) {
    if (code == 'PHONE_REQUIRED') return 'Oy vermek için telefon numaranı doğrulamalısın (Profil > Telefon).';
    if (code == 'ACCOUNT_DELETION_PENDING') return 'Hesabın silinme sürecinde olduğu için oy veremezsin.';
    if (grpcCode == 'unauthenticated') return 'Oy vermek için giriş yapmalısın.';
    if (grpcCode == 'resource-exhausted') return 'Çok sık işlem yaptın. Biraz sonra tekrar dene.';
    if (grpcCode == 'failed-precondition') return 'Bu anket şu an oy kabul etmiyor.';
    return 'Oy kaydedilemedi. Bağlantını kontrol edip tekrar dene.';
  }

  /// Şu an oy kabul eden en yeni anket; yoksa null. (status==active tek alan sorgusu: bileşik indeks gerekmez.)
  Future<Poll?> activePoll() async {
    final QuerySnapshot<Map<String, dynamic>> s =
        await _db.collection('Poll').where('status', isEqualTo: 'active').limit(10).get();
    final List<Poll> l = <Poll>[
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in s.docs) Poll.fromDoc(d.id, d.data()),
    ].where((final Poll p) => p.isOpen()).toList()
      ..sort((final Poll a, final Poll b) =>
          (b.startsAt ?? DateTime(0)).compareTo(a.startsAt ?? DateTime(0)));
    return l.isEmpty ? null : l.first;
  }

  Future<Poll?> byId(final String id) async {
    final DocumentSnapshot<Map<String, dynamic>> s = await _db.collection('Poll').doc(id).get();
    final Map<String, dynamic>? d = s.data();
    return d == null ? null : Poll.fromDoc(s.id, d);
  }

  /// Kullanıcının bu anketteki oyu (kendi `votes/{uid}` belgesi; kuralı sahibine açar).
  Future<String?> myVote(final String pollId, final String uid) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> s =
          await _db.collection('Poll').doc(pollId).collection('votes').doc(uid).get();
      final dynamic v = s.data()?['optionId'];
      return v is String ? v : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> vote(final String pollId, final String optionId) async {
    try {
      await _fn.httpsCallable('votePoll').call<dynamic>(<String, dynamic>{'pollId': pollId, 'optionId': optionId});
    } on FirebaseFunctionsException catch (e) {
      final dynamic det = e.details;
      final String code = det is Map && det['code'] is String ? det['code'] as String : e.code;
      throw PollException(code, mapErrorMessage(e.code, code, e.message));
    }
  }
}

/// F-6 "Birlikte gidelim" planı: sunucu `createPlan` rastgele kimlikli plan üretir; bağlantıyı biz kurarız.
class PlanRepository {
  static const String baseUrl = 'https://tiyatrol.web.app';
  final FirebaseFunctions? _fnOverride;
  PlanRepository([final FirebaseFunctions? fn]) : _fnOverride = fn;

  FirebaseFunctions get _fn => _fnOverride ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  static String planUrl(final String planId) => '$baseUrl/plan/$planId';

  static String mapErrorMessage(final String grpcCode, final String? serverMessage) {
    if (grpcCode == 'unauthenticated' || grpcCode == 'permission-denied') return 'Plan oluşturmak için giriş yapmalısın.';
    if (grpcCode == 'resource-exhausted') return 'Çok sık plan oluşturdun. Biraz sonra tekrar dene.';
    if (grpcCode == 'failed-precondition') return 'Bu seans geçmiş; plan oluşturulamaz.';
    return 'Plan oluşturulamadı. Bağlantını kontrol edip tekrar dene.';
  }

  /// Plan oluşturur ve paylaşılacak bağlantıyı döner.
  Future<String> create({required final String showId, final String? eventId}) async {
    try {
      final HttpsCallableResult<dynamic> r = await _fn.httpsCallable('createPlan').call<dynamic>(<String, dynamic>{
        'showId': showId,
        if (eventId != null && eventId.isNotEmpty) 'eventId': eventId,
      });
      final dynamic id = r.data is Map ? (r.data as Map)['id'] : null;
      if (id is! String || id.isEmpty) throw const PollException('bad-response', 'Plan oluşturulamadı.');
      return planUrl(id);
    } on FirebaseFunctionsException catch (e) {
      throw PollException(e.code, mapErrorMessage(e.code, e.message));
    }
  }
}
