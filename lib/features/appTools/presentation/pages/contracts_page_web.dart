import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_html_css/simple_html_css.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../shared/navigation/widgets/web_account_shell.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../providers/app_tools_provider.dart';

enum _Doc { privacy, terms }

extension on _Doc {
  String get label => switch (this) {
        _Doc.privacy => 'Gizlilik politikası',
        _Doc.terms => 'Kullanım şartları',
      };
  IconData get icon => switch (this) {
        _Doc.privacy => Icons.lock_outline_rounded,
        _Doc.terms => Icons.gavel_rounded,
      };
}

/// YASAL BİLGİLER — WEB. Hesap kabuğu içinde: belge seçici (gizlilik /
/// şartlar), okuma sütununda belge metni (seçilip kopyalanabilir, yazı boyutu
/// ayarlanabilir), sağda yapışkan belge listesi ve iletişim. Mobil
/// `ContractsPage`'den AYRIDIR. Veri: `privacyPolicyProvider` /
/// `termsConditionProvider`. Belgede olmayan bir "son güncelleme" tarihi
/// uydurulmaz.
class ContractsPageWeb extends ConsumerStatefulWidget {
  const ContractsPageWeb({super.key});

  @override
  ConsumerState<ContractsPageWeb> createState() => _ContractsPageWebState();
}

class _ContractsPageWebState extends ConsumerState<ContractsPageWeb> {
  _Doc _doc = _Doc.privacy;
  double _size = 16;

  AsyncValue<String?> _value() => ref.watch(_doc == _Doc.privacy
      ? privacyPolicyProvider
      : termsConditionProvider);

  void _retry() => ref.invalidate(
      _doc == _Doc.privacy ? privacyPolicyProvider : termsConditionProvider);

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<String?> doc = _value();

    final Widget text = doc.when(
      data: (final content) => content == null || content.trim().isEmpty
          ? WebStatePanel(
              icon: Icons.description_outlined,
              title: 'Metin henüz yayımlanmadı',
              message: 'Bu belge şu an görüntülenemiyor. Sorun için bize '
                  'e-posta ile ulaşabilirsin.',
              actionLabel: 'E-posta gönder',
              onAction: () => TiyatrolCommunicationActions.sendEmail(
                  subject: 'TiyatRol Yasal Bilgiler'),
            )
          : WebPanel(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxxl, vertical: AppSpacing.xxxl),
              child: SelectionArea(
                child: Text.rich(
                  HTML.toTextSpan(
                    context,
                    content,
                    defaultTextStyle: TextStyle(
                      fontSize: _size,
                      height: 1.7,
                      color: cs.onSurface,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
      loading: () => const _DocSkeleton(),
      error: (final _, final __) => WebStatePanel(
        icon: Icons.cloud_off_rounded,
        title: 'Belge yüklenemedi',
        message: 'Bağlantını kontrol edip tekrar dene.',
        actionLabel: 'Tekrar dene',
        onAction: _retry,
      ),
    );

    return WebAccountShell(
      current: WebAccountSection.contracts,
      title: 'Yasal bilgiler',
      subtitle: 'Gizlilik politikası ve kullanım şartları.',
      contentMaxWidth: 860,
      aside: _DocList(
        selected: _doc,
        onSelect: (final d) => setState(() => _doc = d),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final _Doc d in _Doc.values)
                      SkChip(
                        label: d.label,
                        icon: d.icon,
                        selected: d == _doc,
                        onTap: () => setState(() => _doc = d),
                      ),
                  ],
                ),
              ),
              _SizeControl(
                size: _size,
                onChanged: (final v) => setState(() => _size = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            child: KeyedSubtree(key: ValueKey(_doc), child: text),
          ),
        ],
      ),
    );
  }
}

class _SizeControl extends StatelessWidget {
  final double size;
  final ValueChanged<double> onChanged;
  const _SizeControl({required this.size, required this.onChanged});

  @override
  Widget build(final BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Yazıyı küçült',
            onPressed: size <= 14 ? null : () => onChanged(size - 2),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.text_decrease_rounded),
          ),
          IconButton(
            tooltip: 'Yazıyı büyüt',
            onPressed: size >= 22 ? null : () => onChanged(size + 2),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.text_increase_rounded),
          ),
        ],
      );
}

class _DocList extends StatelessWidget {
  final _Doc selected;
  final ValueChanged<_Doc> onSelect;
  const _DocList({required this.selected, required this.onSelect});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return WebPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('BELGELER',
              style: Sk.ui(context,
                  size: 11,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w800,
                  letterSpacing: 1.8)),
          const SizedBox(height: AppSpacing.md),
          for (final _Doc d in _Doc.values)
            Semantics(
              button: true,
              selected: d == selected,
              label: d.label,
              excludeSemantics: true,
              child: Material(
                color: d == selected
                    ? cs.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InkWell(
                  onTap: () => onSelect(d),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(d.icon,
                              size: 19,
                              color: d == selected
                                  ? cs.onPrimaryContainer
                                  : cs.primary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(d.label,
                                style: Sk.ui(context,
                                    size: 14,
                                    color: d == selected
                                        ? cs.onPrimaryContainer
                                        : cs.onSurface,
                                    weight: d == selected
                                        ? FontWeight.w800
                                        : FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Divider(height: AppSpacing.xxxl, color: cs.outlineVariant),
          Text('Bu metinlerle ilgili bir sorun mu var?',
              style: Sk.ui(context, size: 13.5, weight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          WebTextAction(
            label: 'Bize e-posta gönder',
            icon: Icons.mail_outline_rounded,
            onTap: () => TiyatrolCommunicationActions.sendEmail(
                subject: 'TiyatRol Yasal Bilgiler'),
          ),
        ],
      ),
    );
  }
}

class _DocSkeleton extends StatelessWidget {
  const _DocSkeleton();

  static const List<double> _lines = [
    0.5, 1, 1, 0.9, 1, 0.7, 0, 1, 1, 0.85, 1, 0.6, //
  ];

  @override
  Widget build(final BuildContext context) => Semantics(
        label: 'Belge yükleniyor',
        child: WebPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final double f in _lines)
                f == 0
                    ? const SizedBox(height: AppSpacing.xl)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: FractionallySizedBox(
                          widthFactor: f,
                          child: const SkBone(height: 14, radius: 6),
                        ),
                      ),
            ],
          ),
        ),
      );
}
