import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/datasources/team_remote_data_source.dart';
import '../../domain/entities/team_manager_entities.dart';
import '../providers/team_providers.dart';
import 'team_manager_widgets.dart';

/// Önceden tanımlı, sunucu şablonlarına 1:1 karşılık gelen "sahne
/// kumandası" ikonları (web `ekip.js` IKON ile aynı fikir).
const Map<String, IconData> _kTemplateIcons = {
  'baslamak_uzere': Icons.alarm_rounded,
  'basladi': Icons.volume_off_rounded,
  'ara': Icons.local_cafe_rounded,
  'ara_bitiyor': Icons.notifications_active_rounded,
  'bitti': Icons.celebration_rounded,
  'ertelendi': Icons.event_repeat_rounded,
  'iptal': Icons.cancel_rounded,
  'genel': Icons.campaign_rounded,
};

String _fmtWhen(final int ms) =>
    DateFormat('d MMM, HH:mm', 'tr_TR').format(DateTime.fromMillisecondsSinceEpoch(ms));

/// "X dk/sa/gün sonra" / "önce" — web `gorece()` ile aynı mantık.
String _fmtRelative(final int ms) {
  final diffMin = ((ms - DateTime.now().millisecondsSinceEpoch) / 60000).round();
  final abs = diffMin.abs();
  final text = abs < 90
      ? '$abs dk'
      : abs < 48 * 60
          ? '${(abs / 60).round()} sa'
          : '${(abs / 1440).round()} gün';
  return diffMin >= 0 ? '$text sonra' : '$text önce';
}

/// Ekip yöneticisi — "Bildirim" sekmesi: kendi ekibinin bir oyununu, o
/// oyunun yaklaşan bir seansını seçer, sunucunun sunduğu şablonlardan
/// birini (ya da serbest metni) kullanarak o seansın bilet sahiplerine
/// bildirim gönderir. Kapsam SUNUCUDA denetlenir
/// (`functions/src/team.js` assertCanManageEvent) — bu widget yalnız
/// kullanıcının KENDİ ekiplerinin verisini listeler (iyi bir UX için),
/// gerçek güvenlik sınırı sunucudadır.
class TeamNotifyTab extends ConsumerStatefulWidget {
  final List<TeamManagerTeam> teams;

  const TeamNotifyTab({super.key, required this.teams});

  @override
  ConsumerState<TeamNotifyTab> createState() => _TeamNotifyTabState();
}

class _TeamNotifyTabState extends ConsumerState<TeamNotifyTab> {
  int _teamIndex = 0;
  String? _showId;
  String? _eventId;
  int _araMinutes = 15;
  final _genelTitle = TextEditingController();
  final _genelBody = TextEditingController();

  @override
  void initState() {
    super.initState();
    _autoSelect();
  }

  @override
  void dispose() {
    _genelTitle.dispose();
    _genelBody.dispose();
    super.dispose();
  }

  TeamManagerTeam get _team => widget.teams[_teamIndex];

  TeamManagerShow? get _show {
    for (final s in _team.shows) {
      if (s.showId == _showId) return s;
    }
    return null;
  }

  TeamManagerEvent? get _event {
    final show = _show;
    if (show == null) return null;
    for (final e in show.events) {
      if (e.eventId == _eventId) return e;
    }
    return null;
  }

