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
  /// ➕ Admin panelinden yeni bir seans (Event) oluşturur.
  Future<Either<Failure, bool>> addEvent(final Event event);

  /// ✏️ Admin panelinden bir seansı düzenler (bağımsız "Seanslar" sekmesi
  /// VE oyuna gömülü Seanslar bölümü AYNI bu metodu çağırır — mantık tek
  /// yerde). `updatedData` yalnızca gerçek `Event` alanlarını içerir
  /// (`showId`/`stageId`/`date`/`price`); `seats` buradan ASLA yazılmaz.
  Future<Either<Failure, bool>> updateEvent(
      final String eventId, final Map<String, dynamic> updatedData);

  /// 🗑️ Admin panelinden bir seansı siler. Çağıran taraf (admin UI),
  /// silmeden önce bu seansa bağlı bilet olup olmadığını
  /// `blockDeleteIfTickets` ile kontrol eder — burada ek bir kontrol
  /// YAPILMAZ (web admin panelinin `sil()` deseniyle aynı sorumluluk
  /// ayrımı).
  Future<Either<Failure, bool>> deleteEvent(final String eventId);

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

  /// 🎟️ Ücretsiz "protokol" bileti (İş T-2): admin her oyunda, aktif ekip
  /// yöneticisi yalnız kendi ekibinin seansında müsait koltuklara doğrudan
  /// (ödemesiz) bilet verir — sunucu `teamGrantFreeSeat` callable'ı
  /// (`functions/src/team.js`). Döndürülen değer oluşan bilet kimliğidir.
  Future<Either<Failure, String>> grantFreeSeat(
      final String eventId, final List<String> seatIds, final String note);
}
