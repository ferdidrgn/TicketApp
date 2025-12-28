import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // Fotoğraf seçimi için
import 'package:shimmer/shimmer.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/shared/widgets/top_normal_header.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/button/custom_elevated_button.dart';
import '../../../../shared/widgets/custom_art_words_card.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../auth/presentation/providers/storage_service.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user.dart' as entity;
import '../providers/user_provider.dart';
import '../providers/user_state.dart';

class UserProfileEditScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileEditScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileEditScreen> createState() =>
      _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends ConsumerState<UserProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImageFile; // Galeriden seçilen dosya

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityController;

  String _profileImageUrl = 'https://via.placeholder.com/150';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _cityController = TextEditingController();

    // Veriyi Firestore'dan çekmeye başla
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      ref.read(userProvider.notifier).loadUserById(widget.userId);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // Fotoğraf Seçme İşlemi (Galeriden)
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  // Verileri Kontrolcülere Doldurma (UI Sync)
  void _fillFields(final User user) {
    if (_isInitialized) return;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phoneNumber;
    _emailController.text = user.eMail;
    _cityController.text = user.city;
    _profileImageUrl = user.imageUrl.isNotEmpty
        ? user.imageUrl
        : 'https://via.placeholder.com/150';

    _isInitialized = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(final BuildContext context) {
    final userState = ref.watch(userProvider);

    // ⚡ VERİ GELDİĞİNDE KUTUCUKLARI DOLDURAN DİNLEYİCİ
    ref.listen<UserState>(userProvider, (final previous, final next) {
      if (!next.isLoading && next.dataSingle != null && !_isInitialized) {
        _fillFields(next.dataSingle!);
      }
    });

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: CustomAppBackground(
        child: SafeArea(
          child: Column(
            children: [
              TopNormalHeader(
                title: 'Kimliğini Biçimlendir',
                subtitle: 'Sanatçı profilini dünyaya tanıt...',
                rightIcon: Icons.auto_fix_high_rounded,
              ),
              Expanded(
                child: (userState.isLoading && !_isInitialized)
                    ? _buildShimmerLoading()
                    : _buildForm(context, userState.dataSingle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(final BuildContext context, final User? currentUser) =>
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CustomArtWordsCard(
                  word: 'Gelecek, güzelliğe inananlarındır.',
                  author: 'Eleanor Roosevelt'),
              const SizedBox(height: 32),
              _buildAvatarSection(),
              const SizedBox(height: 32),
              _buildSectionTitle('Öz Kimlik Bilgileri'),
              Row(
                children: [
                  Expanded(
                      child: CustomTextField(
                          controller: _firstNameController,
                          label: 'Ad',
                          isRequired: true)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: CustomTextField(
                          controller: _lastNameController,
                          label: 'Soyad',
                          isRequired: true)),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _emailController,
                  label: 'E-Posta Adresi',
                  isRequired: false),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _phoneController,
                  label: 'Telefon Numarası',
                  isRequired: false),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _cityController,
                  label: 'Yaşadığın Şehir',
                  isRequired: false),
              const SizedBox(height: 40),
              _buildSaveButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );

  Widget _buildAvatarSection() => Center(
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.primary, width: 2)),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: context.colors.surfaceVariant,
                backgroundImage: _selectedImageFile != null
                    ? FileImage(_selectedImageFile!) as ImageProvider
                    : NetworkImage(_profileImageUrl),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: FloatingActionButton.small(
                onPressed: _pickImage,
                child: const Icon(Icons.camera_alt_rounded),
              ),
            )
          ],
        ),
      );

  Widget _buildSaveButton() {
    final isLoading = ref.watch(userProvider).isLoading;
    return SizedBox(
      width: double.infinity,
      child: CustomElevatedButton(
        text: 'Varlığını Güncelle',
        onPressed: isLoading ? () {} : () => _updateProfile(),
      ),
    );
  }

  // ⚡ GÜNCELLEME VE SENKRONİZASYON MANTIĞI
  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // ⚡ Riverpod üzerinden servisimizi alıyoruz
    final storageService = ref.read(storageServiceProvider);
    final userNotifier = ref.read(userProvider.notifier);

    String finalImageUrl = _profileImageUrl;

    try {
      // 1. ADIM: EĞER YENİ FOTOĞRAF SEÇİLDİYSE
      if (_selectedImageFile != null) {
        // a) Eski fotoğrafı temizle (Varsayılan placeholder değilse)
        if (_profileImageUrl.isNotEmpty &&
            !_profileImageUrl.contains('placeholder')) {
          await storageService.deleteProfileImage(widget.userId);
        }

        // b) Yeni fotoğrafı yükle
        final uploadedUrl = await storageService.uploadProfileImage(
            widget.userId, _selectedImageFile!);

        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        } else {
          throw "Fotoğraf sunucuya yüklenemedi.";
        }
      }

      // 2. ADIM: FIRESTORE GÜNCELLEME
      final currentUser = ref.read(userProvider).dataSingle;
      final userToSave =
          (currentUser ?? entity.User.empty(widget.userId)).copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        imageUrl: finalImageUrl,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await userNotifier.saveUser(userToSave, finalImageUrl, isUpdate: true);

      // 3. ADIM: LOKAL VE AUTH STATE SENKRONİZASYONU
      await LocalStorageService.saveEssentialUserData(
        uid: widget.userId,
        displayName: '${userToSave.firstName} ${userToSave.lastName}',
        photoUrl: finalImageUrl,
      );

      // LoginProvider state'ini tazele
      ref.read(loginProvider.notifier).refreshUserState(userToSave);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _selectedImageFile = null);
    }
  }

  void _showSuccessDialog() => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final dialogContext) => CustomSuccessDialog(
          message: 'Kimliğin başarıyla güncellendi!',
          onConfirm: () {
            // ✅ Sadece Pop-up'ı kapatıyoruz (Geri dönünce siyah ekran olmaması için)
            Navigator.of(dialogContext, rootNavigator: true).pop();
          },
        ),
      );

  Widget _buildShimmerLoading() => Shimmer.fromColors(
        baseColor: context.colors.surfaceVariant.withOpacity(0.4),
        highlightColor: context.colors.surfaceVariant,
        child: const Center(child: CircularProgressIndicator()),
      );

  Widget _buildSectionTitle(final String title) => Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title.toUpperCase(),
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );

  // ⚡ DÜZELTME: Gövdesi dolduruldu
  void _showSnackBar(final String message, {final bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
}
