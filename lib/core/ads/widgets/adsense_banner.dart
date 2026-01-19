import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../common/enum/enums.dart';
import '../../common/extentions/app_context_ui_extension.dart';
import '../ads_manager.dart';
import '../ads_remote_config.dart';

class AdsenseBanner extends StatelessWidget {
  final AdUnitType type;
  final double height;

  const AdsenseBanner({super.key, required this.type, this.height = 90});

  @override
  Widget build(final BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    return ReactiveAdWrapper(
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          'Adsense • ${AdManager.getAdUnitId(type)}',
          style: context.textTheme.bodySmall,
        ),
      ),
    );
  }
}
