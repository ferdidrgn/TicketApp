import 'package:flutter/material.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_shadows.dart';
import 'show_chat_sheet.dart';

/// Gösteri detay sayfasında yüzen, "Sık Sorulan Sorular" sohbet panelini
/// açan tek giriş noktası. Panelin kendisi (`ShowChatSheet`) tamamen yerel
/// anahtar kelime eşleştirmesiyle çalışır — ağ çağrısı/gerçek bir
/// AI servisi YOK.
class ShowChatBubbleButton extends StatelessWidget {
  final String showId;
  final String showName;

  const ShowChatBubbleButton(
      {super.key, required this.showId, required this.showName});

  void _open(final BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (final _) => ShowChatSheet(showId: showId, showName: showName),
      );

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'Gösteri hakkında soru sor',
      button: true,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.primary,
          boxShadow: AppShadows.level4(colors.primary),
        ),
        child: ClipOval(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _open(context),
              child: Center(
                child: Icon(Icons.forum_rounded,
                    color: colors.onPrimary, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
