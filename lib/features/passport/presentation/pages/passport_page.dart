import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../../domain/passport.dart';

/// Bilet satırlarından pasaport girdisi. Ad/sahne/tarih canlı kayıt varsa
/// ondan, yoksa biletin satın alma anındaki özetinden gelir (DetailedTicket).
List<PassportTicket> passportInputs(final List<DetailedTicket> tickets) =>
    tickets
        .map((final d) => PassportTicket(
              id: d.ticket.id,
              eventId: d.ticket.eventId,
              showId: d.ticket.showId,
              showName: d.showTitle,
              stageId: d.ticket.stageId,
              stageName: d.stageTitle,
              posterUrl: d.posterUrl,
              eventDate: d.dateText,
              usedAt: d.ticket.usedAt,
              paymentStatus: d.ticket.paymentStatus,
              cancelled: d.isCancelled,
            ))
        .toList();

String _fmt(final DateTime? d) => d == null
    ? ''
    : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// PASAPORTUM — yalnız sahibine görünür (userId = oturum açan kullanıcı).
/// Hesaplama istemcide, mevcut `myTicketsProvider` verisinden yapılır;
/// sunucuya hiçbir şey yazılmaz. Paylaşım görselinde ad/telefon yoktur.
class PassportPage extends ConsumerStatefulWidget {
  final String userId;
  const PassportPage({super.key, required this.userId});

  @override
  ConsumerState<PassportPage> createState() => _PassportPageState();
}

