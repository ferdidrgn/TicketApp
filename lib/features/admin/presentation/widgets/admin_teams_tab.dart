import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/team_mutation_provider.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import 'admin_form_widgets.dart';

/// "Topluluklar" sekmesi — Phase 1 kapsamı: sadece YENİ topluluk (Team)
/// ekleme. Üstte mevcut topluluklar (salt-okunur, referans), altında
/// gerçek bir ekleme formu.
class AdminTeamsTab extends ConsumerStatefulWidget {
  const AdminTeamsTab({super.key});

  @override
  ConsumerState<AdminTeamsTab> createState() => _AdminTeamsTabState();
}

class _AdminTeamsTabState extends ConsumerState<AdminTeamsTab> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedImageFile;

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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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

    if (!mounted) return;
    final state = ref.read(teamMutationProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Topluluk eklenemedi: ${state.error}'),
        backgroundColor: Colors.red,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Topluluk eklendi.'),
        backgroundColor: Colors.green,
      ));
      _formKey.currentState?.reset();
      _nameController.clear();
      _descriptionController.clear();
      setState(() => _selectedImageFile = null);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider(isLimit: false));
    final isSaving = ref.watch(teamMutationProvider).isLoading;
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle(
              title: 'Mevcut Topluluklar', icon: Icons.groups_rounded),
          teamsAsync.when(
            loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: LinearProgressIndicator()),
            error: (final e, final st) =>
                AdminInlineBanner(message: 'Topluluklar yüklenemedi: $e'),
            data: (final teams) => teams.isEmpty
                ? Text('Henüz topluluk eklenmemiş.',
                    style: TextStyle(color: colors.onSurfaceVariant))
                : Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: teams
                        .map((final t) => Chip(
                              label: Text(t.name),
                              avatar: const Icon(Icons.groups_rounded, size: 16),
                            ))
                        .toList(),
                  ),
          ),
          const AdminSectionTitle(
              title: 'Yeni Topluluk Ekle', icon: Icons.group_add_rounded),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminImagePickerField(
                  selectedFile: _selectedImageFile,
                  existingImageUrl: null,
                  onPick: _pickImage,
                  semanticLabel: 'Topluluk görseli, dokun ve seç',
                ),
                CustomTextField(
                    controller: _nameController, label: 'Topluluk Adı'),
                CustomTextField(
                    controller: _descriptionController,
                    label: 'Açıklama',
                    maxLines: 4),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: 'Topluluğu kaydet',
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _submit,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: const Text('Topluluğu Kaydet'),
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
