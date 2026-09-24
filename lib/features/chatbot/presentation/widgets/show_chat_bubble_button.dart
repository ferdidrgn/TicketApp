import 'package:flutter/material.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_shadows.dart';
import 'show_chat_sheet.dart';

/// Gösteri detay sayfasında yüzen, "Sık Sorulan Sorular" sohbet panelini
/// açan tek giriş noktası. Panelin kendisi (`ShowChatSheet`) tamamen yerel
/// anahtar kelime eşleştirmesiyle çalışır — ağ çağrısı/gerçek bir
/// AI servisi YOK.
///
/// 🔥 DÜZELTME: Önceden statik, sayfa açılır açılmaz zaten oradaymış gibi
/// duran bir dairesel butondu — sohbet/chatbot UI araştırmasında (dribbble/
/// fluttergems) tekrar eden bir örüntü, launcher butonunun "yeni bir
/// olanak" olduğunu bir kerelik giriş hareketiyle hissettirmesiydi. Burada
/// da AYNI amaç: `orientation` (kullanıcı dikkatini çeker) — sürekli
/// tekrarlayan bir animasyon DEĞİL, sayfa açıldığında BİR KEZ ölçek+
/// solma ile beliriyor (`AppMotion.slow`/`dramatic` — "sahne anı" hızı,
/// sık tekrarlanan bir yerde kullanılmadığı için etkisini kaybetmiyor).
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _open(final BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (final _) =>
            ShowChatSheet(showId: widget.showId, showName: widget.showName),
      );

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return ScaleTransition(
      scale: _entrance,
      child: FadeTransition(
        opacity: _entrance,
        child: Semantics(
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
        ),
      ),
    );
  }
}
