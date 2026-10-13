import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_mutation_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_mutation_provider.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import 'admin_form_widgets.dart';
import 'geo_lookup_button.dart';

/// Taslak (henüz kaydedilmemiş) tek seans: sahne + tarih/saat.
class _Draft {
  final String? stageId; // mevcut sahne
  final _NewStage? newStage; // ya da yeni sahne
  final DateTime when;
  const _Draft({this.stageId, this.newStage, required this.when});

  String get stageLabel => newStage?.name ?? '';
}

class _NewStage {
  final String name, address;
  final double lat, lng;
  const _NewStage(this.name, this.address, this.lat, this.lng);

  String get key => '${name.toLowerCase()}|$lat|$lng';
}

const String _kNewStage = '__new__';

/// Harici (başka platformda biletli) oyunlar için SADE seans girişi:
/// sahne (mevcut ya da yeni: ad + konum) ve gün/saat. Fiyat/koltuk yok —
/// bilet satılmıyor, takvim ve harita bu bilgiyle çalışır. Birden çok
/// seans listeye "+ Ekle" ile eklenir, tek tuşla hepsi kaydedilir.
class AdminExternalSessionsSection extends ConsumerStatefulWidget {
  final Show show;

  const AdminExternalSessionsSection({super.key, required this.show});

  @override
  ConsumerState<AdminExternalSessionsSection> createState() =>
      _AdminExternalSessionsSectionState();
}

