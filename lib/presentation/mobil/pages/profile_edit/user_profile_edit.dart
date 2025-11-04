import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/widgets/custom_elevated_button.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../core/widgets/custom_art_words_card.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../data/providers/user/user_provider.dart';
import '../../../../domain/entities/user.dart';

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

  String _firstName = '';
  String _lastName = '';
  String _phoneNumber = '';
  String _email = '';
  int _age = 0;
  String _city = '';
  String _profileImageUrl = 'https://via.placeholder.com/150';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Kullanıcı verilerini yükle
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

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad ve soyad alanları zorunludur')));
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final userState = ref.read(userProvider);
      final currentUser = userState.dataSingle;

      final nowTime = DateFormatter.nowFormatDateTime();
      final updatedUser = User(
        id: widget.userId,
        createdAt: currentUser?.createdAt ?? nowTime,
        updatedAt: nowTime,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        eMail: _emailController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        city: _cityController.text.trim(),
        imageUrl: _profileImageUrl,
        ticketsId: currentUser?.ticketsId ?? [],
        favoritePlayers: currentUser?.favoritePlayers ?? [],
        favoriteShows: currentUser?.favoriteShows ?? [],
        favoriteStages: currentUser?.favoriteStages ?? [],
        fcmToken: currentUser?.fcmToken ?? '',
        isPhoneActive: currentUser?.isPhoneActive ?? false,
        role: currentUser?.role ?? 'user',
      );

      await ref
          .read(userProvider.notifier)
          .saveUser(updatedUser, _profileImageUrl, isUpdate: true);

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme sırasında hata: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Başarılı'),
            ],
          ),
          content: const Text('Profil bilgileriniz başarıyla güncellendi.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToHome();
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _fillFormWithUserData(final User user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phoneNumber;
    _emailController.text = user.eMail;
    _ageController.text = user.age > 0 ? user.age.toString() : '';
    _cityController.text = user.city;
    _profileImageUrl = user.imageUrl.isNotEmpty
        ? user.imageUrl
        : 'https://via.placeholder.com/150';
  }

  @override
  Widget build(final BuildContext context) {
    final userState = ref.watch(userProvider);

    // Kullanıcı verileri yüklendiyse formu doldur
    if (userState.dataSingle != null && _firstNameController.text.isEmpty)
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        _fillFormWithUserData(userState.dataSingle!);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Bilgilerini Düzenle'),
      ),
      body: userState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : userState.errorMessage != null
              ? _buildErrorState(userState.errorMessage!)
              : _buildContentState(context, userState.dataSingle),
    );
  }

  Widget _buildErrorState(final String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Hata: $message'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>
                ref.read(userProvider.notifier).loadUserById(widget.userId),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentState(final BuildContext context, final User? user) {
    if (user != null)
      fillUIUserInfo(user); // UI'yi kullanıcının verileriyle doldur

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomArtWordsCard(
                word: 'Sanat Sanat İçin midir', author: 'Pablo Picasso'),
            const SizedBox(height: 20),
            _buildProfileImage(),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Ad',
              initialValue: _firstName,
              isRequired: true,
              onChanged: (final value) => setState(() => _firstName = value),
            ),
            CustomTextField(
              label: 'Soyad',
              initialValue: _lastName,
              isRequired: true,
              onChanged: (final value) => setState(() => _lastName = value),
            ),
            CustomTextField(
              label: 'Telefon No',
              initialValue: _phoneNumber,
              onChanged: (final value) => setState(() => _phoneNumber = value),
              keyboardType: TextInputType.phone,
              isRequired: false,
            ),
            CustomTextField(
              label: 'E-posta',
              initialValue: _email,
              onChanged: (final value) => setState(() => _email = value),
              keyboardType: TextInputType.emailAddress,
              isRequired: false, // E-posta zorunlu değil
            ),
            CustomTextField(
              label: 'Yaş',
              initialValue: _age > 0 ? _age.toString() : '',
              onChanged: (final value) =>
                  setState(() => _age = int.tryParse(value) ?? 0),
              keyboardType: TextInputType.number,
              isRequired: false, // Yaş zorunlu değil
            ),
            CustomTextField(
              label: 'Lokasyon',
              initialValue: _city,
              onChanged: (final value) => setState(() => _city = value),
              isRequired: false, // Lokasyon zorunlu değil
            ),
            const SizedBox(height: 20),
            Center(
              child: _isUpdating
                  ? const CircularProgressIndicator()
                  : CustomElevatedButton(
                      text: 'Profili Güncelle',
                      onPressed: _updateProfile,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(_profileImageUrl),
            child: Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: _handleProfileImageChange,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context)
                      .bottomNavigationBarTheme
                      .selectedItemColor,
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            right: -10,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _handleProfileImageDelete,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void fillUIUserInfo(final User user) {
    setState(() {
      _firstName = user.firstName;
      _lastName = user.lastName;
      _phoneNumber = user.phoneNumber;
      _email = user.eMail;
      _age = user.age.toInt();
      _city = user.city;
      _profileImageUrl = user.imageUrl;
    });
  }

  void _handleProfileImageChange() {
    // Profil fotoğrafı değiştirme işlemleri
  }

  void _handleProfileImageDelete() {
    setState(() {
      _profileImageUrl = 'https://via.placeholder.com/150';
    });
  }
}
