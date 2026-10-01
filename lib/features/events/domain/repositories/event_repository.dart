import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/event.dart';

/// Bir koltuk admin tarafından operasyonel gerekçeyle (arıza/kontenjan)
/// elle bloke edildiğinde `seats.$seatId.customerId` alanına yazılan sabit
/// işaret. Gerçek bir müşteri uid'i asla bu değere eşit olamaz (Firebase
/// Auth uid'leri bu formatta üretilmez), bu yüzden bilet/koltuk
/// denetleme ekranı ve raporlar bunu "gerçek satış değil, admin bloğu"
/// olarak güvenle ayırt edebilir.
const String kAdminBlockCustomerId = '__ADMIN_BLOCKED__';

abstract class EventRepository {
  Future<Either<Failure, void>> initializeAndGetEventSeats(
      final String eventId);

  /// ➕ Admin panelinden yeni bir seans (Event) oluşturur.
  Future<Either<Failure, bool>> addEvent(final Event event);

  // 🔥 Model yerine temiz Entity (Event) listesi döndürür
  Future<Either<Failure, List<Event>>> getEventsByIds(
      final List<String> eventIds);

  /// Etkinlikleri, `Event.showId` alanına göre DOĞRUDAN sorgular — Show
  /// tarafındaki `eventsId` dizisine bağımlı değildir. `Show.eventsId`
  /// güncellenmeyi unutulursa (ör. Firebase Console'dan elle eklenmiş bir
  /// etkinlik) bu yöntem yine de o etkinliği bulur.
  Future<Either<Failure, List<Event>>> getEventsByShowIds(
      final List<String> showIds);

  Stream<Map<String, Map<String, dynamic>>> getEventSeatStatusStream(
      final String eventId);

  Future<Either<Failure, bool>> attemptReservation(
      final String eventId, final String seatId, final String customerId);

  Future<Either<Failure, bool>> releaseReservation(
      final String eventId, final String seatId, final String customerId);

  Future<Either<Failure, bool>> confirmPurchase(final String eventId,
      final List<String> seatIds, final String customerId);

  /// 🛠️ Admin koltuk denetimi (Phase 2): bir koltuğu operasyonel
  /// gerekçelerle (arızalı koltuk, kontenjan tutma vb.) elle
  /// bloke eder/serbest bırakır. Uygulamanın GERÇEK koltuk durum modeli
  /// sadece 'available' | 'reserved' | 'sold' değerlerini biliyor (bkz.
  /// `event_remote_data_source_and_impl.dart`) — CLAUDE.md'nin bahsettiği
  /// 'blocked' ayrı bir enum değeri olarak HİÇBİR YERDE modellenmemiş,
  /// dolayısıyla burada da icat edilmiyor. Admin bloğu, bu iki gerçek
  /// değerden biriyle ('sold', sahte bir `customerId` işaretiyle) temsil
  /// edilir — bkz. `kAdminBlockCustomerId`.
  Future<Either<Failure, bool>> adminSetSeatBlocked(
      final String eventId, final String seatId, final bool blocked);
}