class _AdminExternalSessionsSectionState
    extends ConsumerState<AdminExternalSessionsSection> {
  final TextEditingController _nameC = TextEditingController();
  final TextEditingController _addrC = TextEditingController();
  final TextEditingController _latC = TextEditingController();
  final TextEditingController _lngC = TextEditingController();

  final List<_Draft> _drafts = [];
  String? _stageChoice; // stage id ya da _kNewStage
  DateTime? _date;
  TimeOfDay? _time;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _nameC.dispose();
    _addrC.dispose();
    _latC.dispose();
    _lngC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (t != null) setState(() => _time = t);
  }

  Future<void> _addDraft() async {
    setState(() => _error = null);
    if (_stageChoice == null) {
      setState(() => _error = 'Önce bir sahne seç ya da yeni sahne ekle.');
      return;
    }
    if (_date == null || _time == null) {
      setState(() => _error = 'Tarih ve saat seç.');
      return;
    }
    _NewStage? ns;
    if (_stageChoice == _kNewStage) {
      final String name = _nameC.text.trim();
      final double? lat =
          double.tryParse(_latC.text.trim().replaceAll(',', '.'));
      final double? lng =
          double.tryParse(_lngC.text.trim().replaceAll(',', '.'));
      if (name.isEmpty) {
        setState(() => _error = 'Sahne adını yaz.');
        return;
      }
      if (lat == null || lng == null) {
        setState(() => _error =
            'Konum yok: "Adresten konum bul"a bas ya da enlem/boylam yaz.');
        return;
      }
      final bool ok = await validateGeoOrWarn(context,
          lat: lat, lng: lng, address: '${_addrC.text} $name');
      if (!ok || !mounted) return;
      ns = _NewStage(name, _addrC.text.trim(), lat, lng);
    }
    final DateTime when = DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    setState(() {
      _drafts.add(_Draft(
        stageId: ns == null ? _stageChoice : null,
        newStage: ns,
        when: when,
      ));
      // Hızlı çoklu giriş: sahne seçili kalır, sadece tarih temizlenir.
      _date = null;
      if (ns != null) {
        // Aynı yeni sahne sonraki seanslar için hazır tutulur (tekrar
        // yazılmaz); kayıtta tek sahne olarak oluşturulur.
      }
    });
  }

  /// Sahne listesinde bu yeni sahneyi bulur (ad + yaklaşık koordinat).
  Stage? _findCreated(final List<Stage> all, final _NewStage n) {
    for (final Stage s in all) {
      if (s.name.trim().toLowerCase() == n.name.toLowerCase() &&
          (s.locationLat - n.lat).abs() < 1e-5 &&
          (s.locationLng - n.lng).abs() < 1e-5) {
        return s;
      }
    }
    return null;
  }

  Future<void> _saveAll() async {
    if (_drafts.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // 1) Yeni sahneleri (tekrarsız) oluştur.
      final Map<String, String> createdIds = {};
      for (final _Draft d in _drafts) {
        final _NewStage? n = d.newStage;
        if (n == null || createdIds.containsKey(n.key)) continue;
        await ref.read(stageMutationProvider.notifier).addStage(
              Stage(
                id: '',
                createdAt: '',
                updatedAt: '',
                name: n.name,
                imageUrl: '',
                capacity: '',
                description: '',
                communication: '',
                address: n.address,
                locationLat: n.lat,
                locationLng: n.lng,
                showsId: const [],
              ),
              null,
            );
        final err = ref.read(stageMutationProvider);
        if (err.hasError) throw Exception('${err.error}');
        final List<Stage> all =
            await ref.read(stagesProvider(isLimit: false).future);
        final Stage? made = _findCreated(all, n);
        if (made == null) throw Exception('Yeni sahne bulunamadı: ${n.name}');
        createdIds[n.key] = made.id;
      }
      // 2) Seansları (Event) yaz — fiyat/koltuk yok.
      for (final _Draft d in _drafts) {
        final String stageId = d.stageId ?? createdIds[d.newStage!.key]!;
        await ref.read(eventMutationProvider.notifier).addEvent(Event(
              id: '',
              stageId: stageId,
              showId: widget.show.id,
              // Uygulamanın gerçek formatı: boşluksuz "dd.MM.yyyy,HH:mm".
              date: DateFormat('dd.MM.yyyy,HH:mm').format(d.when),
              price: '',
              seats: const {},
            ));
        final err = ref.read(eventMutationProvider);
        if (err.hasError) throw Exception('${err.error}');
      }
      if (!mounted) return;
      final int n = _drafts.length;
      setState(() {
        _drafts.clear();
        _stageChoice = null;
        _nameC.clear();
        _addrC.clear();
        _latC.clear();
        _lngC.clear();
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$n seans kaydedildi.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Kaydedilemedi: $e';
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final eventsAsync = ref.watch(eventsForShowProvider(widget.show.id));
    final stagesAsync = ref.watch(stagesProvider(isLimit: false));
    final List<Stage> stages = stagesAsync.value ?? const <Stage>[];
    String stageName(final String id) {
      for (final Stage s in stages) {
        if (s.id == id) return s.name;
      }
      return 'Bilinmeyen sahne';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle(
            title: 'Harici Seanslar', icon: Icons.event_rounded),
        Text(
          'Bilet satmıyoruz; sadece sahne ve gün/saat yeter. Takvim, harita '
          've geri sayım bu bilgiyle çalışır.',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        eventsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (final e, final st) =>
              AdminInlineBanner(message: 'Seanslar yüklenemedi: $e'),
          data: (final events) => Column(
            children: [
              for (final Event e in events)
                _row(colors, Icons.check_circle_outline_rounded, e.date,
                    stageName(e.stageId)),
            ],
          ),
        ),
        for (int i = 0; i < _drafts.length; i++)
          _row(
            colors,
            Icons.schedule_rounded,
            DateFormat('dd.MM.yyyy HH:mm').format(_drafts[i].when),
            _drafts[i].stageId != null
                ? stageName(_drafts[i].stageId!)
                : '${_drafts[i].stageLabel} (yeni sahne)',
            pending: true,
            onRemove: () => setState(() => _drafts.removeAt(i)),
          ),
        const SizedBox(height: AppSpacing.sm),
        if (_error != null) AdminInlineBanner(message: _error!),
        AdminDropdownField<String>(
          label: 'Sahne',
          value: _stageChoice,
          items: [
            ...stages.map((final s) =>
                DropdownMenuItem(value: s.id, child: Text(s.name))),
            const DropdownMenuItem(
                value: _kNewStage, child: Text('＋ Yeni sahne ekle')),
          ],
          onChanged: (final v) => setState(() => _stageChoice = v),
        ),
        if (_stageChoice == _kNewStage) ...[
          CustomTextField(controller: _nameC, label: 'Sahne adı'),
          CustomTextField(
              controller: _addrC,
              label: 'Adres (mahalle, ilçe, şehir)',
              isRequired: false),
          GeoLookupButton(
            query: () => '${_nameC.text} ${_addrC.text}',
            onPick: (final hit) => setState(() {
              _latC.text = hit.lat.toStringAsFixed(6);
              _lngC.text = hit.lng.toStringAsFixed(6);
            }),
          ),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _latC,
                  label: 'Enlem (lat)',
                  isRequired: false,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: CustomTextField(
                  controller: _lngC,
                  label: 'Boylam (long)',
                  isRequired: false,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(_date == null
                    ? 'Gün'
                    : DateFormat('dd.MM.yyyy').format(_date!)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule_rounded, size: 16),
                label: Text(_time == null ? 'Saat' : _time!.format(context)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _saving ? null : _addDraft,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ekle'),
          ),
        ),
        if (_drafts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveAll,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: Text('${_drafts.length} seansı kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(final dynamic colors, final IconData icon, final String title,
      final String sub,
      {final bool pending = false, final VoidCallback? onRemove}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface as Color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
            color: pending
                ? colors.primary as Color
                : colors.outlineVariant as Color),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary as Color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                Text(sub,
                    style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant as Color)),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Listeden çıkar',
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
