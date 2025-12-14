import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/util/role_manager.dart';
import '../../../../shared/widgets/custom_art_words_card.dart';
import '../../../../shared/widgets/custom_elevated_button.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../domain/entities/user.dart';
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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();

  String _profileImageUrl = 'https://via.placeholder.com/150';
  bool _isUpdating = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
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

  void _initializeFormData(final User user) {
    if (!_isInitialized) {
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
    }
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isUpdating = true);

    try {
      final currentUser = ref.read(userProvider).dataSingle;
      final now = DateTime.now().toIso8601String();

      User userToSave;

      if (currentUser == null) {
        // İlk kez kayıt olacak kullanıcı
        userToSave = User(
          id: widget.userId,
          createdAt: now,
          updatedAt: now,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          eMail: _emailController.text.trim(),
          age: int.tryParse(_ageController.text.trim()) ?? 0,
          city: _cityController.text.trim(),
          imageUrl: _profileImageUrl,
          isPhoneActive: false,
          fcmToken: '',
          role: 'users',
          favoriteShows: [],
          favoriteStages: [],
          favoritePlayers: [],
          ticketsId: [],
        );
      } else {
        // Mevcut kullanıcıyı güncelle
        if (!currentUser.role.canEditProfile)
          throw Exception('Profil düzenleme yetkiniz yok');

        userToSave = currentUser.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          eMail: _emailController.text.trim(),
          age: int.tryParse(_ageController.text.trim()) ?? currentUser.age,
          city: _cityController.text.trim(),
          imageUrl: _profileImageUrl,
          updatedAt: now,
        );
      }

      await ref.read(userProvider.notifier).saveUser(
          userToSave, _profileImageUrl,
          isUpdate: currentUser != null);

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted)
        _showSnackBar('Güncelleme sırasında hata: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showSnackBar(final String message, {final bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (final context) {
        // Animasyonları önceden yükle
        precacheImage(const AssetImage("assets/images/confetti.png"), context);

        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.all(20),
            child: CustomSuccessDialog(
              message: 'İşlem başarıyla tamamlandı!',
              onConfirm: () {
                // Dialog context'ini kullanmak yerine, root context kullan
                Navigator.of(context).pop(); // Dialog'u kapat

                // Global key veya root navigator kullan
                Navigator.of(context, rootNavigator: true)
                    .pushNamedAndRemoveUntil(
                  '/home',
                  (final route) => false,
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(final BuildContext context) {
    final userState = ref.watch(userProvider);
    final currentUser = userState.dataSingle;

    // Formu başlat
    if (currentUser != null)
      _initializeFormData(currentUser);
    else if (!_isInitialized) {
      _initializeFormData(User(
        id: widget.userId,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        firstName: '',
        lastName: '',
        imageUrl: _profileImageUrl,
        phoneNumber: '',
        age: 0,
        eMail: '',
        city: '',
        isPhoneActive: false,
        fcmToken: '',
        role: 'users',
        favoriteShows: [],
        favoriteStages: [],
        favoritePlayers: [],
        ticketsId: [],
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Bilgilerini Düzenle'),
        actions: [
          if (currentUser != null) _buildRoleBadge(currentUser.role),
        ],
      ),
      body: userState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContentState(context, currentUser),
    );
  }

  Widget _buildRoleBadge(final String role) {
    final color = _getRoleColor(role);
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(role.roleIcon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                role.displayName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(final String role) {
    if (RoleManager.isAdmin(role)) return Colors.red;
    if (RoleManager.isPremium(role)) return Colors.amber;
    if (RoleManager.isUser(role)) return Colors.green;
    return Colors.grey;
  }

  Widget _buildContentState(final BuildContext context, final User? user) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomArtWordsCard(
                word: 'Sanat Sanat İçin midir',
                author: 'Pablo Picasso',
              ),
              const SizedBox(height: 24),
              _buildProfileImage(),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _firstNameController,
                label: 'Ad',
                isRequired: true,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              CustomTextField(
                controller: _lastNameController,
                label: 'Soyad',
                isRequired: true,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              CustomTextField(
                controller: _phoneController,
                label: 'Telefon No',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: '+90 555 555 55 55',
                isRequired: false,
              ),
              CustomTextField(
                controller: _emailController,
                label: 'E-posta',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                hintText: 'ornek@email.com',
                isRequired: false,
              ),
              CustomTextField(
                controller: _ageController,
                label: 'Yaş',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.cake_outlined),
                isRequired: false,
              ),
              CustomTextField(
                controller: _cityController,
                label: 'Şehir',
                prefixIcon: const Icon(Icons.location_city_outlined),
                hintText: 'İstanbul',
                isRequired: false,
              ),
              const SizedBox(height: 32),
              Center(
                child: _isUpdating
                    ? const CircularProgressIndicator()
                    : CustomElevatedButton(
                        text:
                            user == null ? 'Kaydı Tamamla' : 'Profili Güncelle',
                        onPressed: _updateProfile,
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );

  Widget _buildProfileImage() => Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: NetworkImage(_profileImageUrl),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _handleProfileImageChange,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            if (_profileImageUrl != 'https://via.placeholder.com/150')
              Positioned(
                bottom: 0,
                left: 0,
                child: GestureDetector(
                  onTap: _handleProfileImageDelete,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
          ],
        ),
      );

  void _handleProfileImageChange() =>
      _showSnackBar('Fotoğraf seçme özelliği yakında eklenecek...');

  void _handleProfileImageDelete() => showDialog(
        context: context,
        builder: (final context) => AlertDialog(
          title: const Text('Profil Fotoğrafını Kaldır'),
          content: const Text(
              'Profil fotoğrafınızı kaldırmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                setState(
                    () => _profileImageUrl = 'https://via.placeholder.com/150');
                Navigator.pop(context);
                _showSnackBar('Profil fotoğrafı kaldırıldı');
              },
              child: const Text('Kaldır', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
}
