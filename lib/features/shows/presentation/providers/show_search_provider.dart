import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ticketapp/core/errors/failures.dart';
import '../../domain/entities/show.dart';
import 'show_provider.dart';

part 'show_search_provider.g.dart';

@riverpod
class ShowSearch extends _$ShowSearch {
  /// Başlangıçta boş liste döner
  @override
  FutureOr<List<Show>> build() {
    return [];
  }

  /// 🔍 İSTEDİĞİN FONKSİYON (Manuel Tetikleme)
  Future<void> searchShows(
      final List<String> categories, final String? type) async {
    // 1. Loading durumuna çek
    state = const AsyncLoading();

    // 2. İsteği at ve sonucu state'e kaydet (execute yerine guard kullanıyoruz)
    state = await AsyncValue.guard(() async => ref
        .read(getSearchShowUseCaseProvider)
        .call(categories, type)
        .getOrThrow());
  }

  /// Listeyi temizlemek istersen
  void clearSearch() => state = const AsyncData([]);
}
