import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/button/custom_elevated_button.dart';
import '../../../../shared/widgets/custom_art_words_card.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/footers/footer.dart';
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
    final userAsync = ref.watch(userProfileProvider);
    // Mutation durumunu takip et (Loading vs.)
    final mutationState = ref.watch(userMutationProvider);

    userAsync.whenData((final user) {
      if (user != null && !_isInitialized) _fillFields(user);
    });

    // 🖥️ Masaüstü/web: mobil zırhı (gradient başlık, FAB, parçacık
    // arkaplanı) atlanır; aynı form/controller/save akışı kendi sade web
    // kabuğunda gösterilir.
    if (context.isDesktop) {
      return _buildDesktopPage(context, userAsync);
    }

    return BasePageWrapper(
      showBackButton: true,
      showFab: true,
      title: 'Profili Düzenle',
      subtitle: 'Bilgilerini güncel tut.',
      isLoading: userAsync.isLoading || mutationState.isLoading,
      layoutConfig: BasePageLayoutConfig(
          backgroundColor: context.scaffoldBackgroundColor, safeAreaTop: true),
      child: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final err, final stack) => Center(child: Text('Hata: $err')),
        data: (final user) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Sayfa Başlığı (BasePageWrapper geri butonunu üstte bıraktığı için burayı sadeleştirdik)
                const SizedBox(height: AppSpacing.xl),
                _buildHeaderTexts(),

                const SizedBox(height: AppSpacing.xxl),
                const CustomArtWordsCard(
                  word: 'Gelecek, güzelliğe inananlarındır.',
                  author: 'Eleanor Roosevelt',
                ),

                const SizedBox(height: AppSpacing.xxxl),
                _buildAvatarSection(),

                const SizedBox(height: AppSpacing.xxxl),
                _buildSectionTitle('Kişisel Bilgiler'),

                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        textField: true,
                        label: 'Ad, zorunlu alan',
                        child: CustomTextField(
                          controller: _firstNameController,
                          label: 'Ad',
                          isRequired: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Semantics(
                        textField: true,
                        label: 'Soyad, zorunlu alan',
                        child: CustomTextField(
                          controller: _lastNameController,
                          label: 'Soyad',
                          isRequired: true,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  textField: true,
                  label: 'E-Posta Adresi',
                  child: CustomTextField(
                    controller: _emailController,
                    label: 'E-Posta Adresi',
                    isRequired: false,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  textField: true,
                  label: 'Telefon Numarası',
                  child: CustomTextField(
                    controller: _phoneController,
                    label: 'Telefon Numarası',
                    isRequired: false,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  textField: true,
                  label: 'Yaşadığın Şehir',
                  child: CustomTextField(
                    controller: _cityController,
                    label: 'Yaşadığın Şehir',
                    isRequired: false,
                  ),
                ),

                const SizedBox(height: AppSpacing.huge),
                _buildSaveButton(),
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Başlık metinlerini düzenlemek için yardımcı metod
  Widget _buildHeaderTexts() => Column(
        children: [
          Text(
            'Profilini Düzenle',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ad, fotoğraf, şehir ve iletişim bilgilerini güncelle.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      );

  Widget _buildForm(final BuildContext context, final User? currentUser) =>
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CustomArtWordsCard(
                  word: 'Gelecek, güzelliğe inananlarındır.',
                  author: 'Eleanor Roosevelt'),
              const SizedBox(height: AppSpacing.xxxl),
              _buildAvatarSection(),
              const SizedBox(height: AppSpacing.xxxl),
              _buildSectionTitle('Kişisel Bilgiler'),
              Row(
                children: [
                  Expanded(
                      child: CustomTextField(
                          controller: _firstNameController,
                          label: 'Ad',
                          isRequired: true)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: CustomTextField(
                          controller: _lastNameController,
                          label: 'Soyad',
                          isRequired: true)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              CustomTextField(
                  controller: _emailController,
                  label: 'E-Posta Adresi',
                  isRequired: false),
              const SizedBox(height: AppSpacing.lg),
              CustomTextField(
                  controller: _phoneController,
                  label: 'Telefon Numarası',
                  isRequired: false),
              const SizedBox(height: AppSpacing.lg),
              CustomTextField(
                  controller: _cityController,
                  label: 'Yaşadığın Şehir',
                  isRequired: false),
              const SizedBox(height: AppSpacing.huge),
              _buildSaveButton(),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      );

  Widget _buildAvatarSection() => Center(
        child: Stack(
          children: [
            Semantics(
              image: true,
              label: 'Profil fotoğrafı',
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: context.colors.primary, width: 2)),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: context.colors.surfaceVariant,
                  backgroundImage: _selectedImageFile != null
                      ? FileImage(_selectedImageFile!) as ImageProvider
                      : NetworkImage(_profileImageUrl),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Semantics(
                button: true,
                label: 'Profil fotoğrafını değiştir',
                child: FloatingActionButton.small(
                  tooltip: 'Profil fotoğrafını değiştir',
                  onPressed: _pickImage,
                  child: const Icon(Icons.camera_alt_rounded),
                ),
              ),
            )
          ],
        ),
      );

  Widget _buildSaveButton() {
    final isLoading = ref.watch(userMutationProvider).isLoading;
    return Semantics(
      button: true,
      label: 'Kaydet, profil bilgilerini güncelle',
      child: SizedBox(
        width: double.infinity,
        child: CustomElevatedButton(
          text: 'Kaydet',
          onPressed: isLoading ? () {} : () => _updateProfile(),
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final currentUser = ref.read(userProfileProvider).value;
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
          message: 'Profilin güncellendi.',
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
        padding:
            const EdgeInsets.only(bottom: AppSpacing.lg, top: AppSpacing.sm),
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

  // --- 🖥️ MASAÜSTÜ / WEB KABUĞU ---
  // Aynı _formKey, aynı controller'lar, aynı _pickImage/_updateProfile
  // akışı; sadece mobil BasePageWrapper zırhı yerine sade bir web kabuğu.
  Widget _buildDesktopPage(
    final BuildContext context,
    final AsyncValue<User?> userAsync,
  ) =>
      ColoredBox(
        color: WebColors.darkBlueBackground,
        child: userAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: WebColors.primaryGold)),
          error: (final err, final stack) => Center(
            child: Text('Hata: $err',
                style: const TextStyle(color: WebColors.whiteText)),
          ),
          data: (final user) => ListView(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxxl, vertical: 56),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildDesktopHeaderTexts(),
                          const SizedBox(height: AppSpacing.xxl),
                          const CustomArtWordsCard(
                            word: 'Gelecek, güzelliğe inananlarındır.',
                            author: 'Eleanor Roosevelt',
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          _buildDesktopAvatarSection(),
                          const SizedBox(height: AppSpacing.xxxl),
                          _buildDesktopSectionTitle('Kişisel Bilgiler'),
                          Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  textField: true,
                                  label: 'Ad, zorunlu alan',
                                  child: CustomTextField(
                                    controller: _firstNameController,
                                    label: 'Ad',
                                    isRequired: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Semantics(
                                  textField: true,
                                  label: 'Soyad, zorunlu alan',
                                  child: CustomTextField(
                                    controller: _lastNameController,
                                    label: 'Soyad',
                                    isRequired: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Semantics(
                            textField: true,
                            label: 'E-Posta Adresi',
                            child: CustomTextField(
                              controller: _emailController,
                              label: 'E-Posta Adresi',
                              isRequired: false,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Semantics(
                            textField: true,
                            label: 'Telefon Numarası',
                            child: CustomTextField(
                              controller: _phoneController,
                              label: 'Telefon Numarası',
                              isRequired: false,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Semantics(
                            textField: true,
                            label: 'Yaşadığın Şehir',
                            child: CustomTextField(
                              controller: _cityController,
                              label: 'Yaşadığın Şehir',
                              isRequired: false,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.huge),
                          _buildDesktopSaveButton(),
                          const SizedBox(height: AppSpacing.huge),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Footer(),
            ],
          ),
        ),
      );

  Widget _buildDesktopHeaderTexts() => Column(
        children: [
          const Text(
            'Profilini Düzenle',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 26,
              color: WebColors.whiteText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ad, fotoğraf, şehir ve iletişim bilgilerini güncelle.',
            style: TextStyle(
              color: WebColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      );

  Widget _buildDesktopAvatarSection() => Center(
        child: Stack(
          children: [
            Semantics(
              image: true,
              label: 'Profil fotoğrafı',
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                      BorderSide(color: WebColors.primaryGold, width: 2)),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: WebColors.darkBlueAccent,
                  backgroundImage: _selectedImageFile != null
                      ? FileImage(_selectedImageFile!) as ImageProvider
                      : NetworkImage(_profileImageUrl),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Semantics(
                button: true,
                label: 'Profil fotoğrafını değiştir',
                child: Material(
                  color: WebColors.primaryGold,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.asymSm,
                  ),
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: AppRadius.asymSm,
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Icon(Icons.camera_alt_rounded,
                          color: WebColors.whiteText, size: 20),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      );

  Widget _buildDesktopSectionTitle(final String title) => Padding(
        padding:
            const EdgeInsets.only(bottom: AppSpacing.lg, top: AppSpacing.sm),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: WebColors.primaryGoldLight,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );

  Widget _buildDesktopSaveButton() {
    final isLoading = ref.watch(userMutationProvider).isLoading;
    return Semantics(
      button: true,
      label: 'Kaydet, profil bilgilerini güncelle',
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.asymSm,
            ),
            elevation: 0,
            backgroundColor: WebColors.primaryGold,
            foregroundColor: WebColors.whiteText,
          ),
          onPressed: isLoading ? null : () => _updateProfile(),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: WebColors.whiteText),
                )
              : const Text('Kaydet',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
