import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../events/domain/entities/event.dart';
import '../../domain/entities/show.dart';
import 'show_provider.dart';

part 'show_filter_provider.g.dart';

// ==============================================================================
// GERÇEK, HIZLI (CLIENT-SIDE) FİLTRELEME ALTYAPISI — Keşfet/Arama
// ==============================================================================
//
// Her filtre değişikliğinde Firestore'a gitmiyor: temel liste zaten
// `showsActiveFirstProvider`/`activeShowsProvider` + `eventsByShowMapProvider`
// (ikisi de show_provider.dart'taki GERÇEK, tek doğruluk kaynağı olan
// Event.showId/Show.eventsId birleştirme mantığını kullanıyor — burada asla
// yeniden uygulanmadı) üzerinden BİR KEZ çekiliyor; kategori/tarih/fiyat/
// sahne/arama/sıralama tamamen bellek içinde, senkron uygulanıyor. Bu yüzden
// bir checkbox'a tıklamak ya da fiyat slider'ını sürüklemek ağ gecikmesi
// olmadan anında sonuç veriyor.
//
// Metin arama (searchShowsProvider, show_search_provider.dart) BİLEREK
// buraya taşınmadı/tekrar yazılmadı — o hâlâ gerçek Firestore prefix-arama
// sorgusu (büyük veri setlerinde ölçeklenmesi gereken tek boyut); burada
// `ShowFilterState.searchQuery` sadece o an bellekte olan (zaten aktif
// filtrelerden geçmiş) listeyi ada göre daraltan tamamlayıcı, anlık bir
// istemci-taraflı arama.

enum ShowSortOrder {
  /// showsActiveFirstProvider'ın kendi sırası (aktif oyunlar önce, gerisi
  /// arkada) — varsayılan, uydurma bir "popülerlik" skoru İCAT ETMEZ.
  recommended,
  dateAscending,
  priceAscending,
  priceDescending,
  alphabetical,
}

@immutable
class ShowFilterState {
  final Set<String> categories;
  final Set<String> types;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? minPrice;
  final double? maxPrice;
  final String? stageId;
  final bool activeOnly;
  final ShowSortOrder sortOrder;
  final String searchQuery;

  const ShowFilterState({
    this.categories = const {},
    this.types = const {},
    this.dateFrom,
    this.dateTo,
    this.minPrice,
    this.maxPrice,
    this.stageId,
    this.activeOnly = true,
    this.sortOrder = ShowSortOrder.recommended,
    this.searchQuery = '',
  });

  bool get hasActiveFilters =>
      categories.isNotEmpty ||
      types.isNotEmpty ||
      dateFrom != null ||
      dateTo != null ||
      minPrice != null ||
      maxPrice != null ||
      stageId != null ||
      !activeOnly ||
      sortOrder != ShowSortOrder.recommended ||
      searchQuery.trim().isNotEmpty;

  ShowFilterState copyWith({
    final Set<String>? categories,
    final Set<String>? types,
    final DateTime? dateFrom,
    final bool clearDateFrom = false,
    final DateTime? dateTo,
    final bool clearDateTo = false,
    final double? minPrice,
    final bool clearMinPrice = false,
    final double? maxPrice,
    final bool clearMaxPrice = false,
    final String? stageId,
    final bool clearStageId = false,
    final bool? activeOnly,
    final ShowSortOrder? sortOrder,
    final String? searchQuery,
  }) =>
      ShowFilterState(
        categories: categories ?? this.categories,
        types: types ?? this.types,
        dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
        dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
        minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
        maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
        stageId: clearStageId ? null : (stageId ?? this.stageId),
        activeOnly: activeOnly ?? this.activeOnly,
        sortOrder: sortOrder ?? this.sortOrder,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ShowFilterState &&
          runtimeType == other.runtimeType &&
          categories.length == other.categories.length &&
          categories.containsAll(other.categories) &&
          types.length == other.types.length &&
          types.containsAll(other.types) &&
          dateFrom == other.dateFrom &&
          dateTo == other.dateTo &&
          minPrice == other.minPrice &&
          maxPrice == other.maxPrice &&
          stageId == other.stageId &&
          activeOnly == other.activeOnly &&
          sortOrder == other.sortOrder &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(categories),
        Object.hashAllUnordered(types),
        dateFrom,
        dateTo,
        minPrice,
        maxPrice,
        stageId,
        activeOnly,
        sortOrder,
        searchQuery,
      );
}

