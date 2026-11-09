import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/common/enum/enums.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../reviews/presentation/widgets/review_widgets.dart' show StarRow;
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../users/presentation/providers/user_provider.dart';
import 'admin_form_widgets.dart';
import 'admin_table_tools.dart';

/// Yönetici (admin) "Moderasyon" sekmesi — web panelindeki
/// `site/js/admin/moderasyon.js`'in mobildeki karşılığı (aynı yetenek):
/// kuyruktaki/gizli yorumları gizle-geri aç-SİL, bekleyen/gizli soruları
/// yanıtla-reddet-geri aç-SİL, işlem kayıtlarını (ModerationLog) gör.
///
/// Tamamen ADMIN-ONLY: ekip yöneticisi (küratör) için ayrı, daha kısıtlı
/// (yalnız gizleme) bir akış BAŞKA bir iş — burada inşa edilmiyor. Bu
/// widget'ı barındıran sayfa zaten `AdminGuard` ile korunuyor olsa da
/// (`isUserPrivilegedProvider` admin VEYA küratörü geçirir), burada ayrıca
/// kendi rol denetimini yapar: rol tam olarak admin değilse hiçbir
/// moderasyon verisi/aksiyonu göstermez.
///
/// Sunucu: tüm yazımlar mevcut (deploy edilmiş) callable'lar —
/// `adminModerate`, `answerQuestion`, `rejectQuestion`, `hideQuestion`,
/// `deleteQuestion`. Bu dosya onlara sadece bağlanır; backend değişmedi.
class AdminModerationTab extends ConsumerStatefulWidget {
  const AdminModerationTab({super.key});

  @override
  ConsumerState<AdminModerationTab> createState() =>
      _AdminModerationTabState();
}

enum _ModView { queue, hidden, questions, log }

class _AdminModerationTabState extends ConsumerState<AdminModerationTab> {
  _ModView _view = _ModView.queue;

  final _ModerationRepository _repo = _ModerationRepository();

  Future<List<_ModReview>>? _queueFuture;
  Future<List<_ModReview>>? _hiddenFuture;
  Future<List<_ModQuestion>>? _questionsFuture;
  Future<List<_ModLogEntry>>? _logFuture;

  @override
  void initState() {
    super.initState();
    _queueFuture = _repo.fetchReviews(queueOnly: true);
  }

  void _ensureLoaded(final _ModView view) {
    switch (view) {
      case _ModView.queue:
        _queueFuture ??= _repo.fetchReviews(queueOnly: true);
      case _ModView.hidden:
        _hiddenFuture ??= _repo.fetchReviews(queueOnly: false);
      case _ModView.questions:
        _questionsFuture ??= _repo.fetchQuestions();
      case _ModView.log:
        _logFuture ??= _repo.fetchLog();
    }
  }

  void _reload(final _ModView view) {
    setState(() {
      switch (view) {
        case _ModView.queue:
          _queueFuture = _repo.fetchReviews(queueOnly: true);
        case _ModView.hidden:
          _hiddenFuture = _repo.fetchReviews(queueOnly: false);
        case _ModView.questions:
          _questionsFuture = _repo.fetchQuestions();
        case _ModView.log:
          _logFuture = _repo.fetchLog();
      }
    });
  }

