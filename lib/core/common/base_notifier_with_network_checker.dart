import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../core/errors/failures.dart';
import '../network/internet_service.dart';
import '../network/internet_service_provider.dart';
import 'base_state.dart';

/// Tüm ViewModel'ler için merkezi internet kontrolü ve state yönetimi sağlayan base sınıf
/// Internet bağlantısı kesilip geri geldiğinde otomatik retry mekanizması sunar
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
  void _initializeNetworkListener() => _subscription =
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

  /// Network operasyonları için wrapper. Genellikle Repository metodunu çağıran ve Either<Failure, R> döndüren fonksiyon.
  Future<void> executeWithInternetCheck<R>(
    final Future<Either<Failure, R>> Function() operation, {
    final Function(R)? onSuccess,
  }) async {
    if (!ref.mounted) return;
    try {
      state = state.copyWith(isLoading: true, errorMessage: null) as T;

      final hasInternet = await ref.read(internetServiceProvider).isConnected;
      if (!hasInternet) {
        setErrorState('İnternet Bağlantısı Yok!');
        return;
      }

      final result = await operation(); // İnternet varsa işlemi gerçekleştir
      if (!ref.mounted) return;
      result.fold(
        (final failure) => setErrorState(
            "Sistemimizi kitledik. Meraklılarımıza kodlarımız: ${failure.message}"),
        (final success) {
          try {
            onSuccess?.call(success);
            state = state.copyWith(isLoading: false, errorMessage: null) as T;
          } catch (e, s) {
            if (!ref.mounted) return;
            setErrorState("Veri işlenirken hata oluştu: $e");
          }
        },
      );
    } catch (e, s) {
      setErrorState('Beklenmeyen bir hata oluştu: ${e.toString()}');
    }
  }

  void setErrorState(final String errorMessage) =>
      state = state.copyWith(errorMessage: errorMessage, isLoading: false) as T;

  /// Mevcut hata mesajını temizler (errorMessage=null yapar).
  void clearError() {
    if (state.errorMessage != null)
      state = state.copyWith(errorMessage: null) as T;
  }
}
