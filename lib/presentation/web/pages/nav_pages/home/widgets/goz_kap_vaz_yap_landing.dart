import 'package:flutter/material.dart';

class GozYapVazYapLanding extends StatelessWidget {
  const GozYapVazYapLanding({super.key});

  @override
  Widget build(final BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      children: [
        LayoutBuilder(
          builder: (final context, final constraints) {
            final width = constraints.maxWidth;
            final height = width / (isMobile ? 0.8 : 2.0);

            return SizedBox(
              height: height,
              child:
              isMobile ? _buildMobileLayout(height) : _buildDesktopLayout(),
            );
          },
        ),
        const SizedBox(height: 20),
        Container(height: 20, color: Colors.white),
      ],
    );
  }

  Widget _buildMobileLayout(final double height) {
    const imageUrl =
        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_165452.jpg?alt=media&token=1ebd1bc9-0df5-46fd-bce5-b7400d5d81ae';

    return Column(
      children: [
        Image.network(imageUrl,
            fit: BoxFit.cover, width: double.infinity, height: height * 0.4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: const _TextSection(
            title: 'GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM',
            location: '1889 SES TİYATROSU\n(TAKSİM)',
            fontSize: 14,
            headerSize: 16,
            textColor: Colors.white,
          ),
        ),
        Image.network(imageUrl,
            fit: BoxFit.cover, width: double.infinity, height: height * 0.4),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    const imageLeft =
        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_165452.jpg?alt=media&token=1ebd1bc9-0df5-46fd-bce5-b7400d5d81ae';
    const imageRight =
        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_174009.jpg?alt=media&token=40652d5a-31fe-4dec-9df1-61e516dfda27';

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Image.network(imageLeft,
              fit: BoxFit.cover, height: double.infinity),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: const _TextSection(
              title: 'GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM',
              location: '1889 SES TİYATROSU\n(TAKSİM)',
              fontSize: 14,
              headerSize: 16,
              textColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Image.network(imageRight,
              fit: BoxFit.cover, height: double.infinity),
        ),
      ],
    );
  }
}

class _TextSection extends StatelessWidget {
  final String title;
  final String location;
  final double fontSize;
  final double headerSize;
  final Color textColor;

  const _TextSection({
    required this.title,
    required this.location,
    required this.fontSize,
    required this.headerSize,
    required this.textColor,
  });

  @override
  Widget build(final BuildContext context) {
    return SingleChildScrollView(
      child: DefaultTextStyle(
        style: TextStyle(fontSize: fontSize, color: textColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: headerSize + 10,
                color: textColor,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              location,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize + 4,
                color: textColor.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Yazan: Haldun Taner\nYönetmen: Efsun Kaygusuz\n\n'
                  'Haldun Taner’in bu iki perdelik oyunu, Türkiye’nin yaklaşık 70 yıllık siyasi, ekonomik ve toplumsal durumunu birbirine zıt iki kimlik üzerinden ele alarak, toplumumuza bir ayna tutuyor.\n\n'
                  'İki çocukluk arkadaşı olan baş karakterlerden Vicdani, saf, iyi niyetli, dürüst ve uysal bir kişiliğe sahipken; Efruz ise köşe dönücü, iş bitirici ve fırsatçı biridir.\n\n'
                  'Oyun, bu karakterler üzerinden devleti sömürenler ile devlete itaat edenler arasındaki dengesizliği gözler önüne seriyor',
            ),
            const SizedBox(height: 20),
            Divider(color: textColor.withOpacity(0.5)),
            const Text(
              '.\n\n'
                  'Yazar: Haldun Taner\n'
                  'Yönetmen: Efsun Kaygusuz\n'
                  'Işık Tasarımı: Emre Kahraman\n'
                  'Ses & Efekt Tasarımı: Gökhan Şener\n'
                  'Afiş Tasarımı: Tayfun Kızıldağ\n'
                  'Dansçı: Burcu Koçyiğit\n\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
