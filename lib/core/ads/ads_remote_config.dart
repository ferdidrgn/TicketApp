import 'package:flutter/material.dart';
import '../services/remote_config_service.dart';

class ReactiveAdWrapper extends StatelessWidget {
  final Widget child;

  const ReactiveAdWrapper({super.key, required this.child});

  @override
  Widget build(final BuildContext context) => ValueListenableBuilder<bool>(
      valueListenable: RemoteConfigService.adsEnabledNotifier,
      builder: (final context, final adsEnabled, final _) =>
          adsEnabled ? child : const SizedBox.shrink());
}
