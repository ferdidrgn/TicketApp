import 'package:flutter/material.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';
import '../../../../../../core/theme/app_theme.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({super.key});

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 40),
          CustomSectionTitle(
              title: 'İletişim', textColor: Colors.amber, fontSize: 50),
          SizedBox(height: 40),
          LayoutBuilder(
            builder: (final context, final constraints) {
              final bool isWide = constraints.maxWidth > 800;
              return isWide
                  ? _buildContactWideLayout()
                  : _buildContactNarrowLayout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildContactForm()),
        SizedBox(width: 40),
        Expanded(child: _buildContactInfo()),
      ],
    );
  }

  Widget _buildContactNarrowLayout() {
    return Column(
      children: [
        _buildContactForm(),
        SizedBox(height: 40),
        _buildContactInfo(),
      ],
    );
  }

  Widget _buildContactForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppWebLightColors.primaryGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bize Ulaşın (!HENÜZ AKTİF DEĞİLDİR!)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppWebLightColors.primaryGold,
            ),
          ),
          SizedBox(height: 20),
          _buildFormField('Adınız Soyadınız'),
          _buildFormField('E-posta Adresiniz'),
          _buildFormField('Konu'),
          _buildFormField('Mesajınız', maxLines: 4),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              SnackBar(
                content: Text('Mesajınız başarıyla gönderildi!'),
                backgroundColor: AppWebLightColors.primaryGold,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppWebLightColors.primaryGold,
              foregroundColor: AppWebLightColors.darkBlueBackground,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'GÖNDER',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(final String label, {final int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppWebLightColors.primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          TextField(
            maxLines: maxLines,
            style: TextStyle(color: AppWebLightColors.whiteText),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: AppWebLightColors.primaryGold.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: AppWebLightColors.primaryGold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final contacts = [
      {
        'icon': '📍',
        'title': 'Adres',
        'info':
            '---------\ ----- Caddesi No: ---\nAtaşehir/İSTANBUL'
      },
      {'icon': '📞', 'title': 'Telefon', 'info': '+90 -----'},
      {'icon': '✉️', 'title': 'E-posta', 'info': '----@-----'},
      {'icon': '🎫', 'title': 'Bilet Rezervasyon', 'info': '----@----\n+90 ------'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İletişim Bilgileri',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppWebLightColors.primaryGold,
          ),
        ),
        SizedBox(height: 20),
        ...contacts.map((final contact) => Container(
              margin: EdgeInsets.only(bottom: 15),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppWebLightColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                      color: AppWebLightColors.primaryGold, width: 5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['icon']!,
                    style: TextStyle(fontSize: 20, color: Colors.amber),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact['title']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppWebLightColors.whiteText,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          contact['info']!,
                          style: TextStyle(
                            color: AppWebLightColors.whiteText.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
