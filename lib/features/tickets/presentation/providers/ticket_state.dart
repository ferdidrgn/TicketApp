import 'package:flutter/foundation.dart';
import '../../../../core/base/base_loadable_state.dart';
import '../../../events/domain/entities/event.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../domain/entities/ticket.dart';

/// Bilet state yönetimi için immutable state class.
///
/// DESIGN PRINCIPLES:
/// - Immutability: Tüm alanlar final
/// - Performance: Efficient copyWith implementation
/// - Type Safety: Strongly typed generics
/// - Memory Efficient: Lazy loading ve null safety
///
/// STATE LIFECYCLE:
/// 1. Initial: Empty state, no data
/// 2. Loading: isLoading = true, previous data retained
/// 3. Success: Data loaded, isLoading = false
/// 4. Error: errorMessage set, previous data retained
@immutable
class TicketState extends LoadableState<Ticket, List<Ticket>> {
  /// Lazy loading için nullable - sadece gerektiğinde yüklenir.
  final List<Show>? relatedShows;
  final List<Event>? relatedEvents;
  final List<Stage>? relatedStages;

  const TicketState({
    super.dataList,
    super.dataSingle,
    super.isLoading = false,
    super.errorMessage,
    this.relatedShows,
    this.relatedEvents,
    this.relatedStages,
  });

  /// Boş state factory constructor
  factory TicketState.initial() => const TicketState();

  /// Loading state factory constructor
  factory TicketState.loading({final List<Ticket>? previousData}) =>
      TicketState(
        dataList: previousData,
        isLoading: true,
      );

  /// Success state factory constructor
  factory TicketState.success({
    required final List<Ticket> tickets,
    final List<Show>? shows,
    final List<Event>? events,
    final List<Stage>? stages,
  }) =>
      TicketState(
        dataList: tickets,
        relatedShows: shows,
        relatedEvents: events,
        relatedStages: stages,
        isLoading: false,
      );

  /// Error state factory constructor
  factory TicketState.error({
    required final String error,
    final List<Ticket>? previousData,
  }) =>
      TicketState(
        dataList: previousData,
        errorMessage: error,
        isLoading: false,
      );

  /// İyileştirilmiş copyWith metodu
  ///
  /// PERFORMANCE: Sadece değişen alanlar kopyalanır
  @override
  TicketState copyWith({
    final Ticket? dataSingle,
    final List<Ticket>? dataList,
    final bool? isLoading,
    final String? errorMessage,
    final List<Show>? relatedShows,
    final List<Event>? relatedEvents,
    final List<Stage>? relatedStages,
  }) =>
      TicketState(
        dataSingle: dataSingle ?? this.dataSingle,
        dataList: dataList ?? this.dataList,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        relatedShows: relatedShows ?? this.relatedShows,
        relatedEvents: relatedEvents ?? this.relatedEvents,
        relatedStages: relatedStages ?? this.relatedStages,
      );

  // ============================================================
  // COMPUTED PROPERTIES - UI için optimize edilmiş helper'lar
  // ============================================================

  /// Tüm veriler yüklendi mi?
  /// UI'da tam veri kontrolü için kullanılır.
  bool get isFullyLoaded =>
      dataList != null &&
      relatedShows != null &&
      relatedEvents != null &&
      relatedStages != null;

  /// Herhangi bir bilet var mı?
  bool get hasTickets => (dataList?.isNotEmpty ?? false);

  /// İlişkili veriler yüklendi mi?
  bool get hasRelatedData =>
      (relatedShows?.isNotEmpty ?? false) ||
      (relatedEvents?.isNotEmpty ?? false) ||
      (relatedStages?.isNotEmpty ?? false);

  /// State boş mu? (hiç veri yok)
  bool get isEmpty =>
      !hasTickets && !hasRelatedData && errorMessage == null && !isLoading;

  /// Hata durumunda mı?
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// Başarılı yükleme durumu
  bool get isSuccess => hasTickets && !isLoading && !hasError;

  /// İlk yükleme mi? (henüz hiç veri yüklenmemiş)
  bool get isInitialLoading => isLoading && dataList == null;

  /// Yeniden yükleme mi? (mevcut veri varken yükleme yapılıyor)
  bool get isRefreshing => isLoading && dataList != null;

  // ============================================================
  // PERFORMANCE HELPERS
  // ============================================================

