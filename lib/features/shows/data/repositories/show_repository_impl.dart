import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../core/base/base_repo.dart';
import '../../domain/entities/show.dart';
import '../../domain/repositories/show_repository.dart';
import '../datasources/show_remote_data_source_and_impl.dart';
import '../models/show_model.dart';

class ShowRepositoryImpl extends BaseRepository implements ShowRepository {
  final ShowRemoteDataSource remoteDataSource;

  ShowRepositoryImpl({required this.remoteDataSource});

  /// 🔍 ARAMA
  @override
  Future<Either<Failure, List<Show>>> getSearchShow(
      final List<String> categories, final String? type) {
    return execute(() async {
      // 1. Modelleri çek
      final models = await remoteDataSource.getSearchShow(categories, type);

      // 2. Model -> Entity Dönüşümü
      if (models == null) return [];
      return models
          .map((final model) => model?.toEntity())
          .whereType<Show>()
          .toList();
    });
  }

  /// 📺 LİSTELEME
  @override
  Future<Either<Failure, List<Show>>> getShows(final bool isLimit) {
    return execute(() async {
      final models = await remoteDataSource.getShows(isLimit);

      if (models == null) return [];
      return models
          .map((final model) => model?.toEntity())
          .whereType<Show>()
          .toList();
    });
  }

  /// 🆔 ID İLE GETİRME
  @override
  Future<Either<Failure, List<Show>>> getShowsByIds(
      final List<String> showIds) {
    if (showIds.isEmpty) {
      // Hata fırlatmak yerine boş liste dönmek daha güvenlidir, ama
      // ille de hata olsun dersen Left dönebilirsin.
      return Future.value(const Right([]));
    }

    return execute(() async {
      final models = await remoteDataSource.getShowsByIds(showIds);

      if (models == null) return [];
      return models
          .map((final model) => model?.toEntity())
          .whereType<Show>()
          .toList();
    });
  }

  /// ➕ EKLEME
  @override
  Future<Either<Failure, bool>> addShow(
      final Show show, final Uri? showIdAddOrUpdateImgUrl) {
    if (showIdAddOrUpdateImgUrl == null) {
      // BaseRepository execute metodu Exception yakalar ve Failure'a çevirir
      throw Exception('Image URL cannot be null');
    }

    return execute(() {
      // Entity'i Model'e çevirip DataSource'a veriyoruz
      // Not: ShowModel.fromEntity(show) gibi bir metodun olmalı
      final showModel = ShowModel.fromEntity(show);
      return remoteDataSource.addShow(showModel, showIdAddOrUpdateImgUrl);
    });
  }

  /// 🗑️ SİLME
  @override
  Future<Either<Failure, bool>> deleteShow(final String showId) {
    // String? yerine String kullandık, yine de empty kontrolü yapabiliriz
    if (showId.isEmpty) throw Exception('Show ID cannot be empty');

    return execute(() => remoteDataSource.deleteShow(showId));
  }

  /// 🔄 GÜNCELLEME
  @override
  Future<Either<Failure, bool>> updateShow(
      final String showId, final Map<String, dynamic> updatedData) {
    if (showId.isEmpty) throw Exception('Show ID cannot be empty');
    return execute(() => remoteDataSource.updateShow(showId, updatedData));
  }
}
