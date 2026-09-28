import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_mutation_provider.dart';
import '../../../players/presentation/providers/player_provider.dart';
import 'admin_form_widgets.dart';

/// "Oyuncular" sekmesi — Phase 1 kapsamı: sadece YENİ oyuncu ekleme.
/// Üstte mevcut oyuncular (salt-okunur, referans), altında gerçek bir
/// ekleme formu.
///
/// ⚠️ BİLİNÇLİ SINIR: `Player` entity'sindeki `achievements` (ödüller) ve
/// `collaborations` (iş birlikleri) gibi iç içe liste alanları burada
/// DÜZENLENEMİYOR — bunlar dinamik, tekrarlı liste editörü gerektiren
/// karmaşık alanlar ve Phase 1'in "basit ekleme formu" kapsamının dışında
/// bırakıldı (boş liste olarak kaydedilir). `firstName`/`lastName`/
/// `imageUrl`/`bio`/`quote` gerçek, doğrudan yazılabilir alanlardır.
class AdminPlayersTab extends ConsumerStatefulWidget {
  const AdminPlayersTab({super.key});

  @override
  ConsumerState<AdminPlayersTab> createState() => _AdminPlayersTabState();
}

class _AdminPlayersTabState extends ConsumerState<AdminPlayersTab> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _quoteController = TextEditingController();

  File? _selectedImageFile;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
    if (picked != null) setState(() => _selectedImageFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final player = Player(
      id: '',
      createdAt: '',
      updatedAt: '',
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      imageUrl: '',
      bio: _bioController.text.trim(),
      achievements: const [],
      collaborations: const [],
      quote: _quoteController.text.trim(),
      nowShowsId: const [],
      oldShowsId: const [],
    );

    await ref
        .read(playerMutationProvider.notifier)
        .addPlayer(player, _selectedImageFile);

    if (!mounted) return;
    final state = ref.read(playerMutationProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Oyuncu eklenemedi: ${state.error}'),
        backgroundColor: Colors.red,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Oyuncu eklendi.'),
        backgroundColor: Colors.green,
      ));
      _formKey.currentState?.reset();
      _firstNameController.clear();
      _lastNameController.clear();
      _bioController.clear();
      _quoteController.clear();
      setState(() => _selectedImageFile = null);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final playersAsync = ref.watch(playersProvider(isLimit: false));
    final isSaving = ref.watch(playerMutationProvider).isLoading;
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle(
              title: 'Mevcut Oyuncular', icon: Icons.person_rounded),
          playersAsync.when(
            loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: LinearProgressIndicator()),
            error: (final e, final st) =>
                AdminInlineBanner(message: 'Oyuncular yüklenemedi: $e'),
            data: (final players) => players.isEmpty
                ? Text('Henüz oyuncu eklenmemiş.',
                    style: TextStyle(color: colors.onSurfaceVariant))
                : Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: players
                        .map((final p) => Chip(
                              label: Text('${p.firstName} ${p.lastName}'),
                              avatar:
                                  const Icon(Icons.person_rounded, size: 16),
                            ))
                        .toList(),
                  ),
          ),
          const AdminSectionTitle(
              title: 'Yeni Oyuncu Ekle', icon: Icons.person_add_rounded),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminImagePickerField(
                  selectedFile: _selectedImageFile,
                  existingImageUrl: null,
                  onPick: _pickImage,
                  semanticLabel: 'Oyuncu fotoğrafı, dokun ve seç',
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                          controller: _firstNameController, label: 'Ad'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: CustomTextField(
                          controller: _lastNameController, label: 'Soyad'),
                    ),
                  ],
                ),
                CustomTextField(
                    controller: _bioController,
                    label: 'Biyografi',
                    maxLines: 4,
                    isRequired: false),
                CustomTextField(
                    controller: _quoteController,
                    label: 'Alıntı / Söz',
                    isRequired: false),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: 'Oyuncuyu kaydet',
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _submit,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: const Text('Oyuncuyu Kaydet'),
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
