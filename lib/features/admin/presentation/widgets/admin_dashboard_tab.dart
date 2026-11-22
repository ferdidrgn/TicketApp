import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/admin_dashboard_stats.dart';
import '../providers/admin_dashboard_provider.dart';

const List<String> _ayKisa = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara', //
];
const List<String> _ayUzun = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık', //
];

/// Listenin [i]. elemanı varsa onu, yoksa null döner (negatif indeks güvenli).
T? _at<T>(final List<T> list, final int i) =>
    (i >= 0 && i < list.length) ? list[i] : null;

/// 'yyyy-MM' -> "Kas 2026" (kısa) ya da "Kasım 2026" (uzun).
String _ayAdi(final String monthKey, {final bool uzun = false}) {
  final parcalar = monthKey.split('-');
  final ayIndex = int.tryParse(_at(parcalar, 1) ?? '') ?? 1;
  final liste = uzun ? _ayUzun : _ayKisa;
  final isim = liste[(ayIndex - 1).clamp(0, 11).toInt()];
  final yil = _at(parcalar, 0) ?? '';
  return uzun ? '$isim $yil' : isim;
}

/// Türkiye biçimli tam sayı: 12.345 (intl locale verisine bağımlı değil).
String _sayi(final num? n) {
  if (n == null) return '—';
  final negatif = n < 0;
  final tamSayi = n.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < tamSayi.length; i++) {
    if (i > 0 && (tamSayi.length - i) % 3 == 0) buf.write('.');
    buf.write(tamSayi[i]);
  }
  return (negatif ? '-' : '') + buf.toString();
}

String _yuzde(final double? r) =>
    r == null ? '—' : '%${(r * 100).round()}';

