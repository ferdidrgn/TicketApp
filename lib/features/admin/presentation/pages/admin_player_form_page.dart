import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_mutation_provider.dart';
import '../widgets/admin_form_widgets.dart';

/// Oyuncu ekleme/düzenleme formu — Phase 2. `player == null` -> yeni
/// oyuncu; aksi halde düzenleme + silme (bkz. `AdminShowFormPage`'daki AYNI
/// desen).
///
/// Phase 1'in bilinçli sınırı burada kapatıldı: `achievements` (ödüller —
/// gerçek şekli `List<Map<String, String>>`, alanlar `year`/`title`/
/// `detail`, bkz. `player.dart`) ve `collaborations` (`List<String>`)
/// artık gerçek add/remove editörleriyle DOĞRUDAN `Player` entity'sine
/// yazılıyor — placeholder/boş liste değil.
class AdminPlayerFormPage extends ConsumerStatefulWidget {
  final Player? player;

  const AdminPlayerFormPage({super.key, this.player});

  @override
  ConsumerState<AdminPlayerFormPage> createState() =>
      _AdminPlayerFormPageState();
}

class _AdminPlayerFormPageState extends ConsumerState<AdminPlayerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _quoteController;

  // Achievements ekleme mini-formu
  final _achYearController = TextEditingController();
  final _achTitleController = TextEditingController();
  final _achDetailController = TextEditingController();

  // Collaborations ekleme mini-formu
  final _collabController = TextEditingController();

  File? _selectedImageFile;
  late List<Map<String, String>> _achievements;
  late List<String> _collaborations;

  bool get _isEditing => widget.player != null;

  @override
  void initState() {
    super.initState();
    final player = widget.player;
    _firstNameController = TextEditingController(text: player?.firstName ?? '');
    _lastNameController = TextEditingController(text: player?.lastName ?? '');
    _bioController = TextEditingController(text: player?.bio ?? '');
    _quoteController = TextEditingController(text: player?.quote ?? '');
    _achievements = List<Map<String, String>>.from(
        (player?.achievements ?? const []).map((final e) => Map.of(e)));
    _collaborations = List<String>.from(player?.collaborations ?? const []);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _quoteController.dispose();
    _achYearController.dispose();
    _achTitleController.dispose();
    _achDetailController.dispose();
    _collabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
    if (picked != null) setState(() => _selectedImageFile = File(picked.path));
  }

  void _addAchievement() {
    final year = _achYearController.text.trim();
    final title = _achTitleController.text.trim();
    final detail = _achDetailController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ödül başlığı boş olamaz.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() {
      _achievements = [
        ..._achievements,
        {'year': year, 'title': title, 'detail': detail},
      ];
      _achYearController.clear();
      _achTitleController.clear();
      _achDetailController.clear();
    });
  }

  void _removeAchievement(final int index) =>
      setState(() => _achievements = [..._achievements]..removeAt(index));

  void _addCollaboration() {
    final value = _collabController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _collaborations = [..._collaborations, value];
      _collabController.clear();
    });
  }

  void _removeCollaboration(final int index) =>
      setState(() => _collaborations = [..._collaborations]..removeAt(index));

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_isEditing) {
      final updatedData = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'quote': _quoteController.text.trim(),
        'achievements': _achievements,
        'collaborations': _collaborations,
      };
      await ref.read(playerMutationProvider.notifier).updatePlayer(
            playerId: widget.player!.id,
            updatedData: updatedData,
            imageFile: _selectedImageFile,
          );
    } else {
      final player = Player(
        id: '',
        createdAt: '',
        updatedAt: '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        imageUrl: '',
        bio: _bioController.text.trim(),
        achievements: _achievements,
        collaborations: _collaborations,
        quote: _quoteController.text.trim(),
        nowShowsId: const [],
        oldShowsId: const [],
      );
      await ref
          .read(playerMutationProvider.notifier)
          .addPlayer(player, _selectedImageFile);
    }

    if (!mounted) return;
    final state = ref.read(playerMutationProvider);
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
          message: _isEditing ? 'Oyuncu güncellendi.' : 'Oyuncu oluşturuldu.',
          onConfirm: () {
            Navigator.of(dialogContext, rootNavigator: true).pop();
            if (mounted) Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final player = widget.player;
    if (player == null) return;
    await showDialog(
      context: context,
      builder: (final _) => CustomActionDialog(
        title: 'OYUNCUYU SİL',
        message:
            '"${player.firstName} ${player.lastName}" kalıcı olarak silinecek. Emin misin?',
        icon: Icons.delete_forever_rounded,
        iconColor: Colors.red,
        positiveText: 'SİL',
        negativeText: 'VAZGEÇ',
        onPositiveAction: () async {
          await ref
              .read(playerMutationProvider.notifier)
              .deletePlayer(player.id);
          if (!mounted) return;
          final state = ref.read(playerMutationProvider);
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
    final isSaving = ref.watch(playerMutationProvider).isLoading;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Oyuncuyu Düzenle' : 'Yeni Oyuncu'),
        actions: [
          if (_isEditing)
            Semantics(
              button: true,
              label: 'Oyuncuyu sil',
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
                  existingImageUrl: widget.player?.imageUrl,
                  onPick: _pickImage,
                  semanticLabel: 'Oyuncu fotoğrafı, dokun ve değiştir',
                ),
                const AdminSectionTitle(
                    title: 'Temel Bilgiler', icon: Icons.person_rounded),
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

                // ---- Ödüller (achievements) ----
                const AdminSectionTitle(
                    title: 'Ödüller / Başarılar', icon: Icons.emoji_events_rounded),
                if (_achievements.isEmpty)
                  Text('Henüz ödül eklenmedi.',
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant))
                else
                  Column(
                    children: List.generate(_achievements.length, (final i) {
                      final a = _achievements[i];
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a['year']?.isNotEmpty == true
                                        ? '${a['year']} — ${a['title']}'
                                        : a['title'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                  if (a['detail']?.isNotEmpty == true)
                                    Text(a['detail']!,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: colors.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Semantics(
                              button: true,
                              label: 'Bu ödülü kaldır',
                              child: IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () => _removeAchievement(i),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: CustomTextField(
                          controller: _achYearController,
                          label: 'Yıl',
                          isRequired: false),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: CustomTextField(
                          controller: _achTitleController,
                          label: 'Ödül Başlığı',
                          isRequired: false),
                    ),
                  ],
                ),
                CustomTextField(
                    controller: _achDetailController,
                    label: 'Detay',
                    isRequired: false),
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    button: true,
                    label: 'Ödülü listeye ekle',
                    child: OutlinedButton.icon(
                      onPressed: _addAchievement,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Ödül Ekle'),
                    ),
                  ),
                ),

                // ---- İş birlikleri (collaborations) ----
                const AdminSectionTitle(
                    title: 'İş Birlikleri', icon: Icons.handshake_rounded),
                if (_collaborations.isEmpty)
                  Text('Henüz iş birliği eklenmedi.',
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant))
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: List.generate(_collaborations.length, (final i) {
                      final c = _collaborations[i];
                      return Chip(
                        label: Text(c),
                        onDeleted: () => _removeCollaboration(i),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      );
                    }),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                          controller: _collabController,
                          label: 'İş birliği (ör. bir kurum/kişi adı)',
                          isRequired: false),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Semantics(
                      button: true,
                      label: 'İş birliğini listeye ekle',
                      child: IconButton.filled(
                        onPressed: _addCollaboration,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: _isEditing
                        ? 'Değişiklikleri kaydet'
                        : 'Oyuncuyu oluştur',
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _save,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(_isEditing ? 'Kaydet' : 'Oyuncuyu Oluştur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
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
