import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/show.dart';
import 'show_provider.dart';

part 'show_mutation_provider.g.dart';

@riverpod
class ShowMutation extends _$ShowMutation {
  @override
  FutureOr<void> build() {
    // Başlangıçta boş, bir state tutmamıza gerek yok.
    // Loading/Error durumlarını AsyncValue zaten yönetir.
  }

  /// ➕ EKLEME İŞLEMİ
  Future<void> addShow(
      {required final Show show, required final File? imageFile}) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(addShowUseCaseProvider).call(show, imageFile).getOrThrow();
      ref.invalidate(showsProvider);
    });
  }

  /// 🗑️ SİLME İŞLEMİ
  Future<void> deleteShow(final String showId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(deleteShowUseCaseProvider).call(showId).getOrThrow();

      // Başarılı olursa listeyi yenile
      ref.invalidate(showsProvider);
      // Eğer arama sonuçlarında da varsa orayı da yenilemek isteyebilirsin
      // ref.invalidate(searchShowsProvider);
    });
  }

  /// 🔄 GÜNCELLEME İŞLEMİ
  Future<void> updateShow(
      {required final String showId,
      required final Map<String, dynamic> updatedData}) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref
          .read(updateShowUseCaseProvider)
          .call(showId, updatedData)
          .getOrThrow();

      ref.invalidate(showsProvider);
      ref.invalidate(showsByIdsProvider); // Detay sayfası açıksa yenilensin
    });
  }
}
