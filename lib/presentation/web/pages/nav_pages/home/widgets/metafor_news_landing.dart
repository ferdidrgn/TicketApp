import 'package:flutter/material.dart';

class MetaforNewsLanding extends StatelessWidget {
  const MetaforNewsLanding({super.key});

  @override
  Widget build(final BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sol taraf: Başlık + afiş birlikte
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text(
                  'SAHNENİN KALBİNDEN\nYENİ BİR HİKAYE',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    height: 1.2,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'METAFOR',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Times New Roman',
                    fontStyle: FontStyle.italic,
                    color: Colors.red.shade700,
                    letterSpacing: 3,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2Fmetafor.png?alt=media&token=0e834168-3918-4a3c-96b9-1fe990afcac2',
                    height: 500,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 40),

          // Sağ taraf: Açıklamalar
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG-20250610-WA0011.jpg?alt=media&token=c6d06f59-ebd0-4737-8ed5-1f779e683970',
                    fit: BoxFit.cover,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hayatın kırılgan aynasında yankılanan “Metafor”, bir sahafın raflarında başlayan ve her karakterin kendi gerçeğiyle yüzleştiği büyülü bir anlatı sunuyor. '
                      'Alman kızın içsel yalnızlığı, genç adamın kayıpları ve anlatıcının zamansız gözlemleriyle; izleyiciyi sezgisel bir düşün dünyasına davet ediyor.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Usta kalem Yekta Kopan’ın kelimeleri, yönetmen Gürkan Candan’ın sahne vizyonuyla birleşerek metaforlarla örülü bir evrene dönüşüyor. '
                      'Yazar, aynı zamanda anlatıcı rolünde, zamanın sınırlarını eğip bükerek sahnede geçmişle bugünü iç içe geçiriyor.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Karakterler:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sahafçı, Alman kız, annesini yitirmiş genç adam ve anlatıcı-yazar... '
                      'Her biri kendi metaforunu taşıyor; her biri izleyicinin zihninde iz bırakıyor.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Yazar: Yekta Kopan\nYönetmen: Gürkan Candan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
