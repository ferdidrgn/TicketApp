import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_mutation_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import 'admin_form_widgets.dart';

/// Bir oyunun (Show) düzenleme ekranına gömülü "Seanslar" bölümü.
///
/// Mevcut seansları (`eventsByShowIdsProvider` — `Event.showId`'ye göre
/// DOĞRUDAN sorgular, bkz. `show_provider.dart`) listeler ve gerçek bir
/// "seans ekle" formu (tarih+saat, fiyat, sahne) sunar. Bu, phase 1'in
/// Event yönetimi için gereken TAMAMEN YENİ dikey dilimi
/// (`event_mutation_provider.dart`/`add_event_use_case_impl.dart`) kullanır.
class AdminEventSection extends ConsumerStatefulWidget {
  final Show show;

  const AdminEventSection({super.key, required this.show});

  @override
  ConsumerState<AdminEventSection> createState() => _AdminEventSectionState();
}

class _AdminEventSectionState extends ConsumerState<AdminEventSection> {
  final _eventFormKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedStageId;
  String? _pickerError;

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

  Future<void> _addEvent() async {
    setState(() => _pickerError = null);

    final formOk = _eventFormKey.currentState?.validate() ?? false;
    if (_selectedDate == null || _selectedTime == null) {
      setState(() => _pickerError = 'Lütfen bir tarih ve saat seçin.');
      return;
    }
    if (_selectedStageId == null) {
      setState(() => _pickerError = 'Lütfen bir sahne seçin.');
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

    // 🔥 KRİTİK: Uygulamanın GERÇEK Event.date formatı boşluksuz
    // "dd.MM.yyyy,HH:mm" — bkz. `date_formatter.dart`'taki `_parseAny`.
    // Farklı bir format (ör. ISO8601 ya da boşluklu) yazılırsa bu seans
    // "aktif oyunlar"/"gelecek seanslar" hesaplamalarından düşebilir.
    final dateString = DateFormat('dd.MM.yyyy,HH:mm').format(dateTime);

    final event = Event(
      id: '',
      stageId: _selectedStageId!,
      showId: widget.show.id,
      date: dateString,
      price: _priceController.text.trim(),
      seats: const {},
    );

    await ref.read(eventMutationProvider.notifier).addEvent(event);

    final state = ref.read(eventMutationProvider);
    if (!mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Seans eklenemedi: ${state.error}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      _priceController.clear();
      setState(() {
        _selectedDate = null;
        _selectedTime = null;
        _selectedStageId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Seans eklendi.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final eventsAsync =
        ref.watch(eventsByShowIdsProvider([widget.show.id]));
    final stagesAsync = ref.watch(stagesProvider(isLimit: false));
    final isSaving = ref.watch(eventMutationProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle(
            title: 'Seanslar (Etkinlikler)', icon: Icons.event_rounded),
        eventsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (final e, final st) => AdminInlineBanner(
              message: 'Seanslar yüklenemedi: $e'),
          data: (final events) {
            if (events.isEmpty)
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('Bu oyun için henüz bir seans eklenmemiş.',
                    style: TextStyle(color: colors.onSurfaceVariant)),
              );
            final stages = stagesAsync.value ?? const <Stage>[];
            return Column(
              children: events.map((final event) {
                final matchingStages =
                    stages.where((final s) => s.id == event.stageId);
                final stageName = matchingStages.isNotEmpty
                    ? matchingStages.first.name
                    : 'Bilinmeyen sahne';
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.confirmation_number_outlined,
                          color: colors.primary, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.date,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            Text(stageName,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Text('${event.price} ₺',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: colors.primary)),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const AdminSectionTitle(
            title: 'Yeni Seans Ekle', icon: Icons.add_circle_outline_rounded),
        if (_pickerError != null)
          AdminInlineBanner(message: _pickerError!),
        Form(
          key: _eventFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Seans tarihi seç',
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
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
              Semantics(
                textField: true,
                label: 'Bilet fiyatı, zorunlu alan',
                child: CustomTextField(
                  controller: _priceController,
                  label: 'Fiyat (₺)',
                  keyboardType: TextInputType.number,
                ),
              ),
              stagesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: LinearProgressIndicator(),
                ),
                error: (final e, final st) =>
                    AdminInlineBanner(message: 'Sahneler yüklenemedi: $e'),
                data: (final stages) {
                  if (stages.isEmpty)
                    return const AdminInlineBanner(
                        message:
                            'Önce "Sahneler" sekmesinden en az bir sahne eklemelisiniz.');
                  return AdminDropdownField<String>(
                    label: 'Sahne',
                    value: _selectedStageId,
                    items: stages
                        .map((final s) => DropdownMenuItem(
                            value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: (final v) =>
                        setState(() => _selectedStageId = v),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: 'Seansı kaydet',
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : _addEvent,
                    icon: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add_rounded),
                    label: const Text('Seans Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
