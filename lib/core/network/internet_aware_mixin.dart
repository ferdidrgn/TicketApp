import 'dart:async';
import 'package:flutter/material.dart';
import '../network/internet_service.dart';

//FOR UI. Not use ViewModel
mixin InternetAwareMixin<T extends StatefulWidget> on State<T> {
  late final void Function(bool) _internetListener;

  bool _hasTriggeredRestore = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    InternetService.instance.startListening();

    _internetListener = _onInternetStatusChanged;

    // İnternet durum değişikliklerini dinlemeye başla.
    InternetService.instance.addListener(_internetListener);
  }

  @override
  void dispose() {
    InternetService.instance.removeListener(_internetListener);
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onInternetStatusChanged(final isConnected) =>
      isConnected ? _handleInternetRestored() : _handleInternetLost();

  void _handleInternetRestored() {
    if (_hasTriggeredRestore) return;

    _hasTriggeredRestore = true;

    // 3 saniye sonra yeniden tetiklemeye izin ver
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      _hasTriggeredRestore = false;
    });

    onInternetRestored();
  }

  void _handleInternetLost() {
    _debounceTimer?.cancel();
    _hasTriggeredRestore = false;
    onInternetLost();
  }

  // Override edilecek metodlar
  void onInternetRestored() {}

  void onInternetLost() {}
}
