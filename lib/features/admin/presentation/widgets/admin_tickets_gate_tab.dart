import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/firestore_provider.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart' show ticketPrice;
import '../../../purchase/data/datasources/purchase_remote_data_source_and_impl.dart'
    show kPurchaseFunctionsRegion;
import '../../../purchase/domain/entities/purchase_entities.dart' show SalesMode;
import '../../../purchase/presentation/providers/purchase_provider.dart'
    show salesConfigProvider;
import '../../../tickets/data/mappers/ticket_mapper.dart';
import '../../../tickets/data/models/ticket_model.dart';
import '../../../tickets/domain/entities/ticket.dart';
import 'admin_form_widgets.dart';
import 'admin_table_tools.dart';

/// "Biletler & Kapı" — site çapında bilet/kapı yönetimi (admin).
///
/// `site/js/admin/kapi.js` ile BİREBİR aynı davranış: sistem sağlığı
/// (`adminHealth`), satış modu (`Config/satis`, admin doğrudan Firestore'a
/// yazabiliyor — `firestore.rules`'taki `Config/{docId}` kuralı
/// kontrol edildi), kapı kontrolü (`adminCheckIn`, elle kod girişi — kamera/QR
/// okuyucu YOK) ve bilet listesi (`adminSetTicketStatus`). Aynı sayfadaki
/// mevcut `admin_tickets_tab.dart` TEK bir Show+Event'e odaklı koltuk
/// bloke/protokol ekranıdır — bu dosya ona dokunmaz, tamamen ayrı ve
/// SİTE ÇAPINDA bir araçtır.
///
/// Kendi kendine yeten tek dosya: provider'lar burada, klasik
/// `Provider`/`FutureProvider` (codegen'siz — `build_runner` bu sandbox'ta
/// çalışmıyor, bkz. CLAUDE.md).
class AdminTicketsGateTab extends ConsumerStatefulWidget {
  const AdminTicketsGateTab({super.key});

  @override
  ConsumerState<AdminTicketsGateTab> createState() =>
      _AdminTicketsGateTabState();
}

class _AdminTicketsGateTabState extends ConsumerState<AdminTicketsGateTab> {
  final GlobalKey<_TicketListSectionState> _ticketListKey = GlobalKey();
  final GlobalKey _ticketListAnchorKey = GlobalKey();

  void _refreshAll() {
    HapticFeedback.lightImpact();
    ref.invalidate(_adminHealthProvider);
    ref.invalidate(_adminTicketsProvider);
  }

  void _jumpToCancelled() {
    _ticketListKey.currentState?.showCancelled();
    final ctx = _ticketListAnchorKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: AppMotion.normal, curve: AppMotion.standard);
    }
  }

  @override
  Widget build(final BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: AdminSectionTitle(
                      title: 'Biletler & Kapı',
                      icon: Icons.confirmation_number_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: Semantics(
                    button: true,
                    label: 'Her şeyi yenile',
                    child: TextButton.icon(
                      onPressed: _refreshAll,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Yenile'),
                    ),
                  ),
                ),
              ],
            ),
            _HealthSection(onShowCancelled: _jumpToCancelled),
            const SizedBox(height: AppSpacing.xl),
            const _SalesModeSection(),
            const SizedBox(height: AppSpacing.xl),
            _DoorCheckSection(
                onChecked: () => ref.invalidate(_adminTicketsProvider)),
            const SizedBox(height: AppSpacing.xl),
            KeyedSubtree(
              key: _ticketListAnchorKey,
              child: _TicketListSection(key: _ticketListKey),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      );
}

// ==============================================================================
// PAYLAŞILAN PROVIDER'LAR + YARDIMCILAR
// ==============================================================================

/// Cloud Functions callable çağrısı (`functions/src/orders.js`/`team.js`).
Future<Map<String, dynamic>> _callAdmin(
    final String name, final Map<String, dynamic> data) async {
  final callable = FirebaseFunctions.instanceFor(region: kPurchaseFunctionsRegion)
      .httpsCallable(name);
  final res = await callable.call<Map<String, dynamic>>(data);
  return res.data;
}

/// `adminHealth({})` — sistem sağlığı (hold süresi, takılı sipariş, iade,
/// rezervasyon/ücretsiz/iptal sayaçları, hesap silme kuyruğu).
final _adminHealthProvider =
    FutureProvider<Map<String, dynamic>>((final ref) => _callAdmin('adminHealth', const {}));