@riverpod
class ShowFilterController extends _$ShowFilterController {
  @override
  ShowFilterState build() => const ShowFilterState();

  void toggleCategory(final String category) {
    final next = {...state.categories};
    next.contains(category) ? next.remove(category) : next.add(category);
    state = state.copyWith(categories: next);
  }

  void toggleType(final String type) {
    final next = {...state.types};
    next.contains(type) ? next.remove(type) : next.add(type);
    state = state.copyWith(types: next);
  }

  void setDateRange(final DateTime? from, final DateTime? to) {
    state = state.copyWith(
      dateFrom: from,
      clearDateFrom: from == null,
      dateTo: to,
      clearDateTo: to == null,
    );
  }

  void setPriceRange(final double? min, final double? max) {
    state = state.copyWith(
      minPrice: min,
      clearMinPrice: min == null,
      maxPrice: max,
      clearMaxPrice: max == null,
    );
  }

  void setStage(final String? stageId) {
    state = state.copyWith(stageId: stageId, clearStageId: stageId == null);
  }

  void setActiveOnly(final bool value) {
    state = state.copyWith(activeOnly: value);
  }

  void setSortOrder(final ShowSortOrder order) {
    state = state.copyWith(sortOrder: order);
  }

  void setSearchQuery(final String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearAll() => state = const ShowFilterState();
}

/// Filtrelenmiş sonuçta her gösteri, filtreye uyan GERÇEK en yakın gelecek
/// etkinliğiyle ve GERÇEK en düşük fiyatıyla birlikte döner — kart UI'ının
/// "20 Eylül · 350 TL'den başlayan fiyatlarla" gibi bilgiyi göstermek için
/// ekstra bir sorgu atmasına gerek kalmaz.
@immutable
class FilteredShow {
  final Show show;
  final Event? nextEvent;
  final double? lowestPrice;

