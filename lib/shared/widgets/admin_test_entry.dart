import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Geliştirme sürecinde admin panelini rol/giriş kontrolü olmadan test
/// etmek için tek anahtar.
///
/// `!kReleaseMode` → `flutter run` (debug) ve profile derlemelerinde açık;
/// mağazaya çıkan release derlemesinde KAPALI (şerit hiç çizilmez,
/// `AdminGuard` yine rol kontrolü yapar). Güvenlik sınırı istemci değil:
/// tüm yazmalar sunucuda Firestore `isAdmin()` kuralıyla korunur. Test
/// bitince bu dosyadaki [enabled] `false` yapılabilir.
abstract final class AdminTestAccess {
  static const bool enabled = !kReleaseMode;
}

/// Ana sayfanın en üstündeki ince "TEST" şeridi — dokununca doğrudan
/// admin paneline gider. Sadece [AdminTestAccess.enabled] iken görünür.
class AdminTestStrip extends StatelessWidget {
  const AdminTestStrip({super.key});

  @override
  Widget build(final BuildContext context) {
    if (!AdminTestAccess.enabled) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
        child: Semantics(
          button: true,
          label: 'Test: admin paneline gir',
          excludeSemantics: true,
          child: Material(
            color: cs.tertiaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              onTap: () => context.push('/admin'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined,
                          size: 18, color: cs.onTertiaryContainer),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'TEST',
                        style: TextStyle(
                          color: cs.onTertiaryContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Admin paneline gir (rol kontrolü yok)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: cs.onTertiaryContainer, fontSize: 13),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: cs.onTertiaryContainer),
                    ],
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