/// Site çapında TÜM biletler (makul bir üst sınırla) — `kapi.js`'nin
/// `getDocs(query(collection(db,'Ticket'), limit(500)))` sorgusuyla aynı.
final _adminTicketsProvider = FutureProvider<List<Ticket>>((final ref) async {
  final snap =
      await ref.watch(firestoreProvider).collection('Ticket').limit(500).get();
  final out = <Ticket>[];
  for (final doc in snap.docs) {
    try {
      final data = Map<String, dynamic>.from(doc.data());
      data['_id'] = doc.id;
      out.add(TicketModel.fromFirestore(data).toEntity());
    } catch (_) {
      // Bozuk belge atlanır (bkz. TicketRemoteDataSourceImpl._mapSnapshot).
    }
  }
  return out;
});

const Map<String, String> _kStatusLabels = {
  'pay_at_venue': 'Rezervasyon',
  'paid': 'Ödendi',
  'no_show': 'Gelmedi',
  'cancelled': 'İptal',
  'free': 'Ücretsiz',
};

String _statusLabel(final String code) =>
    _kStatusLabels[code] ?? (code.isEmpty ? '—' : code);

/// `kapi.js`'teki `durumOf`: ödeme durumu boşsa yöntemden türetilir.
String _statusOf(final Ticket t) => t.paymentStatus.isNotEmpty
    ? t.paymentStatus
    : (t.orderMethod == 'venue'
        ? 'pay_at_venue'
        : (t.orderMethod == 'free' ? 'free' : 'paid'));

Map<Object?, Object?> _m(final Object? v) =>
    v is Map<Object?, Object?> ? v : const {};

int _i(final Object? v) => v is int ? v : (v is num ? v.toInt() : 0);

bool _bool(final Object? v) => v == true;

/// `kapi.js`'teki `sure()`: dakika farkını okunur Türkçe metne çevirir.
String _ageLabel(final Object? msRaw) {
  if (msRaw == null) return '—';
  final num ms = msRaw is num ? msRaw : (num.tryParse(msRaw.toString()) ?? 0);
  if (ms < 1) return 'şimdi';
  if (ms < 120) return '${ms.round()} dk önce';
  if (ms < 2880) return '${(ms / 60).round()} sa önce';
  return '${(ms / 1440).round()} gün önce';
}

String _formatUsedAt(final Object? v) {
  if (v == null) return '—';
  final dt = DateTime.tryParse(v.toString());
  if (dt == null) return '—';
  return DateFormat('dd.MM.yyyy HH:mm').format(dt.toLocal());
}

/// Teknik ayrıntı sızdırmayan, tek hata-eşleme yardımcısı (bu dosyaya özel,
/// `purchase_remote_data_source_and_impl.dart`'taki tabloyla aynı ruhta).
String _friendlyError(final Object e) {
  if (e is FirebaseFunctionsException) {
    final msg = (e.message ?? '').trim();
    final technical = msg.isEmpty ||
        msg.length > 240 ||
        RegExp(r'functions/|https?:|exception|firebase|stack',
                caseSensitive: false)
            .hasMatch(msg);
    if (!technical) return msg;
    switch (e.code) {
      case 'not-found':
        return 'Bulunamadı.';
      case 'permission-denied':
        return 'Bu işlem için yetkin yok.';
      case 'unauthenticated':
        return 'Giriş yapman gerekiyor.';
      default:
        return 'İşlem şu anda tamamlanamadı, lütfen tekrar dene.';
    }
  }
  return 'İşlem şu anda tamamlanamadı, lütfen tekrar dene.';
}

/// Tek, tutarlı onay diyaloğu (bkz. `admin_moderation_tab.dart._confirmDelete`
/// ile aynı desen).
Future<bool> _confirm(
  final BuildContext context, {
  required final String title,
  required final String message,
  required final String confirmLabel,
  final bool danger = true,
}) async {
  final colors = context.colors;
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (final ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: danger
              ? FilledButton.styleFrom(
                  backgroundColor: colors.error, foregroundColor: colors.onError)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Durum rozeti — `_checked` özel bir kod: "Girdi" (kapıdan geçti) etiketi.
class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final String status;

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final bool checked = status == '_checked';
    final String label = checked ? 'Girdi' : _statusLabel(status);
    final Color color = checked
        ? Colors.green
        : switch (status) {
            'pay_at_venue' => Colors.orange,
            'paid' => Colors.green,
            'no_show' => Colors.red,
            'cancelled' => Colors.red,
            _ => colors.onSurfaceVariant,
          };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Küçük sayı + etiket kartı (sistem sağlığı istatistik ızgarası).
class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final content = Container(
      width: 152,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface)),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: '$label: $value, ayrıntıları göster',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: content,
      ),
    );
  }
}

