import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../../../core/errors/failures.dart';
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
Future<List<Show>> searchShows(final Ref ref,
        {required final List<String> categories, final String? type}) async =>
    ref.watch(getSearchShowUseCaseProvider).call(categories, type).getOrThrow();

/// 🆔 ID LİSTESİNE GÖRE ÇEKER
/// Kullanım: ref.watch(showsByIdsProvider(['id1', 'id2']))
@riverpod
Future<List<Show>> showsByIds(final Ref ref, final List<String> ids) async =>
    ref.watch(getShowsByIdsUseCaseProvider).call(ids).getOrThrow();
