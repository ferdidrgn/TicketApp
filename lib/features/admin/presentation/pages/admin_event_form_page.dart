import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_mutation_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../widgets/admin_form_widgets.dart';
import '../widgets/delete_guard.dart';

/// Bağımsız "Seanslar" sekmesinin (`AdminEventsTab`) ekle/düzenle formu —
/// TÜM oyunlar arasından bir Oyun + Sahne seçilerek herhangi bir seans
/// oluşturulabilir/düzenlenebilir/silinebilir.
///
/// 🔧 KODLAMA NOTU — neden `AdminEventSection`'ın formu DEĞİL, bu YENİ
/// sayfa kullanılıyor: `AdminEventSection` (oyun düzenleme ekranına gömülü
/// "Seanslar" bölümü) kasıtlı olarak dar bir form — `Show` zaten dışarıdan
/// (widget.show) sabit, sadece EKLEME var, silme/düzenleme yok, sayfa değil
/// satır-içi bir bölüm. Bu sayfanın ihtiyacı farklı: TÜM oyunlar arasından
/// seçim (Oyun dropdown'ı), düzenleme VE silme. Gerçek Event
/// OLUŞTURMA/GÜNCELLEME/SİLME mantığı (Firestore yazımı, cache invalidation)
/// ise İKİ KERE YAZILMADI — her ikisi de AYNI `eventMutationProvider`
/// (`addEvent`/`updateEvent`/`deleteEvent`, bkz. `event_mutation_provider.dart`)
/// metotlarını çağırır; burada tekrarlanan tek şey form ALANLARININ
/// düzeni, iki ekranın şekli gerçekten farklı olduğu için.
class AdminEventFormPage extends ConsumerStatefulWidget {
  final Event? event;

  const AdminEventFormPage({super.key, this.event});

  @override
  ConsumerState<AdminEventFormPage> createState() =>
      _AdminEventFormPageState();
}

