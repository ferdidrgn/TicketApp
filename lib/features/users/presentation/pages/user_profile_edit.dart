import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/shared/widgets/top_normal_header.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../../../../shared/widgets/button/custom_elevated_button.dart';
import '../../../../shared/widgets/custom_art_words_card.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../../shared/widgets/custom_text_field.dart';
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

  // 1. KONTROLCÜLER: Başlangıçta boş tanımlanır
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;
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
    _ageController = TextEditingController();
    _cityController = TextEditingController();

    // Sayfa açılır açılmaz veriyi çekmeye başla
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
    _ageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // 2. VERİ DOLDURMA: Veri geldiğinde kontrolcüleri günceller
  void _fillFields(final User user) {
    if (_isInitialized) return;

    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phoneNumber;
    _emailController.text = user.eMail;
    _ageController.text = user.age > 0 ? user.age.toString() : '';
    _cityController.text = user.city;
    _profileImageUrl = user.imageUrl.isNotEmpty
        ? user.imageUrl
        : 'https://via.placeholder.com/150';

    _isInitialized = true;
    // UI'ın güncellenmesi için setState şart
    if (mounted) setState(() {});
  }

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;
    final userState = ref.watch(userProvider);

    // 3. DİNLEYİCİ: Veri her değiştiğinde veya yüklendiğinde kontrol et
    ref.listen<UserState>(userProvider, (final previous, final next) {
      if (!next.isLoading && next.dataSingle != null && !_isInitialized) {
        _fillFields(next.dataSingle!);
      }
    });

    return Scaffold(
      backgroundColor: themeColors.surface,
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
                // Veri yoksa veya hala yükleniyorsa Shimmer göster
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

  // Yükleme Tasarımı
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: context.colors.surfaceVariant.withOpacity(0.4),
      highlightColor: context.colors.surfaceVariant,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(height: 40),
            ...List.generate(
                4,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16))),
                    )),
          ],
        ),
      ),
    );
  }

  // Form Tasarımı
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
                author: 'Eleanor Roosevelt',
              ),
              const SizedBox(height: 32),
              _buildProfileImagePicker(),
              const SizedBox(height: 32),
              _buildSectionTitle('Öz Kimlik Bilgileri'),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _firstNameController,
                      label: 'Ad',
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _lastNameController,
                      label: 'Soyad',
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: 'E-Posta Adresi',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                keyboardType: TextInputType.emailAddress,
                isRequired: false,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: 'Telefon Numarası',
                prefixIcon: const Icon(Icons.phone_iphone_rounded),
                keyboardType: TextInputType.phone,
                isRequired: false,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _cityController,
                label: 'Yaşadığın Şehir',
                prefixIcon: const Icon(Icons.location_city_rounded),
                isRequired: false,
              ),
              const SizedBox(height: 40),
              _buildSaveButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );

  Widget _buildProfileImagePicker() => Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.colors.primary, width: 2),
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(_profileImageUrl),
            backgroundColor: context.colors.surfaceVariant,
          ),
        ),
      );

  Widget _buildSectionTitle(final String title) => Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title.toUpperCase(),
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colors.primary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

  Widget _buildSaveButton() {
    final isLoading = ref.watch(userProvider).isLoading;
    return SizedBox(
      width: double.infinity,
      child: CustomElevatedButton(
        text: 'Sanat Yolculuğunu Güncelle',
        onPressed: isLoading ? () {} : () => _updateProfile(),
      ),
    );
  }

  // 4. ADIM: Güncelleme ve Geri Dönüş
  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final currentUser = ref.read(userProvider).dataSingle;
    final userToSave = (currentUser ?? User.empty(widget.userId)).copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      eMail: _emailController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      city: _cityController.text.trim(),
      imageUrl: _profileImageUrl,
      updatedAt: DateTime.now().toIso8601String(),
    );

    try {
      // 1. Firebase'i güncelle
      await ref
          .read(userProvider.notifier)
          .saveUser(userToSave, _profileImageUrl, isUpdate: true);

      // 2. Local Storage senkronize et
      await LocalStorageService.saveEssentialUserData(
        uid: widget.userId,
        displayName: '${userToSave.firstName} ${userToSave.lastName}',
        role: userToSave.role,
      );

      // 3. Başarı pop-up göster
      if (mounted) _showSuccessDialog();
    } catch (e) {
      _showSnackBar('Hata oluştu: $e', isError: true);
    }
  }

  void _showSuccessDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final dialogContext) => CustomSuccessDialog(
        message: 'Kimliğin başarıyla güncellendi!',
        onConfirm: () {
          // ÖNCE Dialog'u kapat
          Navigator.of(dialogContext).pop();
          // SONRA Profil sayfasına dön
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showSnackBar(final String msg, {final bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ));
}
