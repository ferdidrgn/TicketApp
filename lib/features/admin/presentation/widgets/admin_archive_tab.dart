import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';

/// Arşiv raporu.
class ArchiveReport {
  int scanned = 0; // yaşı dolan seans
  int archivable = 0; // silinebilir (biletleri özetli)
  int backfilled = 0; // özeti sonradan yazılan bilet
  int archived = 0; // silinen seans
  final List<String> skipped = [];
}

/// 1 yıldan eski seansları (Event) güvenle arşivler:
///
/// 1. Seansın bütün biletlerinde özet (showName…) yoksa canlı kayıttan YAZILIR
///    (yalnızca 4 özet alanı; kurallar admin için buna izin vermeli).
/// 2. Özet yazılamayan bilet varsa o seans ATLANIR (bilet bozulmasın).
/// 3. Hepsi özetliyse seans dokümanı silinir (koltuk haritası büyük yer
///    kaplar). Bilet, oyun ve sahne kayıtlarına dokunulmaz.
///
/// `dryRun: true` hiçbir şey yazmaz/silmez; sadece rapor verir.
class EventArchiveService {
  final FirebaseFirestore _db;
  EventArchiveService([final FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  Future<ArchiveReport> run({
    final Duration age = const Duration(days: 365),
    final bool dryRun = true,
  }) async {
    final report = ArchiveReport();
    final cutoff = DateTime.now().subtract(age);

    final events = await _db.collection('Event').get();
    final showCache = <String, Map<String, dynamic>?>{};
    final stageCache = <String, Map<String, dynamic>?>{};

    Future<Map<String, dynamic>?> docOf(final String col, final String id,
        final Map<String, Map<String, dynamic>?> cache) async {
      if (id.isEmpty) return null;
      if (cache.containsKey(id)) return cache[id];
      final d = await _db.collection(col).doc(id).get();
      return cache[id] = d.data();
    }

    for (final e in events.docs) {
      final data = e.data();
      final String dateRaw = (data['date'] ?? '').toString();
      final DateTime? when = DateFormatter.parseDateString(dateRaw);
      if (when == null || when.isAfter(cutoff)) continue;
      report.scanned++;

      final tickets =
          await _db.collection('Ticket').where('eventId', isEqualTo: e.id).get();
      bool safe = true;
      for (final t in tickets.docs) {
        final td = t.data();
        if ((td['showName'] ?? '').toString().trim().isNotEmpty) continue;
        final show = await docOf('Show', (td['showId'] ?? '').toString(), showCache);
        final stage =
            await docOf('Stage', (td['stageId'] ?? '').toString(), stageCache);
        final String name = (show?['name'] ?? '').toString();
        if (name.isEmpty) {
          safe = false; // özetlenecek canlı kayıt da yok → dokunma
          report.skipped.add('${e.id}: bilet ${t.id} için oyun adı bulunamadı');
          break;
        }
        if (dryRun) {
          report.backfilled++;
          continue;
        }
        try {
          await t.reference.update({
            'showName': name,
            'showImageUrl': (show?['imageUrl'] ?? '').toString(),
            'stageName': (stage?['name'] ?? '').toString(),
            'eventDate': dateRaw,
          });
          report.backfilled++;
        } catch (err) {
          safe = false;
          report.skipped.add('${e.id}: bilet ${t.id} güncellenemedi ($err)');
          break;
        }
      }
      if (!safe) continue;
      report.archivable++;
      if (dryRun) continue;
      try {
        await e.reference.delete();
        report.archived++;
      } catch (err) {
        report.skipped.add('${e.id}: silinemedi ($err)');
      }
    }
    return report;
  }
}

/// Admin → "Arşiv" sekmesi: önce ÖNİZLE, sonra onayla.
class AdminArchiveTab extends StatefulWidget {
  const AdminArchiveTab({super.key});

  @override
  State<AdminArchiveTab> createState() => _AdminArchiveTabState();
}

class _AdminArchiveTabState extends State<AdminArchiveTab> {
  final EventArchiveService _service = EventArchiveService();
  ArchiveReport? _report;
  bool _busy = false;
  bool _lastWasDry = true;
  String? _error;

  Future<void> _run({required final bool dryRun}) async {
    if (!dryRun) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (final ctx) => AlertDialog(
          title: const Text('Eski seanslar arşivlensin mi?'),
          content: const Text(
              '1 yıldan eski seanslar silinir. Biletleri bozulmaz: oyun adı, sahne ve tarih bilete yazılır. Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Vazgeç')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Arşivle')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _service.run(dryRun: dryRun);
      if (!mounted) return;
      setState(() {
        _report = r;
        _lastWasDry = dryRun;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final r = _report;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Eski seansları arşivle',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Yaşı 1 yılı geçen seanslar (Event) silinir; koltuk haritaları büyük '
          'yer kaplar. Her biletin üzerine önce oyun adı, sahne ve tarih '
          'yazılır, böylece kullanıcıların geçmiş biletleri bozulmaz. Oyun ve '
          'sahne kayıtları silinmez. Önce "Önizle" ile ne olacağını gör.',
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.45),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _run(dryRun: true),
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Önizle'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _run(dryRun: false),
                icon: const Icon(Icons.inventory_2_rounded),
                label: const Text('Arşivle'),
              ),
            ),
          ],
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.lg),
            child: LinearProgressIndicator(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Text('Hata: $_error', style: TextStyle(color: cs.error)),
          ),
        if (r != null)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_lastWasDry ? 'Önizleme (hiçbir şey değişmedi)' : 'Sonuç',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.sm),
                Text('Yaşı dolan seans: ${r.scanned}'),
                Text('Güvenle arşivlenebilir: ${r.archivable}'),
                Text(_lastWasDry
                    ? 'Özeti yazılacak bilet: ${r.backfilled}'
                    : 'Özeti yazılan bilet: ${r.backfilled}'),
                if (!_lastWasDry) Text('Silinen seans: ${r.archived}'),
                if (r.skipped.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Atlananlar (${r.skipped.length}):',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  for (final s in r.skipped.take(8))
                    Text(s,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
