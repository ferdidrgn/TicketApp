import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firestore_provider.dart';
import '../../../purchase/presentation/providers/purchase_provider.dart';
import '../../data/account_deletion_service.dart';
import 'auth_provider.dart';

// NOT: Bu dosyada bilerek `@riverpod` codegen KULLANILMAZ (build_runner
// yok); klasik Provider API'si.

final accountDeletionServiceProvider = Provider<AccountDeletionService>(
    (final ref) =>
        AccountDeletionService(ref.watch(purchaseCallableClientProvider)));

/// `User/{uid}` belgesindeki silme durumu (yalnız OKUNUR). Oturum yoksa ya da
/// silme beklemiyorsa `null`. Alanları sunucu yazar; istemci yazmaz.
final accountDeletionInfoProvider =
    StreamProvider<AccountDeletionInfo?>((final ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream<AccountDeletionInfo?>.value(null);
  }
  return ref
      .watch(firestoreProvider)
      .collection('User')
      .doc(uid)
      .snapshots()
      .map((final s) => AccountDeletionInfo.fromUserData(s.data()));
});

/// Silme isteğinin sonucu (arayüz buna göre diyalog/sheet seçer).
sealed class DeletionOutcome {
  const DeletionOutcome();
}

/// Silme [date] tarihinde yapılacak şekilde planlandı.
class DeletionScheduled extends DeletionOutcome {
  final DateTime? date;
  const DeletionScheduled(this.date);
}

/// Misafir hesap: sunucu hemen sildi.
class DeletionDone extends DeletionOutcome {
  const DeletionDone();
}

/// Gelecek biletleri olduğu için reddedildi.
class DeletionBlocked extends DeletionOutcome {
  final UpcomingTicketsException reason;
  const DeletionBlocked(this.reason);
}

/// Hesap zaten silinmek üzere (başka cihazdan istenmiş).
class DeletionAlreadyPending extends DeletionOutcome {
  final DateTime? date;
  const DeletionAlreadyPending(this.date);
}

class DeletionFailed extends DeletionOutcome {
  final String message;
  const DeletionFailed(this.message);
}

/// Hesap silme kapısı: callable'ı çağırır, sonucu sınıflar. Çıkış, arayüzün
/// mevcut çıkış akışıyla (FCM temizliği dahil) yapılır; böylece bu sınıf
/// test edilebilir kalır.
class AccountDeletionController {
  final AccountDeletionService service;

  const AccountDeletionController(this.service);

  static const String _generic =
      'İşlem şu anda tamamlanamadı. Lütfen biraz sonra tekrar dene.';

  Future<DeletionOutcome> request() async {
    try {
      final r = await service.requestDeletion();
      return r.status == AccountDeletionStatus.deleted
          ? const DeletionDone()
          : DeletionScheduled(r.scheduledAt);
    } on UpcomingTicketsException catch (e) {
      return DeletionBlocked(e);
    } on DeletionPendingException catch (e) {
      return DeletionAlreadyPending(e.scheduledAt);
    } on AccountDeletionException catch (e) {
      return DeletionFailed(e.message);
    } catch (_) {
      return const DeletionFailed(_generic);
    }
  }

  /// Silmeyi iptal eder; başarıda `null`, hatada kullanıcı mesajı.
  Future<String?> cancel() async {
    try {
      await service.cancelDeletion();
      return null;
    } on AccountDeletionException catch (e) {
      return e.message;
    } catch (_) {
      return _generic;
    }
  }
}

final accountDeletionControllerProvider = Provider<AccountDeletionController>(
    (final ref) =>
        AccountDeletionController(ref.watch(accountDeletionServiceProvider)));
