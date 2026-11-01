import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';

/// Ekibe sorulan soru (Q-2). Belgede uid YOKTUR; yalnız yayınlanmış (answered) sorular herkese okunur.
class ShowQuestion extends Equatable {
  final String id;
  final String showId;
  final String askerName;
  final String askerKey;
  final String text;
  final String? answer;
  final String? answeredBy;
  final String status; // pending | answered | hidden | rejected
  final DateTime? createdAt;

  const ShowQuestion({
    required this.id,
    required this.showId,
    required this.askerName,
    required this.askerKey,
    required this.text,
    required this.answer,
    required this.answeredBy,
    required this.status,
    required this.createdAt,
  });

  factory ShowQuestion.fromDoc(final String id, final Map<String, dynamic> d) {
    DateTime? ts(final dynamic v) =>
        v is Timestamp ? v.toDate() : (v is String ? DateTime.tryParse(v) : null);
    return ShowQuestion(
      id: id,
      showId: (d['showId'] ?? '').toString(),
      askerName: (d['askerName'] ?? '').toString(),
      askerKey: (d['askerKey'] ?? '').toString(),
      text: (d['text'] ?? '').toString(),
      answer: d['answer']?.toString(),
      answeredBy: d['answeredBy']?.toString(),
      status: (d['status'] ?? 'pending').toString(),
      createdAt: ts(d['createdAt'] ?? d['_createdAt']),
    );
  }

  @override
  List<Object?> get props => [id, status, answer, text];
}

class QuestionException implements Exception {
  final String code;
  final String message;
  const QuestionException(this.code, this.message);
  @override
  String toString() => message;
}

/// Firestore (yalnız yayınlanmış soruları okuma) + Cloud Functions (soru sor / şikâyet / engelle / benim sorularım).
class QuestionRepository {
  final FirebaseFirestore _db;
  final FirebaseFunctions? _fnOverride;
  QuestionRepository([final FirebaseFirestore? db, final FirebaseFunctions? fn])
      : _db = db ?? FirebaseFirestore.instance,
        _fnOverride = fn;

  FirebaseFunctions get _fn => _fnOverride ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<Map<String, dynamic>> _call(final String name, final Map<String, dynamic> data) async {
    try {
      final r = await _fn.httpsCallable(name).call<dynamic>(data);
      final d = r.data;
      return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      final det = e.details;
      final String code = det is Map && det['code'] is String ? det['code'] as String : e.code;
      throw QuestionException(code, mapErrorMessage(e.code, code, e.message));
    }
  }

  static String mapErrorMessage(final String grpcCode, final String code, final String? serverMessage) {
    switch (code) {
      case 'PHONE_REQUIRED':
        return 'Soru sormak için telefon numaranı doğrulamalısın.';
      case 'ACCOUNT_DELETION_PENDING':
        return 'Hesabın silinme sürecinde olduğu için bu işlem yapılamıyor.';
    }
    if (grpcCode == 'resource-exhausted' && serverMessage != null && serverMessage.isNotEmpty) return serverMessage;
    if (grpcCode == 'invalid-argument' && serverMessage != null && serverMessage.isNotEmpty) return serverMessage;
    return 'İşlem tamamlanamadı. Bağlantını kontrol edip tekrar dene.';
  }

  /// Yayınlanmış sorular (kural: status==answered && hidden==false sorgusu).
  Future<List<ShowQuestion>> published(final String showId) async {
    final snap = await _db
        .collection('Question')
        .where('showId', isEqualTo: showId)
        .where('status', isEqualTo: 'answered')
        .where('hidden', isEqualTo: false)
        .get();
    final list = [for (final d in snap.docs) ShowQuestion.fromDoc(d.id, d.data())];
    list.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return list;
  }

  /// Kendi bekleyen/reddedilen/yanıtlanan sorularım (sunucu uid'e göre süzer).
  Future<List<ShowQuestion>> mine(final String showId) async {
    final r = await _call('myQuestions', {'showId': showId});
    final items = r['items'];
    if (items is! List) return const [];
    return [
      for (final x in items)
        if (x is Map)
          ShowQuestion.fromDoc((x['id'] ?? '').toString(), {
            'showId': x['showId'],
            'text': x['text'],
            'answer': x['answer'],
            'answeredBy': x['answeredBy'],
            'status': x['status'],
            'createdAt': x['createdAt'],
          }),
    ];
  }

  Future<void> ask(final String showId, final String text) =>
      _call('askQuestion', {'showId': showId, 'text': text.trim()});

  Future<void> report(final String questionId, {final String reason = 'diger'}) =>
      _call('reportContent', {'type': 'question', 'id': questionId, 'reason': reason, 'detail': ''});

  /// Soruyu soran kişiyi engelle (sunucu uid'i çözer). Dönüş: soranın `askerKey` özeti.
  Future<String> blockAsker(final String questionId) async {
    final r = await _call('blockUser', {'questionId': questionId});
    return (r['askerKey'] ?? '').toString();
  }

  /// Engellediklerimin askerKey özetleri (User/{me}/blocks/*.askerKey).
  Future<Set<String>> blockedAskerKeys(final String myUid) async {
    final snap = await _db.collection('User').doc(myUid).collection('blocks').get();
    return {
      for (final d in snap.docs)
        if ((d.data()['askerKey'] ?? '').toString().isNotEmpty) d.data()['askerKey'].toString(),
    };
  }
}
