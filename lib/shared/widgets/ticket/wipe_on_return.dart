import 'package:flutter/material.dart';

/// Oyun / oyuncu / sahne sayfalarında geri dönüşte yazı wipe'ını yeniden
/// oynatmak için. Hero ve spot [StageEntrance]/[StageHero] geri yönde
/// zaten kapalı.
final RouteObserver<ModalRoute<void>> kDetailRouteObserver =
    RouteObserver<ModalRoute<void>>();

mixin ReplayWipeOnReturn<T extends StatefulWidget> on State<T>
    implements RouteAware {
  void replayWipe();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<void>? route = ModalRoute.of(context);
    if (route != null) {
      kDetailRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    kDetailRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => replayWipe();

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {}
}
