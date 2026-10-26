import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/purchase_entities.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/purchase_remote_data_source_and_impl.dart';

/// `BaseRepository.execute` KULLANILMAZ: o, ham `e.toString()` döndürür
/// (teknik sızıntı). Burada her hata [PurchaseFailure]'a, güvenli Türkçe
/// mesajla çevrilir.
class PurchaseRepositoryImpl implements PurchaseRepository {
  final PurchaseRemoteDataSource remoteDataSource;

  PurchaseRepositoryImpl({required this.remoteDataSource});

  Future<Either<Failure, T>> _run<T>(final Future<T> Function() action) async {
    try {
      return Right(await action());
    } on Object catch (e) {
      final ex = PurchaseRemoteDataSourceImpl.mapError(e);
      return Left(PurchaseFailure(ex.message, code: ex.code));
    }
  }

  @override
  Future<Either<Failure, SeatHold>> holdSeats(
          final String eventId, final List<String> seatIds) =>
      _run(() => remoteDataSource.holdSeats(eventId, seatIds));

  @override
  Future<Either<Failure, void>> releaseHold(final String orderId) =>
      _run(() => remoteDataSource.releaseHold(orderId));

  @override
  Future<Either<Failure, PaymentSession>> startPayment(
          final String orderId, final String returnUrl) =>
      _run(() => remoteDataSource.startPayment(orderId, returnUrl));

  @override
  Future<Either<Failure, List<String>>> confirmFree(final String orderId) =>
      _run(() => remoteDataSource.confirmFree(orderId));

  @override
  Future<Either<Failure, List<String>>> confirmReservation(
          final String orderId) =>
      _run(() => remoteDataSource.confirmReservation(orderId));

  @override
  Future<Either<Failure, void>> cancelTicket(final String ticketId) =>
      _run(() => remoteDataSource.cancelTicket(ticketId));

  @override
  Stream<SalesConfig> watchSalesConfig() =>
      remoteDataSource.watchSalesConfig();

  @override
  Stream<PurchaseOrder?> watchOrder(final String orderId) =>
      remoteDataSource.watchOrder(orderId);

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getOpenOrders(
          final String userId) =>
      _run(() => remoteDataSource.getOpenOrders(userId));
}
