import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../core/network/internet_service.dart';

abstract class BaseRepository {
  final InternetService internetService;

  BaseRepository({required this.internetService});

  Future<Either<Failure, T>> execute<T>(
      final Future<T> Function() action) async {
    if (await internetService.isConnected) {
      try {
        final result = await action();
        if ((result is List && result.isEmpty) || result == null)
          return Left(ServerFailure('No data found'));
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else
      return const Left(NetworkFailure('İnternet Bağlantısı Bulunamamıştır'));
  }
}
