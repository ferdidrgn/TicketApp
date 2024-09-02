import 'package:flutter/material.dart';
import 'package:ticketapp/util/custom_views/custom_text_field.dart';
import 'package:ticketapp/util/custom_views/custom_button.dart';

class UserProfileEditScreen extends StatefulWidget {
  const UserProfileEditScreen({super.key});

  @override
  _UserProfileEditScreenState createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<UserProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  String _firstName = '';
  String _lastName = '';
  String _phoneNumber = '';
  String _email = '';
  int _age = 0;
  String _location = '';
  String _profileImageUrl = 'https://via.placeholder.com/150';

  void _updateProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      // Profil güncelleme işlemleri
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil güncellendi')),
      );
    }
  }

  void _handleProfileImageChange() {
    // Profil fotoğrafı değiştirme işlemleri
  }

  void _handleProfileImageDelete() {
    setState(() {
      _profileImageUrl = 'https://via.placeholder.com/150';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Düzenle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileImage(),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        label: 'Ad',
                        initialValue: _firstName,
                        onChanged: (value) {
                          setState(() => _firstName = value);
                        },
                      ),
                      CustomTextField(
                        label: 'Soyad',
                        initialValue: _lastName,
                        onChanged: (value) {
                          setState(() => _lastName = value);
                        },
                      ),
                      CustomTextField(
                        label: 'Telefon No',
                        initialValue: _phoneNumber,
                        onChanged: (value) {
                          setState(() => _phoneNumber = value);
                        },
                        keyboardType: TextInputType.phone,
                      ),
                      CustomTextField(
                        label: 'E-posta',
                        initialValue: _email,
                        isRequired: false,
                        onChanged: (value) {
                          setState(() => _email = value);
                        },
                        keyboardType: TextInputType.emailAddress,
                      ),
                      CustomTextField(
                        label: 'Yaş',
                        initialValue: _age.toString(),
                        onChanged: (value) {
                          setState(() => _age = int.tryParse(value) ?? 0);
                        },
                        keyboardType: TextInputType.number,
                      ),
                      CustomTextField(
                        label: 'Lokasyon',
                        initialValue: _location,
                        isRequired: false,
                        onChanged: (value) {
                          setState(() => _location = value);
                        },
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
}
