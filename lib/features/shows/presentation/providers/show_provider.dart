import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../data/repositories/show_repository_provider.dart';
import '../../domain/entities/show.dart';
import '../../domain/usecases/add_show_use_case_impl.dart';
import '../../domain/usecases/delete_show_use_case_impl.dart';
import '../../domain/usecases/get_search_show_use_case_impl.dart';
import '../../domain/usecases/get_shows_by_ids_use_case_impl.dart';
import '../../domain/usecases/get_shows_use_case_impl.dart';
import '../../domain/usecases/update_show_use_case_impl.dart';

part 'show_provider.g.dart';

// ==============================================================================
// 1. USE CASE PROVIDERS (Dependency Injection)
// ==============================================================================

@riverpod
AddShowUseCase addShowUseCase(final Ref ref) =>
    AddShowUseCaseImpl(ref.watch(showRepositoryProvider));

@riverpod
DeleteShowUseCase deleteShowUseCase(final Ref ref) =>
    DeleteShowUseCaseImpl(ref.watch(showRepositoryProvider));

@riverpod
UpdateShowUseCase updateShowUseCase(final Ref ref) =>
    UpdateShowUseCaseImpl(ref.watch(showRepositoryProvider));

@riverpod
GetShowsUseCase getShowsUseCase(final Ref ref) =>
    GetShowsUseCaseImpl(ref.watch(showRepositoryProvider));

@riverpod
GetShowsByIdsUseCase getShowsByIdsUseCase(final Ref ref) =>
    GetShowsByIdsUseCaseImpl(ref.watch(showRepositoryProvider));

@riverpod
GetSearchShowUseCase getSearchShowUseCase(final Ref ref) =>
    GetSearchShowUseCaseImpl(ref.watch(showRepositoryProvider));

// ==============================================================================
// 2. DATA PROVIDERS (READ ONLY)
// ==============================================================================

/// 🔥 TÜM GÖSTERİLERİ ÇEKER
/// Parametre: isLimit (bool)
/// Kullanım: ref.watch(showsProvider(true))
@riverpod
Future<List<Show>> shows(final Ref ref, {required final bool isLimit}) async =>
    ref.watch(getShowsUseCaseProvider).call(isLimit).getOrThrow();

/// 🔍 ARAMA SONUÇLARINI ÇEKER
/// Parametreler family olarak geçilir.
/// Kullanım: ref.watch(searchShowsProvider(categories: ['Tiyatro'], type: 'Dram'))
@riverpod
Future<List<Show>> searchShows(final Ref ref, final String? query,
        {required final List<String> categories, final String? type}) async =>
    ref.watch(getSearchShowUseCaseProvider).call(query, categories, type).getOrThrow();

/// 🆔 ID LİSTESİNE GÖRE ÇEKER
/// Kullanım: ref.watch(showsByIdsProvider(['id1', 'id2']))
@riverpod
Future<List<Show>> showsByIds(final Ref ref, final List<String> ids) async =>
    ref.watch(getShowsByIdsUseCaseProvider).call(ids).getOrThrow();

// ==============================================================================
// 3. TÜRETİLMİŞ (COMPUTED) PROVIDER'LAR — "AKTİF" OYUN KAVRAMI
// ==============================================================================
//
// Firestore'da "isActive" gibi elle tutulan bir alan YOK — kasıtlı olarak
// eklenmedi. Böyle bir bayrak, bir oyunun son etkinliği geçtiğinde birinin
// onu elle "false" yapmayı unutmasıyla kolayca gerçekle uyuşmaz hale gelir
// (ve senkron tutulması gereken ekstra bir yazma-yolu demektir). Onun
// yerine "aktiflik" mevcut `Show.eventsId` + `Event.date` alanlarından
// CANLI hesaplanıyor — `landing/app.js`'teki `upcomingEvents()` ile aynı
// mantık: bir oyunun takviminde bugünden sonraki en az bir etkinliği varsa
// aktiftir; hepsi geçmişte kaldıysa ya da hiç etkinliği yoksa değildir.
//
// Bu iki provider `@riverpod` kod üretimi KULLANMIYOR (bilerek) — bu
// sandbox'ta `build_runner` çalıştırılamıyor, `showsProvider`/`shows...`
// gibi diğerleri gibi otomatik bir `.g.dart` parçası gerektirseydi elle
// güncellenmiş sahte bir generated dosya yazmak riskli olurdu. Klasik
// `FutureProvider.family` API'si (flutter_riverpod) ek kod üretimi
// gerektirmeden derlenir, bu yüzden burada onu kullanıyoruz. Kullanım
// şekli SADECE bu yüzden farklı: `activeShowsProvider(true)` (isim
// olmadan pozisyonel bool), `showsProvider(isLimit: true)` gibi değil.
//
// NOT: `isLimit: true` iken önce Firestore'dan en fazla 20 oyun çekilip
// SONRA aktiflik filtresi uygulanıyor (showsProvider'ın kendi limitini
// aynen kullanıyor) — yani "aktif 20 oyun" değil, "en yeni 20 oyunun
// aktif olanları" garantisi var. Ana sayfa/vitrin gibi "son eklenenler"
// bağlamları için doğru davranış bu; sonucun 20'den az (hatta 0) olması
// olağan ve beklenen bir durumdur.

Future<Set<String>> _activeShowIdsFromEvents(
    final Ref ref, final List<Show> shows) async {
  final eventIds = shows
      .expand((final s) => s.eventsId)
      .where((final id) => id.isNotEmpty)
      .toSet()
      .toList();
  if (eventIds.isEmpty) return {};

  final events = await ref.watch(eventsByIdsProvider(eventIds).future);
  final now = DateTime.now();
  final activeIds = <String>{};
  for (final event in events) {
    final date = DateFormatter.parseDateString(event.date);
    if (date != null && date.isAfter(now)) activeIds.add(event.showId);
  }
  return activeIds;
}

/// 🟢 AKTİF OYUNLAR — takviminde en az bir gelecek etkinliği olanlar.
/// Ana sayfa/öneriler/keşfet'in VARSAYILAN listesi bu olmalı, ham
/// `showsProvider` değil.
/// Kullanım: `ref.watch(activeShowsProvider(true))`
final activeShowsProvider =
    FutureProvider.family<List<Show>, bool>((final ref, final isLimit) async {
  final shows = await ref.watch(showsProvider(isLimit: isLimit).future);
  if (shows.isEmpty) return [];
  final activeIds = await _activeShowIdsFromEvents(ref, shows);
  return shows.where((final s) => activeIds.contains(s.id)).toList();
});

/// 🔴 GEÇMİŞ OYUNLAR — tüm etkinlikleri geçmişte kalmış (ya da hiç
/// etkinliği hiç olmamış) oyunlar. "Geçmiş Oyunlar" arşiv görünümü gibi
/// bir yer için — varsayılan listelerde KULLANILMAMALI.
/// Kullanım: `ref.watch(pastShowsProvider(false))`
final pastShowsProvider =
    FutureProvider.family<List<Show>, bool>((final ref, final isLimit) async {
  final shows = await ref.watch(showsProvider(isLimit: isLimit).future);
  if (shows.isEmpty) return [];
  final activeIds = await _activeShowIdsFromEvents(ref, shows);
  return shows.where((final s) => !activeIds.contains(s.id)).toList();
});
