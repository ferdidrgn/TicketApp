import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_provider.dart';
import '../../data/datasources/purchase_remote_data_source_and_impl.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/entities/purchase_entities.dart';
import '../../domain/usecases/cancel_ticket_use_case_impl.dart';
import '../../domain/usecases/confirm_free_use_case_impl.dart';
import '../../domain/usecases/confirm_reservation_use_case_impl.dart';
import '../../domain/usecases/get_open_orders_use_case_impl.dart';
import '../../domain/usecases/hold_seats_use_case_impl.dart';
import '../../domain/usecases/release_hold_use_case_impl.dart';
import '../../domain/usecases/start_payment_use_case_impl.dart';
import '../../domain/usecases/watch_order_use_case_impl.dart';

// NOT: Bu dosyada bilerek `@riverpod` codegen KULLANILMAZ (build_runner
// yok); klasik Provider API'si.

/// Callable istemcisi — testlerde sahte bir uygulamayla override edilir.
final purchaseCallableClientProvider = Provider<PurchaseCallableClient>(
    (final ref) => FirebasePurchaseCallableClient());

final purchaseRemoteDataSourceProvider =
    Provider<PurchaseRemoteDataSource>((final ref) =>
        PurchaseRemoteDataSourceImpl(
          client: ref.watch(purchaseCallableClientProvider),
          firestore: ref.watch(firestoreProvider),
        ));

final purchaseRepositoryProvider = Provider<PurchaseRepository>((final ref) =>
    PurchaseRepositoryImpl(
        remoteDataSource: ref.watch(purchaseRemoteDataSourceProvider)));

final holdSeatsUseCaseProvider = Provider<HoldSeatsUseCase>((final ref) =>
    HoldSeatsUseCaseImpl(ref.watch(purchaseRepositoryProvider)));

final releaseHoldUseCaseProvider = Provider<ReleaseHoldUseCase>((final ref) =>
    ReleaseHoldUseCaseImpl(ref.watch(purchaseRepositoryProvider)));

final startPaymentUseCaseProvider = Provider<StartPaymentUseCase>((final ref) =>
    StartPaymentUseCaseImpl(ref.watch(purchaseRepositoryProvider)));

final confirmFreeUseCaseProvider = Provider<ConfirmFreeUseCase>((final ref) =>
    ConfirmFreeUseCaseImpl(ref.watch(purchaseRepositoryProvider)));

final confirmReservationUseCaseProvider =
    Provider<ConfirmReservationUseCase>((final ref) =>
        ConfirmReservationUseCaseImpl(ref.watch(purchaseRepositoryProvider)));

final cancelTicketUseCaseProvider = Provider<CancelTicketUseCase>((final ref) =>
    CancelTicketUseCaseImpl(ref.watch(purchaseRepositoryProvider)));

/// `Config/satis` canlı akışı. Yüklenirken/hatada/belge yokken
/// [SalesConfig.defaults] (rezervasyon, 3, 24) kullanılır — bkz. [salesConfigProvider].
final salesConfigStreamProvider = StreamProvider<SalesConfig>((final ref) =>
    ref.watch(purchaseRepositoryProvider).watchSalesConfig());

/// UI için her zaman değer veren satış ayarı.
final salesConfigProvider = Provider<SalesConfig>((final ref) =>
    ref.watch(salesConfigStreamProvider).value ?? SalesConfig.defaults);

final watchOrderUseCaseProvider = Provider<WatchOrderUseCase>((final ref) =>
    WatchOrderUseCaseImpl(ref.watch(purchaseRepositoryProvider)));

final getOpenOrdersUseCaseProvider = Provider<GetOpenOrdersUseCase>(
    (final ref) =>
        GetOpenOrdersUseCaseImpl(ref.watch(purchaseRepositoryProvider)));

/// Zaman kaynağı (testte sahte saat). Geri sayım HER ZAMAN sunucunun verdiği
/// `expiresAt`'ten bu saate göre hesaplanır.
final purchaseClockProvider =
    Provider<DateTime Function()>((final ref) => DateTime.now);