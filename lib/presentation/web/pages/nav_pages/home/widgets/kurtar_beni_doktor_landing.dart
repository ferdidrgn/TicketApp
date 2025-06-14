import 'package:flutter/material.dart';

class KurtarBeniDoktorLanding extends StatelessWidget {
  const KurtarBeniDoktorLanding({super.key});

  @override
  Widget build(final BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return LayoutBuilder(
      builder: (final context, final constraints) {
        final width = constraints.maxWidth;
        final height = width / (isMobile ? 0.7 : 1.8);

        return SizedBox(
          height: height,
          child: isMobile
              ? Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FkurtarBeniDoktor%2F21903122132.png?alt=media&token=21913d43-e257-45fb-8d2e-4d1065b0be8b',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 32,
                            left: 20,
                            child: Text(
                              'KURTAR BENİ DOKTOR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            left: 20,
                            child: Text(
                              'KADIKÖY\n(İSTANBUL)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: _RightMenu(fontSize: 14, headerSize: 16),
                    )
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: width * 0.04,
                      color: Colors.grey.shade100,
                      alignment: Alignment.center,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'PRÖMİYERİMİZ\n“Yalnızlık bazen en iyi doktordur; insan kendini o zaman daha iyi tanır.”',
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
      },
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
                  'Yönetmen Yardımcı\nUĞUR KILIÇ-EBRU AKGÜN\n\nMakyaj\nDİALRA SEKMEN\n\nKostüm\nDERYA DİNÇER\n\n Işık\nSEYİT ÇOLAK\n\nAsistan\nDUYGU ŞAHİN'),
              const Divider(height: 30),
              Text(
                'Oyuncular\n\nADEM SOY\nNEVZAT KAYAOKAY\nGÜRKAN CANDAN\nZEYNEP ÜĞÜDÜR\nSİTEM ARSLAN GENÇ\n...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