// ==============================================================================
// 1) SİSTEM SAĞLIĞI
// ==============================================================================

class _HealthSection extends ConsumerWidget {
  const _HealthSection({required this.onShowCancelled});

  final VoidCallback onShowCancelled;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final healthAsync = ref.watch(_adminHealthProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle(
            title: 'Sistem Sağlığı', icon: Icons.health_and_safety_rounded),
        healthAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (final e, final st) => AdminInlineBanner(
              message: 'Sağlık bilgisi alınamadı: ${_friendlyError(e)}'),
          data: (final h) =>
              _HealthBody(data: h, onShowCancelled: onShowCancelled),
        ),
      ],
    );
  }
}

class _HealthBody extends StatelessWidget {
  const _HealthBody({required this.data, required this.onShowCancelled});

  final Map<String, dynamic> data;
  final VoidCallback onShowCancelled;

  @override
  Widget build(final BuildContext context) {
    final hb = _m(data['heartbeat']);
    final stuck = _m(data['stuck']);
    final res = _m(data['reservations']);
    final free = _m(data['freeTickets']);
    final cancelled = _m(data['cancelled']);
    final refund = _m(data['refundRequired']);
    final reminders = _m(data['reminders']);
    final adRaw = data['accountDeletion'];
    final ad = adRaw is Map<Object?, Object?> ? adRaw : null;

    final bool hbStale = _bool(hb['stale']);
    final int held = _i(stuck['held']);
    final int paying = _i(stuck['paying']);
    final int stuckTotal = held + paying;
    final int refundCount = _i(refund['count']);
    final bool remindersStale = _bool(reminders['stale']);
    final bool adBad =
        ad != null && (_bool(ad['stale']) || _i(ad['failing']) > 0);

    final List<String> alerts = [
      if (hbStale)
        '⚠ Süre dolumu görevi ${hb['lastRunAt'] != null ? '${_ageLabel(hb['ageMinutes'])} çalışmış — 15 dakikadan eski' : 'hiç çalışmamış'}. '
            'Tutulan koltuklar serbest kalmayabilir.',
      if (stuckTotal > 0)
        '⚠ $stuckTotal sipariş süresi geçtiği hâlde kapanmadı (tutulan: $held, ödemede: $paying).',
      if (refundCount > 0) '⚠ İade gereken $refundCount sipariş var.',
      if (remindersStale)
        '⚠ Otomatik hatırlatma görevi çalışmıyor (son çalışma: '
            '${reminders['lastRunAt'] != null ? _ageLabel(reminders['ageMinutes']) : 'hiç'}).',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final a in alerts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AdminInlineBanner(message: a),
          ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _StatTile(
              value: _ageLabel(hb['ageMinutes']),
              label:
                  'Son süre dolumu (${_i(hb['expiredOrders'])} sipariş, ${_i(hb['releasedSeats'])} koltuk)',
            ),
            _StatTile(value: '$stuckTotal', label: 'Takılı sipariş'),
            _StatTile(
                value: '${_i(res['today'])} / ${_i(res['total'])}',
                label: 'Rezervasyon (bugün / toplam)'),
            _StatTile(
                value: '${_i(free['today'])} / ${_i(free['total'])}',
                label: 'Ücretsiz bilet (bugün / toplam)'),
            _StatTile(
              value: '${_i(cancelled['today'])} / ${_i(cancelled['total'])}',
              label: 'İptal edilen (bugün / toplam) ›',
              onTap: onShowCancelled,
            ),
            _StatTile(value: '$refundCount', label: 'İade gereken'),
          ],
        ),
        if (ad != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _AccountDeletionHealth(data: ad, bad: adBad),
        ],
      ],
    );
  }
}

