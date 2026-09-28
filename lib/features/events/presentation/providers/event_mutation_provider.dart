import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../data/repositories/event_repository_provider.dart';
import '../../domain/entities/event.dart';
import '../../domain/usecases/add_event_use_case_impl.dart';

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
    });
  }
}
