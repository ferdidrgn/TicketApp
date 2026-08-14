import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/base/base_repo.dart';
import '../../domain/entities/show.dart';
import '../../domain/repositories/show_repository.dart';
import '../datasources/show_remote_data_source_and_impl.dart';
import '../mappers/show_mapper.dart';

class ShowRepositoryImpl extends BaseRepository implements ShowRepository {
  final ShowRemoteDataSource remoteDataSource;

  ShowRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Show>>> getSearchShow(final String? query,
      final List<String> categories, final String? type) {
    return execute(() async {
      final models = await remoteDataSource.getSearchShow(query, categories, type);

      // 🔥 Mapper kullanımı (Extension)
      return models.map((final model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<Show>>> getShows(final bool isLimit) {
    return execute(() async {
      final models = await remoteDataSource.getShows(isLimit);
      return models.map((final model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<Show>>> getShowsByIds(
      final List<String> showIds) {
    if (showIds.isEmpty) return Future.value(const Right([]));

    return execute(() async {
      final models = await remoteDataSource.getShowsByIds(showIds);
      return models.map((final model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, bool>> addShow(
      final Show show, final File? imageFile) {
    if (imageFile == null) throw Exception('Image URL cannot be null');

    return execute(() async {
      // Entity -> Model dönüşümü Mapper ile
      final model = show.toModel();
      return remoteDataSource.addShow(model, imageFile);
    });
  }

  @override
  Future<Either<Failure, bool>> deleteShow(final String showId) {
    if (showId.isEmpty)
      return Future.value(const Left(ServerFailure('Invalid ID')));
    return execute(() => remoteDataSource.deleteShow(showId));
  }

  @override
  Future<Either<Failure, bool>> updateShow(
      final String showId, final Map<String, dynamic> updatedData) {
    if (showId.isEmpty)
      return Future.value(const Left(ServerFailure('Invalid ID')));
    return execute(() => remoteDataSource.updateShow(showId, updatedData));
  }
}
