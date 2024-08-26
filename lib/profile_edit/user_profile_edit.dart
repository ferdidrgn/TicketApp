import 'package:flutter/material.dart';

class UserProfileEditScreen extends StatefulWidget {
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
                      _buildTextField('Ad', _firstName, (value) {
                        setState(() => _firstName = value);
                      }),
                      _buildTextField('Soyad', _lastName, (value) {
                        setState(() => _lastName = value);
                      }),
                      _buildTextField('Telefon No', _phoneNumber, (value) {
                        setState(() => _phoneNumber = value);
                      }, keyboardType: TextInputType.phone),
                      _buildTextField('E-posta', _email, (value) {
                        setState(() => _email = value);
                      }, keyboardType: TextInputType.emailAddress),
                      _buildTextField('Yaş', _age.toString(), (value) {
                        setState(() => _age = int.tryParse(value) ?? 0);
                      }, keyboardType: TextInputType.number),
                      _buildTextField('Lokasyon', _location, (value) {
                        setState(() => _location = value);
                      }),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          child: const Text('Güncelle'),
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
            child: GestureDetector(
              onTap: _handleProfileImageChange,
              child: Container(
                alignment: Alignment.bottomRight,
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            right: -10,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _handleProfileImageDelete,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, String initialValue, ValueChanged<String> onChanged,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Bu alan boş olamaz';
          }
          return null;
        },
      ),
    );
  }
}