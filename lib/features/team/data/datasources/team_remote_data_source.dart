import 'package:cloud_functions/cloud_functions.dart';

/// Cloud Functions bölgesi (`functions/src/config.js` > REGION). Satın alma
/// akışıyla aynı değer (`kPurchaseFunctionsRegion`); burada ayrıca
/// tanımlanır ki `team` özelliği kendi klasöründe tam bağımsız kalsın
/// (admin/purchase modüllerine bağımlılığı olmasın).
const String kTeamFunctionsRegion = 'europe-west1';

/// Kullanıcıya gösterilebilir, teknik sızıntısı olmayan hata
/// (bkz. `purchase_remote_data_source_and_impl.dart` > PurchaseException —
/// aynı desen).
class TeamException implements Exception {
  final String code;
  final String message;

  const TeamException(this.code, this.message);

  @override
  String toString() => 'TeamException($code): $message';
}

const String _kServiceUnavailableMessage =
    'Ekip paneli şu an kullanılamıyor, lütfen daha sonra dene.';
const String _kNetworkMessage =
    'Sunucuya şu an ulaşılamıyor. Bağlantını kontrol edip tekrar dene.';
const String _kGenericMessage =
    'İşlem şu anda tamamlanamadı. Lütfen tekrar dene.';

/// Ham/teknik görünen metin (functions/..., NOT_FOUND, URL, istisna adı...)
/// kullanıcıya ASLA gösterilmez.
bool _looksTechnical(final String msg) =>
    RegExp(r'functions/|https?:|exception|error|firebase|stack',
            caseSensitive: false)
        .hasMatch(msg) ||
    RegExp(r'[A-Z]{2,}_[A-Z]{2,}').hasMatch(msg) ||
    RegExp(r'^[A-Z][A-Z ]{3,}$').hasMatch(msg);

/// `functions/src/team.js` ve `notify.js` callable'larının hata sözleşmesini
/// tek yerde Türkçe'ye çevirir. Sunucu zaten temiz Türkçe mesajlar
/// döndürüyor (ör. "Bu işlem için yetkin yok.", "X kişiye gönderilecek;
/// onay gerekli.") — bu fonksiyon öncelikle o mesajı kullanır, yalnız
/// teknik/boş olduğunda sabit bir karşılığa düşer.
TeamException mapTeamError(final Object e) {
  if (e is TeamException) return e;
  if (e is FirebaseFunctionsException) {
    final code = e.code;
    final msg = (e.message ?? '').trim();
    final details = e.details;
    final dcode = details is Map ? details['code'] : null;
    if (dcode == 'ACCOUNT_DELETION_PENDING') {
      return const TeamException('account-deletion-pending',
          'Hesabın silinme sürecinde; bu süreçte ekip paneli kullanılamaz.');
    }
    if (code == 'unauthenticated') {
      return const TeamException(
          'unauthenticated', 'Oturum süresi doldu. Tekrar giriş yap.');
    }
    if (code == 'unavailable' || code == 'deadline-exceeded') {
      return const TeamException('network', _kNetworkMessage);
    }
    if (code == 'unimplemented' || code == 'not-found') {
      return const TeamException(
          'service-unavailable', _kServiceUnavailableMessage);
    }
    const trusted = {
      'failed-precondition',
      'resource-exhausted',
      'invalid-argument',
      'permission-denied',
    };
    if (trusted.contains(code)) {
      if (msg.isNotEmpty && msg.length <= 240 && !_looksTechnical(msg)) {
        return TeamException(code, msg);
      }
      return switch (code) {
        'permission-denied' =>
          const TeamException('permission-denied', 'Bu işlem için yetkin yok.'),
        'failed-precondition' => const TeamException(
            'failed-precondition', 'Bu işlem şu an yapılamaz.'),
        'resource-exhausted' => const TeamException(
            'resource-exhausted', 'Gönderim sınırına ulaşıldı.'),
        _ => const TeamException('invalid-argument', _kGenericMessage),
      };
    }
    return TeamException(code, _kGenericMessage);
  }
  final text = e.toString();
  if (text.contains('SocketException') || text.contains('ClientException')) {
    return const TeamException('network', _kNetworkMessage);
  }
  return const TeamException('unknown', _kGenericMessage);
}

/// Callable çağrısını soyutlar: üretimde `FirebaseFunctions`, testte sahte.
abstract class TeamCallableClient {
  Future<Map<String, dynamic>> call(
      final String name, final Map<String, dynamic> data);
}

class FirebaseTeamCallableClient implements TeamCallableClient {
  final FirebaseFunctions _functions;

  FirebaseTeamCallableClient({final FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: kTeamFunctionsRegion);

  @override
  Future<Map<String, dynamic>> call(
      final String name, final Map<String, dynamic> data) async {
    try {
      final result = await _functions.httpsCallable(name).call<Object?>(data);
      final raw = result.data;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      throw mapTeamError(e);
    }
  }
}

/// Ekip yöneticisi callable'ları (`functions/index.js`'te tanımlı adlar —
/// isimler doğrulandı, uydurma değil):
/// `getMyManagedTeams`, `teamNotifyPreview`, `teamSendNotification`,
/// `teamStats`.
abstract class TeamRemoteDataSource {
  Future<Map<String, dynamic>> getMyManagedTeams();
  Future<Map<String, dynamic>> teamNotifyPreview(
      final Map<String, dynamic> data);
  Future<Map<String, dynamic>> teamSendNotification(
      final Map<String, dynamic> data);
  Future<Map<String, dynamic>> teamStats(final Map<String, dynamic> data);
}

class TeamRemoteDataSourceImpl implements TeamRemoteDataSource {
  final TeamCallableClient _client;

  TeamRemoteDataSourceImpl({final TeamCallableClient? client})
      : _client = client ?? FirebaseTeamCallableClient();

  @override
  Future<Map<String, dynamic>> getMyManagedTeams() =>
      _client.call('getMyManagedTeams', const {});

  @override
  Future<Map<String, dynamic>> teamNotifyPreview(
          final Map<String, dynamic> data) =>
      _client.call('teamNotifyPreview', data);

  @override
  Future<Map<String, dynamic>> teamSendNotification(
          final Map<String, dynamic> data) =>
      _client.call('teamSendNotification', data);

  @override
  Future<Map<String, dynamic>> teamStats(final Map<String, dynamic> data) =>
      _client.call('teamStats', data);
}
