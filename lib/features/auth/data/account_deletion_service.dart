import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';

import '../../purchase/data/datasources/purchase_remote_data_source_and_impl.dart';

/// Hesap silme bekleme süresi (gün). Gerçek tarih sunucudan gelir; bu değer
/// yalnız onay diyalogundaki ÖN GÖSTERİM içindir.
const int kAccountDeletionGraceDays = 30;

/// Sunucunun `details.code` değerleri (functions/ — requestAccountDeletion).
const String kUpcomingTicketsCode = 'UPCOMING_TICKETS';
const String kDeletionPendingCode = 'ACCOUNT_DELETION_PENDING';

/// `requestAccountDeletion` sonucu.
enum AccountDeletionStatus { scheduled, deleted }

class AccountDeletionResult {
  final AccountDeletionStatus status;

  /// `scheduled` ise kalıcı silinme tarihi.
  final DateTime? scheduledAt;

  const AccountDeletionResult(this.status, {this.scheduledAt});
}

/// Kullanıcı belgesindeki silme durumu (yalnız OKUNUR, istemci yazmaz).
class AccountDeletionInfo {
  final DateTime scheduledAt;

  const AccountDeletionInfo(this.scheduledAt);

  /// `User/{uid}` verisinden: `deletionStatus == 'pending'` ve geçerli bir
  /// `deletionScheduledAt` varsa dolu, yoksa `null`.
  static AccountDeletionInfo? fromUserData(final Map<String, dynamic>? data) {
    if (data == null || data['deletionStatus'] != 'pending') {
      return null;
    }
    final at = parseDeletionDate(data['deletionScheduledAt']);
    return at == null ? null : AccountDeletionInfo(at);
  }
}

/// Timestamp / epoch ms / ISO metin / `{_seconds}` biçimlerini tolere eder.
DateTime? parseDeletionDate(final Object? v) {
  if (v is Timestamp) {
    return v.toDate();
  }
  if (v is DateTime) {
    return v;
  }
  if (v is num) {
    return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  }
  if (v is String) {
    return DateTime.tryParse(v);
  }
  if (v is Map) {
    final s = v['_seconds'] ?? v['seconds'];
    if (s is num) {
      return DateTime.fromMillisecondsSinceEpoch(s.toInt() * 1000);
    }
  }
  return null;
}

/// "12 Kasım 2026" (tr_TR). Yerel veri yüklü değilse (testler) sayısal
/// biçime düşer; uygulama `initializeDateFormatting()` ile açılır.
String formatDeletionDate(final DateTime d) {
  try {
    return DateFormat('d MMMM yyyy', 'tr_TR').format(d.toLocal());
  } catch (_) {
    return DateFormat('dd.MM.yyyy').format(d.toLocal());
  }
}

/// Silme isteği/iptali hatası; [message] kullanıcıya gösterilebilir Türkçe.
class AccountDeletionException implements Exception {
  final String code;
  final String message;

  const AccountDeletionException(this.code, this.message);

  @override
  String toString() => 'AccountDeletionException($code): $message';
}

/// Gelecek tarihli bileti olduğu için silme reddedildi.
class UpcomingTicketsException extends AccountDeletionException {
  final int count;
  final DateTime? nextEventDate;
  final String? nextEventTitle;

  const UpcomingTicketsException({
    required this.count,
    this.nextEventDate,
    this.nextEventTitle,
  }) : super(kUpcomingTicketsCode, 'Gelecek etkinlik biletiniz var.');
}

/// Hesap zaten silinmeye alınmış (ör. başka cihazdan).
class DeletionPendingException extends AccountDeletionException {
  final DateTime? scheduledAt;

  const DeletionPendingException(this.scheduledAt)
      : super(kDeletionPendingCode, 'Hesabınız zaten silinmek üzere.');
}

/// `requestAccountDeletion` / `cancelAccountDeletion` callable'ları.
///
/// Callable istemcisi satın almayla paylaşılır (aynı bölge, testte sahte).
class AccountDeletionService {
  final PurchaseCallableClient client;

  const AccountDeletionService(this.client);

  static const String _generic =
      'İşlem şu anda tamamlanamadı. Lütfen biraz sonra tekrar dene.';

  Future<AccountDeletionResult> requestDeletion() async {
    final r = await _call('requestAccountDeletion');
    if (r['status'] == 'deleted') {
      return const AccountDeletionResult(AccountDeletionStatus.deleted);
    }
    return AccountDeletionResult(
      AccountDeletionStatus.scheduled,
      scheduledAt: parseDeletionDate(r['scheduledAt']),
    );
  }

  Future<void> cancelDeletion() async {
    await _call('cancelAccountDeletion');
  }

  Future<Map<String, dynamic>> _call(final String name) async {
    try {
      return await client.call(name, const <String, dynamic>{});
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Sunucu/SDK hatasını kullanıcıya gösterilebilir istisnaya çevirir.
  static AccountDeletionException mapError(final Object e) {
    if (e is AccountDeletionException) {
      return e;
    }
    if (e is FirebaseFunctionsException) {
      final details = e.details;
      if (details is Map) {
        if (details['code'] == kUpcomingTicketsCode) {
          final count = details['count'];
          final title = details['nextEventTitle'];
          return UpcomingTicketsException(
            count: count is num ? count.toInt() : 1,
            nextEventDate: parseDeletionDate(details['nextEventDate']),
            nextEventTitle:
                title is String && title.trim().isNotEmpty ? title : null,
          );
        }
        if (details['code'] == kDeletionPendingCode) {
          return DeletionPendingException(
              parseDeletionDate(details['scheduledAt']));
        }
      }
      if (details is Map && details['code'] == 'DELETION_IN_PROGRESS') {
        return const AccountDeletionException('deletion-in-progress',
            'Hesabınızın silinme işlemi başladı, artık vazgeçilemez.');
      }
      switch (e.code) {
        case 'unauthenticated':
          return const AccountDeletionException(
              'unauthenticated', 'Devam etmek için giriş yapmalısın.');
        case 'unavailable':
        case 'deadline-exceeded':
          return const AccountDeletionException('network',
              'Sunucuya şu an ulaşılamıyor. Bağlantını kontrol edip tekrar dene.');
      }
      return AccountDeletionException(e.code, _generic);
    }
    return const AccountDeletionException('unknown', _generic);
  }
}