  /// Show ID'sinden Show nesnesini hızlı erişim için Map döndürür
  /// O(1) lookup için optimize edilmiş
  Map<String, Show> get showMap {
    if (relatedShows == null || relatedShows!.isEmpty) return {};
    return {for (final show in relatedShows!) show.id: show};
  }

  /// Event ID'sinden Event nesnesini hızlı erişim için Map döndürür
  /// O(1) lookup için optimize edilmiş
  Map<String, Event> get eventMap {
    if (relatedEvents == null || relatedEvents!.isEmpty) return {};
    return {for (final event in relatedEvents!) event.id: event};
  }

  /// Stage ID'sinden Stage nesnesini hızlı erişim için Map döndürür
  /// O(1) lookup için optimize edilmiş
  Map<String, Stage> get stageMap {
    if (relatedStages == null || relatedStages!.isEmpty) return {};
    return {for (final stage in relatedStages!) stage.id: stage};
  }

  // ============================================================
  // EQUALITY & HASH CODE
  // ============================================================

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is TicketState &&
        other.dataList == dataList &&
        other.dataSingle == dataSingle &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.relatedShows == relatedShows &&
        other.relatedEvents == relatedEvents &&
        other.relatedStages == relatedStages;
  }

  @override
  int get hashCode => Object.hash(
        dataList,
        dataSingle,
        isLoading,
        errorMessage,
        relatedShows,
        relatedEvents,
        relatedStages,
      );

  // ============================================================
  // DEBUG & LOGGING
  // ============================================================

  @override
  String toString() => 'TicketState('
      'tickets: ${dataList?.length ?? 0}, '
      'shows: ${relatedShows?.length ?? 0}, '
      'events: ${relatedEvents?.length ?? 0}, '
      'stages: ${relatedStages?.length ?? 0}, '
      'isLoading: $isLoading, '
      'hasError: $hasError, '
      'isFullyLoaded: $isFullyLoaded'
      ')';

  /// Debug bilgisi - Development'ta kullanım için
  String toDebugString() {
    final buffer = StringBuffer();
    buffer.writeln('=== TicketState Debug Info ===');
    buffer.writeln('Tickets: ${dataList?.length ?? 0}');
    buffer.writeln('Shows: ${relatedShows?.length ?? 0}');
    buffer.writeln('Events: ${relatedEvents?.length ?? 0}');
    buffer.writeln('Stages: ${relatedStages?.length ?? 0}');
    buffer.writeln('Is Loading: $isLoading');
    buffer.writeln('Has Error: $hasError');
    buffer.writeln('Error Message: ${errorMessage ?? 'None'}');
    buffer.writeln('Is Fully Loaded: $isFullyLoaded');
    buffer.writeln('Is Empty: $isEmpty');
    buffer.writeln('Is Success: $isSuccess');
    buffer.writeln('============================');
    return buffer.toString();
  }
}

/// Extension methods for List<Ticket>
extension TicketListExtensions on List<Ticket> {
  /// Aktif biletleri filtreler (Date kontrolü yapmaz, UI katmanında yapılır)
  List<Ticket> get active => where((final t) => !t.isPast).toList();

  /// Toplam bilet fiyatını hesaplar
  //double get totalPrice => fold(0.0, (final sum, final ticket) => sum + ticket.orderPrice);

  /// Benzersiz show ID'lerini döndürür
  Set<String> get uniqueShowIds => map((final t) => t.showId).toSet();

  /// Benzersiz events ID'lerini döndürür
  Set<String> get uniqueEventIds => map((final t) => t.eventId).toSet();

  /// Benzersiz stages ID'lerini döndürür
  Set<String> get uniqueStageIds => map((final t) => t.stageId).toSet();
}

/// Extension methods for TicketState
extension TicketStateExtensions on TicketState {
  /// State'i temizler (reset)
  TicketState clear() => const TicketState();

  /// Loading state'e geçirir (mevcut verileri koruyarak)
  TicketState toLoading() => copyWith(isLoading: true, errorMessage: null);

  /// Error state'e geçirir
  TicketState toError(final String error) =>
      copyWith(isLoading: false, errorMessage: error);

  /// Success state'e geçirir
  TicketState toSuccess() => copyWith(isLoading: false, errorMessage: null);
}
