import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../auth/presentation/providers/auth_provider.dart'
    show currentUserIdProvider, isUserPrivilegedProvider;
import '../../../users/presentation/providers/user_provider.dart';
import '../../data/review_repository.dart';
import '../providers/review_providers.dart';

/// Doldurulmuş / yarım / boş yıldızlar (salt gösterim).
class StarRow extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;

  const StarRow({super.key, required this.rating, this.size = 16, this.color});

  @override
  Widget build(final BuildContext context) {
    final Color c = color ?? const Color(0xFFF5B301);
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 1; i <= 5; i++)
            Icon(
              rating >= i
                  ? Icons.star_rounded
                  : (rating >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
              size: size,
              color: c,
            ),
        ],
      ),
    );
  }
}

/// Kartların üstüne konan küçük "★ 4.6" rozeti. Puan yoksa hiçbir şey çizmez.
class RatingChip extends ConsumerWidget {
  final String showId;
  final bool onImage;

  const RatingChip({super.key, required this.showId, this.onImage = true});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ReviewStat? stat = ref.watch(reviewStatsProvider).value?[showId];
    if (stat == null || stat.count == 0) return const SizedBox.shrink();
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg =
        onImage ? Colors.black.withValues(alpha: 0.6) : cs.surfaceContainerHigh;
    final Color fg = onImage ? Colors.white : cs.onSurface;
    return Semantics(
      label:
          'Puan ${stat.average.toStringAsFixed(1)} üzerinden 5, ${stat.count} yorum',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF5B301)),
          const SizedBox(width: 3),
          Text(stat.average.toStringAsFixed(1),
              style: Sk.ui(context,
                  size: 12, color: fg, weight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

String _shortName(final String first, final String last) {
  final String f = first.trim();
  final String l = last.trim();
  if (f.isEmpty) return 'Seyirci';
  return l.isEmpty ? f : '$f ${l.substring(0, 1).toUpperCase()}.';
}

String _ago(final DateTime? d) {
  if (d == null) return '';
  final Duration diff = DateTime.now().difference(d);
  if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()} yıl önce';
  if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()} ay önce';
  if (diff.inDays >= 1) return '${diff.inDays} gün önce';
  if (diff.inHours >= 1) return '${diff.inHours} saat önce';
  return 'az önce';
}

/// Oyun detayında: özet puan + dağılım + yorum yaz + yorumlar.
class ReviewsSection extends ConsumerStatefulWidget {
  final String showId;
  final String showName;

  const ReviewsSection({super.key, required this.showId, required this.showName});

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  bool _all = false;

