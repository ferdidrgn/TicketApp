import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../auth/presentation/providers/auth_provider.dart' show currentUserIdProvider;
import '../../data/question_repository.dart';
import '../../domain/faq_bot.dart';

// NOT: `@riverpod` codegen kullanılmaz (build_runner yok) — klasik API.
final questionRepositoryProvider = Provider<QuestionRepository>((final ref) => QuestionRepository());

final publishedQuestionsProvider = FutureProvider.family<List<ShowQuestion>, String>(
    (final ref, final showId) => ref.watch(questionRepositoryProvider).published(showId));

final myQuestionsProvider = FutureProvider.family<List<ShowQuestion>, String>((final ref, final showId) async {
  final String? uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) return const [];
  try {
    return await ref.watch(questionRepositoryProvider).mine(showId);
  } catch (_) {
    return const [];
  }
});

final blockedAskerKeysProvider = FutureProvider<Set<String>>((final ref) async {
  final String? uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) return <String>{};
  try {
    return await ref.watch(questionRepositoryProvider).blockedAskerKeys(uid);
  } catch (_) {
    return <String>{};
  }
});

/// "Ekibe sor": yayınlanmış soru-cevaplar + soru sorma (SSS botu önerisiyle) + şikâyet/engelle.
class ShowQuestionsSection extends ConsumerStatefulWidget {
  final String showId;
  final FaqFacts facts;
  const ShowQuestionsSection({super.key, required this.showId, required this.facts});

  @override
  ConsumerState<ShowQuestionsSection> createState() => _ShowQuestionsSectionState();
}

class _ShowQuestionsSectionState extends ConsumerState<ShowQuestionsSection> {
  bool _all = false;
  final TextEditingController _ctrl = TextEditingController();
  bool _busy = false;
  String? _msg;
  FaqReply _bot = const FaqReply('', null);

