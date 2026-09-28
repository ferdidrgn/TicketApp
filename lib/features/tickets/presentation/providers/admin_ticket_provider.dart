import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/ticket_repository_provider.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/usecases/get_tickets_by_event_id_use_case.dart';

// 🔧 KODLAMA NOTU: `my_ticket_provider.dart` `@riverpod` codegen kullanıyor
// ve bir `my_ticket_provider.g.dart`'ı var — build_runner bu sandbox'ta
// çalışmadığından oraya yeni bir `@riverpod` provider EKLENEMEZ (CLAUDE.md).
// Bu YENİ, sadece OKUMA amaçlı admin provider'ı `stage_mutation_provider.
// dart`/`event_mutation_provider.dart` ile AYNI, klasik/codegen'siz
// `Provider`/`FutureProvider.family` API'siyle ayrı bir dosyada tanımlandı.

final getTicketsByEventIdUseCaseProvider =
    Provider<GetTicketsByEventIdUseCase>((final ref) =>
        GetTicketsByEventIdUseCaseImpl(ref.watch(ticketRepositoryProvider)));

/// 🎫 Admin bilet/koltuk denetimi: bir seansa (Event) ait GERÇEK satın
/// alınmış biletleri Firestore'dan çeker (`Ticket.eventId` alanına göre).
final ticketsByEventIdProvider =
    FutureProvider.family<List<Ticket>, String>((final ref, final eventId) {
  if (eventId.isEmpty) return Future.value(const <Ticket>[]);
  return ref.watch(getTicketsByEventIdUseCaseProvider).call(eventId).getOrThrow();
});
