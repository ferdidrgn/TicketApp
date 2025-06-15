import 'package:flutter/material.dart';

class MetaforLanding extends StatelessWidget {
  const MetaforLanding({super.key});

  @override
  Widget build(final BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      width: double.infinity,
      color: Colors.black,
      // Web'de zemin rengi olmazsa içerik görünmez olabilir
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: isMobile ? _buildMobileLayout() : _buildWebLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleTexts(fontSize: 26, metaforSize: 40),
        const SizedBox(height: 24),

        // First Image
        _buildImageWithOverlay(
          url:
              'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2Fmetafor.png?alt=media&token=0e834168-3918-4a3c-96b9-1fe990afcac2',
          height: 220,
        ),
        const SizedBox(height: 24),

        // Second Image with Overlay
        _buildImageWithOverlay(
          url:
              'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG-20250610-WA0011.jpg?alt=media&token=c6d06f59-ebd0-4737-8ed5-1f779e683970',
          height: 220,
        ),
        const SizedBox(height: 24),

        // Text Content
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: _buildTextContent(),
        ),
      ],
    );
  }

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// SOL
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleTexts(fontSize: 40, metaforSize: 60),
              const SizedBox(height: 32),
              _buildImageWithOverlay(
                url:
                    'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2Fmetafor.png?alt=media&token=0e834168-3918-4a3c-96b9-1fe990afcac2',
                height: 400,
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),

        /// SAĞ
        Expanded(
          flex: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                SizedBox(
                  height: 600,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Image.network(
                        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG-20250610-WA0011.jpg?alt=media&token=c6d06f59-ebd0-4737-8ed5-1f779e683970',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                      // Black Overlay
                      Container(
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildTextContent(), // This is where your text will go
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleTexts(
      {required final double fontSize, required final double metaforSize}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SAHNENİN KALBİNDEN\nYENİ BİR HİKAYE',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            height: 1.3,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'METAFOR',
          style: TextStyle(
            fontSize: metaforSize,
            fontWeight: FontWeight.w900,
            fontFamily: 'Times New Roman',
            fontStyle: FontStyle.italic,
            color: Colors.red.shade700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildImageWithOverlay(
      {required final String url, required final double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            height: height,
            width: double.infinity,
          ),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hayatın kırılgan aynasında yankılanan “Metafor”, bir sahafın raflarında başlayan ve her karakterin kendi gerçeğiyle yüzleştiği büyülü bir anlatı sunuyor. '
            'Alman kızın içsel yalnızlığı, genç adamın kayıpları ve anlatıcının zamansız gözlemleriyle; izleyiciyi sezgisel bir düşün dünyasına davet ediyor.',
            style: TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
          ),
          SizedBox(height: 16),
          Text(
            'Usta kalem Yekta Kopan’ın kelimeleri, yönetmen Gürkan Candan’ın sahne vizyonuyla birleşerek metaforlarla örülü bir evrene dönüşüyor. '
            'Yazar, aynı zamanda anlatıcı rolünde, zamanın sınırlarını eğip bükerek sahnede geçmişle bugünü iç içe geçiriyor.',
            style: TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
          ),
          SizedBox(height: 16),
          Text(
            'Karakterler:',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'Sahafçı, Alman kız, annesini yitirmiş genç adam ve anlatıcı-yazar... '
            'Her biri kendi metaforunu taşıyor; her biri izleyicinin zihninde iz bırakıyor.',
            style: TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
          ),
          SizedBox(height: 16),
          Text(
            'Yazar: Yekta Kopan\nYönetmen: Gürkan Candan',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
