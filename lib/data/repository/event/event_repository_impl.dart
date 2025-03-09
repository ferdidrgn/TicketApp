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
  Future<void> initializeAndGetEventSeats(final String? eventId) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.initializeAndGetEventSeats(eventId);
      } catch (e) {
        throw ServerFailure(e.toString());
      }
    } else {
      throw NetworkFailure('No internet connection');
    }
  }

  @override
  Future<Map<String, Map<String, dynamic>>> getSeatStatusByEvent(final String? eventId) async {
    if (await internetService.isConnected) {
      try {
        return await remoteDataSource.getSeatStatusByEvent(eventId);
      } catch (e) {
        throw ServerFailure(e.toString());
      }
    } else {
      throw NetworkFailure('No internet connection');
    }
  }

  @override
  Future<List<String>> getPurchasedSeatsByCustomerId(final String? eventId, final String? customerId) async {
    if (await internetService.isConnected) {
      try {
        return await remoteDataSource.getPurchasedSeatsByCustomerId(eventId, customerId);
      } catch (e) {
        throw ServerFailure(e.toString());
      }
    } else {
      throw NetworkFailure('No internet connection');
    }
  }

  @override
  Future<void> updateSeatStatus(final String eventId, final String seatId, final String status, {final String? customerId}) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.updateSeatStatus(eventId, seatId, status, customerId: customerId);
      } catch (e) {
        throw ServerFailure(e.toString());
      }
    } else {
      throw NetworkFailure('No internet connection');
    }
  }

  @override
  Future<String> getStageId(final String eventId) async {
    if (await internetService.isConnected) {
      try {
        return await remoteDataSource.getStageId(eventId);
      } catch (e) {
        throw ServerFailure(e.toString());
      }
    } else {
      throw NetworkFailure('No internet connection');
    }
  }

  @override
  Future<String?> getEventPrice(final String eventId) async {
    if (await internetService.isConnected) {
      try {
        return await remoteDataSource.getEventPrice(eventId);
      } catch (e) {
        throw ServerFailure(e.toString());
      }
    } else {
      throw NetworkFailure('No internet connection');
    }
  }

  @override
  Future<Map<String, String>?> getEventDate(final String eventId, {final bool formatWithMonthName = false}) async {
    if (await internetService.isConnected) {
      try {
        return await remoteDataSource.getEventDate(eventId, formatWithMonthName: formatWithMonthName);
      } catch (e) {
        throw ServerFailure(e.toString());
      }
    } else {
      throw NetworkFailure('No internet connection');
    }
  }

  @override
  Future<void> reserveSeat(final String eventId, final String seatId, final String customerId) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.reserveSeat(eventId, seatId, customerId);
      } catch (e) {
        throw ServerFailure(e.toString());
      }
    } else {
      throw NetworkFailure('No internet connection');
    }
  }

  @override
  Future<void> cancelReservation(final String eventId, final String seatId) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.cancelReservation(eventId, seatId);
      } catch (e) {
        throw ServerFailure(e.toString());
      }
    } else {
      throw NetworkFailure('No internet connection');
    }
  }
}