class _PassportPageState extends ConsumerState<PassportPage> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share(final PassportSummary p) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    HapticFeedback.selectionClick();
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('kart hazır değil');
      final ui.Image img = await boundary.toImage(pixelRatio: 3);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('görsel üretilemedi');
      final bytes = data.buffer.asUint8List();
      await SharePlus.instance.share(ShareParams(
        text: p.shareText,
        files: [
          XFile.fromData(bytes,
              mimeType: 'image/png', name: 'tiyatrol-pasaport.png')
        ],
        fileNameOverrides: const ['tiyatrol-pasaport.png'],
      ));
    } catch (e) {
      debugPrint('Pasaport görsel paylaşımı olmadı (${e.runtimeType}); metin paylaşılıyor');
      try {
        await SharePlus.instance.share(ShareParams(text: p.shareText));
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final async = ref.watch(myTicketsProvider(widget.userId));
    final gutter = context.isTablet ? AppSpacing.xxxl : AppSpacing.lg;

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      title: 'Pasaportum',
      isLoading: false,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: cs.surface,
        ambientColor: cs.primary.withOpacity(0.04),
        safeAreaTop: true,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (final e, final s) => Center(
              child: Padding(
                padding: EdgeInsets.all(gutter),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Pasaportun yüklenemedi.',
                      style: context.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(myTicketsProvider(widget.userId)),
                    child: const Text('Tekrar dene'),
                  ),
                ]),
              ),
            ),
            data: (final tickets) {
              final p = buildPassport(passportInputs(tickets), DateTime.now());
              return ListView(
                padding: EdgeInsets.fromLTRB(
                    gutter, AppSpacing.sm, gutter, AppSpacing.massive),
                children: [
                  RepaintBoundary(key: _cardKey, child: _CoverCard(p: p)),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: Semantics(
                      button: true,
                      label: 'Pasaportu görsel olarak paylaş',
                      child: FilledButton.icon(
                        onPressed: _sharing ? null : () => _share(p),
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: Text(_sharing ? 'Hazırlanıyor…' : 'Paylaş'),
                      ),
                    ),
                  ),
                  if (p.isEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    const _EmptyState(),
                  ] else ...[
                    const SizedBox(height: AppSpacing.xxl),
                    const _SectionTitle('Sahne damgaları'),
                    _StampGrid(stamps: p.stamps),
                    const SizedBox(height: AppSpacing.xxl),
                    const _SectionTitle('İzlediğin oyunlar'),
                    for (final w in p.watched) _WatchedTile(w: w),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  const _SectionTitle('Rozetler'),
                  for (final b in p.badges) _BadgeTile(b: b),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Pasaport yalnız sana görünür; biletlerinden bu cihazda '
                    'hesaplanır. İptal edilen ve gelinmeyen biletler sayılmaz.',
                    style: context.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Paylaşılan görsel: yalnız sayılar + sezon; kişisel veri yok, afiş yok.
class _CoverCard extends StatelessWidget {
  final PassportSummary p;
  const _CoverCard({required this.p});

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final earned = p.badges.where((b) => b.earned).toList();
    return Semantics(
      container: true,
      label:
          'Tiyatro pasaportu: ${p.playCount} oyun, ${p.stageCount} sahne, bu yıl ${p.thisYear} oyun',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primary, cs.tertiary],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TİYATROL',
                style: TextStyle(
                    color: cs.onPrimary.withOpacity(0.8),
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.xs),
            Text('Tiyatro Pasaportu',
                style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.xl),
            Row(children: [
              _Stat(value: p.playCount, label: 'oyun'),
              _Stat(value: p.stageCount, label: 'sahne'),
              _Stat(value: p.thisYear, label: 'bu yıl'),
            ]),
            const SizedBox(height: AppSpacing.lg),
            Text(
              earned.isEmpty
                  ? 'İlk perde seni bekliyor.'
                  : earned.map((b) => b.title).join(' · '),
              style: TextStyle(
                  color: cs.onPrimary.withOpacity(0.92),
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$value',
            style: TextStyle(
                color: cs.onPrimary,
                fontSize: 38,
                height: 1,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: cs.onPrimary.withOpacity(0.8),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Semantics(
          header: true,
          child: Text(text,
              style: context.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(children: [
        Icon(Icons.theater_comedy_outlined, size: 40, color: cs.primary),
        const SizedBox(height: AppSpacing.md),
        Text('Pasaportun henüz boş',
            style: context.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Bir oyunu izlediğinde (seansı geçmiş ya da biletin kapıdan geçmiş '
          'olsun) sahnenin damgası buraya düşer.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
      ]),
    );
  }
}

/// Sahne başına bir damga; dönüşümlü eğimle ve sırayla "basılma" girişiyle.
/// Hareketi azalt açıksa animasyonsuz çizilir.
class _StampGrid extends StatelessWidget {
  final List<StageStamp> stamps;
  const _StampGrid({required this.stamps});

  @override
  Widget build(final BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (var i = 0; i < stamps.length; i++)
          _Stamp(
            stamp: stamps[i],
            tilt: (i.isEven ? -1 : 1) * (0.05 + (i % 3) * 0.02),
            delay: Duration(milliseconds: math.min(i * 90, 540)),
            animate: !reduce,
          ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  final StageStamp stamp;
  final double tilt;
  final Duration delay;
  final bool animate;
  const _Stamp(
      {required this.stamp,
      required this.tilt,
      required this.delay,
      required this.animate});

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final body = Semantics(
      label:
          '${stamp.name} sahnesi damgası, ${stamp.count} oyun${stamp.first != null ? ', ilk ziyaret ${_fmt(stamp.first)}' : ''}',
      child: Container(
        width: 104,
        height: 104,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cs.primary, width: 2.5),
          color: cs.primary.withOpacity(0.06),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(stamp.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(_fmt(stamp.first),
                style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            Text('×${stamp.count}',
                style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
    final tilted = Transform.rotate(angle: tilt, child: body);
    if (!animate) return tilted;
    return _Delayed(
      delay: delay,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.normal,
        curve: AppMotion.spring,
        builder: (final _, final v, final child) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: 1.35 - 0.35 * v, child: child),
        ),
        child: tilted,
      ),
    );
  }
}

/// Çocuğu [delay] sonra gösterir (kademeli damga girişi).
class _Delayed extends StatefulWidget {
  final Duration delay;
  final Widget child;
  const _Delayed({required this.delay, required this.child});

  @override
  State<_Delayed> createState() => _DelayedState();
}

class _DelayedState extends State<_Delayed> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  Widget build(final BuildContext context) => _show
      ? widget.child
      : const SizedBox(width: 104, height: 104);
}

class _WatchedTile extends StatelessWidget {
  final WatchedPlay w;
  const _WatchedTile({required this.w});

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final sub = [
      if (w.date != null) _fmt(w.date),
      if (w.stageName.isNotEmpty) w.stageName,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        container: true,
        label: '${w.name}${sub.isEmpty ? '' : ', $sub'}',
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: SizedBox(
              width: 48,
              height: 64,
              child: w.posterUrl.isEmpty
                  ? ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.theater_comedy_outlined,
                          color: cs.onSurfaceVariant))
                  : Image.network(w.posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (final _, final __, final ___) =>
                          ColoredBox(color: cs.surfaceContainerHighest)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              if (sub.isNotEmpty)
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final PassportBadge b;
  const _BadgeTile({required this.b});

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final on = b.earned;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        container: true,
        label: on
            ? '${b.title} rozeti kazanıldı'
            : '${b.title} rozeti kilitli. ${b.how} ${b.current}/${b.target}',
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: on ? cs.primary.withOpacity(0.08) : Colors.transparent,
            border: Border.all(color: on ? cs.primary : cs.outlineVariant),
          ),
          child: Row(children: [
            Icon(on ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                color: on ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.title,
                    style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: on ? cs.onSurface : cs.onSurfaceVariant)),
                if (!on) ...[
                  Text(b.how,
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                        value: b.current / b.target, minHeight: 5),
                  ),
                ],
              ]),
            ),
            if (!on)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text('${b.current}/${b.target}',
                    style: context.textTheme.labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ),
          ]),
        ),
      ),
    );
  }
}
