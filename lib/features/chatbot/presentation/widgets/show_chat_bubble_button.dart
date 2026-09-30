import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import 'show_chat_sheet.dart';

/// Oyun detayında yüzen, "bu oyun hakkında sor" yardım sohbetini açan tek
/// giriş noktası. Panel (`ShowChatSheet`) tamamen yerel anahtar kelime
/// eşleştirmesiyle çalışır — ağ çağrısı/gerçek bir AI servisi YOK.
///
/// Sayfa açıldığında BİR KEZ ölçek + solma ile belirir (azaltılmış
/// harekette doğrudan görünür). Açılış biçimi ekrana göre:
/// - mobil/tablet: alttan açılan sayfa (tablette en fazla 640px genişlik),
/// - masaüstü: sağ altta, butonun olduğu köşede yüzen 400px panel.
class ShowChatBubbleButton extends StatefulWidget {
  final String showId;
  final String showName;

  const ShowChatBubbleButton(
      {super.key, required this.showId, required this.showName});

  @override
  State<ShowChatBubbleButton> createState() => _ShowChatBubbleButtonState();
}

class _ShowChatBubbleButtonState extends State<ShowChatBubbleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final Animation<double> _entrance =
      CurvedAnimation(parent: _entranceController, curve: AppMotion.dramatic);
  bool _started = false;
  bool _focused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _entranceController.value = 1;
    } else {
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _open(final BuildContext context) {
    if (context.isDesktop) {
      showDialog<void>(
        context: context,
        barrierColor: Colors.black26,
        barrierLabel: 'Kapat',
        builder: (final dialogContext) {
          final Size size = MediaQuery.sizeOf(dialogContext);
          return Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: SizedBox(
                width: 400,
                height: math.min(640, size.height - AppSpacing.xxl * 2),
                child: ShowChatSheet(
                  showId: widget.showId,
                  showName: widget.showName,
                  floating: true,
                ),
              ),
            ),
          );
        },
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (final _) =>
          ShowChatSheet(showId: widget.showId, showName: widget.showName),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return ScaleTransition(
      scale: _entrance,
      child: FadeTransition(
        opacity: _entrance,
        child: Semantics(
          label: 'Bu oyun hakkında soru sor',
          button: true,
          excludeSemantics: true,
          child: Tooltip(
            message: 'Bu oyun hakkında sor',
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary,
                border: Border.all(
                  color: _focused ? colors.onSurface : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: AppShadows.level3(colors.shadow),
              ),
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(context),
                  onFocusChange: (final v) => setState(() => _focused = v),
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: Icon(Icons.question_answer_outlined,
                        color: colors.onPrimary, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
