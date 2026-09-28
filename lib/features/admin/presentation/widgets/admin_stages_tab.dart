import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_mutation_provider.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import 'admin_form_widgets.dart';

/// "Sahneler" sekmesi — Phase 1 kapsamı: sadece YENİ sahne ekleme (edit/
/// silme sonraki faz). Üstte mevcut sahnelerin gerçek, salt-okunur listesi
/// (tekrar isim girmemek için referans), altında gerçek bir ekleme formu.
class AdminStagesTab extends ConsumerStatefulWidget {
  const AdminStagesTab({super.key});

  @override
  ConsumerState<AdminStagesTab> createState() => _AdminStagesTabState();
}

class _AdminStagesTabState extends ConsumerState<AdminStagesTab> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _communicationController = TextEditingController();

  File? _selectedImageFile;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    _communicationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
    if (picked != null) setState(() => _selectedImageFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final lat = double.tryParse(_latController.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(_lngController.text.trim().replaceAll(',', '.'));
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enlem/Boylam geçerli bir sayı olmalı (ör. 41.0082).'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final stage = Stage(
      id: '',
      createdAt: '',
      updatedAt: '',
      name: _nameController.text.trim(),
      imageUrl: '',
      capacity: _capacityController.text.trim(),
      description: _descriptionController.text.trim(),
      communication: _communicationController.text.trim(),
      address: _addressController.text.trim(),
      locationLat: lat,
      locationLng: lng,
      showsId: const [],
    );

    await ref
        .read(stageMutationProvider.notifier)
        .addStage(stage, _selectedImageFile);

    if (!mounted) return;
    final state = ref.read(stageMutationProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sahne eklenemedi: ${state.error}'),
        backgroundColor: Colors.red,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sahne eklendi.'),
        backgroundColor: Colors.green,
      ));
      _formKey.currentState?.reset();
      _nameController.clear();
      _addressController.clear();
      _latController.clear();
      _lngController.clear();
      _capacityController.clear();
      _descriptionController.clear();
      _communicationController.clear();
      setState(() => _selectedImageFile = null);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final stagesAsync = ref.watch(stagesProvider(isLimit: false));
    final isSaving = ref.watch(stageMutationProvider).isLoading;
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle(
              title: 'Mevcut Sahneler', icon: Icons.location_city_rounded),
          stagesAsync.when(
            loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: LinearProgressIndicator()),
            error: (final e, final st) =>
                AdminInlineBanner(message: 'Sahneler yüklenemedi: $e'),
            data: (final stages) => stages.isEmpty
                ? Text('Henüz sahne eklenmemiş.',
                    style: TextStyle(color: colors.onSurfaceVariant))
                : Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: stages
                        .map((final s) => Chip(
                              label: Text(s.name),
                              avatar: const Icon(Icons.theater_comedy_rounded,
                                  size: 16),
                            ))
                        .toList(),
                  ),
          ),
          const AdminSectionTitle(
              title: 'Yeni Sahne Ekle', icon: Icons.add_business_rounded),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminImagePickerField(
                  selectedFile: _selectedImageFile,
                  existingImageUrl: null,
                  onPick: _pickImage,
                  semanticLabel: 'Sahne görseli, dokun ve seç',
                ),
                CustomTextField(controller: _nameController, label: 'Sahne Adı'),
                CustomTextField(
                    controller: _addressController, label: 'Adres'),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _latController,
                        label: 'Enlem (lat)',
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: CustomTextField(
                        controller: _lngController,
                        label: 'Boylam (lng)',
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                      ),
                    ),
                  ],
                ),
                CustomTextField(
                    controller: _capacityController, label: 'Kapasite'),
                CustomTextField(
                    controller: _communicationController,
                    label: 'İletişim (telefon/e-posta)',
                    isRequired: false),
                CustomTextField(
                    controller: _descriptionController,
                    label: 'Açıklama',
                    maxLines: 3,
                    isRequired: false),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: 'Sahneyi kaydet',
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _submit,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: const Text('Sahneyi Kaydet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}
