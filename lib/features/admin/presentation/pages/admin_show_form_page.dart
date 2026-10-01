import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_mutation_provider.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../widgets/admin_event_section.dart';
import '../widgets/admin_form_widgets.dart';

/// Oyun (Show) ekleme/düzenleme formu — Phase 1 admin panelinin kalbi.
/// `show == null` -> yeni oyun; aksi halde düzenleme (+ gömülü Seanslar
/// bölümü, bkz. `AdminEventSection`).
///
/// Her alan gerçek `Show` entity alanına yazılır (`show.dart`) — hiçbir
/// sahte/placeholder alan yok. `externalTicketUrl` doldurulursa bu oyun,
/// biletlerin uygulama dışında satıldığı bir "harici bilet" oyunu olur
/// (bkz. `Show.hasExternalTicketing`).
class AdminShowFormPage extends ConsumerStatefulWidget {
  final Show? show;

  const AdminShowFormPage({super.key, this.show});

  @override
  ConsumerState<AdminShowFormPage> createState() => _AdminShowFormPageState();
}

class _AdminShowFormPageState extends ConsumerState<AdminShowFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;
  late final TextEditingController _categoryController;
  late final TextEditingController _typeController;
  late final TextEditingController _ageLimitController;
  late final TextEditingController _eventRuleController;
  late final TextEditingController _externalTicketUrlController;

  String? _selectedTeamId;
  File? _selectedImageFile;

  bool get _isEditing => widget.show != null;

  @override
  void initState() {
    super.initState();
    final show = widget.show;
    _nameController = TextEditingController(text: show?.name ?? '');
    _descriptionController =
        TextEditingController(text: show?.description ?? '');
    _durationController = TextEditingController(text: show?.duration ?? '');
    _categoryController = TextEditingController(text: show?.category ?? '');
    _typeController = TextEditingController(text: show?.type ?? '');
    _ageLimitController = TextEditingController(text: show?.ageLimit ?? '');
    _eventRuleController = TextEditingController(text: show?.eventRule ?? '');
    _externalTicketUrlController =
        TextEditingController(text: show?.externalTicketUrl ?? '');
    _selectedTeamId = show?.teamId.isNotEmpty == true ? show!.teamId : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _categoryController.dispose();
    _typeController.dispose();
    _ageLimitController.dispose();
    _eventRuleController.dispose();
    _externalTicketUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _selectedImageFile = File(picked.path));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_isEditing) {
      final updatedData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'duration': _durationController.text.trim(),
        'category': _categoryController.text.trim(),
        'type': _typeController.text.trim(),
        'ageLimit': _ageLimitController.text.trim(),
        'eventRule': _eventRuleController.text.trim(),
        'teamId': _selectedTeamId ?? '',
        'externalTicketUrl': _externalTicketUrlController.text.trim(),
      };
      await ref.read(showMutationProvider.notifier).updateShowWithImage(
            showId: widget.show!.id,
            updatedData: updatedData,
            imageFile: _selectedImageFile,
          );
    } else {
      final newShow = Show(
        id: '',
        createdAt: '',
        updatedAt: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: '',
        duration: _durationController.text.trim(),
        category: _categoryController.text.trim(),
        type: _typeController.text.trim(),
        ageLimit: _ageLimitController.text.trim(),
        eventRule: _eventRuleController.text.trim(),
        teamId: _selectedTeamId ?? '',
        eventsId: const [],
        nowPlayersId: const [],
        oldPlayersId: const [],
        photosShowId: const [],
        externalTicketUrl: _externalTicketUrlController.text.trim(),
      );
      await ref.read(showMutationProvider.notifier).addShow(
            show: newShow,
            imageFile: _selectedImageFile,
          );
    }

    if (!mounted) return;
    final state = ref.read(showMutationProvider);
    if (state.hasError) {
      showDialog(
        context: context,
        builder: (final _) => CustomErrorDialog(message: state.error.toString()),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final dialogContext) => CustomSuccessDialog(
          message: _isEditing ? 'Oyun güncellendi.' : 'Oyun oluşturuldu.',
          // Diyalog kendini kapatır (CustomSuccessDialog); burada ikinci
          // kez kapatmak admin panelini de kapatıp ana sayfaya atıyordu.
          // Güncellemede kaydın sayfasında kalınır, yeni kayıtta admin
          // listesine dönülür.
          onConfirm: () {
            if (!_isEditing && mounted) Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final show = widget.show;
    if (show == null) return;
    await showDialog(
      context: context,
      builder: (final _) => CustomActionDialog(
        title: 'OYUNU SİL',
        message: '"${show.name}" kalıcı olarak silinecek. Emin misin?',
        icon: Icons.delete_forever_rounded,
        iconColor: Colors.red,
        positiveText: 'SİL',
        negativeText: 'VAZGEÇ',
        onPositiveAction: () async {
          await ref.read(showMutationProvider.notifier).deleteShow(show.id);
          if (!mounted) return;
          final state = ref.read(showMutationProvider);
          if (state.hasError) {
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
    final isSaving = ref.watch(showMutationProvider).isLoading;
    final teamsAsync = ref.watch(teamsProvider(isLimit: false));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Oyunu Düzenle' : 'Yeni Oyun'),
        actions: [
          if (_isEditing)
            Semantics(
              button: true,
              label: 'Oyunu sil',
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
                AdminImagePickerField(
                  selectedFile: _selectedImageFile,
                  existingImageUrl: widget.show?.imageUrl,
                  onPick: _pickImage,
                  semanticLabel: 'Oyun afişi görseli, dokun ve değiştir',
                ),
                const AdminSectionTitle(
                    title: 'Temel Bilgiler', icon: Icons.theater_comedy_rounded),
                Semantics(
                  textField: true,
                  label: 'Oyun adı, zorunlu alan',
                  child: CustomTextField(
                      controller: _nameController, label: 'Oyun Adı'),
                ),
                Semantics(
                  textField: true,
                  label: 'Açıklama, zorunlu alan',
                  child: CustomTextField(
                      controller: _descriptionController,
                      label: 'Açıklama',
                      maxLines: 4),
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                          controller: _durationController, label: 'Süre'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: CustomTextField(
                          controller: _ageLimitController, label: 'Yaş Sınırı'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                          controller: _categoryController, label: 'Kategori'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: CustomTextField(
                          controller: _typeController, label: 'Tür'),
                    ),
                  ],
                ),
                CustomTextField(
                    controller: _eventRuleController,
                    label: 'Seans/Bilet Kuralı',
                    isRequired: false),
                teamsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: LinearProgressIndicator(),
                  ),
                  error: (final e, final st) =>
                      AdminInlineBanner(message: 'Topluluklar yüklenemedi: $e'),
                  data: (final teams) => AdminDropdownField<String>(
                    label: 'Topluluk (Team)',
                    value: _selectedTeamId,
                    items: teams
                        .map((final t) => DropdownMenuItem(
                            value: t.id, child: Text(t.name)))
                        .toList(),
                    onChanged: (final v) => setState(() => _selectedTeamId = v),
                    validator: (final v) =>
                        (v == null || v.isEmpty) ? 'Bir topluluk seçin' : null,
                  ),
                ),
                const AdminSectionTitle(
                    title: 'Harici Bilet',
                    icon: Icons.open_in_new_rounded),
                Text(
                  'Doldurulursa bu oyunun bilet satışı uygulama içi koltuk '
                  'seçimi yerine bu URL üzerinden yapılır.',
                  style: TextStyle(
                      fontSize: 12, color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: _externalTicketUrlController,
                  label: 'Harici Bilet URL\'i',
                  isRequired: false,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: _isEditing ? 'Değişiklikleri kaydet' : 'Oyunu oluştur',
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _save,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(_isEditing ? 'Kaydet' : 'Oyunu Oluştur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.colors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg),
                      ),
                    ),
                  ),
                ),
                if (_isEditing) ...[
                  const Divider(height: AppSpacing.section),
                  AdminEventSection(show: widget.show!),
                ],
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