  void _autoSelect() {
    final team = _team;
    if (!team.shows.any((final s) => s.showId == _showId)) {
      _showId = team.shows.isNotEmpty ? team.shows.first.showId : null;
    }
    final events = _show?.events ?? const <TeamManagerEvent>[];
    if (!events.any((final e) => e.eventId == _eventId)) {
      TeamManagerEvent? nearest;
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final e in events) {
        if (nearest == null ||
            (e.ms - now).abs() < (nearest.ms - now).abs()) {
          nearest = e;
        }
      }
      _eventId = nearest?.eventId;
    }
  }

  @override
  Widget build(final BuildContext context) {
    final team = _team;
    final show = _show;
    final event = _event;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        TeamSectionCard(
          title: 'Hedef seç',
          icon: Icons.theater_comedy_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.teams.length > 1)
                _Picker<int>(
                  label: 'Topluluk',
                  value: _teamIndex,
                  items: [
                    for (var i = 0; i < widget.teams.length; i++)
                      DropdownMenuItem(value: i, child: Text(widget.teams[i].name)),
                  ],
                  onChanged: (final v) => setState(() {
                    _teamIndex = v ?? 0;
                    _showId = null;
                    _eventId = null;
                    _autoSelect();
                  }),
                ),
              _Picker<String>(
                label: 'Oyun',
                value: _showId,
                items: [
                  for (final s in team.shows)
                    DropdownMenuItem(value: s.showId, child: Text(s.name)),
                ],
                emptyHint: 'Oyun yok',
                onChanged: (final v) => setState(() {
                  _showId = v;
                  _eventId = null;
                  _autoSelect();
                }),
              ),
              _Picker<String>(
                label: 'Seans',
                value: _eventId,
                items: [
                  for (final e in show?.events ?? const <TeamManagerEvent>[])
                    DropdownMenuItem(
                      value: e.eventId,
                      child: Text(
                          '${_fmtWhen(e.ms)}${e.stage.isNotEmpty ? ' · ${e.stage}' : ''}'),
                    ),
                ],
                emptyHint: 'Yaklaşan seans yok',
                onChanged: (final v) => setState(() => _eventId = v),
              ),
              if (event != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _OccupancyRow(event: event),
              ],
            ],
          ),
        ),
        if (event == null)
          const TeamSectionCard(
            child: TeamEmptyState(
              message: 'Bildirim göndermek için bir seans seç.',
              icon: Icons.event_busy_rounded,
            ),
          )
        else
          _NotifyComposer(
            key: ValueKey(event.eventId),
            eventId: event.eventId,
            event: event,
            araMinutes: _araMinutes,
            onAraMinutesChanged: (final v) => setState(() => _araMinutes = v),
            genelTitle: _genelTitle,
            genelBody: _genelBody,
          ),
      ],
    );
  }
}

class _OccupancyRow extends StatelessWidget {
  final TeamManagerEvent event;

  const _OccupancyRow({required this.event});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          TeamStatTile(value: '${event.sold}', label: 'Satılan'),
          TeamStatTile(value: '${event.held}', label: 'Tutulan'),
          TeamStatTile(value: '${event.total}', label: 'Toplam'),
          TeamStatTile(value: '%${event.occupancyPercent}', label: 'Doluluk'),
          const Spacer(),
          Text(_fmtRelative(event.ms),
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Picker<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String emptyHint;

  const _Picker({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.emptyHint = 'Seçenek yok',
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
        ),
        items: items.isEmpty
            ? [DropdownMenuItem(value: value, child: Text(emptyHint))]
            : items,
        onChanged: items.isEmpty ? null : onChanged,
      ),
    );
  }
}

/// Seçili seans için: temel önizleme (kaç kişiye ulaşılır) + şablon
/// ızgarası + serbest "Kısa mesaj" formu.
class _NotifyComposer extends ConsumerWidget {
  final String eventId;
  final TeamManagerEvent event;
  final int araMinutes;
  final ValueChanged<int> onAraMinutesChanged;
  final TextEditingController genelTitle;
  final TextEditingController genelBody;

