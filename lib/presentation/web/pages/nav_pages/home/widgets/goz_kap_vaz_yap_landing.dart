import 'package:flutter/material.dart';

class GozYapVazYapLanding extends StatelessWidget {
  const GozYapVazYapLanding({super.key});

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final context, final constraints) {
        final isMobile = constraints.maxWidth < 600;

        return isMobile
            ? _buildMobileLayout(context)
            : _buildDesktopLayout(context);
      },
    );
  }

  Widget _buildMobileLayout(final BuildContext context) {
    const imageUrl =
        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_165452.jpg?alt=media&token=1ebd1bc9-0df5-46fd-bce5-b7400d5d81ae';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Başlık bölümü
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
            child: Column(
              children: [
                Text(
                  'GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '1889 SES TİYATROSU\n(TAKSİM)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Ana görsel
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (final context, final error, final stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 50),
                  ),
                );
              },
            ),
          ),

          // İçerik bölümü
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
            child: _MobileTextSection(),
          ),

          // Alt görsel
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            width: double.infinity,
            child: Image.network(
              'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_174009.jpg?alt=media&token=40652d5a-31fe-4dec-9df1-61e516dfda27',
              fit: BoxFit.cover,
              errorBuilder: (final context, final error, final stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 50),
                  ),
                );
              },
            ),
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
      height: MediaQuery.of(context).size.height,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Image.network(
              imageLeft,
              fit: BoxFit.cover,
              height: double.infinity,
              errorBuilder: (final context, final error, final stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 100),
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
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
            child: Image.network(
              imageRight,
              fit: BoxFit.cover,
              height: double.infinity,
              errorBuilder: (final context, final error, final stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 100),
                  ),
                );
              },
            ),
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
              "Haldun Taner'in bu iki perdelik oyunu, Türkiye'nin yaklaşık 70 yıllık siyasi, ekonomik ve toplumsal durumunu birbirine zıt iki kimlik üzerinden ele alarak, toplumumuza bir ayna tutuyor.\n\nİki çocukluk arkadaşı olan baş karakterlerden Vicdani, saf, iyi niyetli, dürüst ve uysal bir kişiliğe sahipken; Efruz ise köşe dönücü, iş bitirici ve fırsatçı biridir.\n\nOyun, bu karakterler üzerinden devleti sömürenler ile devlete itaat edenler arasındaki dengesizliği gözler önüne seriyor",
            ),
            const SizedBox(height: 20),
            Divider(color: textColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'KADRO\n\n'
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

class _MobileTextSection extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OYUN HAKKINDA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Haldun Taner'in bu iki perdelik oyunu, Türkiye'nin yaklaşık 70 yıllık siyasi, ekonomik ve toplumsal durumunu birbirine zıt iki kimlik üzerinden ele alarak, toplumumuza bir ayna tutuyor.",
            style: TextStyle(height: 1.5, fontSize: 15),
          ),
          const SizedBox(height: 16),
          const Text(
            'İki çocukluk arkadaşı olan baş karakterlerden Vicdani, saf, iyi niyetli, dürüst ve uysal bir kişiliğe sahipken; Efruz ise köşe dönücü, iş bitirici ve fırsatçı biridir.',
            style: TextStyle(height: 1.5, fontSize: 15),
          ),
          const SizedBox(height: 16),
          const Text(
            'Oyun, bu karakterler üzerinden devleti sömürenler ile devlete itaat edenler arasındaki dengesizliği gözler önüne seriyor.',
            style: TextStyle(height: 1.5, fontSize: 15),
          ),
          const SizedBox(height: 24),
          const Text(
            'KADRO',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildCrewSection(),
          const SizedBox(height: 24),
          const Text(
            'OYUNCULAR',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildActorsList(),
        ],
      ),
    );
  }

  Widget _buildCrewSection() {
    final crew = [
      'Işık Tasarımı: Emre Kahraman',
      'Ses & Efekt Tasarımı: Gökhan Şener',
      'Afiş Tasarımı: Tayfun Kızıldağ',
      'Dansçı: Burcu Koçyiğit',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: crew
          .map((final item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  item,
                  style: const TextStyle(color: Colors.black54, height: 1.3),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildActorsList() {
    final actors = [
      'SELİN GÜL',
      'DENİZ KORKMAZ',
      'MERT AYDIN',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: actors
          .map((final actor) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  actor,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ))
          .toList(),
    );
  }
}