  void _snack(final String message, {final bool isError = false}) {
    if (!mounted) {
      return;
    }
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? colors.error : null,
    ));
  }

  Future<void> _runAction(
      final Future<void> Function() action, final _ModView reloadView,
      {final String success = 'İşlem kaydedildi.'}) async {
    try {
      await action();
      _snack(success);
      _reload(reloadView);
    } on Object catch (e) {
      _snack(
          e is _ModerationException ? e.message : 'İşlem tamamlanamadı.',
          isError: true);
    }
  }

  // ---- Review aksiyonları ----------------------------------------------

  Future<void> _reviewHideOrRestore(
      final _ModReview r, final _ModView reloadView) async {
    final String action = r.hidden ? 'restore' : 'hide';
    final String? reason = await _askReason(
      context,
      title: r.hidden ? 'Yorumu yayınla / geri aç' : 'Yorumu gizle',
    );
    if (reason == null) {
      return;
    }
    await _runAction(
        () => _repo.adminModerateReview(
            reviewId: r.id, action: action, reason: reason),
        reloadView);
  }

  Future<void> _reviewDelete(
      final _ModReview r, final _ModView reloadView) async {
    final String? reason =
        await _askReason(context, title: 'Yorumu kalıcı sil', isDelete: true);
    if (reason == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    final bool confirmed = await _confirmDelete(
        context, 'Yorum kalıcı olarak silinsin mi?');
    if (!confirmed) {
      return;
    }
    await _runAction(
        () => _repo.adminModerateReview(
            reviewId: r.id, action: 'delete', reason: reason),
        reloadView);
  }

  // ---- Soru aksiyonları ---------------------------------------------------

  Future<void> _questionAnswer(final _ModQuestion q, final String answer)
      async {
    if (answer.trim().isEmpty) {
      _snack('Önce bir cevap yaz.', isError: true);
      return;
    }
    await _runAction(
        () => _repo.answerQuestion(id: q.id, answer: answer.trim()),
        _ModView.questions,
        success: 'Soru yanıtlandı ve yayınlandı.');
  }

  Future<void> _questionReject(final _ModQuestion q) async {
    final String? reason =
        await _askReason(context, title: 'Soruyu reddet');
    if (reason == null) {
      return;
    }
    await _runAction(
        () => _repo.rejectQuestion(id: q.id, reason: reason),
        _ModView.questions,
        success: 'Soru reddedildi.');
  }

  Future<void> _questionRestore(final _ModQuestion q) async {
    final String? reason = await _askReason(context, title: 'Soruyu geri aç');
    if (reason == null) {
      return;
    }
    await _runAction(
        () => _repo.hideQuestion(id: q.id, reason: reason, restore: true),
        _ModView.questions,
        success: 'Soru geri açıldı.');
  }

  Future<void> _questionDelete(final _ModQuestion q) async {
    final String? reason =
        await _askReason(context, title: 'Soruyu kalıcı sil', isDelete: true);
    if (reason == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    final bool confirmed =
        await _confirmDelete(context, 'Soru kalıcı olarak silinsin mi?');
    if (!confirmed) {
      return;
    }
    await _runAction(
        () => _repo.deleteQuestion(id: q.id, reason: reason),
        _ModView.questions,
        success: 'Soru silindi.');
  }

  @override
  Widget build(final BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    return userAsync.when(
      loading: () =>
          const Center(child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: CircularProgressIndicator())),
      error: (final e, final st) => const _AccessDenied(),
      data: (final user) {
        if (user == null || user.role != UserRole.admin) {
          return const _AccessDenied();
        }
        return _buildBody(context);
      },
    );
  }

  Widget _buildBody(final BuildContext context) {
    final colors = context.colors;
    _ensureLoaded(_view);
    final showsAsync = ref.watch(showsProvider(isLimit: false));
    final Map<String, String> showNames = {
      for (final Show s in showsAsync.value ?? const <Show>[]) s.id: s.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminSectionTitle(
                  title: 'Moderasyon', icon: Icons.shield_rounded),
              Text(
                'Bekleyen (süzgece takılan), şikâyetli yorum ve sorular. '
                'Her işlem için bir sebep zorunludur ve kalıcı olarak kaydedilir; '
                'silme geri alınamaz.',
                style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              AdminFilterChipRow(
                group: AdminFilterGroup(
                  options: const [
                    AdminFilterOption(id: 'queue', label: 'Kuyruk'),
                    AdminFilterOption(id: 'hidden', label: 'Gizli yorumlar'),
                    AdminFilterOption(id: 'questions', label: 'Sorular'),
                    AdminFilterOption(id: 'log', label: 'İşlem kayıtları'),
                  ],
                  selectedId: _view.name,
                  onSelected: (final id) => setState(() {
                    _view = _ModView.values.firstWhere((final v) => v.name == id);
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(child: _buildSelectedView(showNames)),
      ],
    );
  }

  Widget _buildSelectedView(final Map<String, String> showNames) {
    switch (_view) {
      case _ModView.queue:
        return _ReviewList(
          future: _queueFuture!,
          showNames: showNames,
          emptyMessage: 'Kuyrukta bekleyen yorum yok.',
          onRetry: () => _reload(_ModView.queue),
          onHideOrRestore: (final r) =>
              _reviewHideOrRestore(r, _ModView.queue),
          onDelete: (final r) => _reviewDelete(r, _ModView.queue),
        );
      case _ModView.hidden:
        return _ReviewList(
          future: _hiddenFuture!,
          showNames: showNames,
          emptyMessage: 'Gizlenmiş yorum yok.',
          onRetry: () => _reload(_ModView.hidden),
          onHideOrRestore: (final r) =>
              _reviewHideOrRestore(r, _ModView.hidden),
          onDelete: (final r) => _reviewDelete(r, _ModView.hidden),
        );
      case _ModView.questions:
        return _QuestionList(
          future: _questionsFuture!,
          showNames: showNames,
          onRetry: () => _reload(_ModView.questions),
          onAnswer: _questionAnswer,
          onReject: _questionReject,
          onRestore: _questionRestore,
          onDelete: _questionDelete,
        );
      case _ModView.log:
        return _LogList(
          future: _logFuture!,
          showNames: showNames,
          onRetry: () => _reload(_ModView.log),
        );
    }
  }
}

/// Admin olmayan biri bu widget'a (hatalı bağlanmış bir sekmeyle) ulaşırsa
/// gösterilen kilit ekranı — gerçek güvenlik Firestore/Functions'ta, bu
/// sadece istemci tarafı UX.
class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gavel_rounded, size: 40, color: colors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Bu bölüm yalnızca yöneticiler içindir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// REVIEW LİSTESİ (Kuyruk / Gizli yorumlar)
// ==============================================================================

class _ReviewList extends StatelessWidget {
  final Future<List<_ModReview>> future;
  final Map<String, String> showNames;
  final String emptyMessage;
  final VoidCallback onRetry;
  final void Function(_ModReview) onHideOrRestore;
  final void Function(_ModReview) onDelete;

  const _ReviewList({
    required this.future,
    required this.showNames,
    required this.emptyMessage,
    required this.onRetry,
    required this.onHideOrRestore,
    required this.onDelete,
  });

  @override
  Widget build(final BuildContext context) => FutureBuilder<List<_ModReview>>(
        future: future,
        builder: (final context, final snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const AdminListLoading();
          }
          if (snap.hasError) {
            return AdminListError(message: 'Yorumlar yüklenemedi: ${snap.error}');
          }
          final items = snap.data ?? const <_ModReview>[];
          if (items.isEmpty) {
            return AdminEmptyList(message: emptyMessage);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            itemCount: items.length,
            separatorBuilder: (final _, final __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (final context, final i) => _ReviewRow(
              review: items[i],
              showName: showNames[items[i].showId] ?? items[i].showId,
              onHideOrRestore: () => onHideOrRestore(items[i]),
              onDelete: () => onDelete(items[i]),
            ),
          );
        },
      );
}

class _ReviewRow extends StatelessWidget {
  final _ModReview review;
  final String showName;
  final VoidCallback onHideOrRestore;
  final VoidCallback onDelete;

  const _ReviewRow({
    required this.review,
    required this.showName,
    required this.onHideOrRestore,
    required this.onDelete,
  });

  static const Map<String, String> _durum = {
    'pending': 'Bekliyor',
    'hidden': 'Gizli',
    'published': 'Yayında',
  };
  static const Map<String, String> _sebep = {
    'pending': 'Süzgeç',
    'reports': 'Şikâyetler',
    'moderator': 'Moderatör',
  };

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final String durum =
        _durum[review.status] ?? (review.hidden ? 'Gizli' : 'Yayında');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: 4,
                  children: [
                    Text(review.userName.isEmpty ? 'Seyirci' : review.userName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    Text('· $showName',
                        style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant)),
                    StarRow(rating: review.rating.toDouble(), size: 13),
                    _StatusTag(
                      label: durum,
                      tone: review.hidden ? _Tone.warn : _Tone.ok,
                    ),
                    if (review.hiddenReason != null)
                      Text('(${_sebep[review.hiddenReason] ?? review.hiddenReason})',
                          style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Şikâyet: ${review.reportCount} · ${_fmtDate(review.createdAt)}',
            style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant),
          ),
          if (review.text.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(review.text.trim(),
                style: TextStyle(fontSize: 13.5, color: colors.onSurface, height: 1.4)),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onHideOrRestore,
                icon: Icon(review.hidden
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                    size: 16),
                label: Text(review.hidden ? 'Yayınla / geri aç' : 'Gizle'),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: Icon(Icons.delete_forever_rounded, size: 16, color: colors.error),
                label: Text('Sil', style: TextStyle(color: colors.error)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: colors.error.withValues(alpha: 0.5))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// SORU LİSTESİ
// ==============================================================================

class _QuestionList extends StatelessWidget {
  final Future<List<_ModQuestion>> future;
  final Map<String, String> showNames;
  final VoidCallback onRetry;
  final Future<void> Function(_ModQuestion, String) onAnswer;
  final Future<void> Function(_ModQuestion) onReject;
  final Future<void> Function(_ModQuestion) onRestore;
  final Future<void> Function(_ModQuestion) onDelete;

  const _QuestionList({
    required this.future,
    required this.showNames,
    required this.onRetry,
    required this.onAnswer,
    required this.onReject,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(final BuildContext context) => FutureBuilder<List<_ModQuestion>>(
        future: future,
        builder: (final context, final snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const AdminListLoading();
          }
          if (snap.hasError) {
            return AdminListError(message: 'Sorular yüklenemedi: ${snap.error}');
          }
          final items = snap.data ?? const <_ModQuestion>[];
          if (items.isEmpty) {
            return const AdminEmptyList(
                message: 'Bekleyen ya da gizli soru yok.');
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            itemCount: items.length,
            separatorBuilder: (final _, final __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (final context, final i) => _QuestionRow(
              question: items[i],
              showName: showNames[items[i].showId] ?? items[i].showId,
              onAnswer: (final a) => onAnswer(items[i], a),
              onReject: () => onReject(items[i]),
              onRestore: () => onRestore(items[i]),
              onDelete: () => onDelete(items[i]),
            ),
          );
        },
      );
}

class _QuestionRow extends StatefulWidget {
  final _ModQuestion question;
  final String showName;
  final Future<void> Function(String answer) onAnswer;
  final VoidCallback onReject;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _QuestionRow({
    required this.question,
    required this.showName,
    required this.onAnswer,
    required this.onReject,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  State<_QuestionRow> createState() => _QuestionRowState();
}

class _QuestionRowState extends State<_QuestionRow> {
  final TextEditingController _answerController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _wrap(final Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final q = widget.question;
    final bool isPending = q.status == 'pending';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: 4,
            children: [
              Text(q.askerName.isEmpty ? 'Seyirci' : q.askerName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              Text('· ${widget.showName}',
                  style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant)),
              _StatusTag(
                label: isPending ? 'Onay bekliyor' : 'Gizli',
                tone: isPending ? _Tone.ok : _Tone.warn,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Şikâyet: ${q.reportCount} · ${_fmtDate(q.createdAt)}',
            style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(q.text, style: TextStyle(fontSize: 13.5, color: colors.onSurface, height: 1.4)),
          if (q.answer != null && q.answer!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Cevap: ${q.answer}',
                style: TextStyle(
                    fontSize: 13, color: colors.onSurfaceVariant, fontStyle: FontStyle.italic)),
          ],
          if (isPending) ...[
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              textField: true,
              label: 'Cevap',
              child: TextField(
                controller: _answerController,
                maxLength: 600,
                maxLines: 3,
                minLines: 2,
                enabled: !_busy,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Cevap (en fazla 600 karakter; bağlantı yazılamaz)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              if (isPending)
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _wrap(() => widget.onAnswer(_answerController.text)),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Yanıtla ve yayınla'),
                ),
              if (isPending)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _wrap(() async => widget.onReject()),
                  icon: const Icon(Icons.block_rounded, size: 16),
                  label: const Text('Reddet'),
                )
              else
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _wrap(() async => widget.onRestore()),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('Geri aç'),
                ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _wrap(() async => widget.onDelete()),
                icon: Icon(Icons.delete_forever_rounded, size: 16, color: colors.error),
                label: Text('Sil', style: TextStyle(color: colors.error)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: colors.error.withValues(alpha: 0.5))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// İŞLEM KAYITLARI (ModerationLog)
// ==============================================================================

class _LogList extends StatelessWidget {
  final Future<List<_ModLogEntry>> future;
  final Map<String, String> showNames;
  final VoidCallback onRetry;

  const _LogList({required this.future, required this.showNames, required this.onRetry});

  @override
  Widget build(final BuildContext context) => FutureBuilder<List<_ModLogEntry>>(
        future: future,
        builder: (final context, final snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const AdminListLoading();
          }
          if (snap.hasError) {
            return AdminListError(message: 'Kayıtlar yüklenemedi: ${snap.error}');
          }
          final items = snap.data ?? const <_ModLogEntry>[];
          if (items.isEmpty) {
            return const AdminEmptyList(message: 'Kayıt yok.');
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            itemCount: items.length,
            separatorBuilder: (final _, final __) =>
                const SizedBox(height: AppSpacing.xs),
            itemBuilder: (final context, final i) {
              final entry = items[i];
              final colors = context.colors;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_fmtDate(entry.at)} · ${entry.byRole}',
                      style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.action} — ${showNames[entry.showId] ?? entry.showId}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    if (entry.reason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(entry.reason,
                            style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant)),
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
}

// ==============================================================================
// KÜÇÜK PARÇALAR (etiket, tarih, sebep diyaloğu, silme onayı)
// ==============================================================================

enum _Tone { ok, warn }

class _StatusTag extends StatelessWidget {
  final String label;
  final _Tone tone;

  const _StatusTag({required this.label, required this.tone});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final Color bg = tone == _Tone.ok ? colors.primaryContainer : colors.errorContainer;
    final Color fg = tone == _Tone.ok ? colors.onPrimaryContainer : colors.onErrorContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

String _fmtDate(final DateTime? d) {
  if (d == null) {
    return '—';
  }
  return DateFormat('d MMM y, HH:mm', 'tr').format(d);
}

/// Sebep giriş diyaloğu (zorunlu, 3-200 karakter) — her hide/restore/delete/
/// reject işlemi için. `isDelete` true ise başlık/metin kalıcı silmeye uygun
/// vurguyla gösterilir (onay adımı AYRI, bkz. [_confirmDelete]).
Future<String?> _askReason(final BuildContext context,
    {required final String title, final bool isDelete = false}) {
  return showDialog<String>(
    context: context,
    builder: (final ctx) => _ReasonDialog(title: title, isDelete: isDelete),
  );
}

class _ReasonDialog extends StatefulWidget {
  final String title;
  final bool isDelete;

  const _ReasonDialog({required this.title, required this.isDelete});

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid {
    final int len = _controller.text.trim().length;
    return len >= 3 && len <= 200;
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sebep (zorunlu, 3-200 karakter).'),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 200,
            maxLines: 3,
            minLines: 1,
            onChanged: (final _) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Örn. Hakaret içeriyor',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.of(context).pop(_controller.text.trim())
              : null,
          style: widget.isDelete
              ? FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError)
              : null,
          child: Text(widget.isDelete ? 'Devam et' : 'Onayla'),
        ),
      ],
    );
  }
}

Future<bool> _confirmDelete(final BuildContext context, final String message) async {
  final colors = context.colors;
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (final ctx) => AlertDialog(
      title: const Text('Kalıcı silme'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Vazgeç')),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
          child: const Text('Kalıcı sil'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

// ==============================================================================
// VERİ MODELLERİ + ERİŞİM (Firestore okuma + Cloud Functions yazma)
// ==============================================================================

DateTime? _ts(final dynamic v) =>
    v is Timestamp ? v.toDate() : (v is String ? DateTime.tryParse(v) : null);

class _ModReview {
  final String id;
  final String showId;
  final String userName;
  final int rating;
  final String text;
  final String status;
  final bool hidden;
  final String? hiddenReason;
  final int reportCount;
  final DateTime? createdAt;

  const _ModReview({
    required this.id,
    required this.showId,
    required this.userName,
    required this.rating,
    required this.text,
    required this.status,
    required this.hidden,
    required this.hiddenReason,
    required this.reportCount,
    required this.createdAt,
  });

  factory _ModReview.fromDoc(final String id, final Map<String, dynamic> d) {
    final dynamic r = d['rating'];
    return _ModReview(
      id: id,
      showId: (d['showId'] ?? '').toString(),
      userName: (d['userName'] ?? '').toString(),
      rating: r is num ? r.toInt().clamp(1, 5) : 0,
      text: (d['text'] ?? '').toString(),
      status: (d['status'] ?? (d['hidden'] == true ? 'hidden' : 'published')).toString(),
      hidden: d['hidden'] == true,
      hiddenReason: d['hiddenReason']?.toString(),
      reportCount: (d['reportCount'] is num) ? (d['reportCount'] as num).toInt() : 0,
      createdAt: _ts(d['createdAt']),
    );
  }
}

class _ModQuestion {
  final String id;
  final String showId;
  final String askerName;
  final String text;
  final String? answer;
  final String status;
  final int reportCount;
  final DateTime? createdAt;

  const _ModQuestion({
    required this.id,
    required this.showId,
    required this.askerName,
    required this.text,
    required this.answer,
    required this.status,
    required this.reportCount,
    required this.createdAt,
  });

  factory _ModQuestion.fromDoc(final String id, final Map<String, dynamic> d) =>
      _ModQuestion(
        id: id,
        showId: (d['showId'] ?? '').toString(),
        askerName: (d['askerName'] ?? '').toString(),
        text: (d['text'] ?? '').toString(),
        answer: d['answer']?.toString(),
        status: (d['status'] ?? 'pending').toString(),
        reportCount: (d['reportCount'] is num) ? (d['reportCount'] as num).toInt() : 0,
        createdAt: _ts(d['createdAt'] ?? d['_createdAt']),
      );
}

class _ModLogEntry {
  final DateTime? at;
  final String byRole;
  final String action;
  final String showId;
  final String reason;

  const _ModLogEntry({
    required this.at,
    required this.byRole,
    required this.action,
    required this.showId,
    required this.reason,
  });

  factory _ModLogEntry.fromDoc(final Map<String, dynamic> d) => _ModLogEntry(
        at: _ts(d['at']),
        byRole: (d['byRole'] ?? '').toString(),
        action: (d['action'] ?? '').toString(),
        showId: (d['showId'] ?? '').toString(),
        reason: (d['reason'] ?? '').toString(),
      );
}

class _ModerationException implements Exception {
  final String code;
  final String message;
  const _ModerationException(this.code, this.message);
  @override
  String toString() => message;
}

/// Firestore (okuma) + Cloud Functions (yazma) — bu sekmeye özel, admin-only
/// erişim. Review/Question'a istemci YAZAMAZ (firestore.rules); tüm
/// yazımlar zaten deploy edilmiş sunucu callable'larıdır (bkz. CLAUDE.md).
class _ModerationRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseFunctions get _fn => FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<Map<String, dynamic>> _call(final String name, final Map<String, dynamic> data) async {
    try {
      final r = await _fn.httpsCallable(name).call<dynamic>(data);
      final d = r.data;
      return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      final det = e.details;
      final String code = det is Map && det['code'] is String ? det['code'] as String : e.code;
      throw _ModerationException(code, _mapError(e.code, code, e.message));
    }
  }

  static String _mapError(final String grpcCode, final String code, final String? serverMessage) {
    if (grpcCode == 'permission-denied' || code == 'permission-denied') {
      return 'Bu işlem için yönetici yetkisi gerekir.';
    }
    if (grpcCode == 'resource-exhausted') {
      return 'Çok sık işlem yaptın. Biraz sonra tekrar dene.';
    }
    if ((grpcCode == 'invalid-argument' || grpcCode == 'failed-precondition') &&
        serverMessage != null &&
        serverMessage.isNotEmpty) {
      return serverMessage;
    }
    if (grpcCode == 'not-found') {
      return 'Kayıt bulunamadı; liste yenilendi.';
    }
    return 'İşlem tamamlanamadı. Bağlantını kontrol edip tekrar dene.';
  }

  Future<List<_ModReview>> fetchReviews({required final bool queueOnly}) async {
    final field = queueOnly ? 'queue' : 'hidden';
    final snap = await _db
        .collection('Review')
        .where(field, isEqualTo: true)
        .limit(200)
        .get();
    return [for (final d in snap.docs) _ModReview.fromDoc(d.id, d.data())];
  }

  Future<List<_ModQuestion>> fetchQuestions() async {
    final results = await Future.wait([
      _db.collection('Question').where('status', isEqualTo: 'pending').limit(100).get(),
      _db.collection('Question').where('status', isEqualTo: 'hidden').limit(100).get(),
    ]);
    final list = [
      for (final snap in results)
        for (final d in snap.docs) _ModQuestion.fromDoc(d.id, d.data()),
    ];
    list.sort((final a, final b) =>
        (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return list;
  }

  Future<List<_ModLogEntry>> fetchLog() async {
    final snap = await _db.collection('ModerationLog').limit(200).get();
    final list = [for (final d in snap.docs) _ModLogEntry.fromDoc(d.data())];
    list.sort((final a, final b) =>
        (b.at ?? DateTime(2000)).compareTo(a.at ?? DateTime(2000)));
    return list;
  }

  Future<void> adminModerateReview(
          {required final String reviewId, required final String action, required final String reason}) =>
      _call('adminModerate', {'reviewId': reviewId, 'action': action, 'reason': reason});

  Future<void> answerQuestion({required final String id, required final String answer}) =>
      _call('answerQuestion', {'id': id, 'answer': answer});

  Future<void> rejectQuestion({required final String id, required final String reason}) =>
      _call('rejectQuestion', {'id': id, 'reason': reason});

  Future<void> hideQuestion(
          {required final String id, required final String reason, final bool restore = false}) =>
      _call('hideQuestion', {'id': id, 'reason': reason, 'restore': restore});

  Future<void> deleteQuestion({required final String id, required final String reason}) =>
      _call('deleteQuestion', {'id': id, 'reason': reason});
}