  const _NotifyComposer({
    super.key,
    required this.eventId,
    required this.event,
    required this.araMinutes,
    required this.onAraMinutesChanged,
    required this.genelTitle,
    required this.genelBody,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final baseline =
        ref.watch(notifyPreviewProvider(NotifyPreviewRequest(eventId: eventId)));

    return baseline.when(
      loading: () => const TeamSectionCard(child: TeamLoadingSkeleton(rows: 2)),
      error: (final e, final st) => TeamSectionCard(
        child: TeamInlineBanner(
            message: e is TeamException ? e.message : 'Önizleme yüklenemedi.'),
      ),
      data: (final preview) {
        final recipients = preview.recipients;
        final quota = preview.quota;
        final kalan = [quota.hourLeft, quota.dayLeft, quota.targetLeft]
            .reduce((final a, final b) => a < b ? a : b);
        return Column(
          children: [
            TeamSectionCard(
              title: 'Sahne kumandası',
              icon: Icons.campaign_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$recipients bilet sahibine ulaşılır (${preview.withToken} kişi '
                    'push alabilir; diğerleri uygulama içi kutuda görür). Kişi '
                    'bilgileri gösterilmez.',
                    style: TextStyle(
                        fontSize: 12.5, color: context.colors.onSurfaceVariant),
                  ),
                  if (preview.loudOf > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${preview.loudOptedIn}/${preview.loudOf} kişi sessiz modda '
                      'sesli alarmı açık.',
                      style: TextStyle(
                          fontSize: 12.5, color: context.colors.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  if (recipients == 0)
                    const TeamInlineBanner(
                      tone: TeamBannerTone.warning,
                      message:
                          'Bu seansta bildirim alacak aktif bilet sahibi yok.',
                    )
                  else if (kalan <= 2)
                    TeamInlineBanner(
                      tone: TeamBannerTone.warning,
                      message: 'Gönderim hakkın azalıyor: bu seansa '
                          '${quota.targetLeft} / saatlik ${quota.hourLeft} / '
                          'günlük ${quota.dayLeft} hakkın kaldı.',
                    )
                  else
                    Text(
                      'Kalan hak: bu seansa ${quota.targetLeft}, saatte '
                      '${quota.hourLeft}, günde ${quota.dayLeft}.',
                      style: TextStyle(
                          fontSize: 12, color: context.colors.onSurfaceVariant),
                    ),
                  if (!event.inWindow)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: TeamInlineBanner(
                        tone: TeamBannerTone.info,
                        message: 'Bu seans ±24 saat dışında: sahne şablonları '
                            '(başladı, ara, bitti…) kapalı; duyuru '
                            '(ertelendi/iptal/genel) gönderebilirsin.',
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _AraMinutesField(
                      minutes: araMinutes, onChanged: onAraMinutesChanged),
                  const SizedBox(height: AppSpacing.sm),
                  _TemplateGrid(
                    eventId: eventId,
                    event: event,
                    templates: preview.templates,
                    recipients: recipients,
                    araMinutes: araMinutes,
                  ),
                ],
              ),
            ),
            TeamSectionCard(
              title: 'Kısa mesaj',
              icon: Icons.edit_note_rounded,
              child: _GenelMessageForm(
                eventId: eventId,
                recipients: recipients,
                titleController: genelTitle,
                bodyController: genelBody,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AraMinutesField extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  const _AraMinutesField({required this.minutes, required this.onChanged});

  @override
  Widget build(final BuildContext context) => Row(
        children: [
          Text('Ara süresi:', style: TextStyle(color: context.colors.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            button: true,
            label: 'Ara süresini azalt',
            child: IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded),
              onPressed: minutes > 5
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged(minutes - 1);
                    }
                  : null,
            ),
          ),
          Text('$minutes dk', style: const TextStyle(fontWeight: FontWeight.w700)),
          Semantics(
            button: true,
            label: 'Ara süresini artır',
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: minutes < 30
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged(minutes + 1);
                    }
                  : null,
            ),
          ),
        ],
      );
}

class _TemplateGrid extends ConsumerWidget {
  final String eventId;
  final TeamManagerEvent event;
  final List<NotifyTemplate> templates;
  final int recipients;
  final int araMinutes;

  const _TemplateGrid({
    required this.eventId,
    required this.event,
    required this.templates,
    required this.recipients,
    required this.araMinutes,
  });

  NotifyTemplate? _find(final String id) {
    for (final t in templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final entries = <_GridEntry>[
      if (_find('baslamak_uzere') != null) ...[
        _GridEntry('baslamak_uzere', 'Oyun 10 dk sonra başlıyor', const {'dk': 10}),
        _GridEntry('baslamak_uzere', 'Oyun 5 dk sonra başlıyor', const {'dk': 5}),
      ],
      if (_find('basladi') != null)
        const _GridEntry('basladi', 'Oyun başladı — telefonları sessize alın', null),
      if (_find('ara') != null)
        _GridEntry('ara', 'Birinci perde bitti — $araMinutes dk ara', {'dk': araMinutes}),
      if (_find('ara_bitiyor') != null)
        const _GridEntry(
            'ara_bitiyor', 'Ara bitiyor — 5 dk içinde yerlerimize', null),
      if (_find('bitti') != null)
        const _GridEntry('bitti', 'Oyun bitti — teşekkürler', null),
      if (_find('ertelendi') != null)
        const _GridEntry('ertelendi', 'Seans ertelendi…', null, promptText: true),
      if (_find('iptal') != null)
        const _GridEntry('iptal', 'Seans iptal edildi…', null, promptText: true),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final entry in entries)
          _buildButton(context, ref, entry, _find(entry.templateId)!),
      ],
    );
  }

  Widget _buildButton(final BuildContext context, final WidgetRef ref,
      final _GridEntry entry, final NotifyTemplate template) {
    final colors = context.colors;
    final disabledByWindow = template.timed && !event.inWindow;
    final disabled = disabledByWindow || recipients == 0;
    final isAlarm = template.kind == 'alarm';
    return SizedBox(
      width: (MediaQuery.of(context).size.width - AppSpacing.lg * 2 - AppSpacing.sm) / 2,
      child: Semantics(
        button: true,
        label: entry.label,
        child: OutlinedButton(
          onPressed: disabled
              ? null
              : () async {
                  HapticFeedback.lightImpact();
                  if (entry.promptText) {
                    final body = await _promptFreeText(
                      context,
                      title: entry.templateId == 'iptal'
                          ? 'Seans iptal mesajı'
                          : 'Seans erteleme mesajı',
                      hint: entry.templateId == 'iptal'
                          ? 'Örn. Teknik bir arıza nedeniyle iptal edildi'
                          : 'Örn. Yeni tarih 12 Kasım 20:00',
                    );
                    if (body == null || !context.mounted) return;
                    await _openConfirmSheet(context, ref,
                        eventId: eventId, template: entry.templateId, body: body);
                  } else {
                    await _openConfirmSheet(context, ref,
                        eventId: eventId,
                        template: entry.templateId,
                        params: entry.params);
                  }
                },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            side: BorderSide(
                color: isAlarm ? Colors.orange : colors.outlineVariant),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
          child: Row(
            children: [
              Icon(_kTemplateIcons[entry.templateId] ?? Icons.campaign_rounded,
                  size: 18, color: isAlarm ? Colors.orange : colors.onSurface),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.label,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: disabled ? colors.onSurfaceVariant : colors.onSurface)),
                    if (isAlarm)
                      Text('Alarm bildirimi',
                          style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridEntry {
  final String templateId;
  final String label;
  final Map<String, int>? params;
  final bool promptText;

  const _GridEntry(this.templateId, this.label, this.params,
      {this.promptText = false});
}

class _GenelMessageForm extends ConsumerStatefulWidget {
  final String eventId;
  final int recipients;
  final TextEditingController titleController;
  final TextEditingController bodyController;

  const _GenelMessageForm({
    required this.eventId,
    required this.recipients,
    required this.titleController,
    required this.bodyController,
  });

  @override
  ConsumerState<_GenelMessageForm> createState() => _GenelMessageFormState();
}

class _GenelMessageFormState extends ConsumerState<_GenelMessageForm> {
  String? _warning;

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_warning != null) TeamInlineBanner(message: _warning!),
        TextField(
          controller: widget.titleController,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Başlık'),
          onChanged: (final _) => setState(() {}),
        ),
        TextField(
          controller: widget.bodyController,
          maxLength: 240,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Mesaj'),
          onChanged: (final _) => setState(() {}),
        ),
        Text(
          '{oyun} ve {sahne} yazarsan seansın bilgisiyle dolar. Bağlantı, '
          'telefon numarası ve e-posta yazılamaz; serbest mesaj alarm olarak '
          'gitmez.',
          style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: widget.recipients == 0
                ? null
                : () async {
                    final t = widget.titleController.text.trim();
                    final b = widget.bodyController.text.trim();
                    if (t.isEmpty || b.isEmpty) {
                      setState(() => _warning = 'Başlık ve mesaj gerekli.');
                      return;
                    }
                    setState(() => _warning = null);
                    await _openConfirmSheet(context, ref,
                        eventId: widget.eventId,
                        template: 'genel',
                        title: t,
                        body: b);
                  },
            child: const Text('Önizle ve gönder'),
          ),
        ),
      ],
    );
  }
}

/// Önizleme + gönderim onayı (web `onay()` ile aynı akış): önce
/// `teamNotifyPreview` ile üretilmiş metni ve alıcı sayısını gösterir,
/// yönetici onaylarsa `teamSendNotification` çağrılır.
Future<void> _openConfirmSheet(
  final BuildContext context,
  final WidgetRef ref, {
  required final String eventId,
  required final String template,
  final Map<String, int>? params,
  final String? title,
  final String? body,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (final sheetContext) => _NotifyConfirmSheet(
      eventId: eventId,
      template: template,
      params: params,
      title: title,
      body: body,
    ),
  );
  if (sent == true) {
    ref.invalidate(notifyPreviewProvider(NotifyPreviewRequest(eventId: eventId)));
  }
}

Future<String?> _promptFreeText(
  final BuildContext context, {
  required final String title,
  required final String hint,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (final dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLength: 240,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            Navigator.of(dialogContext).pop(text);
          },
          child: const Text('Devam'),
        ),
      ],
    ),
  );
}

class _NotifyConfirmSheet extends ConsumerStatefulWidget {
  final String eventId;
  final String template;
  final Map<String, int>? params;
  final String? title;
  final String? body;

  const _NotifyConfirmSheet({
    required this.eventId,
    required this.template,
    this.params,
    this.title,
    this.body,
  });

  @override
  ConsumerState<_NotifyConfirmSheet> createState() => _NotifyConfirmSheetState();
}

class _NotifyConfirmSheetState extends ConsumerState<_NotifyConfirmSheet> {
  NotifyPreview? _preview;
  String? _error;
  bool _sending = false;
  NotifySendResult? _result;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preview = await ref.read(teamRepositoryProvider).notifyPreview(
            eventId: widget.eventId,
            template: widget.template,
            params: widget.params,
            title: widget.title,
            body: widget.body,
          );
      if (mounted) setState(() => _preview = preview);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e is TeamException ? e.message : 'Önizleme yüklenemedi.');
      }
    }
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final result = await ref.read(sendNotificationProvider.notifier).send(
            eventId: widget.eventId,
            template: widget.template,
            params: widget.params,
            title: widget.title,
            body: widget.body,
          );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _sendError = e is TeamException ? e.message : 'Gönderilemedi.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Göndermeden önce kontrol et',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          if (_result != null) ...[
            TeamInlineBanner(
              tone: TeamBannerTone.info,
              message: _result!.duplicate
                  ? 'Zaten gönderilmiş · ${_result!.recipients} alıcı'
                  : '${_result!.duplicate ? 'ZATEN GÖNDERİLMİŞ' : 'GÖNDERİLDİ'} · '
                      '${_result!.recipients} alıcı · push: ${_result!.success} '
                      'başarılı${_result!.failure > 0 ? ', ${_result!.failure} başarısız' : ''}',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Kapat'),
              ),
            ),
          ] else if (_error != null) ...[
            TeamInlineBanner(message: _error!),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Kapat'),
              ),
            ),
          ] else if (_preview == null) ...[
            const TeamLoadingSkeleton(rows: 2),
          ] else if (_preview!.blocked != null) ...[
            TeamInlineBanner(message: _preview!.blocked!),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Kapat'),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _preview!.preview?.isAlarm == true
                    ? Colors.orange.withOpacity(0.12)
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: AppShadows.level1(colors.shadow),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TiyatRol${_preview!.preview?.isAlarm == true ? ' · ALARM' : ''}',
                    style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_preview!.preview?.title ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(_preview!.preview?.body ?? ''),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${_preview!.targetLabel} · ${_preview!.recipients} kişi · '
              '${_preview!.withToken} push alabilir',
              style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
            ),
            if (_preview!.preview?.isAlarm == true)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Alarm bildirimi yüksek öncelikle gider; telefon sessizdeyse '
                  'sesli olması alıcının iznine bağlıdır.',
                  style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant),
                ),
              ),
            if (_sendError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: TeamInlineBanner(message: _sendError!),
              ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _sending ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Vazgeç'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _preview!.recipients == 0 || _sending ? null : _send,
                  child: Text(_sending
                      ? 'Gönderiliyor…'
                      : 'Gönder (${_preview!.recipients} kişi)'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
