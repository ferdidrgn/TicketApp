import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/repository/show_repository.dart';
import '../../datasources/show/show_remote_data_source_and_impl.dart';
import '../../model/show_model.dart';

class ShowRepositoryImpl implements ShowRepository {
  final ShowRemoteDataSource remoteDataSource;
  final InternetService internetService;

  ShowRepositoryImpl({
    required this.remoteDataSource,
    required this.internetService,
  });

  @override
  Future<Either<Failure, List<ShowModel?>>> getSearchShow(
      final List<String?> categories, final String? type) async {
    if (await internetService.isConnected) {
      try {
        final shows = await remoteDataSource.getSearchShow(categories, type);
        return Right(shows);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<ShowModel?>>> getShows(final isLimit) async {
    if (await internetService.isConnected) {
      try {
        final shows = await remoteDataSource.getShows(isLimit);
        return Right(shows);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ShowModel?>> getShowById(final String showId) async {
    if (await internetService.isConnected) {
      try {
        final show = await remoteDataSource.getShowById(showId);
        return Right(show);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> addShow(
      final ShowModel show, final Uri? showIdAddOrUpdateImgUrl) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.addShow(show, showIdAddOrUpdateImgUrl);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteShow(final String? showId) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.deleteShow(showId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> updateShow(
      final String showId, final Map<String, dynamic> updatedData) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.updateShow(showId, updatedData);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}