  static const List<(String, String)> _reasons = [
    ('spam', 'Spam / reklam'),
    ('hakaret', 'Hakaret / küfür'),
    ('nefret', 'Nefret söylemi'),
    ('uygunsuz', 'Uygunsuz içerik'),
    ('kisisel_bilgi', 'Kişisel bilgi paylaşımı'),
    ('diger', 'Diğer'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _snack(final String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  void _onChanged(final String v) {
    final r = v.trim().length >= 5 ? FaqBot.sor(v, widget.facts) : const FaqReply('', null);
    setState(() => _bot = r);
  }

  Future<void> _send() async {
    final String uid = ref.read(currentUserIdProvider) ?? '';
    final String t = _ctrl.text.trim();
    if (uid.isEmpty) {
      setState(() => _msg = 'Soru sormak için giriş yapmalısın.');
      return;
    }
    if (t.length < 5) {
      setState(() => _msg = 'Sorun en az 5 karakter olmalı.');
      return;
    }
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      await ref.read(questionRepositoryProvider).ask(widget.showId, t);
      if (!mounted) return;
      _ctrl.clear();
      ref.invalidate(myQuestionsProvider(widget.showId));
      setState(() {
        _busy = false;
        _bot = const FaqReply('', null);
        _msg = 'Teşekkürler! Sorun ekibe iletildi; yanıtlanınca burada yayınlanır.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = e is QuestionException ? e.message : 'Gönderilemedi. Tekrar dene.';
      });
    }
  }

  Future<void> _report(final ShowQuestion q) async {
    final String? reason = await showDialog<String>(
      context: context,
      builder: (final ctx) => SimpleDialog(
        title: const Text('Şikâyet nedeni'),
        children: [
          for (final (String k, String v) in _reasons)
            SimpleDialogOption(onPressed: () => Navigator.of(ctx).pop(k), child: Text(v)),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await ref.read(questionRepositoryProvider).report(q.id, reason: reason);
      if (mounted) _snack('Şikâyetin alındı. İnceleyeceğiz.');
    } catch (e) {
      if (mounted) _snack(e is QuestionException ? e.message : 'Şikâyet gönderilemedi.');
    }
  }

  Future<void> _block(final ShowQuestion q) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: const Text('Soran kişi engellensin mi?'),
        content: const Text('Bu kişinin sorularını artık görmeyeceksin.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Engelle')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(questionRepositoryProvider).blockAsker(q.id);
      if (mounted) {
        ref.invalidate(blockedAskerKeysProvider);
        _snack('Kullanıcı engellendi.');
      }
    } catch (e) {
      if (mounted) _snack(e is QuestionException ? e.message : 'Engellenemedi.');
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? uid = ref.watch(currentUserIdProvider);
    final bool loggedIn = uid != null && uid.isNotEmpty;
    final Set<String> blocked = ref.watch(blockedAskerKeysProvider).value ?? const <String>{};
    final List<ShowQuestion> mine = ref.watch(myQuestionsProvider(widget.showId)).value ?? const [];
    final async = ref.watch(publishedQuestionsProvider(widget.showId));

    final List<ShowQuestion> all = [
      for (final q in async.value ?? const <ShowQuestion>[])
        if (!blocked.contains(q.askerKey)) q,
    ];
    final List<ShowQuestion> shown = _all ? all : all.take(3).toList();
    final List<ShowQuestion> waiting = [for (final q in mine) if (q.status == 'pending' || q.status == 'rejected') q];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkSectionHead(
          title: 'Ekibe sor',
          subtitle: all.isEmpty ? 'İlk soruyu sen sor' : '${all.length} yanıtlanmış soru',
        ),
        const SizedBox(height: AppSpacing.md),
        for (final q in shown)
          _QuestionTile(
            q: q,
            onReport: loggedIn ? () => _report(q) : null,
            onBlock: loggedIn ? () => _block(q) : null,
          ),
        if (all.length > 3)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _all = !_all),
              child: Text(_all ? 'Daha az göster' : 'Tüm soruları göster (${all.length})'),
            ),
          ),
        if (all.isEmpty && !async.isLoading)
          Text('Henüz yanıtlanmış soru yok.',
              style: Sk.ui(context, size: 13.5, color: cs.onSurfaceVariant, weight: FontWeight.w500)),
        for (final q in waiting)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Semantics(
              label: 'Sorun: ${q.text}. ${q.status == 'pending' ? 'Onay bekliyor' : 'Yayınlanmadı'}',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(q.text, style: Sk.ui(context, size: 14, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(q.status == 'pending' ? 'Onay bekliyor' : 'Yayınlanmadı',
                    style: Sk.ui(context, size: 12.5, color: cs.onSurfaceVariant)),
              ]),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _ctrl,
          maxLength: 300,
          minLines: 2,
          maxLines: 4,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            labelText: 'Ekibe soru sor',
            hintText: 'Örn. Çocuğa uygun mu?',
            helperText: 'Bağlantı, telefon ve e-posta yazılamaz. Giriş ve doğrulanmış telefon gerekir.',
            border: OutlineInputBorder(),
          ),
        ),
        if (_bot.answer != null)
          Semantics(
            liveRegion: true,
            label: 'Cevap burada olabilir: ${_bot.answer}',
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Cevap burada olabilir', style: Sk.ui(context, size: 13, weight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(_bot.answer!, style: Sk.ui(context, size: 14)),
                const SizedBox(height: 4),
                Text('Bu otomatik bir yanıttır; yetmezse ekibe sorabilirsin.',
                    style: Sk.ui(context, size: 12, color: cs.onSurfaceVariant)),
              ]),
            ),
          ),
        if (_msg != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(_msg!, style: Sk.ui(context, size: 13, color: cs.onSurfaceVariant)),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _busy ? null : _send,
            child: Text(_busy ? 'Gönderiliyor…' : 'Ekibe sor'),
          ),
        ),
      ],
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final ShowQuestion q;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  const _QuestionTile({required this.q, this.onReport, this.onBlock});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('${q.askerName.isEmpty ? 'Seyirci' : q.askerName} sordu',
                  style: Sk.ui(context, size: 12.5, color: cs.onSurfaceVariant, weight: FontWeight.w600)),
            ),
            if (onReport != null || onBlock != null)
              PopupMenuButton<String>(
                tooltip: 'Soru seçenekleri',
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (final v) => v == 'r' ? onReport?.call() : onBlock?.call(),
                itemBuilder: (final _) => [
                  if (onReport != null) const PopupMenuItem(value: 'r', child: Text('Şikâyet et')),
                  if (onBlock != null) const PopupMenuItem(value: 'b', child: Text('Soran kişiyi engelle')),
                ],
              ),
          ]),
          Text(q.text, style: Sk.ui(context, size: 15, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('${q.answeredBy ?? 'Ekip'}: ${q.answer ?? ''}', style: Sk.ui(context, size: 14)),
        ],
      ),
    );
  }
}
