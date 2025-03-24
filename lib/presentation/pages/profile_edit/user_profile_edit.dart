import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/util/date_formatter.dart';
import '../../../core/widgets/custom_art_words_card.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/providers/user/user_provider.dart';
import '../../../domain/entities/user.dart';

class UserProfileEditScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileEditScreen({super.key, required this.userId});

  @override
  _UserProfileEditScreenState createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends ConsumerState<UserProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  String _firstName = '';
  String _lastName = '';
  String _phoneNumber = '';
  String _email = '';
  int _age = 0;
  String _city = '';
  String _profileImageUrl = 'https://via.placeholder.com/150';

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (ref.read(userProvider).user != null)
        ref.read(userProvider.notifier).loadUserById(widget.userId);
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final nowTime = DateFormatter.nowFormatDateTime();
      final updatedUser = User(
        id: widget.userId,
        createdAt: nowTime,
        updatedAt: nowTime,
        firstName: _firstName,
        lastName: _lastName,
        phoneNumber: _phoneNumber.isNotEmpty ? _phoneNumber : null,
        eMail: _email.isNotEmpty ? _email : null,
        age: _age > 0 ? _age : null,
        city: _city.isNotEmpty ? _city : null,
        imageUrl: _profileImageUrl,
        ticketsId: [],
        favoritePlayers: [],
        favoriteShows: [],
        favoriteStages: [],
        fcmToken: '',
        isPhoneActive: false,
        role: '',
      );

      await ref
          .read(userProvider.notifier)
          .saveUser(updatedUser, _profileImageUrl, isUpdate: true);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Düzenle'),
      ),
      body: userState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : userState.errorMessage != null
              ? _buildErrorState(userState.errorMessage!)
              : _buildContentState(context, userState.user?.toEntity()),
    );
  }

  Widget _buildErrorState(final String message) {
    return Center(child: Text(message));
  }

  Widget _buildContentState(final BuildContext context, final User? user) {
    if (user != null) {
      fillUIUserInfo(user); // UI'yi kullanıcının verileriyle doldur
    }

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
              isRequired: false, // Telefon zorunlu değil
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
              child: CustomButton(
                text: 'Güncelle',
                onPressed: _updateProfile,
                backgroundColor: Theme.of(context).primaryColor,
                textColor: Colors.white,
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
      _firstName = user.firstName ?? "";
      _lastName = user.lastName ?? "";
      _phoneNumber = user.phoneNumber ?? "";
      _email = user.eMail ?? "";
      _age = user.age?.toInt() ?? 0;
      _city = user.city ?? "";
      _profileImageUrl = user.imageUrl ?? 'https://via.placeholder.com/150';
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
