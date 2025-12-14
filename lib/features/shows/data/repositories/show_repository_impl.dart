import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../core/common/base_repo.dart';
import '../../domain/repositories/show_repository.dart';
import '../datasources/show_remote_data_source_and_impl.dart';
import '../models/show_model.dart';

class ShowRepositoryImpl extends BaseRepository implements ShowRepository {
  final ShowRemoteDataSource remoteDataSource;

  ShowRepositoryImpl({
    required this.remoteDataSource,
    //required super.internetService,
  });

  @override
  Future<Either<Failure, List<ShowModel?>?>> getSearchShow(
          final List<String> categories, final String? type) =>
      execute(() => remoteDataSource.getSearchShow(categories, type));

  @override
  Future<Either<Failure, List<ShowModel?>?>> getShows(final bool isLimit) =>
      execute(() => remoteDataSource.getShows(isLimit));

  @override
  Future<Either<Failure, List<ShowModel?>?>> getShowsByIds(
      final List<String> showIds) {
    if (showIds.isEmpty) throw Exception('showIds cannot be empty');
    return execute(() => remoteDataSource.getShowsByIds(showIds));
  }

  @override
  Future<Either<Failure, bool>> addShow(
      final ShowModel show, final Uri? showIdAddOrUpdateImgUrl) {
    if (showIdAddOrUpdateImgUrl == null)
      throw Exception('showIdAddOrUpdateImgUrl cannot be null');
    return execute(
        () => remoteDataSource.addShow(show, showIdAddOrUpdateImgUrl));
  }

  @override
  Future<Either<Failure, bool>> deleteShow(final String? showId) {
    if (showId == null) throw Exception('showId cannot be null');
    return execute(() => remoteDataSource.deleteShow(showId));
  }

  @override
  Future<Either<Failure, bool>> updateShow(
      final String showId, final Map<String, dynamic> updatedData) {
    if (showId.isEmpty) throw Exception('showId cannot be empty');
    return execute(() => remoteDataSource.updateShow(showId, updatedData));
  }
}