/// Yönetim paneli — mobil "Genel bakış" (dashboard/istatistik) sekmesi.
///
/// Web admin paneliyle (`site/js/admin/dashboard.js`) AYNI veri kaynağı:
/// `adminStats` callable'ı (bkz. `functions/src/stats.js`). Grafikler pixel
/// pixel aynı değil — bu projede yeni bir grafik paketi eklenmedi
/// (`pubspec.yaml`'da hazır bir charting kütüphanesi yok), basit `Container`/
/// `Row` tabanlı çubuk görselleştirmeler kullanıldı; sayıların DOĞRULUĞU
/// görsel paritenin önünde.
///
/// `TabBarView` çocuğu olarak kullanılmak üzere tasarlandı — kendi
/// `Scaffold`'unu KURMAZ (ebeveyn `AdminHomePage` zaten bir `Scaffold`
/// içinde).
class AdminDashboardTab extends ConsumerWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final month = ref.watch(adminDashboardSelectedMonthProvider);
    final statsAsync = ref.watch(adminDashboardStatsProvider(month));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminDashboardStatsProvider(month));
        await ref.read(adminDashboardStatsProvider(month).future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardHeader(month: month),
            const SizedBox(height: AppSpacing.lg),
            statsAsync.when(
              loading: () => const _DashboardSkeleton(),
              error: (final e, final st) => _ErrorBanner(
                message: '$e',
                onRetry: () => ref.invalidate(adminDashboardStatsProvider(month)),
              ),
              data: (final stats) => _DashboardBody(stats: stats),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// BAŞLIK — ay seçici + yenile
// ==============================================================================

class _DashboardHeader extends ConsumerWidget {
  final String month;

  const _DashboardHeader({required this.month});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colors = context.colors;
    final aylar = lastTwelveMonthKeys();
    final selected = aylar.contains(month) ? month : aylar.first;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Genel bakış',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
        ),
        Semantics(
          label: 'İstatistik ayı seç',
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              items: aylar
                  .map((final a) => DropdownMenuItem(
                        value: a,
                        child: Text(_ayAdi(a, uzun: true)),
                      ))
                  .toList(),
              onChanged: (final v) {
                if (v == null) return;
                ref.read(adminDashboardSelectedMonthProvider.notifier).state =
                    v;
              },
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          label: 'İstatistikleri yenile',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(adminDashboardStatsProvider(month)),
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// YÜKLENİYOR / HATA
// ==============================================================================

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    Widget box(final double h) => Container(
          height: h,
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        );
    return Column(children: [box(140), box(220), box(220), box(160)]);
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('İstatistikler alınamadı',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: colors.onErrorContainer)),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: TextStyle(color: colors.onErrorContainer)),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// GÖVDE
// ==============================================================================

class _DashboardBody extends ConsumerWidget {
  final AdminDashboardStats stats;

  const _DashboardBody({required this.stats});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final r = stats;
    final generated = DateTime.fromMillisecondsSinceEpoch(r.generatedAt);
    final gSaat = '${generated.hour.toString().padLeft(2, '0')}:'
        '${generated.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KpiGrid(stats: r),
        const SizedBox(height: AppSpacing.xl),
        _SectionCard(
          title: 'Günlük görüntülenme',
          subtitle: _ayAdi(r.month, uzun: true),
          child: _DailyViewsChart(stats: r),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionCard(
          title: 'Aylık trend',
          trailing: _TrendShowPicker(trend: r.trend),
          child: const _TrendChart(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionCard(
          title: 'En çok görüntülenen oyunlar',
          child: _HorizontalBarList(
            emptyMessage: 'Bu ay henüz görüntülenme yok.',
            items: r.topShows
                .where((final s) => s.views > 0)
                .take(8)
                .map((final s) => _RankedItem(label: s.name, value: s.views.toDouble(), valueLabel: _sayi(s.views)))
                .toList(),
          ),
        ),
        if (r.sessions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: 'Seans doluluğu',
            child: _HorizontalBarList(
              emptyMessage: 'Koltuk düzeni oluşmuş yaklaşan seans yok.',
              items: r.sessions
                  .where((final s) => s.occupancy != null)
                  .take(10)
                  .map((final s) => _RankedItem(
                        label: '${s.show.isEmpty ? 'Oyun' : s.show} · ${_seansTarih(s.date)}',
                        value: (s.occupancy ?? 0) * 100,
                        valueLabel:
                            '${_yuzde(s.occupancy)} (${s.seatsSold}/${s.seatsTotal})',
                      ))
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _SectionCard(title: 'Oyunlar', child: _ShowsTable(shows: r.topShows)),
        if (r.limits.showRowsCapped)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Maliyeti düşük tutmak için en çok görüntülenen 20 oyun gösteriliyor.',
              style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        _SectionCard(
          title: 'Mekân sıralaması',
          child: _HorizontalBarList(
            emptyMessage: 'Mekân verisi yok.',
            items: r.venues
                .map((final v) => _RankedItem(
                      label: v.name,
                      value: v.seatsSold.toDouble(),
                      valueLabel: '${v.seatsSold} koltuk'
                          '${v.occupancy == null ? '' : ' · ${_yuzde(v.occupancy)}'}',
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionCard(
          title: 'Öne çıkanlar (bu ay)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mekânlar',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.xs),
              _HorizontalBarList(
                emptyMessage: 'Henüz yok.',
                items: r.topStages
                    .take(5)
                    .map((final x) => _RankedItem(
                        label: x.name, value: x.views.toDouble(), valueLabel: _sayi(x.views)))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Oyuncular',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.xs),
              _HorizontalBarList(
                emptyMessage: 'Henüz yok.',
                items: r.topPlayers
                    .take(5)
                    .map((final x) => _RankedItem(
                        label: x.name, value: x.views.toDouble(), valueLabel: _sayi(x.views)))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Görüntülenme sayaçları çerezsiz ve kimliksizdir (yalnız toplu '
          'sayı). Veri $gSaat itibarıyla; ${_sayi(r.limits.events)} seans '
          'okundu.',
          style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

String _seansTarih(final String isoDate) {
  final d = DateTime.tryParse(isoDate);
  if (d == null) return '';
  return '${d.day} ${_ayKisa[(d.month - 1).clamp(0, 11).toInt()]}';
}

// ==============================================================================
// KPI KARTLARI
// ==============================================================================

class _KpiGrid extends StatelessWidget {
  final AdminDashboardStats stats;

  const _KpiGrid({required this.stats});

  @override
  Widget build(final BuildContext context) {
    final kpi = stats.kpi;
    final kartlar = <_KpiData>[
      _KpiData(
        value: _sayi(kpi.viewsMonth),
        label: 'Görüntülenme',
        hint: '${_ayAdi(stats.month, uzun: true)} · oyun sayfası ${_sayi(kpi.showViewsMonth)}',
      ),
      _KpiData(
        value: _sayi(kpi.reservationsMonth),
        label: 'Rezervasyon (bu ay)',
        hint: 'toplam aktif ${_sayi(kpi.reservationsTotal)} · iptaller hariç',
      ),
      _KpiData(
        value: _sayi(kpi.freeTicketsMonth),
        label: 'Ücretsiz bilet (bu ay)',
        hint: 'toplam aktif ${_sayi(kpi.freeTicketsTotal)}',
      ),
      _KpiData(
        value: _sayi(kpi.upcomingSessions),
        label: 'Yaklaşan seans',
        hint: '${_sayi(kpi.activeShows)} aktif oyun',
      ),
      _KpiData(
        value: _yuzde(kpi.cancelRate),
        label: 'İptal oranı',
        hint: '${_sayi(kpi.cancelled)} iptal / ${_sayi(kpi.ticketsAllTime)} bilet (tüm zamanlar)',
        warn: (kpi.cancelRate ?? 0) > 0.25,
      ),
      _KpiData(
        value: _yuzde(kpi.noShowRate),
        label: 'Gelmeme oranı',
        hint: '${_sayi(kpi.noShow)} bilet "gelmedi"',
        warn: (kpi.noShowRate ?? 0) > 0.2,
      ),
      _KpiData(
        value: _sayi(kpi.checkedIn),
        label: 'Kapıdan geçen',
        hint: 'aktif biletlerin ${_yuzde(kpi.checkInRate)}',
      ),
      _KpiData(
        value: _yuzde(kpi.conversion),
        label: 'Görüntülenme → bilet',
        hint: 'bu ay oluşan bilet / oyun sayfası görüntülenmesi',
      ),
    ];

    return LayoutBuilder(builder: (final context, final constraints) {
      final cols = constraints.maxWidth > 760
          ? 4
          : constraints.maxWidth > 480
              ? 3
              : 2;
      const spacing = AppSpacing.sm;
      final itemWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: kartlar
            .map((final k) => SizedBox(width: itemWidth, child: _KpiCard(data: k)))
            .toList(),
      );
    });
  }
}

class _KpiData {
  final String value;
  final String label;
  final String hint;
  final bool warn;

  const _KpiData({
    required this.value,
    required this.label,
    required this.hint,
    this.warn = false,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final accent = data.warn ? colors.error : colors.primary;
    return Semantics(
      label: '${data.label}: ${data.value}. ${data.hint}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: data.warn ? colors.error.withOpacity(0.4) : colors.outlineVariant,
          ),
          boxShadow: AppShadows.level1(colors.shadow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: accent),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              data.label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              data.hint,
              style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// ORTAK BÖLÜM KARTI
// ==============================================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: AppShadows.level1(colors.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: colors.onSurface)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: TextStyle(
                              fontSize: 11, color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ==============================================================================
// GÜNLÜK GÖRÜNTÜLENME — çubuk grafik
// ==============================================================================

class _DailyViewsChart extends StatelessWidget {
  final AdminDashboardStats stats;

  const _DailyViewsChart({required this.stats});

  @override
  Widget build(final BuildContext context) {
    final parts = stats.month.split('-');
    final yil = int.tryParse(_at(parts, 0) ?? '') ?? DateTime.now().year;
    final ay = int.tryParse(_at(parts, 1) ?? '') ?? 1;
    final gunSayisi = DateTime(yil, ay + 1, 0).day;
    final harita = {for (final d in stats.days) d.day: d.views};

    final noktalar = List.generate(gunSayisi, (final i) {
      final gun = i + 1;
      final key = '${stats.month}-${gun.toString().padLeft(2, '0')}';
      return _ChartPoint(
        label: gun % 5 == 1 || gun == gunSayisi ? '$gun' : '',
        value: (harita[key] ?? 0).toDouble(),
        tooltip: '$gun ${_ayAdi(stats.month, uzun: true)}: ${_sayi(harita[key] ?? 0)} görüntülenme',
      );
    });

    return _BarChart(
        points: noktalar,
        emptyMessage: 'Bu ay henüz görüntülenme yok.',
        height: 190);
  }
}

// ==============================================================================
// AYLIK TREND — çubuk grafik + oyun filtresi
// ==============================================================================

class _TrendShowPicker extends ConsumerWidget {
  final AdminDashboardTrend trend;

  const _TrendShowPicker({required this.trend});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final selected = ref.watch(adminDashboardSelectedShowProvider);
    final mevcut = trend.shows.any((final s) => s.showId == selected) ? selected : null;
    return Semantics(
      label: 'Trend grafiğinde oyun filtrele',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: mevcut,
          isDense: true,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Tüm içerik')),
            ...trend.shows.map((final s) => DropdownMenuItem<String?>(
                  value: s.showId,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ),
                )),
          ],
          onChanged: (final v) =>
              ref.read(adminDashboardSelectedShowProvider.notifier).state = v,
        ),
      ),
    );
  }
}

class _TrendChart extends ConsumerWidget {
  const _TrendChart();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final month = ref.watch(adminDashboardSelectedMonthProvider);
    final statsAsync = ref.watch(adminDashboardStatsProvider(month));
    final stats = statsAsync.value;
    if (stats == null) return const SizedBox(height: 190);
    final selectedShowId = ref.watch(adminDashboardSelectedShowProvider);
    final eslesenler =
        stats.trend.shows.where((final s) => s.showId == selectedShowId);
    final serie = eslesenler.isEmpty ? null : eslesenler.first;
    final degerler = serie?.values ?? stats.trend.total;
    final noktalar = List.generate(stats.trend.months.length, (final i) {
      final v = i < degerler.length ? degerler[i] : 0;
      final ay = stats.trend.months[i];
      return _ChartPoint(
        label: _ayAdi(ay),
        value: v.toDouble(),
        tooltip: '${_ayAdi(ay, uzun: true)}: ${_sayi(v)} görüntülenme',
      );
    });
    return _BarChart(points: noktalar, emptyMessage: 'Henüz görüntülenme verisi yok.');
  }
}

// ==============================================================================
// GENEL ÇUBUK GRAFİK (basit Container/Row tabanlı — harici paket YOK)
// ==============================================================================

class _ChartPoint {
  final String label;
  final double value;
  final String tooltip;

  const _ChartPoint({required this.label, required this.value, required this.tooltip});
}

class _BarChart extends StatefulWidget {
  final List<_ChartPoint> points;
  final String emptyMessage;
  final double height;

  const _BarChart({required this.points, required this.emptyMessage, this.height = 170});

  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart> {
  int? _selected;

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    if (widget.points.isEmpty || widget.points.every((final p) => p.value == 0)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(widget.emptyMessage, style: TextStyle(color: colors.onSurfaceVariant)),
      );
    }
    final maxVal = widget.points.map((final p) => p.value).reduce((final a, final b) => a > b ? a : b);
    final tavan = maxVal <= 0 ? 1.0 : maxVal * 1.2;
    final secilen = _selected != null && _selected! < widget.points.length
        ? widget.points[_selected!]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: widget.points.asMap().entries.map((final entry) {
              final i = entry.key;
              final p = entry.value;
              final barH = (p.value / tavan) * (widget.height - 22);
              final secili = _selected == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _selected = secili ? null : i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: barH
                                .clamp(p.value > 0 ? 1.5 : 0.0, widget.height - 22)
                                .toDouble(),
                            decoration: BoxDecoration(
                              color: secili ? colors.primary : colors.primary.withOpacity(0.55),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.xs / 2)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 18,
                        child: p.label.isEmpty
                            ? null
                            : Text(
                                p.label,
                                style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          secilen?.tooltip ?? 'Ayrıntı için çubuğa dokun.',
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ==============================================================================
// YATAY ÇUBUK LİSTESİ (en çok görüntülenen oyunlar, mekânlar, öne çıkanlar…)
// ==============================================================================

class _RankedItem {
  final String label;
  final double value;
  final String valueLabel;

  const _RankedItem({required this.label, required this.value, required this.valueLabel});
}

class _HorizontalBarList extends StatelessWidget {
  final List<_RankedItem> items;
  final String emptyMessage;

  const _HorizontalBarList({required this.items, required this.emptyMessage});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    if (items.isEmpty) {
      return Text(emptyMessage, style: TextStyle(color: colors.onSurfaceVariant));
    }
    final maxVal = items.map((final i) => i.value).reduce((final a, final b) => a > b ? a : b);
    final tavan = maxVal <= 0 ? 1.0 : maxVal;
    return Column(
      children: items
          .map((final it) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        it.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: colors.onSurface),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xs / 2),
                        child: LinearProgressIndicator(
                          value: (it.value / tavan).clamp(0.02, 1.0).toDouble(),
                          minHeight: 8,
                          backgroundColor: colors.surfaceContainerHighest,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 72,
                      child: Text(
                        it.valueLabel,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ==============================================================================
// "OYUNLAR" TABLOSU — mobilde kompakt kart listesi
// ==============================================================================

class _ShowsTable extends StatelessWidget {
  final List<AdminDashboardTopShow> shows;

  const _ShowsTable({required this.shows});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    if (shows.isEmpty) {
      return Text('Henüz oyun verisi yok.', style: TextStyle(color: colors.onSurfaceVariant));
    }
    return Column(
      children: shows
          .map((final s) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _ShowStat('Görüntülenme', _sayi(s.views)),
                        _ShowStat('Bilet', _sayi(s.tickets)),
                        _ShowStat('Bu ay bilet', _sayi(s.ticketsMonth)),
                        _ShowStat('Dönüşüm', _yuzde(s.conversion)),
                        _ShowStat('Yaklaşan', _sayi(s.upcoming)),
                        _ShowStat(
                            'Doluluk',
                            s.occupancy == null
                                ? '—'
                                : '${_yuzde(s.occupancy)} (${s.seatsSold}/${s.seatsTotal})'),
                      ],
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _ShowStat extends StatelessWidget {
  final String label;
  final String value;

  const _ShowStat(this.label, this.value);

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant)),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: colors.onSurface)),
      ],
    );
  }
}
