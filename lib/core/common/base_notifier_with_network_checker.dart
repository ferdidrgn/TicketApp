import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../core/errors/failures.dart';
import '../network/internet_service.dart';
import 'base_state.dart';

/// Tüm Notifier'lar için merkezi internet kontrolü, state yönetimi (loading, error, success)
/// ve otomatik yeniden deneme mekanizması sağlayan base sınıf.
abstract class BaseNotifierWithNetworkChecker<T extends BaseState>
    extends Notifier<T> {
  StreamSubscription<InternetConnectionStatus>? _subscription;
  bool _wasOffline = false;
  Timer? _debounceTimer;

  @override
  T build() {
    _initializeNetworkListener();
    _registerCleanup();
    return initialState();
  }

  T initialState();

  /// İnternet geri geldiğinde veriyi yeniden yüklemek için abstract metot.
  void reloadData();

  /// Ağ dinleyicisini başlatır.    // Daha önce başlatıldıysa tekrar başlatma
  void _initializeNetworkListener() => _subscription ??=
      InternetService.instance.connectionStream.listen(_handleConnectionChange);

  /// Notifier dispose edildiğinde dinleyiciyi ve timer'ı temizler.
  void _registerCleanup() => ref.onDispose(() {
        _subscription?.cancel();
        _subscription = null; // Referansı temizle
        _debounceTimer?.cancel();
        _debounceTimer = null; // Referansı temizle
      });

  /// İnternet durumu değişikliğini ele alır.
  void _handleConnectionChange(final InternetConnectionStatus status) {
    final isOnline = status == InternetConnectionStatus.connected;

    if (isOnline && _wasOffline) {
      _scheduleReload();
      _wasOffline = false;
      clearError(); // İnternet geldiğinde varsa hata mesajını temizle
    } else if (!isOnline && !_wasOffline) {
      _wasOffline = true;
      setErrorState('İnternet Bağlantısı Yok!');
    }
  }

  /// Veri yeniden yüklemesini kısa bir gecikmeyle planlar (arka arkaya gelen
  /// bağlantı değişikliklerinde gereksiz yüklemeyi önlemek için).
  void _scheduleReload() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(seconds: 2),
      () {
        try {
          reloadData();
        } catch (e, s) {
          print("BaseNotifier: Error during scheduled reloadData: $e\n$s");
        }
      },
    );
  }

  /// Cihazın internet bağlantısını kontrol eder.
  Future<bool> _hasInternetConnection() async {
    try {
      return await InternetService.instance.isConnected;
    } catch (e) {
      return false; // Hata durumunda internet yok varsay
    }
  }

  /// Network operasyonları için wrapper /// Genellikle Repository metodunu çağıran ve Either<Failure, R> döndüren fonksiyon.
  Future<void> executeWithInternetCheck<R>(
    final Future<Either<Failure, R>> Function() operation, {
    final Function(R)? onSuccess,
  }) async {
    try {
      _setLoadingState();

      final hasInternet = await _hasInternetConnection();
      if (!hasInternet) {
        setErrorState('İnternet Bağlantısı Yok!');
        return;
      }

      final result = await operation(); // İnternet varsa işlemi gerçekleştir

      result.fold(
        (final failure) => setErrorState(failure.message),
        (final success) {
          try {
            _setSuccessState();
          } catch (e, s) {
            setErrorState("Veri işlenirken hata oluştu: $e");
          }
        },
      );
    } catch (e, s) {
      setErrorState('Beklenmeyen bir hata oluştu: ${e.toString()}');
    }
  }

  void _setLoadingState() =>
      state = state.copyWith(isLoading: true, errorMessage: null) as T;

  void _setSuccessState() =>
      state = state.copyWith(isLoading: false, errorMessage: null) as T;

  void setErrorState(final String errorMessage) =>
      state = state.copyWith(errorMessage: errorMessage, isLoading: false) as T;

  /// Mevcut hata mesajını temizler (errorMessage=null yapar).
  void clearError() {
    if (state.errorMessage != null)
      state = state.copyWith(errorMessage: null) as T;
  }
}
