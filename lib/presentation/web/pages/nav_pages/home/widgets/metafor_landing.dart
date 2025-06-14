import 'package:flutter/material.dart';

class MetaforLanding extends StatelessWidget {
  const MetaforLanding({super.key});

  @override
  Widget build(final BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sol Yan Metin (Manşet gibi büyük başlık)
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EKİPTEN\nYENİ OYUN!',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.1,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'METAFOR',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.red.shade700,
                    letterSpacing: 3,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 40),

          // Sağ Yan İçerik (Oyun hakkında detaylar)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“Metafor” hayatın katmanlarında dolaşan, gerçek ile hayal arasında ince bir çizgide yürüyen bir oyun. '
                      'Sahafçı dükkanının tozlu raflarından, Alman kızın geçmişine, kaybetmenin ve anıların dokunuşlarına kadar; '
                      'her karakter kendi metaforunu yaratıyor ve birbiriyle iç içe geçmiş öykülerle izleyiciyi büyülüyor.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Oyun, Yekta Kopan’ın kaleminden çıkan derinlikli metinlerle, '
                      'Gürkan Candan’ın ustalıkla yönettiği sahnede hayat buluyor. '
                      'Yazarın kendisi aynı zamanda anlatıcı rolünde; zaman ve mekanları bükerek, '
                      'izleyiciyi kendi içinde bir yolculuğa çıkarıyor.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Oyuncuların Dokunuşları:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sahafçı, Alman kız, geçmişin gölgesinde annesini kaybetmiş genç adam, '
                      've yazar-anlatıcı; her biri oyunun çok katmanlı dünyasında birbirine dokunuyor.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Yazar: Yekta Kopan\nYönetmen: Gürkan Candan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
