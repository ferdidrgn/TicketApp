import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ticketapp/shared/widgets/top_normal_header.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/button/custom_elevated_button.dart';
import '../../../../shared/widgets/custom_art_words_card.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../domain/entities/user.dart';
import '../providers/user_mutation_provider.dart';
import '../providers/user_provider.dart';

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
    final userAsync = ref.watch(currentUserProvider);
    ref.watch(userMutationProvider);

    userAsync.whenData((final user) {
      if (user != null && !_isInitialized) _fillFields(user);
    });

    return Scaffold(
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
                child: userAsync.when(
                  loading: () => _buildShimmerLoading(),
                  error: (final err, final stack) =>
                      Center(child: Text('Hata: $err')),
                  data: (final user) => _buildForm(context, user),
                ),
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
    final isLoading = ref.watch(userMutationProvider).isLoading;
    return SizedBox(
      width: double.infinity,
      child: CustomElevatedButton(
        text: 'Varlığını Güncelle',
        onPressed: isLoading ? () {} : () => _updateProfile(),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    // 1. Yeni veriyi hazırla
    final updatedUser = currentUser.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      city: _cityController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    // 2. ⚡ TEK SATIRDA GÜNCELLEME:
    // Bu metod hem Storage'ı, hem Firestore'u hem de LocalStorage'ı senkronize eder.
    await ref.read(userMutationProvider.notifier).save(
          updatedUser,
          _selectedImageFile?.path ?? _profileImageUrl,
          // Yeni dosya yolu veya eski URL
          isUpdate: true,
        );

    // 3. Sonuç Kontrolü
    final state = ref.read(userMutationProvider);
    if (!state.hasError && mounted) {
      _showSuccessDialog();
      setState(() => _selectedImageFile = null);
    } else if (state.hasError)
      _showSnackBar(state.error.toString(), isError: true);
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
