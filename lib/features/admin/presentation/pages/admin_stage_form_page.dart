import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_mutation_provider.dart';
import '../widgets/admin_form_widgets.dart';

/// Sahne (Stage/mekân) ekleme/düzenleme formu — Phase 2. `stage == null` ->
/// yeni sahne; aksi halde düzenleme + silme (bkz. `AdminShowFormPage`'daki
/// AYNI desen).
class AdminStageFormPage extends ConsumerStatefulWidget {
  final Stage? stage;

  const AdminStageFormPage({super.key, this.stage});

  @override
  ConsumerState<AdminStageFormPage> createState() =>
      _AdminStageFormPageState();
}

class _AdminStageFormPageState extends ConsumerState<AdminStageFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _capacityController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _communicationController;

  File? _selectedImageFile;

  bool get _isEditing => widget.stage != null;

  @override
  void initState() {
    super.initState();
    final stage = widget.stage;
    _nameController = TextEditingController(text: stage?.name ?? '');
    _addressController = TextEditingController(text: stage?.address ?? '');
    _latController =
        TextEditingController(text: stage != null ? '${stage.locationLat}' : '');
    _lngController =
        TextEditingController(text: stage != null ? '${stage.locationLng}' : '');
    _capacityController = TextEditingController(text: stage?.capacity ?? '');
    _descriptionController =
        TextEditingController(text: stage?.description ?? '');
    _communicationController =
        TextEditingController(text: stage?.communication ?? '');
  }

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

  Future<void> _save() async {
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

    if (_isEditing) {
      final updatedData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'locationLat': lat,
        'locationLng': lng,
        'capacity': _capacityController.text.trim(),
        'description': _descriptionController.text.trim(),
        'communication': _communicationController.text.trim(),
      };
      await ref.read(stageMutationProvider.notifier).updateStage(
            stageId: widget.stage!.id,
            updatedData: updatedData,
            imageFile: _selectedImageFile,
          );
    } else {
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
    }

    if (!mounted) return;
    final state = ref.read(stageMutationProvider);
    if (state.hasError) {
      showDialog(
        context: context,
        builder: (final _) =>
            CustomErrorDialog(message: state.error.toString()),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final dialogContext) => CustomSuccessDialog(
          message: _isEditing ? 'Sahne güncellendi.' : 'Sahne oluşturuldu.',
          onConfirm: () {
            Navigator.of(dialogContext, rootNavigator: true).pop();
            if (mounted) Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final stage = widget.stage;
    if (stage == null) return;
    await showDialog(
      context: context,
      builder: (final _) => CustomActionDialog(
        title: 'SAHNEYİ SİL',
        message: '"${stage.name}" kalıcı olarak silinecek. Emin misin?',
        icon: Icons.delete_forever_rounded,
        iconColor: Colors.red,
        positiveText: 'SİL',
        negativeText: 'VAZGEÇ',
        onPositiveAction: () async {
          await ref.read(stageMutationProvider.notifier).deleteStage(stage.id);
          if (!mounted) return;
          final state = ref.read(stageMutationProvider);
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
    final isSaving = ref.watch(stageMutationProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sahneyi Düzenle' : 'Yeni Sahne'),
        actions: [
          if (_isEditing)
            Semantics(
              button: true,
              label: 'Sahneyi sil',
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
                  existingImageUrl: widget.stage?.imageUrl,
                  onPick: _pickImage,
                  semanticLabel: 'Sahne görseli, dokun ve değiştir',
                ),
                const AdminSectionTitle(
                    title: 'Sahne Bilgileri', icon: Icons.location_city_rounded),
                CustomTextField(controller: _nameController, label: 'Sahne Adı'),
                CustomTextField(
                    controller: _addressController, label: 'Adres'),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _latController,
                        label: 'Enlem (lat)',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: CustomTextField(
                        controller: _lngController,
                        label: 'Boylam (lng)',
                        keyboardType: const TextInputType.numberWithOptions(
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
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: _isEditing ? 'Değişiklikleri kaydet' : 'Sahneyi oluştur',
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _save,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(_isEditing ? 'Kaydet' : 'Sahneyi Oluştur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.colors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