class _AdminEventFormPageState extends ConsumerState<AdminEventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();

  String? _selectedShowId;
  String? _selectedStageId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _cancelled = false;
  String? _pickerError;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event != null) {
      _selectedShowId = event.showId.isNotEmpty ? event.showId : null;
      _selectedStageId = event.stageId.isNotEmpty ? event.stageId : null;
      _priceController.text = event.price;
      final parsed = DateFormatter.parseDateString(event.date);
      if (parsed != null) {
        _selectedDate = DateTime(parsed.year, parsed.month, parsed.day);
        _selectedTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    setState(() => _pickerError = null);

    final formOk = _formKey.currentState?.validate() ?? false;
    if (_selectedShowId == null) {
      setState(() => _pickerError = 'Lütfen bir oyun seçin.');
      return;
    }
    if (_selectedStageId == null) {
      setState(() => _pickerError = 'Lütfen bir sahne seçin.');
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      setState(() => _pickerError = 'Lütfen bir tarih ve saat seçin.');
      return;
    }
    if (!formOk) return;

    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    // 🔥 Uygulamanın GERÇEK Event.date formatı — bkz. `AdminEventSection`
    // ve `date_formatter.dart`'taki `_parseAny` ile AYNI sözleşme.
    final dateString = DateFormat('dd.MM.yyyy,HH:mm').format(dateTime);
    final price = _priceController.text.trim();
    final cancelledValue = _cancelled ? 'evet' : '';

    bool ok;
    if (_isEditing) {
      ok = await ref.read(eventMutationProvider.notifier).updateEvent(
        widget.event!.id,
        {
          'showId': _selectedShowId,
          'stageId': _selectedStageId,
          'date': dateString,
          'price': price,
          'cancelled': cancelledValue,
        },
      );
    } else {
      final event = Event(
        id: '',
        stageId: _selectedStageId!,
        showId: _selectedShowId!,
        date: dateString,
        price: price,
        seats: const {},
      );
      await ref.read(eventMutationProvider.notifier).addEvent(event);
      ok = !ref.read(eventMutationProvider).hasError;
    }

    if (!mounted) return;
    final state = ref.read(eventMutationProvider);
    if (!ok || state.hasError) {
      showDialog(
        context: context,
        builder: (final _) => CustomErrorDialog(
            message: 'Seans kaydedilemedi: ${state.error ?? "bilinmeyen hata"}'),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final _) => CustomSuccessDialog(
        message: _isEditing ? 'Seans güncellendi.' : 'Seans eklendi.',
        onConfirm: () {
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final event = widget.event;
    if (event == null) return;
    final shows = ref.read(showsProvider(isLimit: false)).value ?? const <Show>[];
    final stages =
        ref.read(stagesProvider(isLimit: false)).value ?? const <Stage>[];
    final showName =
        shows.where((final s) => s.id == event.showId).firstOrNull?.name ??
            'Oyun?';
    final stageName =
        stages.where((final s) => s.id == event.stageId).firstOrNull?.name ??
            'Sahne?';
    final label = '$showName · $stageName · ${event.date}';
    if (await blockDeleteIfTickets(context, eventId: event.id, label: label)) {
      return;
    }
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (final _) => CustomActionDialog(
        title: 'SEANSI SİL',
        message: '"$label" kalıcı olarak silinecek. Emin misin?',
        icon: Icons.delete_forever_rounded,
        iconColor: Colors.red,
        positiveText: 'SİL',
        negativeText: 'VAZGEÇ',
        onPositiveAction: () async {
          final ok = await ref
              .read(eventMutationProvider.notifier)
              .deleteEvent(event.id);
          if (!mounted) return;
          final state = ref.read(eventMutationProvider);
          if (!ok || state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Silinemedi: ${state.error}'),
              backgroundColor: Colors.red,
            ));
          } else {
            Navigator.of(context).pop();
          }
        },
        onNegativeAction: () {},
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final isSaving = ref.watch(eventMutationProvider).isLoading;
    final showsAsync = ref.watch(showsProvider(isLimit: false));
    final stagesAsync = ref.watch(stagesProvider(isLimit: false));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Seansı Düzenle' : 'Yeni Seans'),
        actions: [
          if (_isEditing)
            Semantics(
              button: true,
              label: 'Seansı sil',
              child: IconButton(
                tooltip: 'Sil',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: isSaving ? null : _confirmDelete,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_pickerError != null)
                  AdminInlineBanner(message: _pickerError!),
                showsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: LinearProgressIndicator(),
                  ),
                  error: (final e, final st) =>
                      AdminInlineBanner(message: 'Oyunlar yüklenemedi: $e'),
                  data: (final shows) {
                    if (shows.isEmpty) {
                      return const AdminInlineBanner(
                          message:
                              'Önce "Oyunlar" sekmesinden en az bir oyun eklemelisiniz.');
                    }
                    final sorted = [...shows]
                      ..sort((final a, final b) => a.name
                          .toLowerCase()
                          .compareTo(b.name.toLowerCase()));
                    return AdminDropdownField<String>(
                      label: 'Oyun',
                      value: _selectedShowId,
                      items: sorted
                          .map((final s) => DropdownMenuItem(
                              value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (final v) =>
                          setState(() => _selectedShowId = v),
                    );
                  },
                ),
                stagesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: LinearProgressIndicator(),
                  ),
                  error: (final e, final st) =>
                      AdminInlineBanner(message: 'Sahneler yüklenemedi: $e'),
                  data: (final stages) {
                    if (stages.isEmpty) {
                      return const AdminInlineBanner(
                          message:
                              'Önce "Sahneler" sekmesinden en az bir sahne eklemelisiniz.');
                    }
                    final sorted = [...stages]
                      ..sort((final a, final b) => a.name
                          .toLowerCase()
                          .compareTo(b.name.toLowerCase()));
                    return AdminDropdownField<String>(
                      label: 'Sahne',
                      value: _selectedStageId,
                      items: sorted
                          .map((final s) => DropdownMenuItem(
                              value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (final v) =>
                          setState(() => _selectedStageId = v),
                    );
                  },
                ),
                const AdminSectionTitle(
                    title: 'Tarih ve saat', icon: Icons.event_rounded),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Seans tarihi seç',
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon:
                              const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text(_selectedDate == null
                              ? 'Tarih Seç'
                              : DateFormat('dd.MM.yyyy').format(_selectedDate!)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Seans saati seç',
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule_rounded, size: 16),
                          label: Text(_selectedTime == null
                              ? 'Saat Seç'
                              : _selectedTime!.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  textField: true,
                  label: 'Bilet fiyatı, zorunlu alan',
                  child: CustomTextField(
                    controller: _priceController,
                    label: 'Fiyat (₺)',
                    keyboardType: TextInputType.number,
                    hintText: '0 = ücretsiz',
                  ),
                ),
                Semantics(
                  label: 'Seans iptal edildi',
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _cancelled,
                    onChanged: (final v) => setState(() => _cancelled = v),
                    title: const Text('Seans iptal edildi'),
                    subtitle: const Text(
                        'İptal edilirse bilet sahiplerine bildirim gider.'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: _isEditing
                        ? 'Değişiklikleri kaydet'
                        : 'Seansı kaydet',
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              _save();
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(
                          _isEditing ? 'Değişiklikleri Kaydet' : 'Seansı Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.colors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
