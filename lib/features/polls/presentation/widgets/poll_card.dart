import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../auth/presentation/providers/auth_provider.dart' show currentUserIdProvider;
import '../../data/poll_repository.dart';
import '../providers/poll_providers.dart';

/// Ana sayfa "Anket" kartı (F-5). Aktif anket yoksa hiçbir şey çizmez.
/// Sonuç yüzdeleri oy verdikten SONRA ya da anket bitince görünür; oy yalnız sunucu callable'ıyla (giriş + doğrulanmış telefon).
class PollCard extends ConsumerStatefulWidget {
  const PollCard({super.key});

  @override
  ConsumerState<PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<PollCard> {
  bool _busy = false;
  bool _changing = false;
  String? _error;
  Poll? _fresh; // oy sonrası güncel sayaçlar
  String? _myOption; // oy sonrası iyimser

  Future<void> _vote(final Poll poll, final String optionId) async {
    final String? uid = ref.read(currentUserIdProvider);
    if (uid == null || uid.isEmpty) {
      setState(() => _error = 'Oy vermek için giriş yapmalısın.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final PollRepository repo = ref.read(pollRepositoryProvider);
      await repo.vote(poll.id, optionId);
      final Poll? updated = await repo.byId(poll.id);
      if (mounted) {
        setState(() {
          _busy = false;
          _changing = false;
          _myOption = optionId;
          _fresh = updated ?? poll;
        });
      }
    } on PollException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Oy kaydedilemedi. Bağlantını kontrol edip tekrar dene.';
        });
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    final Poll? base = ref.watch(activePollProvider).value;
    if (base == null) return const SizedBox.shrink();
    final Poll poll = _fresh ?? base;
    final String? uid = ref.watch(currentUserIdProvider);
    final String? stored =
        uid == null || uid.isEmpty ? null : ref.watch(myPollVoteProvider('${poll.id}|$uid')).value;
    final String? mine = _myOption ?? stored;
    final bool showResults = (mine != null && !_changing) || !poll.isOpen();
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: 'Anket: ${poll.question}',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ANKET', style: Sk.ui(context, size: 12, color: cs.primary, weight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.xs),
            Text(poll.question, style: Sk.display(context, size: 22)),
            const SizedBox(height: AppSpacing.md),
            for (final PollOption o in poll.options)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: showResults ? _ResultRow(poll: poll, option: o, mine: mine == o.id) : _ChoiceRow(label: o.label, enabled: !_busy, onTap: () => _vote(poll, o.id)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(_error!, style: Sk.ui(context, size: 13, color: cs.error), semanticsLabel: 'Hata: $_error'),
              ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  showResults
                      ? '${poll.totalVotes} oy · TiyatRol anketi'
                      : 'Hesap başına tek oy · telefon doğrulaması gerekir · TiyatRol anketi',
                  style: Sk.ui(context, size: 12, color: cs.onSurfaceVariant, weight: FontWeight.w500),
                ),
                if (showResults && mine != null && poll.isOpen())
                  TextButton(
                    onPressed: () => setState(() => _changing = true),
                    child: const Text('Oyumu değiştir'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _ChoiceRow({required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Oy ver: $label',
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Text(label, style: Sk.ui(context, size: 15)),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final Poll poll;
  final PollOption option;
  final bool mine;
  const _ResultRow({required this.poll, required this.option, required this.mine});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int pct = poll.percentOf(option.id);
    return Semantics(
      label: '${option.label}: yüzde $pct${mine ? ', senin oyun' : ''}',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: mine ? cs.primary : cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct / 100,
                child: ColoredBox(color: cs.primary.withValues(alpha: 0.18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(child: Text(option.label + (mine ? '  (oyun)' : ''), style: Sk.ui(context, size: 15))),
                  Text('%$pct', style: Sk.ui(context, size: 15, weight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
