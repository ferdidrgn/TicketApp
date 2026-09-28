import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/team_mutation_provider.dart';
import '../widgets/admin_form_widgets.dart';

/// Topluluk (Team) ekleme/düzenleme formu — Phase 2. `team == null` -> yeni
/// topluluk; aksi halde düzenleme + silme (bkz. `AdminShowFormPage`'daki
/// AYNI desen).
class AdminTeamFormPage extends ConsumerStatefulWidget {
  final Team? team;

  const AdminTeamFormPage({super.key, this.team});

  @override
  ConsumerState<AdminTeamFormPage> createState() => _AdminTeamFormPageState();
}

class _AdminTeamFormPageState extends ConsumerState<AdminTeamFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  File? _selectedImageFile;

  bool get _isEditing => widget.team != null;

  @override
  void initState() {
    super.initState();
    final team = widget.team;
    _nameController = TextEditingController(text: team?.name ?? '');
    _descriptionController =
        TextEditingController(text: team?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
    if (picked != null) setState(() => _selectedImageFile = File(picked.path));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_isEditing) {
      final updatedData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
      };
      await ref.read(teamMutationProvider.notifier).updateTeam(
            teamId: widget.team!.id,
            updatedData: updatedData,
            imageFile: _selectedImageFile,
          );
    } else {
      final team = Team(
        id: '',
        createdAt: '',
        updatedAt: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: '',
        photosId: const [],
        showsId: const [],
      );
      await ref
          .read(teamMutationProvider.notifier)
          .addTeam(team, _selectedImageFile);
    }

    if (!mounted) return;
    final state = ref.read(teamMutationProvider);
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
          message:
              _isEditing ? 'Topluluk güncellendi.' : 'Topluluk oluşturuldu.',
          onConfirm: () {
            Navigator.of(dialogContext, rootNavigator: true).pop();
            if (mounted) Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final team = widget.team;
    if (team == null) return;
    await showDialog(
      context: context,
      builder: (final _) => CustomActionDialog(
        title: 'TOPLULUĞU SİL',
        message: '"${team.name}" kalıcı olarak silinecek. Emin misin?',
        icon: Icons.delete_forever_rounded,
        iconColor: Colors.red,
        positiveText: 'SİL',
        negativeText: 'VAZGEÇ',
        onPositiveAction: () async {
          await ref.read(teamMutationProvider.notifier).deleteTeam(team.id);
          if (!mounted) return;
          final state = ref.read(teamMutationProvider);
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
    final isSaving = ref.watch(teamMutationProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Topluluğu Düzenle' : 'Yeni Topluluk'),
        actions: [
          if (_isEditing)
            Semantics(
              button: true,
              label: 'Topluluğu sil',
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
                  existingImageUrl: widget.team?.imageUrl,
                  onPick: _pickImage,
                  semanticLabel: 'Topluluk görseli, dokun ve değiştir',
                ),
                const AdminSectionTitle(
                    title: 'Topluluk Bilgileri', icon: Icons.groups_rounded),
                CustomTextField(
                    controller: _nameController, label: 'Topluluk Adı'),
                CustomTextField(
                    controller: _descriptionController,
                    label: 'Açıklama',
                    maxLines: 4),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: _isEditing
                        ? 'Değişiklikleri kaydet'
                        : 'Topluluğu oluştur',
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _save,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(_isEditing ? 'Kaydet' : 'Topluluğu Oluştur'),
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
