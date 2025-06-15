import 'package:flutter/material.dart';

class KurtarBeniDoktorLanding extends StatelessWidget {
  const KurtarBeniDoktorLanding({super.key});

  @override
  Widget build(final BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return isMobile
        ? _buildMobileLayout(context)
        : _buildDesktopLayout(context);
  }

  Widget _buildMobileLayout(final BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Başlık
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            color: Colors.black,
            child: Text(
              'KURTAR BENİ DOKTOR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Ana görsel bölümü
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FkurtarBeniDoktor%2F21903122132.png?alt=media&token=21913d43-e257-45fb-8d2e-4d1065b0be8b',
                    fit: BoxFit.fill,
                    errorBuilder:
                        (final context, final error, final stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 50),
                        ),
                      );
                    },
                  ),
                ),

                // Sevgili Doktor yazısı - sol tarafta
                Positioned(
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SEVGİLİ DOKTOR\n"Yalnızlık bazen en iyi doktordur;\ninsan kendini o zaman daha iyi tanır."',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'KADIKÖY\n(İSTANBUL)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // İçerik bölümü
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: _MobileRightMenu(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(final BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Container(
            width: width * 0.04,
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'PRÖMİYERİMİZ\n"Yalnızlık bazen en iyi doktordur; insan kendini o zaman daha iyi tanır."',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          // Orta görsel
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FkurtarBeniDoktor%2F21903122132.png?alt=media&token=21913d43-e257-45fb-8d2e-4d1065b0be8b',
                    fit: BoxFit.cover,
                    errorBuilder:
                        (final context, final error, final stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 100),
                        ),
                      );
                    },
                  ),
                ),
                const Positioned(
                  top: 40,
                  left: 40,
                  child: Text(
                    'KURTAR BENİ DOKTOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 30,
                  left: 30,
                  child: Text(
                    'KADIKÖY\n(İSTANBUL)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sağ Menü
          Container(
            width: width * 0.10,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: 40,
              horizontal: 12,
            ),
            child: const _RightMenu(fontSize: 14, headerSize: 16),
          )
        ],
      ),
    );
  }
}

class _RightMenu extends StatelessWidget {
  final double fontSize;
  final double headerSize;

  const _RightMenu({
    required this.fontSize,
    required this.headerSize,
  });

  @override
  Widget build(final BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height,
        child: DefaultTextStyle(
          style: TextStyle(fontSize: fontSize, color: Colors.black),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YAZAN - UYARLAYAN & YÖNETEN',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: headerSize)),
              const SizedBox(height: 4),
              const Text('ANTON ÇEHOV\n\nİSKENDER ATİLLA ATASOY'),
              const Divider(height: 30),
              Text('CAST',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: headerSize)),
              const SizedBox(height: 4),
              const Text(
                  'Yönetmen Yardımcı\nUĞUR KILIÇ-EBRU AKGÜN\n\nMakyaj\nDİALRA SEKMEN\n\nKostüm\nDERYA DİNÇER\n\nIşık\nSEYİT ÇOLAK\n\nAsistan\nDUYGU ŞAHİN'),
              const Divider(height: 30),
              Text(
                'Oyuncular',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: headerSize),
              ),
              const SizedBox(height: 8),
              const Text(
                'ADEM SOY\nNEVZAT KAYAOKAY\nGÜRKAN CANDAN\nZEYNEP ÜĞÜDÜR\nSİTEM ARSLAN GENÇ\n...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileRightMenu extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Colors.black),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YAZAN - UYARLAYAN & YÖNETEN',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ANTON ÇEHOV\n\nİSKENDER ATİLLA ATASOY',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 24),
          const Text(
            'CAST',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildCastSection('Yönetmen Yardımcı', 'UĞUR KILIÇ - EBRU AKGÜN'),
          _buildCastSection('Makyaj', 'DİALRA SEKMEN'),
          _buildCastSection('Kostüm', 'DERYA DİNÇER'),
          _buildCastSection('Işık', 'SEYİT ÇOLAK'),
          _buildCastSection('Asistan', 'DUYGU ŞAHİN'),
          const SizedBox(height: 24),
          const Text(
            'OYUNCULAR',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildActorsList(),
        ],
      ),
    );
  }

  Widget _buildCastSection(final String title, final String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActorsList() {
    final actors = [
      'ADEM SOY',
      'NEVZAT KAYAOKAY',
      'GÜRKAN CANDAN',
      'ZEYNEP ÜĞÜDÜR',
      'SİTEM ARSLAN GENÇ',
      '...',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: actors
          .map((final actor) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  actor,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ))
          .toList(),
    );
  }
}