  Future<void> _compose(final Review? existing) async {
    HapticFeedback.selectionClick();
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final ctx) => _Composer(
          showId: widget.showId, showName: widget.showName, existing: existing),
    );
    if (saved == true && mounted) {
      refreshReviews(ref, widget.showId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Yorumun kaydedildi. Teşekkürler!'),
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _delete(final Review r) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: const Text('Yorumun silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(reviewRepositoryProvider).delete(r.id);
    if (mounted) refreshReviews(ref, widget.showId);
  }

  Future<void> _report(final Review r, final String uid) async {
    try {
      await ref.read(reviewRepositoryProvider).report(r.id, uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Şikâyetin alındı. İnceleyeceğiz.'),
          behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Şikâyet gönderilemedi. Tekrar dene.'),
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _toggleHidden(final Review r) async {
    await ref.read(reviewRepositoryProvider).setHidden(r.id, !r.hidden);
    if (mounted) refreshReviews(ref, widget.showId);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? uid = ref.watch(currentUserIdProvider);
    final bool loggedIn = uid != null && uid.isNotEmpty;
    final bool isAdmin = ref.watch(isUserPrivilegedProvider);
    final async = ref.watch(reviewsByShowProvider(widget.showId));
    final bool canReview = ref.watch(canReviewProvider(widget.showId)).value ?? false;

    return async.when(
      loading: () => const SkBone(height: 120, radius: AppRadius.lg),
      error: (final e, _) => const SizedBox.shrink(),
      data: (final all) {
        final List<Review> visible = [
          for (final Review r in all)
            if (!r.hidden || isAdmin) r,
        ];
        final Review? mine = loggedIn
            ? visible.where((final r) => r.userId == uid).firstOrNull
            : null;
        final List<Review> others = [
          for (final Review r in visible)
            if (r.userId != uid) r,
        ];
        final ReviewStat stat = ReviewStat.fromReviews(all)[widget.showId] ??
            ReviewStat.empty;
        final List<Review> shown = _all ? others : others.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkSectionHead(
              title: 'Yorumlar',
              subtitle: stat.count == 0
                  ? 'İlk yorumu sen yaz'
                  : '${stat.count} yorum',
            ),
            const SizedBox(height: AppSpacing.md),
            if (stat.count > 0) _Summary(stat: stat),
            if (stat.count > 0) const SizedBox(height: AppSpacing.md),

            // Yazma çağrısı
            if (mine == null)
              _Callout(
                icon: canReview
                    ? Icons.rate_review_rounded
                    : Icons.confirmation_number_outlined,
                text: canReview
                    ? 'Bu oyunu izledin. Puanını ve düşüncelerini paylaş.'
                    : (loggedIn
                        ? 'Yorum yazmak için bu oyunun biletini alıp izlemiş olmalısın.'
                        : 'Yorum yazmak için giriş yapıp oyunu izlemiş olmalısın.'),
                action: canReview ? 'Yorum yaz' : null,
                onTap: canReview ? () => _compose(null) : null,
              ),

            if (mine != null)
              _ReviewTile(
                review: mine,
                isMine: true,
                isAdmin: isAdmin,
                onEdit: () => _compose(mine),
                onDelete: () => _delete(mine),
              ),
            for (final Review r in shown)
              _ReviewTile(
                review: r,
                isMine: false,
                isAdmin: isAdmin,
                onReport: loggedIn ? () => _report(r, uid) : null,
                onToggleHidden: isAdmin ? () => _toggleHidden(r) : null,
              ),
            if (others.length > 3)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _all = !_all),
                  child: Text(_all
                      ? 'Daha az göster'
                      : 'Tüm yorumları göster (${others.length})'),
                ),
              ),
            if (others.isEmpty && mine == null && stat.count == 0)
              Text('Henüz yorum yok.',
                  style: Sk.ui(context,
                      size: 13.5,
                      color: cs.onSurfaceVariant,
                      weight: FontWeight.w500)),
          ],
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  final ReviewStat stat;
  const _Summary({required this.stat});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int maxN = stat.distribution.reduce((a, b) => a > b ? a : b);
    return SkSoftCard(
      radius: AppRadius.lg,
      color: cs.surfaceContainerHigh,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(stat.average.toStringAsFixed(1),
                  style: Sk.display(context, size: 44, height: 1.0)),
              const SizedBox(height: 6),
              StarRow(rating: stat.average, size: 16),
            ],
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              children: [
                for (int s = 5; s >= 1; s--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          child: Text('$s',
                              style: Sk.ui(context,
                                  size: 12,
                                  color: cs.onSurfaceVariant,
                                  weight: FontWeight.w700)),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                  begin: 0,
                                  end: maxN == 0
                                      ? 0
                                      : stat.distribution[s - 1] / maxN),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (_, final v, __) => LinearProgressIndicator(
                                value: v,
                                minHeight: 7,
                                backgroundColor:
                                    cs.outlineVariant.withValues(alpha: 0.4),
                                color: const Color(0xFFF5B301),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onTap;

  const _Callout({required this.icon, required this.text, this.action, this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SkSoftCard(
        radius: AppRadius.lg,
        color: cs.surfaceContainerLow,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(text,
                  style: Sk.ui(context,
                      size: 13.5, weight: FontWeight.w600, height: 1.4)),
            ),
            if (action != null) ...[
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(shape: const StadiumBorder()),
                child: Text(action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  final bool isMine;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onToggleHidden;

  const _ReviewTile({
    required this.review,
    required this.isMine,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.onToggleHidden,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: review.hidden ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isMine
              ? cs.primary.withValues(alpha: 0.1)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
              color: isMine
                  ? cs.primary.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: review.userImage.startsWith('http')
                      ? NetworkImage(review.userImage)
                      : null,
                  child: review.userImage.startsWith('http')
                      ? null
                      : Icon(Icons.person_rounded,
                          size: 18, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(isMine ? 'Senin yorumun' : review.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Sk.ui(context,
                                  size: 13.5, weight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.verified_rounded,
                            size: 14, color: cs.primary),
                      ]),
                      Text('İzledi · ${_ago(review.createdAt)}',
                          style: Sk.ui(context,
                              size: 11.5,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w600)),
                    ],
                  ),
                ),
                StarRow(rating: review.rating.toDouble(), size: 15),
              ],
            ),
            if (review.text.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm + 2),
              Text(review.text.trim(),
                  style: Sk.ui(context,
                      size: 14,
                      weight: FontWeight.w500,
                      height: 1.5,
                      color: cs.onSurface.withValues(alpha: 0.9))),
            ],
            if (review.hidden)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Gizlendi (yalnızca yöneticiler görür)',
                    style: Sk.ui(context,
                        size: 12,
                        color: cs.error,
                        weight: FontWeight.w700)),
              ),
            Wrap(
              spacing: AppSpacing.md,
              children: [
                if (isMine) ...[
                  _TextAction('Düzenle', Icons.edit_rounded, onEdit),
                  _TextAction('Sil', Icons.delete_outline_rounded, onDelete),
                ],
                if (!isMine && onReport != null)
                  _TextAction('Şikâyet et', Icons.flag_outlined, onReport),
                if (!isMine && isAdmin && onToggleHidden != null)
                  _TextAction(review.hidden ? 'Göster' : 'Gizle',
                      Icons.visibility_off_outlined, onToggleHidden),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _TextAction(this.label, this.icon, this.onTap);

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return PressScale(
      onTap: onTap ?? () {},
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: Sk.ui(context,
                  size: 12.5,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

/// Alttan açılan yorum yazma/düzenleme formu.
class _Composer extends ConsumerStatefulWidget {
  final String showId;
  final String showName;
  final Review? existing;

  const _Composer({required this.showId, required this.showName, this.existing});

  @override
  ConsumerState<_Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<_Composer> {
  late int _rating = widget.existing?.rating ?? 0;
  late final TextEditingController _text =
      TextEditingController(text: widget.existing?.text ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  static const List<String> _words = [
    'Seç',
    'Kötü',
    'Idare eder',
    'İyi',
    'Çok iyi',
    'Harika',
  ];

  Future<void> _save() async {
    if (_rating == 0) {
      setState(() => _error = 'Önce yıldız ver.');
      return;
    }
    final String? uid = ref.read(currentUserIdProvider);
    final profile = ref.read(userProfileProvider).value;
    if (uid == null || uid.isEmpty) {
      setState(() => _error = 'Yorum için giriş yapmalısın.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(reviewRepositoryProvider).upsert(
            userId: uid,
            showId: widget.showId,
            userName: _shortName(profile?.firstName ?? '', profile?.lastName ?? ''),
            userImage: profile?.imageUrl ?? '',
            rating: _rating,
            text: _text.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Kaydedilemedi. Bağlantını kontrol edip tekrar dene.';
        });
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing == null ? 'Yorum yaz' : 'Yorumunu düzenle',
                style: Sk.display(context, size: 26, height: 1.1)),
            const SizedBox(height: 4),
            Text(widget.showName,
                style: Sk.ui(context,
                    size: 13.5,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Column(children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 1; i <= 5; i++)
                      Semantics(
                        button: true,
                        label: '$i yıldız',
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _rating = i);
                          },
                          child: AnimatedScale(
                            scale: _rating == i ? 1.25 : 1,
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOutBack,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                _rating >= i
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 42,
                                color: const Color(0xFFF5B301),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Text(_words[_rating],
                    style: Sk.ui(context,
                        size: 13,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _text,
              maxLength: 500,
              maxLines: 5,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Oyun nasıldı? (isteğe bağlı)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: const StadiumBorder()),
                child: _busy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.onPrimary))
                    : const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