  const FilteredShow({required this.show, this.nextEvent, this.lowestPrice});
}

@riverpod
Future<List<FilteredShow>> filteredShows(final Ref ref) async {
  final filter = ref.watch(showFilterControllerProvider);

  final baseShows = filter.activeOnly
      ? await ref.watch(activeShowsProvider(false).future)
      : await ref.watch(showsActiveFirstProvider(false).future);
  if (baseShows.isEmpty) return [];

  final eventsByShow = await ref.watch(eventsByShowMapProvider(false).future);
  final now = DateTime.now();
  final query = filter.searchQuery.trim().toLowerCase();

  final hasExtraFilters = filter.dateFrom != null ||
      filter.dateTo != null ||
      filter.stageId != null ||
      filter.minPrice != null ||
      filter.maxPrice != null;

  final results = <FilteredShow>[];

  for (final show in baseShows) {
    if (filter.categories.isNotEmpty &&
        !filter.categories.contains(show.category)) continue;
    if (filter.types.isNotEmpty && !filter.types.contains(show.type)) continue;
    if (query.isNotEmpty && !show.name.toLowerCase().contains(query)) continue;

    final allEvents = eventsByShow[show.id] ?? const <Event>[];

    final matchingEvents = allEvents.where((final event) {
      final date = DateFormatter.parseDateString(event.date);
      if (filter.dateFrom != null &&
          (date == null || date.isBefore(filter.dateFrom!))) return false;
      if (filter.dateTo != null &&
          (date == null || date.isAfter(filter.dateTo!))) return false;
      if (filter.stageId != null && event.stageId != filter.stageId) {
        return false;
      }
      if (filter.minPrice != null || filter.maxPrice != null) {
        final price = double.tryParse(event.price);
        if (price == null) return false;
        if (filter.minPrice != null && price < filter.minPrice!) {
          return false;
        }
        if (filter.maxPrice != null && price > filter.maxPrice!) {
          return false;
        }
      }
      return true;
    }).toList();

    // Tarih/fiyat/sahne gibi ek bir filtre AKTİFSE ve bu gösterinin buna
    // uyan hiç GERÇEK etkinliği yoksa, gösteri tamamen gizlenir — sahte bir
    // "en yakın tarih yok" satırı göstermek yerine.
    if (hasExtraFilters && matchingEvents.isEmpty) continue;

    final relevantEvents = hasExtraFilters ? matchingEvents : allEvents;

    final futureMatching = matchingEvents
        .map((final e) => (event: e, date: DateFormatter.parseDateString(e.date)))
        .where((final e) => e.date != null && e.date!.isAfter(now))
        .toList()
      ..sort((final a, final b) => a.date!.compareTo(b.date!));

    double? lowestPrice;
    for (final event in relevantEvents) {
      final price = double.tryParse(event.price);
      if (price == null) continue;
      if (lowestPrice == null || price < lowestPrice) lowestPrice = price;
    }

    results.add(FilteredShow(
      show: show,
      nextEvent: futureMatching.isNotEmpty ? futureMatching.first.event : null,
      lowestPrice: lowestPrice,
    ));
  }

  switch (filter.sortOrder) {
    case ShowSortOrder.recommended:
      break; // baseShows sırası zaten korunuyor (aktif önce)
    case ShowSortOrder.dateAscending:
      results.sort((final a, final b) {
        final da = a.nextEvent != null
            ? DateFormatter.parseDateString(a.nextEvent!.date)
            : null;
        final db = b.nextEvent != null
            ? DateFormatter.parseDateString(b.nextEvent!.date)
            : null;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
      break;
    case ShowSortOrder.priceAscending:
      results.sort((final a, final b) =>
          (a.lowestPrice ?? double.infinity)
              .compareTo(b.lowestPrice ?? double.infinity));
      break;
    case ShowSortOrder.priceDescending:
      results.sort((final a, final b) =>
          (b.lowestPrice ?? -1).compareTo(a.lowestPrice ?? -1));
      break;
    case ShowSortOrder.alphabetical:
      results.sort((final a, final b) => a.show.name.compareTo(b.show.name));
      break;
  }

  return results;
}

/// Fiyat aralığı slider'ının GERÇEK alt/üst sınırı — sabit bir "0-2000 TL"
/// tahmini DEĞİL, o an var olan tüm gerçek etkinliklerin (`Event.price`)
/// en düşük/en yüksek değerinden hesaplanır. Hiç fiyatlı etkinlik yoksa
/// `null` döner — UI bu durumda fiyat filtresini tamamen gizlemeli.
@riverpod
Future<({double min, double max})?> priceRangeBounds(final Ref ref) async {
  final eventsByShow = await ref.watch(eventsByShowMapProvider(false).future);
  double? min;
  double? max;
  for (final events in eventsByShow.values) {
    for (final event in events) {
      final price = double.tryParse(event.price);
      if (price == null) continue;
      if (min == null || price < min) min = price;
      if (max == null || price > max) max = price;
    }
  }
  if (min == null || max == null) return null;
  return (min: min, max: max);
}

/// Filtre UI'ının kategori/tür seçeneklerini doldurmak için — sabit,
/// uydurma bir liste DEĞİL; o an gerçekten var olan gösterilerin kendi
/// `category`/`type` alanlarından türetilir. Yeni bir kategori Firestore'a
/// eklendiği an burada da otomatik görünür.
@riverpod
Future<({List<String> categories, List<String> types})>
    availableShowFilterOptions(final Ref ref) async {
  final shows = await ref.watch(showsActiveFirstProvider(false).future);
  final categories = shows
      .map((final s) => s.category.trim())
      .where((final c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  final types = shows
      .map((final s) => s.type.trim())
      .where((final t) => t.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return (categories: categories, types: types);
}
