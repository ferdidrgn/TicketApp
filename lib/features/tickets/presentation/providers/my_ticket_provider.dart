import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../data/repositories/ticket_repository_provider.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/usecases/create_ticket_use_case_impl.dart';
import '../../domain/usecases/get_ticket_by_id_use_case.dart';
import '../../domain/usecases/get_tickets_by_customer_id_use_case.dart';

part 'my_ticket_provider.g.dart';

/// ==============================================================================
/// 1. UI MODEL (Presentation Layer DTO)
/// Sadece UI'da göstermek için özelleştirilmiş model.
/// ==============================================================================
class DetailedTicket {
  final Ticket ticket;
  final Show? show;
  final Event? event;
  final Stage? stage;
  final bool isPast;

  const DetailedTicket({
    required this.ticket,
    this.show,
    this.event,
    this.stage,
    required this.isPast,
  });
}

/// ==============================================================================
/// 2. USE CASE PROVIDERS (Dependency Injection)
/// Repository'yi UseCase'lere burada bağlıyoruz.
/// ==============================================================================

@riverpod
GetTicketsByIdUseCase getTicketByIdUseCase(final Ref ref) =>
    GetTicketsByIdUseCaseImpl(ref.watch(ticketRepositoryProvider));

@riverpod
GetTicketsByCustomerIdUseCase getTicketByCustomerIdUseCase(final Ref ref) =>
    GetTicketByCustomerIdUseCaseImpl(ref.watch(ticketRepositoryProvider));

@riverpod
CreateTicketUseCase createTicketUseCase(final Ref ref) =>
    CreateTicketUseCaseImpl(ref.watch(ticketRepositoryProvider));

/// ==============================================================================
/// 3. COMPOSITE PROVIDER (MAIN LOGIC)
/// Kullanıcının biletlerini çeker, diğer modüllerden (Show, Event, Stage)
/// verileri paralel olarak getirir ve birleştirir.
/// ==============================================================================
@riverpod
Future<List<DetailedTicket>> myTickets(
    final Ref ref, final String userId) async {
  // 0. Guard Clause: User ID yoksa boş dön
  if (userId.isEmpty) return [];

  // 1. Biletleri Çek
  final tickets = await ref
      .watch(getTicketByCustomerIdUseCaseProvider)
      .call(userId)
      .getOrThrow();

  if (tickets.isEmpty) return [];

  // 2. ID'leri Topla (Unique listeler oluştur)
  // Boş stringleri filtrelemek iyi bir pratiktir.
  final showIds = tickets
      .map((final t) => t.showId)
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  final eventIds = tickets
      .map((final t) => t.eventId)
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  final stageIds = tickets
      .map((final t) => t.stageId)
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  // 3. İlişkili Verileri Paralel Çek (Future.wait ile performans artışı)
  final results = await Future.wait([
    showIds.isNotEmpty
        ? ref.watch(showsByIdsProvider(showIds).future)
        : Future.value(<Show>[]),
    eventIds.isNotEmpty
        ? ref.watch(eventsByIdsProvider(eventIds).future)
        : Future.value(<Event>[]),
    stageIds.isNotEmpty
        ? ref.watch(stagesByIdsProvider(stageIds).future)
        : Future.value(<Stage>[]),
  ]);

  final shows = results[0] as List<Show>;
  final events = results[1] as List<Event>;
  final stages = results[2] as List<Stage>;

  // 4. Hızlı Erişim İçin Map'le (O(1) Lookup)
  final showMap = {for (var s in shows) s.id: s};
  final eventMap = {for (var e in events) e.id: e};
  final stageMap = {for (var s in stages) s.id: s};

  // 5. Birleştir ve DetailedTicket Oluştur
  final now = DateTime.now();

  return tickets.map((final ticket) {
    final event = eventMap[ticket.eventId];
    final show = showMap[ticket.showId];
    final stage = stageMap[ticket.stageId];

    // Geçmiş etkinlik kontrolü
    bool isPast = false;
    if (event?.date != null) {
      final eventDate = DateFormatter.parseDateString(event!.date);
      if (eventDate != null) isPast = eventDate.isBefore(now);
    }

    return DetailedTicket(
        ticket: ticket, show: show, event: event, stage: stage, isPast: isPast);
  }).toList();
}

/// ==============================================================================
/// 4. HELPER EXTENSIONS (UI Filters)
/// ==============================================================================
extension DetailedTicketListX on List<DetailedTicket> {
  /// Gelecek biletler
  List<DetailedTicket> get upcoming => where((final t) => !t.isPast).toList();

  /// Geçmiş biletler
  List<DetailedTicket> get past => where((final t) => t.isPast).toList();
}