/// Hesap silme kuyruğu sağlığı (`docs/HESAP-SILME.md`) — sunucu yanıtında
/// `accountDeletion` varsa gösterilir (eski backend'de/hatada yok).
class _AccountDeletionHealth extends ConsumerStatefulWidget {
  const _AccountDeletionHealth({required this.data, required this.bad});

  final Map<Object?, Object?> data;
  final bool bad;

  @override
  ConsumerState<_AccountDeletionHealth> createState() =>
      _AccountDeletionHealthState();
}

class _AccountDeletionHealthState
    extends ConsumerState<_AccountDeletionHealth> {
  bool _running = false;
  String? _resultText;

  Future<void> _run() async {
    final ok = await _confirm(
      context,
      title: 'Hesap silme işlerini çalıştır',
      message: 'Vadesi gelen hesap silme talepleri şimdi İŞLENECEK: bu '
          'hesaplar ve kişisel verileri KALICI olarak silinir (geri '
          'alınamaz). Devam edilsin mi?',
      confirmLabel: 'Şimdi çalıştır',
    );
    if (!ok || !mounted) return;
    setState(() {
      _running = true;
      _resultText = 'Çalışıyor…';
    });
    try {
      final r = await _callAdmin('adminProcessAccountDeletions', const {});
      final remaining = _i(r['remainingDue']);
      if (!mounted) return;
      setState(() => _resultText =
          'Silinen ${_i(r['deleted'])}, ertelenen ${_i(r['postponed'])}, '
          'hatalı ${_i(r['failed'])} (taranan ${_i(r['scanned'])}'
          '${remaining > 0 ? ', kalan vadesi gelmiş $remaining' : ''})');
      ref.invalidate(_adminHealthProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _resultText = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final d = widget.data;
    final bool stale = _bool(d['stale']);
    final int failing = _i(d['failing']);
    final int pending = _i(d['pending']);
    final int deleting = _i(d['deleting']);
    final int overdue = _i(d['overdue']);
    final bool idle = pending == 0 && deleting == 0 && overdue == 0 && failing == 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: widget.bad ? Border.all(color: colors.error) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HESAP SİLME (30 GÜN BEKLEME)',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1,
                color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (stale)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AdminInlineBanner(
                message: '⚠ Hesap silme görevi '
                    '${d['lastRunAt'] != null ? '${_ageLabel(d['ageMinutes'])} çalışmış' : 'hiç çalışmamış'} '
                    've vadesi geçmiş $overdue kayıt var. Aşağıdan elle çalıştır.',
              ),
            ),
          if (failing > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AdminInlineBanner(
                  message:
                      '⚠ $failing silme kaydı tekrar tekrar hata veriyor.'),
            ),
          if (idle)
            Text('Şu an bekleyen hesap silme talebi yok.',
                style:
                    TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _StatTile(value: '$pending', label: 'Bekleyen'),
              _StatTile(value: '$deleting', label: 'Siliniyor'),
              _StatTile(value: '$overdue', label: 'Vadesi geçmiş'),
              _StatTile(value: '$failing', label: 'Hatalı (3+)'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _running ? null : _run,
                child: _running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Silme işlerini şimdi çalıştır'),
              ),
              if (_resultText != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(_resultText!,
                      style: TextStyle(
                          fontSize: 11, color: colors.onSurfaceVariant)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 2) SATIŞ MODU
// ==============================================================================

class _SalesModeSection extends ConsumerStatefulWidget {
  const _SalesModeSection();

  @override
  ConsumerState<_SalesModeSection> createState() => _SalesModeSectionState();
}

class _SalesModeSectionState extends ConsumerState<_SalesModeSection> {
  bool _saving = false;

  Future<void> _setMode(final SalesMode mode) async {
    if (_saving) return;
    final current = ref.read(salesConfigProvider);
    if (mode == current.mode) return;
    if (mode == SalesMode.online) {
      final ok = await _confirm(
        context,
        title: 'Online ödemeyi aç?',
        message: 'iyzico henüz canlı değil. Online modu yine de açmak '
            'istiyor musun?',
        confirmLabel: 'Aç',
        danger: false,
      );
      if (!ok) return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(firestoreProvider).collection('Config').doc('satis').set({
        'mode': mode.name,
        'rezervasyonLimit': current.rezervasyonLimit,
        'iptalSaat': current.iptalSaat,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Satış modu güncellendi ✓')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_friendlyError(e)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _description(final SalesMode m) => switch (m) {
        SalesMode.kapali => 'Satış durur; yeni koltuk tutulamaz.',
        SalesMode.rezervasyon => 'Bilet onaylanır, ödeme sahnede alınır.',
        SalesMode.online => 'iyzico ile kartla ödeme.',
      };

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final config = ref.watch(salesConfigProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle(
            title: 'Satış Modu', icon: Icons.point_of_sale_rounded),
        AbsorbPointer(
          absorbing: _saving,
          child: Opacity(
            opacity: _saving ? 0.6 : 1,
            child: SegmentedButton<SalesMode>(
              segments: const [
                ButtonSegment(
                    value: SalesMode.kapali,
                    label: Text('Kapalı'),
                    icon: Icon(Icons.block_rounded)),
                ButtonSegment(
                    value: SalesMode.rezervasyon,
                    label: Text('Rezervasyon'),
                    icon: Icon(Icons.event_seat_rounded)),
                ButtonSegment(
                    value: SalesMode.online,
                    label: Text('Online'),
                    icon: Icon(Icons.credit_card_rounded)),
              ],
              selected: {config.mode},
              onSelectionChanged: (final s) => _setMode(s.first),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(_description(config.mode),
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        if (config.mode == SalesMode.online) ...[
          const SizedBox(height: AppSpacing.sm),
          const AdminInlineBanner(
            message: 'iyzico henüz canlı değil. Online modda kartla ödeme '
                'denenir; canlı anahtarlar tanımlanmadan açmayın.',
          ),
        ],
      ],
    );
  }
}

// ==============================================================================
// 3) KAPI KONTROLÜ
// ==============================================================================

class _CheckResult {
  const _CheckResult(
      {required this.ok, required this.title, required this.body, this.note});

  final bool ok;
  final String title;
  final String body;
  final String? note;
}

String _ticketSummary(final Map<Object?, Object?> t) {
  final showName = t['showName']?.toString() ?? '';
  final eventDate = t['eventDate']?.toString() ?? '';
  final stageName = t['stageName']?.toString() ?? '';
  final seatsRaw = t['buySeats'];
  final seats = seatsRaw is List ? seatsRaw.join(', ') : '';
  final customer = t['customerName']?.toString();
  final lines = <String>[
    [if (showName.isNotEmpty) showName else '—', if (eventDate.isNotEmpty) eventDate]
        .join(' · '),
    if (stageName.isNotEmpty) stageName,
    'Koltuk: ${seats.isEmpty ? '—' : seats}'
        '${customer != null && customer.isNotEmpty ? ' · $customer' : ''}',
  ];
  return lines.join('\n');
}

class _DoorCheckSection extends ConsumerStatefulWidget {
  const _DoorCheckSection({required this.onChecked});

  final VoidCallback onChecked;

  @override
  ConsumerState<_DoorCheckSection> createState() => _DoorCheckSectionState();
}

class _DoorCheckSectionState extends ConsumerState<_DoorCheckSection> {
  final _controller = TextEditingController();
  bool _busy = false;
  _CheckResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _result = const _CheckResult(
          ok: false, title: 'KOD YOK', body: 'Bilet kodunu gir ya da yapıştır.'));
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final data = await _callAdmin('adminCheckIn', {'ticketId': raw});
      final t = _m(data['ticket']);
      final summary = _ticketSummary(t);
      final bool ok = data['ok'] == true;
      final bool already = data['already'] == true;
      final String? paymentStatus = t['paymentStatus']?.toString();
      _CheckResult result;
      if (ok) {
        result = _CheckResult(
          ok: true,
          title: 'GEÇERLİ',
          body: summary,
          note: paymentStatus == 'pay_at_venue'
              ? 'ÖDEME ALINACAK — rezervasyon sahnede ödenir'
              : null,
        );
      } else if (already) {
        result = _CheckResult(
          ok: false,
          title: 'ZATEN KULLANILDI',
          body: '$summary\nİlk giriş: ${_formatUsedAt(t['usedAt'])}',
        );
      } else if (paymentStatus == 'cancelled') {
        result = _CheckResult(ok: false, title: 'İPTAL EDİLMİŞ', body: summary);
      } else {
        result = _CheckResult(
          ok: false,
          title: 'GEÇERSİZ',
          body: '$summary\nDurum: ${_statusLabel(paymentStatus ?? '')}',
        );
      }
      if (!mounted) return;
      setState(() => _result = result);
      widget.onChecked();
    } catch (e) {
      final bool notFound = e is FirebaseFunctionsException && e.code == 'not-found';
      if (!mounted) return;
      setState(() => _result = _CheckResult(
            ok: false,
            title: notFound ? 'BULUNAMADI' : 'HATA',
            body: notFound ? '"$raw" koduyla bilet yok.' : _friendlyError(e),
          ));
    } finally {
      if (mounted) setState(() => _busy = false);
      _controller.clear();
    }
  }

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle(
              title: 'Kapı Kontrolü', icon: Icons.sensor_door_rounded),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Bilet kodu',
                    hintText: 'QR okuyucu buraya yazar / elle yapıştır',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (final _) => _check(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: _busy ? null : _check,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Kontrol et'),
              ),
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: AppSpacing.md),
            _CheckResultCard(result: _result!),
          ],
        ],
      );
}

class _CheckResultCard extends StatelessWidget {
  const _CheckResultCard({required this.result});

  final _CheckResult result;

  @override
  Widget build(final BuildContext context) {
    final Color color = result.ok ? Colors.green : Colors.red;
    return Semantics(
      liveRegion: true,
      label: '${result.title}. ${result.body}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.title,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: color,
                  letterSpacing: 0.6),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(result.body, style: const TextStyle(fontSize: 13)),
            if (result.note != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(result.note!,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 4) BİLET LİSTESİ (+ 5. İPTAL EDİLENLER — aynı listenin durum filtresi)
// ==============================================================================

class _TicketListSection extends ConsumerStatefulWidget {
  const _TicketListSection({super.key});

  @override
  ConsumerState<_TicketListSection> createState() => _TicketListSectionState();
}

class _TicketListSectionState extends ConsumerState<_TicketListSection> {
  String _status = 'aktif';
  String? _eventId;
  String _sortId = 'show';
  bool _sortAsc = true;
  final _search = TextEditingController();
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  /// Sistem sağlığındaki "İptal edilen" sayacına dokununca çağrılır.
  void showCancelled() => setState(() => _status = 'cancelled');

  List<Ticket> _filtered(final List<Ticket> all) {
    final q = _search.text.trim().toLowerCase();
    return all.where((final t) {
      if (_eventId != null && t.eventId != _eventId) return false;
      final status = _statusOf(t);
      if (_status == 'aktif') {
        if (status == 'cancelled') return false;
      } else if (_status.isNotEmpty && status != _status) {
        return false;
      }
      if (q.isNotEmpty && !t.id.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  Map<String, String> _eventOptions(final List<Ticket> all) {
    final out = <String, String>{};
    for (final t in all) {
      if (t.eventId.isEmpty) continue;
      out.putIfAbsent(
          t.eventId,
          () =>
              '${t.showName.isEmpty ? 'Oyun' : t.showName} — ${t.eventDate.isEmpty ? '?' : t.eventDate}');
    }
    return out;
  }

  Future<void> _mutate(final Ticket ticket, final String target) async {
    if (_busyIds.contains(ticket.id)) return;
    if (target == 'cancelled') {
      final ok = await _confirm(
        context,
        title: 'Bileti iptal et?',
        message: 'Bilet iptal edilsin mi? Koltuklar başkasına açılır, geri '
            'alınamaz.',
        confirmLabel: 'İptal et',
      );
      if (!ok) return;
    } else if (target == 'no_show') {
      final date = DateFormatter.parseDateString(ticket.eventDate);
      final bool future = date != null && date.isAfter(DateTime.now());
      final ok = await _confirm(
        context,
        title: 'Gelmedi olarak işaretle?',
        message: future
            ? '⚠ Bu seans henüz olmadı (${ticket.eventDate}). "Gelmedi" '
                'işaretlenirse bu kişi bildirim/hatırlatmalardan düşer ama '
                'bilet iptal olmaz. Emin misin?'
            : 'Bu bilet "gelmedi" olarak işaretlensin mi? Bildirim/'
                'hatırlatmalardan düşer, bilet iptal olmaz.',
        confirmLabel: 'Gelmedi işaretle',
      );
      if (!ok) return;
    }
    setState(() => _busyIds.add(ticket.id));
    try {
      await _callAdmin('adminSetTicketStatus',
          {'ticketId': ticket.id, 'paymentStatus': target});
      ref.invalidate(_adminTicketsProvider);
      ref.invalidate(_adminHealthProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Güncellendi ✓')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_friendlyError(e)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busyIds.remove(ticket.id));
    }
  }

  Widget _rowButton(final String label, final bool busy, final VoidCallback onTap) =>
      TextButton(
        onPressed: busy ? null : onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          minimumSize: const Size(0, 32),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );

  List<Widget> _actionsFor(final Ticket t) {
    final status = _statusOf(t);
    if (status == 'cancelled') return const [];
    final bool busy = _busyIds.contains(t.id);
    return [
      if (t.orderMethod == 'venue' && status != 'pay_at_venue')
        _rowButton('Rezervasyon', busy, () => _mutate(t, 'pay_at_venue')),
      if (t.orderMethod == 'venue' && status != 'paid')
        _rowButton('Ödendi', busy, () => _mutate(t, 'paid')),
      if (status != 'no_show') _rowButton('Gelmedi', busy, () => _mutate(t, 'no_show')),
      if (t.orderMethod != 'card')
        _rowButton('İptal', busy, () => _mutate(t, 'cancelled')),
    ];
  }

  List<AdminTableColumn<Ticket>> get _columns => [
        AdminTableColumn<Ticket>(
          id: 'code',
          label: 'Kod',
          text: (final t) => t.id,
          compare: (final a, final b) => adminCompareText(a.id, b.id),
          cell: (final context, final t) =>
              Text(t.id.length > 8 ? '${t.id.substring(0, 8)}…' : t.id),
        ),
        AdminTableColumn<Ticket>(
          id: 'show',
          label: 'Oyun / seans',
          text: (final t) => '${t.showName} ${t.eventDate}',
          compare: (final a, final b) => adminCompareText(a.showName, b.showName),
          cell: (final context, final t) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.showName.isEmpty ? '—' : t.showName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(t.eventDate,
                  style: TextStyle(
                      fontSize: 11, color: context.colors.onSurfaceVariant)),
            ],
          ),
        ),
        AdminTableColumn<Ticket>(
          id: 'seats',
          label: 'Koltuk',
          text: (final t) => t.buySeats.join(', '),
          compare: (final a, final b) =>
              adminCompareText(a.buySeats.join(','), b.buySeats.join(',')),
        ),
        AdminTableColumn<Ticket>(
          id: 'price',
          label: 'Tutar',
          text: (final t) => ticketPrice(t.orderPrice) ?? t.orderPrice,
          compare: (final a, final b) =>
              (double.tryParse(a.orderPrice.replaceAll(',', '.')) ?? 0)
                  .compareTo(double.tryParse(b.orderPrice.replaceAll(',', '.')) ?? 0),
          numeric: true,
        ),
        AdminTableColumn<Ticket>(
          id: 'status',
          label: 'Durum',
          text: (final t) => _statusLabel(_statusOf(t)),
          compare: (final a, final b) =>
              adminCompareText(_statusLabel(_statusOf(a)), _statusLabel(_statusOf(b))),
          cell: (final context, final t) => Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _StatusTag(status: _statusOf(t)),
              if (t.usedAt.isNotEmpty) const _StatusTag(status: '_checked'),
            ],
          ),
        ),
        AdminTableColumn<Ticket>(
          id: 'actions',
          label: '',
          text: (final _) => '',
          compare: (final a, final b) => 0,
          cell: (final context, final t) =>
              Wrap(spacing: AppSpacing.xs, children: _actionsFor(t)),
        ),
      ];

  @override
  Widget build(final BuildContext context) {
    final ticketsAsync = ref.watch(_adminTicketsProvider);
    final allTickets = ticketsAsync.value ?? const <Ticket>[];
    final events = _eventOptions(allTickets);
    final filtered = _filtered(allTickets);
    final sorted = adminSorted(
        items: filtered,
        columns: _columns,
        sortColumnId: _sortId,
        sortAscending: _sortAsc);
    final visible = sorted.take(300).toList();
    final String? validEventId = events.containsKey(_eventId) ? _eventId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionTitle(
            title: _status == 'cancelled' ? 'İptal Edilenler' : 'Bilet Listesi',
            icon: Icons.receipt_long_rounded),
        if (allTickets.length >= 500)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'İlk 500 bilet gösteriliyor; daha fazlası olabilir.',
              style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AdminDropdownField<String?>(
            label: 'Etkinlik',
            value: validEventId,
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('Tüm etkinlikler')),
              ...events.entries.map((final e) => DropdownMenuItem<String?>(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (final v) => setState(() => _eventId = v),
          ),
        ),
        AdminListToolbar(
          searchController: _search,
          searchHint: 'Bilet kodu ara…',
          visibleCount: visible.length,
          totalCount: allTickets.length,
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          filterGroups: [
            AdminFilterGroup(
              options: const [
                AdminFilterOption(id: 'aktif', label: 'Aktif'),
                AdminFilterOption(id: '', label: 'Tüm durumlar'),
                AdminFilterOption(id: 'pay_at_venue', label: 'Rezervasyon'),
                AdminFilterOption(id: 'paid', label: 'Ödendi'),
                AdminFilterOption(id: 'no_show', label: 'Gelmedi'),
                AdminFilterOption(id: 'cancelled', label: 'İptal'),
                AdminFilterOption(id: 'free', label: 'Ücretsiz'),
              ],
              selectedId: _status,
              onSelected: (final id) => setState(() => _status = id),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ticketsAsync.when(
          loading: () => const AdminListLoading(rows: 4),
          error: (final e, final st) =>
              AdminListError(message: 'Biletler yüklenemedi: $e'),
          data: (final _) {
            if (allTickets.isEmpty) {
              return const AdminEmptyList(message: 'Henüz bilet yok.');
            }
            if (visible.isEmpty) {
              return const AdminEmptyList(
                  message: 'Bu filtreye uyan bilet yok.', isFiltered: true);
            }
            return AdminCatalogPane<Ticket>(
              items: visible,
              shrinkWrap: true,
              cardBuilder: (final t) => _GateTicketCard(
                ticket: t,
                status: _statusOf(t),
                actions: _actionsFor(t),
              ),
              table: AdminSortableTable<Ticket>(
                items: visible,
                columns: _columns,
                sortColumnId: _sortId,
                sortAscending: _sortAsc,
                onSort: ({required final columnId, required final ascending}) =>
                    setState(() {
                  _sortId = columnId;
                  _sortAsc = ascending;
                }),
                semanticLabel: (final t) =>
                    'Bilet ${t.id}, ${t.showName}, koltuk ${t.buySeats.join(', ')}',
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Mobil kart görünümü — sıradan bir satırdır, "bilet dili"nin fiziksel
/// koçan/perforasyon süsünü TAŞIMAZ (bu bir yoğun admin tablosu satırı,
/// `admin_tickets_tab.dart`'ın kendi `_TicketRow` düzeniyle aynı dilde).
class _GateTicketCard extends StatelessWidget {
  const _GateTicketCard(
      {required this.ticket, required this.status, required this.actions});

  final Ticket ticket;
  final String status;
  final List<Widget> actions;

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final priceLabel = ticketPrice(ticket.orderPrice) ?? ticket.orderPrice;
    return Semantics(
      label: 'Bilet ${ticket.id}, ${ticket.showName}, koltuk '
          '${ticket.buySeats.join(', ')}, durum ${_statusLabel(status)}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: colors.outlineVariant),
          boxShadow: AppShadows.level1(colors.shadow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.showName.isEmpty ? '—' : ticket.showName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(ticket.eventDate,
                          style: TextStyle(
                              fontSize: 11, color: colors.onSurfaceVariant)),
                      if (ticket.stageName.isNotEmpty)
                        Text(ticket.stageName,
                            style: TextStyle(
                                fontSize: 11, color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  alignment: WrapAlignment.end,
                  children: [
                    _StatusTag(status: status),
                    if (ticket.usedAt.isNotEmpty) const _StatusTag(status: '_checked'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.event_seat_rounded, size: 14, color: colors.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    ticket.buySeats.isEmpty ? '—' : ticket.buySeats.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                  ),
                ),
                Text(priceLabel,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: colors.primary)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Kod: ${ticket.id}',
                  style: TextStyle(fontSize: 10, color: colors.outline)),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
