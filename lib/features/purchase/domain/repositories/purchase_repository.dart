import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/purchase_entities.dart';

abstract class PurchaseRepository {
  Future<Either<Failure, SeatHold>> holdSeats(
      final String eventId, final List<String> seatIds);

  Future<Either<Failure, void>> releaseHold(final String orderId);

  Future<Either<Failure, PaymentSession>> startPayment(
      final String orderId, final String returnUrl);

  /// Ücretsiz sipariş onayı; oluşan bilet kimliklerini döner.
  Future<Either<Failure, List<String>>> confirmFree(final String orderId);

  /// Siparişi canlı izler (ödeme sonucu burada görünür). Belge yoksa `null`.
  Stream<PurchaseOrder?> watchOrder(final String orderId);

  /// Kullanıcının `held`/`paying` siparişleri (süresi dolmuş olanlar dahil;
  /// süzme çağıranın işi). Yalnızca kendi `userId`'sine göre sorgular.
  Future<Either<Failure, List<PurchaseOrder>>> getOpenOrders(
      final String userId);
}
