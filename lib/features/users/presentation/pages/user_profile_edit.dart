import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
import '../../domain/entities/user.dart';
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
  File? _selectedImageFile;

  final StorageService _storageService = StorageService();
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

  Future<void> _pickImage(final ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final userState = ref.watch(userProvider);

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
                subtitle: 'Hafıza Sarayı\'ndaki izlerini güncelle...',
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CustomArtWordsCard(
                  word: 'Gelecek, güzelliğe inananlarındır.',
                  author: 'Eleanor Roosevelt'),
              const SizedBox(height: 32),
              _buildAvatarPicker(),
              const SizedBox(height: 32),
              _buildFields(),
              const SizedBox(height: 40),
              _buildSaveButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );

  Widget _buildAvatarPicker() => Center(
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.primary, width: 2)),
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _selectedImageFile != null
                    ? FileImage(_selectedImageFile!) as ImageProvider
                    : NetworkImage(_profileImageUrl),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: FloatingActionButton.small(
                onPressed: () => _pickImage(ImageSource.gallery),
                child: const Icon(Icons.camera_alt),
              ),
            )
          ],
        ),
      );

  Widget _buildFields() => Column(
        children: [
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
              label: 'E-Posta',
              isRequired: false),
          const SizedBox(height: 16),
          CustomTextField(
              controller: _phoneController,
              label: 'Telefon',
              isRequired: false),
          const SizedBox(height: 16),
          CustomTextField(
              controller: _cityController, label: 'Şehir', isRequired: false),
        ],
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

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Yükleme durumunu başlat (Butonu pasife çeker)
    // ref.read(userProvider.notifier).setLoading(true); // Gerekirse ekleyin

    final currentUser = ref.read(userProvider).dataSingle;
    String finalImageUrl = _profileImageUrl; // Varsayılan olarak mevcut URL

    try {
      // ⚡ KRİTİK ADIM: Eğer yeni bir fotoğraf seçilmişse önce Storage'a yükle
      if (_selectedImageFile != null) {
        final uploadedUrl = await _storageService.uploadProfileImage(
            widget.userId, _selectedImageFile!);

        if (uploadedUrl != null)
          finalImageUrl = uploadedUrl; // Yeni URL'yi kullan
        else {
          _showSnackBar("Fotoğraf sunucuya iletilemedi.", isError: true);
          return; // Yükleme başarısızsa işlemi durdur
        }
      }

      // Yeni verileri hazırla (Yeni resim URL'si dahil)
      final userToSave = (currentUser ?? User.empty(widget.userId)).copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        eMail: _emailController.text.trim(),
        city: _cityController.text.trim(),
        imageUrl: finalImageUrl,
        // Firestore'a gidecek nihai URL
        updatedAt: DateTime.now().toIso8601String(),
      );

      // 1. Firestore'u güncelle
      await ref
          .read(userProvider.notifier)
          .saveUser(userToSave, finalImageUrl, isUpdate: true);

      // 2. Local Storage güncelle
      await LocalStorageService.saveEssentialUserData(
        uid: widget.userId,
        displayName: '${userToSave.firstName} ${userToSave.lastName}',
        role: userToSave.role,
        photoUrl: finalImageUrl, // Local'e de yeni fotoğrafı ver
      );

      if (mounted) _showSuccessDialog();
    } catch (e) {
      _showSnackBar("İşlem sırasında bir sorun oluştu: $e", isError: true);
    }
  }

  void _showSuccessDialog() => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final dialogContext) => CustomSuccessDialog(
          message: 'Bilgilerin güncellendi!',
          onConfirm: () {
            Navigator.of(dialogContext, rootNavigator: true)
                .pop(); // Dialogu kapat
          },
        ),
      );

  void _showSnackBar(final String msg, {final bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : Colors.green));

  Widget _buildShimmerLoading() => Shimmer.fromColors(
        baseColor: context.colors.surfaceVariant.withOpacity(0.4),
        highlightColor: context.colors.surfaceVariant,
        child: const Center(child: CircularProgressIndicator()),
      );
}
