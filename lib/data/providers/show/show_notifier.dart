import 'package:ticketapp/data/providers/show/show_provider.dart';
import '../../../core/common/base_notifier_with_network_checker.dart';
import '../../../domain/entities/show.dart';
import '../../model/show_model.dart';
import 'show_state.dart';

class ShowNotifier extends BaseNotifierWithNetworkChecker<ShowState> {
  @override
  ShowState initialState() => const ShowState();

  @override
  void reloadData() => loadShows(false);

  Future<void> addShow(final ShowModel show, final Uri? imageUrl) =>
      executeWithInternetCheck(
          () => ref.read(addShowUseCaseProvider).call(show, imageUrl),
          onSuccess: (final _) {});

  Future<void> deleteShow(final String? showId) => executeWithInternetCheck(
      () => ref.read(deleteShowUseCaseProvider).call(showId),
      onSuccess: (final _) {});

  Future<void> updateShow(
          final String showId, final Map<String, dynamic> updatedData) =>
      executeWithInternetCheck(
          () => ref.read(updateShowUseCaseProvider).call(showId, updatedData),
          onSuccess: (final _) {});

  Future<void> loadShowsByIds(final List<String> showsIds) =>
      executeWithInternetCheck(
          () => ref.read(getShowsByIdsUseCaseProvider).call(showsIds),
          onSuccess: (final shows) => _setShowLoaded(shows));

  Future<void> loadShows(final bool isLimit) => executeWithInternetCheck(
      () => ref.read(getShowsUseCaseProvider).call(isLimit),
      onSuccess: (final shows) => _setShowLoaded(shows));

  Future<void> searchShows(final List<String> categories, final String? type) =>
      executeWithInternetCheck(
          () => ref.read(getSearchShowUseCaseProvider).call(categories, type),
          onSuccess: (final shows) => _setShowLoaded(shows));

  void clearShows() =>
      state = state.copyWith(dataList: const [], dataSingle: null);

  void _setShowLoaded(final List<Show>? shows) => state = state.copyWith(
      dataList: shows,
      dataSingle: shows?.length == 1 ? shows!.first : state.dataSingle,
      errorMessage: null);
}

/// ShowState için extension metodlar
extension ShowStateX on ShowState {
  bool hasShow(final String showId) {
    if (dataList == null) return false;
    return dataList!.any((final show) => show.id == showId);
  }

  Show? getShowById(final String showId) {
    if (dataList == null) return null;
    try {
      return dataList!.firstWhere((final show) => show.id == showId);
    } catch (_) {
      return null;
    }
  }

  int get showCount => dataList?.length ?? 0;

  bool get hasData => dataList != null && dataList!.isNotEmpty;

  List<String> get showIds =>
      dataList?.map((final show) => show.id).toList() ?? [];
}

// ==============================================================================
// USAGE EXAMPLES
// ==============================================================================

/// Example 1: Load all shows
/// ```dart
/// final notifier = ref.read(showProvider.notifier);
/// await notifier.loadShows(isLimit: false);
/// ```
///
/// Example 2: Load shows by specific IDs
/// ```dart
/// final showIds = ['show1', 'show2'];
/// await notifier.loadShowsByIds(showIds);
/// ```
///
/// Example 3: Add a new show
/// ```dart
/// await notifier.addShow(showModel, imageUri);
/// ```
///
/// Example 4: Update a show
/// ```dart
/// await notifier.updateShow(showId, updatedDataMap);
/// ```
///
/// Example 5: Delete a show
/// ```dart
/// await notifier.deleteShow(showId);
/// ```
///
/// Example 6: Search shows
/// ```dart
/// await notifier.searchShows(['category1'], 'typeA');
/// ```
///
/// Example 7: Clear shows
/// ```dart
/// notifier.clearShows();
/// ```
///
/// Example 8: Extension usage
/// ```dart
/// final hasShow = notifier.state.hasShow('show123');
/// final show = notifier.state.getShowById('show123');
/// final total = notifier.state.showCount;
/// ```
