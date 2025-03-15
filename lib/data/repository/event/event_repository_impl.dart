import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/repository/event_repository.dart';
import '../../datasources/event/event_remote_data_source_and_impl.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource remoteDataSource;
  final InternetService internetService;

  EventRepositoryImpl({
    required this.remoteDataSource,
    required this.internetService,
  });

  @override
  Future<Either<Failure, void>> initializeAndGetEventSeats(final String? eventId) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.initializeAndGetEventSeats(eventId!);
        return const Right(null); // Başarılı
      } catch (e) {
        return Left(ServerFailure(e.toString())); // Hata
      }
    } else {
      return const Left(NetworkFailure('No internet connection')); // Hata
    }
  }

  @override
  Future<Either<Failure, Map<String, Map<String, dynamic>>>> getSeatStatusByEvent(final String? eventId) async {
    if (await internetService.isConnected) {
      try {
        final seatStatus = await remoteDataSource.getSeatStatusByEvent(eventId!);
        return Right(seatStatus); // Başarılı
      } catch (e) {
        return Left(ServerFailure(e.toString())); // Hata
      }
    } else {
      return const Left(NetworkFailure('No internet connection')); // Hata
    }
  }

  @override
  Future<Either<Failure, List<String>>> getPurchasedSeatsByCustomerId(final String? eventId, final String? customerId) async {
    if (await internetService.isConnected) {
      try {
        final purchasedSeats = await remoteDataSource.getPurchasedSeatsByCustomerId(eventId, customerId);
        return Right(purchasedSeats); // Başarılı
      } catch (e) {
        return Left(ServerFailure(e.toString())); // Hata
      }
    } else {
      return const Left(NetworkFailure('No internet connection')); // Hata
    }
  }

  @override
  Future<Either<Failure, void>> updateSeatStatus(final String eventId, final String seatId, final String status, {final String? customerId}) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.updateSeatStatus(eventId, seatId, status, customerId: customerId);
        return const Right(null); // Başarılı
      } catch (e) {
        return Left(ServerFailure(e.toString())); // Hata
      }
    } else {
      return const Left(NetworkFailure('No internet connection')); // Hata
    }
  }

  @override
  Future<Either<Failure, String>> getStageId(final String eventId) async {
    if (await internetService.isConnected) {
      try {
        final stageId = await remoteDataSource.getStageId(eventId);
        return Right(stageId); // Başarılı
      } catch (e) {
        return Left(ServerFailure(e.toString())); // Hata
      }
    } else {
      return const Left(NetworkFailure('No internet connection')); // Hata
    }
  }

  @override
  Future<Either<Failure, String?>> getEventPrice(final String eventId) async {
    if (await internetService.isConnected) {
      try {
        final price = await remoteDataSource.getEventPrice(eventId);
        return Right(price); // Başarılı
      } catch (e) {
        return Left(ServerFailure(e.toString())); // Hata
      }
    } else {
      return const Left(NetworkFailure('No internet connection')); // Hata
    }
  }

  @override
  Future<Either<Failure, Map<String, String>?>> getEventDate(final String eventId, {final bool formatWithMonthName = false}) async {
    if (await internetService.isConnected) {
      try {
        final date = await remoteDataSource.getEventDate(eventId, formatWithMonthName: formatWithMonthName);
        return Right(date); // Başarılı
      } catch (e) {
        return Left(ServerFailure(e.toString())); // Hata
      }
    } else {
      return const Left(NetworkFailure('No internet connection')); // Hata
    }
  }

  @override
  Future<Either<Failure, void>> reserveSeat(final String eventId, final String seatId, final String customerId) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.reserveSeat(eventId, seatId, customerId);
        return const Right(null); // Başarılı
      } catch (e) {
        return Left(ServerFailure(e.toString())); // Hata
      }
    } else {
      return const Left(NetworkFailure('No internet connection')); // Hata
    }
  }

  @override
  Future<Either<Failure, void>> cancelReservation(final String eventId, final String seatId) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.cancelReservation(eventId, seatId);
        return const Right(null); // Başarılı
      } catch (e) {
        return Left(ServerFailure(e.toString())); // Hata
      }
    } else {
      return const Left(NetworkFailure('No internet connection')); // Hata
    }
  }
}
