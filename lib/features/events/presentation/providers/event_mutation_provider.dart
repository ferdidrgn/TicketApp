import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../data/repositories/event_repository_provider.dart';
import '../../domain/entities/event.dart';
import '../../domain/usecases/add_event_use_case_impl.dart';
import '../../domain/usecases/admin_set_seat_blocked_use_case_impl.dart';
import '../../domain/usecases/delete_event_use_case_impl.dart';
import '../../domain/usecases/grant_free_seat_use_case_impl.dart';
import '../../domain/usecases/update_event_use_case_impl.dart';
import '../../../tickets/presentation/providers/admin_ticket_provider.dart';
import 'event_provider.dart';

// 🔧 KODLAMA NOTU (Event Mutation — codegen'siz):
// `event_provider.dart` zaten `@riverpod` (build_runner) codegen kullanıyor
// ve eşleşen bir `event_provider.g.dart`'ı var — bu sandbox'ta build_runner
// ÇALIŞTIRILAMADIĞI için o dosyaya yeni bir `@riverpod` provider EKLENEMEZ
// (CLAUDE.md). Bu yüzden bu YENİ mutation (yazma) provider'ı ayrı bir
// dosyada, `theme_notifier.dart`'taki `CustomAccentColorNotifier` ile
// AYNI, tamamen klasik/codegen'siz `Notifier`+`NotifierProvider` API'siyle
// yazıldı — hiçbir `.g.dart` üretimine ihtiyaç duymaz.

final addEventUseCaseProvider = Provider<AddEventUseCase>(
    (final ref) => AddEventUseCaseImpl(ref.watch(eventRepositoryProvider)));

final updateEventUseCaseProvider = Provider<UpdateEventUseCase>((final ref) =>
    UpdateEventUseCaseImpl(ref.watch(eventRepositoryProvider)));

final deleteEventUseCaseProvider = Provider<DeleteEventUseCase>((final ref) =>
    DeleteEventUseCaseImpl(ref.watch(eventRepositoryProvider)));

final adminSetSeatBlockedUseCaseProvider =
    Provider<AdminSetSeatBlockedUseCase>((final ref) =>
        AdminSetSeatBlockedUseCaseImpl(ref.watch(eventRepositoryProvider)));

final grantFreeSeatUseCaseProvider = Provider<GrantFreeSeatUseCase>(
    (final ref) => GrantFreeSeatUseCaseImpl(ref.watch(eventRepositoryProvider)));

final eventMutationProvider =
    NotifierProvider<EventMutationNotifier, AsyncValue<void>>(
        EventMutationNotifier.new);

class EventMutationNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// ➕ Admin panelinden bir oyuna yeni bir seans (Event) ekler.
  Future<void> addEvent(final Event event) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(addEventUseCaseProvider).call(event).getOrThrow();
      // Bu oyunun (showId) seans listesini gösteren HER ekran
      // `eventsByShowIdsProvider` üzerinden besleniyor (bkz.
      // `show_provider.dart`) — family'nin tamamı invalidate edilir.
      ref.invalidate(eventsByShowIdsProvider);
      ref.invalidate(eventsForShowProvider);
      ref.invalidate(eventsByShowMapProvider);
    });
  }

  /// ✏️ Admin panelinden (gömülü Seanslar bölümü VEYA bağımsız "Seanslar"
  /// sekmesi — AYNI metot, mantık tek yerde) bir seansı düzenler.
  /// `updatedData` yalnızca gerçek alanları içerir (`showId`/`stageId`/
  /// `date`/`price`/`cancelled`); `seats` buradan ASLA yazılmaz.
  Future<bool> updateEvent(
      final String eventId, final Map<String, dynamic> updatedData) async {
    state = const AsyncLoading();
    var ok = false;
    state = await AsyncValue.guard(() async {
      ok = await ref
          .read(updateEventUseCaseProvider)
          .call(eventId, updatedData)
          .getOrThrow();
      ref.invalidate(eventsByShowIdsProvider);
      ref.invalidate(eventsForShowProvider);
      ref.invalidate(eventsByShowMapProvider);
    });
    return ok;
  }

  /// 🗑️ Admin panelinden bir seansı siler. Bilet varsa silinmemesi
  /// çağıran UI'ın sorumluluğu (`blockDeleteIfTickets`) — burada ikinci
  /// bir kontrol YOK.
  Future<bool> deleteEvent(final String eventId) async {
    state = const AsyncLoading();
    var ok = false;
    state = await AsyncValue.guard(() async {
      ok = await ref.read(deleteEventUseCaseProvider).call(eventId).getOrThrow();
      ref.invalidate(eventsByShowIdsProvider);
      ref.invalidate(eventsForShowProvider);
      ref.invalidate(eventsByShowMapProvider);
    });
    return ok;
  }

  /// 🛠️ Admin koltuk denetimi (Phase 2): bir koltuğu operasyonel
  /// gerekçeyle bloke eder/serbest bırakır (bkz. `EventRepository.
  /// adminSetSeatBlocked` — 'blocked' YENİ bir enum değeri değil, mevcut
  /// 'available'/'sold' durumlarının admin işaretli bir kullanımı).
  Future<void> adminSetSeatBlocked(
      final String eventId, final String seatId, final bool blocked) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(adminSetSeatBlockedUseCaseProvider)
          .call(eventId, seatId, blocked)
          .getOrThrow();
      // Real-time stream zaten kendi kendine güncellenir (bkz.
      // `getEventSeatStatusStream`) ama emin olmak için family'yi de
      // invalidate ediyoruz.
      ref.invalidate(eventSeatsProvider);
    });
  }

  /// 🎟️ Ücretsiz "protokol" bileti (İş T-2): admin her oyunda, aktif ekip
  /// yöneticisi yalnız kendi ekibinin seansında müsait koltuklara doğrudan
  /// bilet verir (bkz. `EventRepository.grantFreeSeat`). Başarılıysa oluşan
  /// bilet kimliğini döner; hata durumunda `null` (ayrıntı `state.error`'da).
  Future<String?> grantFreeSeat(final String eventId,
      final List<String> seatIds, final String note) async {
    state = const AsyncLoading();
    String? ticketId;
    state = await AsyncValue.guard(() async {
      ticketId = await ref
          .read(grantFreeSeatUseCaseProvider)
          .call(eventId, seatIds, note)
          .getOrThrow();
      ref.invalidate(eventSeatsProvider);
      ref.invalidate(ticketsByEventIdProvider);
    });
    return ticketId;
  }
}
