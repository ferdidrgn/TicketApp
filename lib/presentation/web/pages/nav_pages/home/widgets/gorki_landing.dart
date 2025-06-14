import 'package:flutter/material.dart';

class GorkiLanding extends StatelessWidget {
  const GorkiLanding({super.key});

  @override
  Widget build(final BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Örnek görsel en-boy oranı: 4:3 (genişlik:yukseklik)
    // Görsel URL'nin gerçek oranını biliyorsan ona göre değiştir.
    const imageAspectRatio = 4 / 3;

    // Genişliği al, yüksekliği orana göre hesapla
    final desiredWidth = screenWidth * 0.6; // Genişliğin %60'ını kullanalım
    final desiredHeight = desiredWidth / imageAspectRatio;

    return SizedBox(
      height: desiredHeight,
      child: Row(
        children: [
          // Sol Yatay Yazı
          Container(
            width: 50,
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'ALL PLAYS WITH\nENGLISH SUBTITLES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // Orta Alan (Görsel + Metin)
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRtW6qeVqO0J_THuQUhkwC5HedVCi1dPlqy4g&s',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 40,
                  child: Text(
                    'GORKI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 30,
                  child: Text(
                    'BÜHNENSCHIMPF\n(ÜBERE ICH ES NICHT)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sağ Menü
          Container(
            width: 160,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SPIELPLAN',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('Zur Programmübersicht'),
                const Divider(height: 30),
                Text(
                  'GORKI KIOSK',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('Theaterkasse, Merchshop & Lounge'),
                const Divider(height: 30),
                Text(
                  'CAN DÜNDARS\nTHEATER\nKOLUMNE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
