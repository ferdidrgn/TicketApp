import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../auth/presentation/providers/storage_service.dart';
import '../../../settings/presentation/widgets/preference_widgets.dart';
import '../../domain/entities/user.dart';
import '../providers/user_mutation_provider.dart';
import '../providers/user_provider.dart';

/// PROFİLİ DÜZENLE — sade bir form; tek birincil aksiyon: "Kaydet".
///
/// - Mobil (<768): tek sütun; fotoğraf satırı → kişisel bilgiler →
///   iletişim → tam genişlikte Kaydet (formun sonunda, başparmak bölgesi).
/// - Tablet (768–1023): aynı akış, ~560px sütunda ortalı.
/// - Masaüstü (≥1024): kendi Scaffold'u; solda fotoğraf paneli, sağda form,
///   Kaydet formun sağ altında. Altta Footer.
///
/// Veri akışı aynı: `userProfileProvider` → controller'lar →
/// (varsa) Storage'a fotoğraf yükleme → `userMutationProvider.save`.
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

  // 🔥 DÜZELTME: Varsayılan önceden 'https://via.placeholder.com/150'
  // idi ve fotoğrafı OLMAYAN bir kullanıcı adını değiştirip kaydettiğinde
  // bu dış yer tutucu adres Firestore'daki `imageUrl` alanına yazılıyordu
  // (servis artık yanıt vermiyor → kırık avatar). Artık boş kalır; boşsa
  // baş harfler gösterilir.
  String _profileImageUrl = '';
  bool _isInitialized = false;
  bool _isUploadingImage = false;

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
    _profileImageUrl = user.imageUrl;

    _isInitialized = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(final BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    userAsync.whenData((final user) {
      if (user != null && !_isInitialized) _fillFields(user);
    });

    if (context.isDesktop) return _buildDesktopPage(context, userAsync);

    final bool tablet = context.isTablet;
    final double gutter = tablet ? AppSpacing.xxxl : AppSpacing.lg;

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      // İskelet/hata/giriş durumlarını sayfa kendisi çiziyor; kaydetme
      // durumu Kaydet butonunda görünür.
      isLoading: false,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
        safeAreaTop: true,
      ),
      child: SingleChildScrollView(
        padding:
            EdgeInsets.fromLTRB(gutter, AppSpacing.sm, gutter, AppSpacing.huge),
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading(),
                const SizedBox(height: AppSpacing.xxxl),
                ..._stateOr(
                  userAsync,
                  (final user) => [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _photoRow(user),
                          const SizedBox(height: AppSpacing.xxxl),
                          ..._formFields(user),
                          const SizedBox(height: AppSpacing.xxxl),
                          _buildSaveButton(expand: true),
                        ],
                      ),
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: AppSpacing.section),
                      const Footer(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading({final VoidCallback? onBack}) => PreferencePageHeading(
        title: 'Profili düzenle',
        lede: 'Adını, fotoğrafını, şehrini ve telefonunu güncel tut.',
        onBack: onBack,
      );

  /// Yükleniyor → iskelet, hata → neden + tekrar dene, oturum yok →
  /// giriş daveti; veri varsa [builder].
  List<Widget> _stateOr(final AsyncValue<User?> async,
          final List<Widget> Function(User user) builder) =>
      async.when(
        loading: () => const [_EditSkeleton()],
        error: (final err, final stack) => [
          Align(
            alignment: Alignment.centerLeft,
            child: TicketNotice(
              label: 'BAĞLANTI',
              title: 'Bilgilerin yüklenemedi',
              message: 'Profil bilgilerine ulaşamadık. İnternet bağlantını '
                  'kontrol edip tekrar dene.',
              actionLabel: 'Tekrar dene',
              actionIcon: Icons.refresh_rounded,
              onAction: () => ref.invalidate(userProfileProvider),
            ),
          ),
        ],
        data: (final user) {
          if (user == null) {
            return [
              Align(
                alignment: Alignment.centerLeft,
                child: TicketNotice(
                  label: 'OTURUM',
                  title: 'Önce giriş yap',
                  message: 'Profilini düzenlemek için hesabına giriş '
                      'yapman gerekiyor.',
                  actionLabel: 'Giriş yap',
                  actionIcon: Icons.login_rounded,
                  onAction: () => NavigationHandler.goToLogin(context),
                ),
              ),
            ];
          }
          return builder(user);
        },
      );

  // ─────────────────────────────────────────────────────────────────────
  // Parçalar
  // ─────────────────────────────────────────────────────────────────────

  String _displayName(final User user) {
    final String typed =
        '${_firstNameController.text} ${_lastNameController.text}'.trim();
    return typed.isNotEmpty
        ? typed
        : '${user.firstName} ${user.lastName}'.trim();
  }

  Widget _avatar(final User user, final double size) {
    final ColorScheme cs = context.colors;
    final ImageProvider? image = _selectedImageFile != null
        ? FileImage(_selectedImageFile!) as ImageProvider
        : (_profileImageUrl.startsWith('http')
            ? NetworkImage(_profileImageUrl)
            : null);
    final String initials = _displayName(user)
        .split(RegExp(r'\s+'))
        .where((final p) => p.isNotEmpty)
        .take(2)
        .map((final p) {
      final String c = p.substring(0, 1);
      return c == 'i' ? 'İ' : c.toUpperCase();
    }).join();

    return Semantics(
      image: true,
      label: 'Profil fotoğrafı',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cs.outlineVariant, width: 1.5),
        ),
        child: CircleAvatar(
          radius: size / 2,
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
          backgroundImage: image,
          onBackgroundImageError:
              image == null ? null : (final _, final __) {},
          child: image != null
              ? null
              : (initials.isEmpty
                  ? Icon(Icons.person_rounded, size: size * 0.45)
                  : Text(
                      initials,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: size * 0.36,
                        fontWeight: FontWeight.w800,
                      ),
                    )),
        ),
      ),
    );
  }

  /// Fotoğraf değiştirme: Storage yüklemesi `File` ile çalışıyor (web'de
  /// desteklenmiyor) — web'de buton yerine dürüst bir not gösterilir.
  Widget _photoAction() {
    if (kIsWeb) {
      return Text(
        'Fotoğrafını mobil uygulamadan değiştirebilirsin.',
        style: TextStyle(
          color: context.colors.onSurfaceVariant,
          fontSize: 13,
          height: 1.4,
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: _isUploadingImage ? null : _pickImage,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      icon: const Icon(Icons.photo_camera_outlined, size: 18),
      label: Text(_selectedImageFile == null
          ? 'Fotoğrafı değiştir'
          : 'Başka bir fotoğraf seç'),
    );
  }

  Widget _photoRow(final User user) => Row(
        children: [
          _avatar(user, 88),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedImageFile != null) ...[
                  Text(
                    'Yeni fotoğraf kaydedince yüklenecek.',
                    style: TextStyle(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _photoAction(),
              ],
            ),
          ),
        ],
      );

  /// Masaüstü sol paneli: büyük fotoğraf + ad + fotoğraf aksiyonu.
  Widget _photoPanel(final User user) => Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Column(
          children: [
            _avatar(user, 128),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _displayName(user).isEmpty ? 'TiyatRol üyesi' : _displayName(user),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                color: context.colors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _photoAction(),
          ],
        ),
      );

  List<Widget> _formFields(final User user) => [
        const PreferenceSectionTitle('Kişisel bilgiler'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
        Semantics(
          textField: true,
          label: 'Yaşadığın şehir',
          child: CustomTextField(
            controller: _cityController,
            label: 'Yaşadığın şehir',
            isRequired: false,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const PreferenceSectionTitle('İletişim'),
        Semantics(
          textField: true,
          label: 'Telefon numarası',
          child: CustomTextField(
            controller: _phoneController,
            label: 'Telefon numarası',
            isRequired: false,
            keyboardType: TextInputType.phone,
          ),
        ),
        if (user.eMail.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _ReadOnlyField(
            label: 'E-posta',
            value: user.eMail.trim(),
            note: 'Giriş hesabına bağlı; buradan değiştirilemez.',
          ),
        ],
      ];

  Widget _buildSaveButton({required final bool expand}) {
    final bool busy =
        ref.watch(userMutationProvider).isLoading || _isUploadingImage;
    final ColorScheme cs = context.colors;
    return Semantics(
      button: true,
      label: 'Kaydet, profil bilgilerini güncelle',
      excludeSemantics: true,
      child: SizedBox(
        width: expand ? double.infinity : 240,
        height: 52,
        child: FilledButton(
          onPressed: busy ? null : _updateProfile,
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            disabledBackgroundColor: cs.primary.withOpacity(0.55),
            disabledForegroundColor: cs.onPrimary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
          child: busy
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.onPrimary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(_isUploadingImage
                        ? 'Fotoğraf yükleniyor…'
                        : 'Kaydediliyor…'),
                  ],
                )
              : const Text(
                  'Kaydet',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.lightImpact();

    final currentUser = ref.read(userProfileProvider).value;
    if (currentUser == null) return;

    // 🔥 DÜZELTME: Burada `_selectedImageFile?.path` (cihazdaki YEREL dosya
    // yolu) doğrudan `.save()`e "downloadUrl" olarak veriliyordu —
    // user_mutation_provider.dart/save_user_use_case_impl.dart/
    // user_repository_impl.dart zincirinin HİÇBİRİ Storage'a yükleme
    // yapmıyor, parametreyi olduğu gibi Firestore'un `imageUrl` alanına
    // yazıyor (bkz. user_remote_data_source_and_impl.dart). Sonuç: yeni
    // bir profil fotoğrafı seçip kaydedince Firestore'a cihaza özel,
    // dışarıdan asla erişilemeyen bir yol yazılıyordu — avatar başka
    // cihazda/oturumda, hatta aynı cihazda uygulama yeniden başlatılınca
    // bile kırık görünüyordu. Gerçek yükleme fonksiyonu
    // (`storageServiceProvider.uploadProfileImage`) zaten vardı ama hiçbir
    // yerden çağrılmıyordu — artık burada gerçekten kullanılıyor.
    String photoUrl = _profileImageUrl;
    if (_selectedImageFile != null) {
      setState(() => _isUploadingImage = true);
      try {
        final uploadedUrl = await ref
            .read(storageServiceProvider)
            .uploadProfileImage(currentUser.id, _selectedImageFile!);
        if (uploadedUrl != null && uploadedUrl.isNotEmpty)
          photoUrl = uploadedUrl;
      } catch (e) {
        if (mounted) {
          setState(() => _isUploadingImage = false);
          _showSnackBar(e.toString(), isError: true);
        }
        return;
      }
      if (mounted) setState(() => _isUploadingImage = false);
    }

    // 1. Yeni veriyi hazırla (e-posta giriş hesabına bağlı — formda salt
    // okunur, burada da değiştirilmiyor).
    final updatedUser = currentUser.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      city: _cityController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    // 2. ⚡ TEK SATIRDA GÜNCELLEME:
    // Bu metod Firestore'u ve LocalStorage'ı senkronize eder — Storage
    // yüklemesi artık yukarıda AYRI/açıkça yapılıyor, gerçek download
    // URL'i buraya veriliyor.
    await ref.read(userMutationProvider.notifier).save(
          updatedUser,
          photoUrl,
          isUpdate: true,
        );

    // 3. Sonuç Kontrolü
    final state = ref.read(userMutationProvider);
    if (!state.hasError && mounted) {
      _showSuccessDialog();
      setState(() {
        _selectedImageFile = null;
        _profileImageUrl = photoUrl;
      });
    } else if (state.hasError)
      _showSnackBar(state.error.toString(), isError: true);
  }

  void _showSuccessDialog() => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final dialogContext) => CustomSuccessDialog(
          message: 'Profilin güncellendi.',
          // Diyalog kendini kapatır; ikinci bir pop düzenleme sayfasını da
          // kapatıyordu. Kullanıcı sayfada kalır.
          onConfirm: null,
        ),
      );

  void _showSnackBar(final String message, {final bool isError = false}) {
    if (!mounted) return;
    final ColorScheme cs = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError ? TextStyle(color: cs.onError) : null,
        ),
        backgroundColor: isError ? cs.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Masaüstü / web
  // ─────────────────────────────────────────────────────────────────────

  // Aynı _formKey, aynı controller'lar, aynı _updateProfile akışı; rota
  // kabuğun dışında olduğu için Material atası olarak kendi Scaffold'u
  // (önceden yoktu — TextField'lar "No Material widget found" ile
  // çöküyordu).
  Widget _buildDesktopPage(
    final BuildContext context,
    final AsyncValue<User?> userAsync,
  ) =>
      Scaffold(
        backgroundColor: context.colors.surface,
        body: SafeArea(
          child: ListView(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xxxl,
                        AppSpacing.xxxl, AppSpacing.xxxl, AppSpacing.section),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _heading(
                            onBack: () =>
                                NavigationHandler.smartGoBack(context)),
                        const SizedBox(height: AppSpacing.section),
                        ..._stateOr(
                          userAsync,
                          (final user) => [
                            Form(
                              key: _formKey,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 300,
                                    child: _photoPanel(user),
                                  ),
                                  const SizedBox(width: AppSpacing.section),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ..._formFields(user),
                                        const SizedBox(
                                            height: AppSpacing.xxxl),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: _buildSaveButton(
                                              expand: false),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Footer(),
            ],
          ),
        ),
      );
}

/// Değiştirilemeyen bilgi (giriş hesabına bağlı e-posta).
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final String note;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.note,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = context.colors;
    return Semantics(
      label: '$label: $value. $note',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 2),
                  SelectableText(
                    value,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(note,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditSkeleton extends StatelessWidget {
  const _EditSkeleton();

  @override
  Widget build(final BuildContext context) => const ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ShimmerLoading(width: 94, height: 94, isCircular: true),
                SizedBox(width: AppSpacing.xl),
                ShimmerLoading(width: 170, height: 48, borderRadius: AppRadius.sm),
              ],
            ),
            SizedBox(height: AppSpacing.xxxl),
            ShimmerLoading(width: 180, height: 24, borderRadius: AppRadius.xs),
            SizedBox(height: AppSpacing.lg),
            ShimmerLoading(
                width: double.infinity, height: 56, borderRadius: AppRadius.sm),
            SizedBox(height: AppSpacing.lg),
            ShimmerLoading(
                width: double.infinity, height: 56, borderRadius: AppRadius.sm),
            SizedBox(height: AppSpacing.lg),
            ShimmerLoading(
                width: double.infinity, height: 56, borderRadius: AppRadius.sm),
          ],
        ),
      );
}
