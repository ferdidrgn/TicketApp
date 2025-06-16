import 'package:flutter/material.dart';

class GozYapVazYapLanding extends StatelessWidget {
  const GozYapVazYapLanding({super.key});

  @override
  Widget build(final BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) // Mobil görünüm
      return _buildMobileLayout(context);
    else if (screenWidth < 1024) // Tablet görünüm
      return _buildTabletLayout(context);
    else // Masaüstü görünüm
      return _buildDesktopLayout(context);
  }

  Widget _buildMobileLayout(final BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.5;
    const imageTop =
        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_165452.jpg?alt=media&token=1ebd1bc9-0df5-46fd-bce5-b7400d5d81ae';
    const imageBottom =
        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_174009.jpg?alt=media&token=40652d5a-31fe-4dec-9df1-61e516dfda27';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(imageTop,
              fit: BoxFit.cover, width: double.infinity, height: height * 0.6),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade800,
                  Colors.indigo.shade900,
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: const _TextSection(
              title: 'GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM',
              location: '1889 SES TİYATROSU\n(TAKSİM)',
              fontSize: 14,
              headerSize: 20,
              textColor: Colors.white,
            ),
          ),
          Image.network(imageBottom,
              fit: BoxFit.cover, width: double.infinity, height: height * 0.6),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(final BuildContext context) {
    const imageLeft =
        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_165452.jpg?alt=media&token=1ebd1bc9-0df5-46fd-bce5-b7400d5d81ae';
    const imageRight =
        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_174009.jpg?alt=media&token=40652d5a-31fe-4dec-9df1-61e516dfda27';

    return SizedBox(
      height: 600,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Image.network(imageLeft,
                fit: BoxFit.cover, height: double.infinity),
          ),
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade800,
                    Colors.indigo.shade900,
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: const _TextSection(
                title: 'GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM',
                location: '1889 SES TİYATROSU\n(TAKSİM)',
                fontSize: 16,
                headerSize: 22,
                textColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Image.network(imageRight,
                fit: BoxFit.cover, height: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(final BuildContext context) {
    const imageLeft =
        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_165452.jpg?alt=media&token=1ebd1bc9-0df5-46fd-bce5-b7400d5d81ae';
    const imageRight =
        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_174009.jpg?alt=media&token=40652d5a-31fe-4dec-9df1-61e516dfda27';

    return SizedBox(
      height: 700,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Image.network(imageLeft,
                fit: BoxFit.cover, height: double.infinity),
          ),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade800,
                    Colors.indigo.shade900,
                  ],
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 48.0, vertical: 60),
              child: const _TextSection(
                title: 'GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM',
                location: '1889 SES TİYATROSU\n(TAKSİM)',
                fontSize: 18,
                headerSize: 26,
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
      ),
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
                fontSize: headerSize,
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
