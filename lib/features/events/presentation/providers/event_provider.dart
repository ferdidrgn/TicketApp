import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../../data/repositories/event_repository_provider.dart';
import '../../domain/entities/event.dart';
import '../../domain/usecases/attempt_reservation_use_case_impl.dart';
import '../../domain/usecases/confirm_purchase_case_impl.dart';
import '../../domain/usecases/get_events_by_ids_use_case_impl.dart';
import '../../domain/usecases/get_seat_status_by_event_use_case_impl.dart';
import '../../domain/usecases/release_reservation_use_case_impl.dart';

part 'event_provider.g.dart';

// ==============================================================================
// 1. USE CASE PROVIDERS
// ==============================================================================

@riverpod
GetEventsByIdsUseCase getEventsByIdsUseCase(final Ref ref) =>
    GetEventsByIdsUseCaseImpl(ref.watch(eventRepositoryProvider));

@riverpod
GetEventSeatStatusStreamUseCase getEventSeatStatusStreamUseCase(
        final Ref ref) =>
    GetEventSeatStatusStreamUseCaseImpl(ref.watch(eventRepositoryProvider));

@riverpod
AttemptReservationUseCase attemptReservationUseCase(final Ref ref) =>
    AttemptReservationUseCaseImpl(ref.watch(eventRepositoryProvider));

@riverpod
ReleaseReservationUseCase releaseReservationUseCase(final Ref ref) =>
    ReleaseReservationUseCaseImpl(ref.watch(eventRepositoryProvider));

@riverpod
ConfirmPurchaseUseCase confirmPurchaseUseCase(final Ref ref) =>
    ConfirmPurchaseUseCaseImpl(ref.watch(eventRepositoryProvider));

// ==============================================================================
// 2. DATA PROVIDERS
// ==============================================================================

/// 🎯 KOLTUK DURUMU (Real-time Stream)
/// HATA ÇÖZÜMÜ: .cast() kullanarak nullable Map'i istenen tipe zorluyoruz.
/// 🎯 ID LİSTESİNE GÖRE ETKİNLİKLERİ ÇEKER
/// MyTicketProvider'ın beklediği provider budur.
@riverpod
Future<List<Event>> eventsByIds(final Ref ref, final List<String> ids) async {
  if (ids.isEmpty) return [];
  final result = await ref.watch(getEventsByIdsUseCaseProvider).call(ids);
  return result.getOrThrow();
}

/// 🎯 KOLTUK DURUMU (Real-time Stream)
/// HATA ÇÖZÜMÜ: .map ve .cast ile nullable Map uyuşmazlığını gideriyoruz.
@riverpod
Stream<Map<String, Map<String, dynamic>>> eventSeats(
        final Ref ref, final String eventId) =>
    ref.watch(getEventSeatStatusStreamUseCaseProvider).call(eventId).map(
        (final eventData) => eventData.cast<String, Map<String, dynamic>>());

/// 🎯 ETKİNLİK DETAYI
@riverpod
Future<Event> eventDetail(final Ref ref, final String eventId) async {
  final result = await ref.watch(getEventsByIdsUseCaseProvider).call([eventId]);
  final list = await result.getOrThrow();
  return list.first;
}

/// 🎯 GERİ SAYIM (Timer)
@riverpod
Stream<int> reservationTimer(final Ref ref) =>
    Stream.periodic(const Duration(seconds: 1), (final i) => 600 - i).take(601);

// ==============================================================================
// 3. ACTION PROVIDERS (Side Effects)
// ==============================================================================

@riverpod
Future<bool> toggleSeatSelection(
  final Ref ref, {
  required final String eventId,
  required final String seatId,
  required final String customerId,
  required final bool isAdding,
}) async {
  if (isAdding)
    return ref
        .read(attemptReservationUseCaseProvider)
        .call(eventId, seatId, customerId)
        .getOrThrow();
  else
    return ref
        .read(releaseReservationUseCaseProvider)
        .call(eventId, seatId, customerId)
        .getOrThrow();
}

@riverpod
Future<void> purchaseAction(
  final Ref ref, {
  required final String eventId,
  required final String showId,
  required final String stageId,
  required final List<String> seatIds,
  required final String customerId,
  required final String paymentMethod,
  required final double totalPrice,
}) async {
  // ⚠️ ÖDEME ENTEGRASYONU HENÜZ YOK:
  // `paymentSuccess` sabit `true` — gerçek bir ödeme sağlayıcısına
  // (iyzico/Stripe/PayTR vb.) bağlanana kadar bu akış parayı GERÇEKTEN
  // tahsil etmiyor, sadece Firestore'da koltuğu "sold" yapıyor. Kredi kartı
  // seçeneği canlıya çıkmadan önce bu kesinlikle gerçek bir ödeme SDK'sına
  // bağlanmalı.
  const paymentSuccess = true;

  if (!paymentSuccess) throw Exception('Ödeme başarısız oldu.');

  // 1. Koltukları onayla — confirmPurchase artık transaction içinde,
  // her koltuğun GERÇEKTEN bu müşteri tarafından 'reserved' durumda
  // olduğunu doğruluyor (bkz. event_remote_data_source_and_impl.dart).
  final result = await ref
      .read(confirmPurchaseUseCaseProvider)
      .call(eventId, seatIds, customerId);

  // 🔥 KRİTİK DÜZELTME: Önceden `result.isLeft()` (yani confirmPurchase
  // başarısız) durumunda hiçbir şey yapılmadan fonksiyon sessizce bitiyordu.
  // UI tarafı (seat_details.dart _processPurchase) hata fırlatılmadığı için
  // bunu "başarılı" sanıp kullanıcıya "Biletleriniz başarıyla oluşturuldu!"
  // gösteriyordu — oysa hiçbir bilet oluşturulmamıştı ve koltuk hâlâ
  // rezervasyonda/başkasına satılmış olabilirdi. Artık başarısızlık durumunda
  // anlamlı bir hata fırlatılıyor ki kullanıcı gerçek durumu görsün.
  result.getOrThrow();

  // 2. Ticket nesnesi oluştur ve kaydet
  final ticket = Ticket(
    id: '',
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
    showId: showId,
    customerId: customerId,
    stageId: stageId,
    eventId: eventId,
    orderPrice: totalPrice.toStringAsFixed(2),
    orderMethod: paymentMethod,
    buySeats: seatIds,
    isPast: false,
  );

  await ref.read(createTicketUseCaseProvider).call(ticket).getOrThrow();

  // 3. Başarılı alımdan sonra bilet listesini yenile
  ref.invalidate(myTicketsProvider(customerId));
}
