import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class BaseRepository {
  /// Internet kontrolü YOK - sadece try/catch
  /// Network hatası zaten SocketException olarak yakalanacak
  Future<Either<Failure, T>> execute<T>(
      final Future<T> Function() action) async {
    try {
      final result = await action();
      return Right(result);
    } on SocketException {
      // İnternet yoksa veya sunucuya ulaşılamıyorsa
      return const Left(NetworkFailure('Bağlantı hatası'));
    } on HttpException catch (e) {
      return Left(ServerFailure('HTTP Hatası: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

/*
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
      return const Left(NetworkFailure('İnternet Bağlantısı Bulunamadı'));
  }
} */
