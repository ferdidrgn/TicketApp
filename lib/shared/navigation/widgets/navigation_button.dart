import 'package:flutter/material.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';

/// Bölüm başlığının yanındaki "tümünü gör" düğmesi. 48dp dokunma alanı,
/// temanın çizgi rengiyle ince çerçeve, klavye odağında görünür halka.
class NavigationButton extends StatelessWidget {
  final VoidCallback? onTap;

  const NavigationButton({super.key, this.onTap});

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    return Semantics(
      button: true,
      label: 'Tümünü gör',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Tümünü gör',
        child: SizedBox(
          width: 48,
          height: 48,
          child: Material(
            type: MaterialType.transparency,
            shape: CircleBorder(side: BorderSide(color: cs.outlineVariant)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              focusColor: cs.primary.withOpacity(0.16),
              hoverColor: cs.onSurface.withOpacity(0.05),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
