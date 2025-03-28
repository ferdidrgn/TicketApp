import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../core/common/base_repo.dart';
import '../../../domain/repository/show_repository.dart';
import '../../datasources/show/show_remote_data_source_and_impl.dart';
import '../../model/show_model.dart';

class ShowRepositoryImpl extends BaseRepository implements ShowRepository {
  final ShowRemoteDataSource remoteDataSource;

  ShowRepositoryImpl({
    required this.remoteDataSource,
    required super.internetService,
  });

  @override
  Future<Either<Failure, List<ShowModel?>?>> getSearchShow(
      final List<String> categories, final String? type) async {
    return execute(() async {
      return remoteDataSource.getSearchShow(categories, type);
    });
  }

  @override
  Future<Either<Failure, List<ShowModel?>?>> getShows(final isLimit) async {
    return execute(() async {
      if (isLimit == null) throw Exception('isLimit is null');
      return remoteDataSource.getShows(isLimit);
    });
  }

  @override
  Future<Either<Failure, List<ShowModel?>?>> getShowsByIds(
      final List<String> showsIds) async {
    return execute(() async {
      if (showsIds.isEmpty) throw Exception('showsIds is empty');
      return remoteDataSource.getShowsByIds(showsIds);
    });
  }

  @override
  Future<Either<Failure, void>> addShow(final ShowModel show,
      final Uri? showIdAddOrUpdateImgUrl) async {
    return execute(() async {
      if (showIdAddOrUpdateImgUrl == null) throw Exception(
          'showIdAddOrUpdateImgUrl is null');
      await remoteDataSource.addShow(show, showIdAddOrUpdateImgUrl);
    });
  }

  @override
  Future<Either<Failure, void>> deleteShow(final String? showId) async {
    return execute(() async {
      if (showId == null) throw Exception('showId is null');
      await remoteDataSource.deleteShow(showId);
    });
  }

  @override
  Future<Either<Failure, void>> updateShow(final String showId,
      final Map<String, dynamic> updatedData) async {
    return execute(() async {
      if (showId.isEmpty) throw Exception('showId is empty');
      await remoteDataSource.updateShow(showId, updatedData);
    });
  }
}
