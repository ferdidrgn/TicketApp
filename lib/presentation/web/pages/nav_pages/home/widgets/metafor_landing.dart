import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
              'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2Fmetafor%20afiş.jpg?alt=media&token=b7f46ce1-df8f-48ea-87c1-89bc39ec294a',
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
        _buildPremiereAnnouncement(),
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
                    'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2Fmetafor%20afiş.jpg?alt=media&token=b7f46ce1-df8f-48ea-87c1-89bc39ec294a',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPremiereAnnouncement(), // 👈 burada
                      _buildTextContent(),
                    ],
                  ),
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

  Widget _buildPremiereAnnouncement() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎭 PRÖMİYER DUYURUSU 🎭',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Metafor, ilk kez 27 Haziran 2025 Cuma akşamı saat 20.00’de\n'
            'Altunizade Kültür Merkezi’nde seyirciyle buluşuyor!\n\n'
            '🎫 Ücretsizdir, davetiye ya da bilet gerekmez.\n'
            'Gelin, bu özel gecede zamanın ötesinde bir hikâyeye birlikte tanıklık edelim.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              const url = 'https://maps.app.goo.gl/CnW99UqhxyBJt1fL6';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              }
            },
            child: Row(
              children: [
                const Icon(Icons.location_pin, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Konumu Google Haritalarda Aç',
                  style: TextStyle(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ],
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
            'Zamanın olmadığı bir yerde, eski kitaplarla dolu tozlu bir sahaf dükkânında üç kişi bir araya gelir: '
            'Hayata küsmüş, geçmişin sayfalarına sığınmış içedönük bir sahaf; yanından hiç ayrılmayan, yazar olma hayaliyle dolu genç bir adam; '
            've geçmişin gölgesinden çıkıp gelen bir genç kadın.',
            style: TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
          ),
          SizedBox(height: 16),
          Text(
            'Kadın, annesinin geçmişine dair cevaplar ararken, sahaf yıllardır sakladığı sessizliğiyle yüzleşmek zorunda kalır. '
            'Genç adam ve genç kadın arasında filizlenen kırılgan bir aşk,  saklı kalan sırlar ve zamanın dışında salınan hayatlar…, '
            '“Metafor”, dram ve mizahın iç içe geçtiği bu oyunla, hafızanın labirentlerinde gezinirken insan olmanın karmaşık duygularını sahneye taşıyor.',
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
            'Sahaf, genç adam, genç kadın... Her biri kendi geçmişinin yükünü taşıyor. '
            'Kelimelerle, sessizlikle ve zamanla örülmüş bir hikâyede izleyicinin zihnine işleyen metaforlar sunuyorlar.',
            style: TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
          ),
          SizedBox(height: 16),
          Text(
            'Yazar: Yekta Kopan\nYönetmen: Gürkan Candan\nIşık-Ses: Ferdi Durgun',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Yekta Kopan’ın güçlü kalemi, zaman kavramını eğip bükerek insan ruhunun en kırılgan yönlerine dokunuyor. '
            'Gürkan Candan’ın yönetmenliğindeki sahne dili ise bu derin metni görsel ve duyusal bir anlatıya dönüştürüyor.',
            style: TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
          ),
        ],
      ),
    );
  }
}
