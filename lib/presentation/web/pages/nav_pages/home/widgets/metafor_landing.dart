import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/theme/app_colors.dart';

class MetaforLanding extends StatefulWidget {
  const MetaforLanding({Key? key}) : super(key: key);

  @override
  State<MetaforLanding> createState() => _MetaforLandingState();
}

class _MetaforLandingState extends State<MetaforLanding> {
  bool _isHoveringCTA = false;
  bool _isHoveringImage = false;

  @override
  Widget build(final BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF050B15),
            Color(0xFF0A1628),
            Color(0xFF0F1F35),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 50,
          vertical: isMobile ? 32 : 60,
        ),
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMagazineHeader(isMobile: true),
        const SizedBox(height: 32),
        _buildMainImage(isMobile: true),
        const SizedBox(height: 32),
        _buildFullStorySection(isMobile: true),
        const SizedBox(height: 32),
        _buildCrewSection(isMobile: true),
        const SizedBox(height: 40),
        _buildLocationCTA(isMobile: true),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        _buildMagazineHeader(isMobile: false),
        const SizedBox(height: 50),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _buildMainImage(isMobile: false),
            ),
            const SizedBox(width: 40),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _buildFullStorySection(isMobile: false),
                  const SizedBox(height: 30),
                  _buildCrewSection(isMobile: false),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 50),
        _buildLocationCTA(isMobile: false),
      ],
    );
  }

  Widget _buildMagazineHeader({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: WebColors.primaryGold.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: WebColors.primaryGold.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 2,
                width: isMobile ? 50 : 100,
                color: WebColors.primaryGold,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'TİYATRO ESERİ',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: WebColors.primaryGold,
                  ),
                ),
              ),
              Container(
                height: 2,
                width: isMobile ? 50 : 100,
                color: WebColors.primaryGold,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'METAFOR',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 48 : 80,
              fontWeight: FontWeight.w900,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              color: WebColors.primaryGold,
              letterSpacing: 4,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sahnentin Kalbinden Yeni Bir Hikâye',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 13 : 16,
              color: WebColors.textSecondary,
              letterSpacing: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainImage({required bool isMobile}) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringImage = true),
      onExit: (_) => setState(() => _isHoveringImage = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHoveringImage
                ? WebColors.primaryGold
                : WebColors.primaryGold.withOpacity(0.3),
            width: _isHoveringImage ? 3 : 2,
          ),
          boxShadow: [
            if (_isHoveringImage)
              BoxShadow(
                color: WebColors.primaryGold.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 5,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Image.network(
                'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG-20250610-WA0011.jpg?alt=media&token=c6d06f59-ebd0-4737-8ed5-1f779e683970',
                fit: BoxFit.cover,
                height: isMobile ? 450 : 700,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: isMobile ? 450 : 700,
                    color: WebColors.darkBlueAccent,
                    child: const Center(
                      child: Icon(Icons.auto_stories,
                          size: 100, color: WebColors.primaryGold),
                    ),
                  );
                },
              ),
              Container(
                height: isMobile ? 450 : 700,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      WebColors.veryDarkBlue.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: WebColors.primaryGold.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book,
                          color: WebColors.veryDarkBlue, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Sahaf Dükkânında Bir Hikâye',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 15,
                          color: WebColors.veryDarkBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullStorySection({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: WebColors.primaryGold.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 30,
                decoration: BoxDecoration(
                  color: WebColors.primaryGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'OYUN HAKKINDA',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: WebColors.primaryGold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Zamanın olmadığı bir yerde, eski kitaplarla dolu tozlu bir sahaf dükkânında üç kişi bir araya gelir: '
            'Hayata küsmüş, geçmişin sayfalarına sığınmış içedönük bir sahaf; yanından hiç ayrılmayan, yazar olma hayaliyle dolu genç bir adam; '
            've geçmişin gölgesinden çıkıp gelen bir genç kadın.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: WebColors.textSecondary,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Kadın, annesinin geçmişine dair cevaplar ararken, sahaf yıllardır sakladığı sessizliğiyle yüzleşmek zorunda kalır. '
            'Genç adam ve genç kadın arasında filizlenen kırılgan bir aşk, saklı kalan sırlar ve zamanın dışında salınan hayatlar…, '
            '"Metafor", dram ve mizahın iç içe geçtiği bu oyunla, hafızanın labirentlerinde gezinirken insan olmanın karmaşık duygularını sahneye taşıyor.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: WebColors.textSecondary,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: WebColors.darkBlueAccent.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: WebColors.primaryGold.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Karakterler',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 16 : 18,
                    color: WebColors.primaryGold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sahaf, genç adam, genç kadın... Her biri kendi geçmişinin yükünü taşıyor. '
                  'Kelimelerle, sessizlikle ve zamanla örülmüş bir hikâyede izleyicinin zihnine işleyen metaforlar sunuyorlar.',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    color: WebColors.lightWhite,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrewSection({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: WebColors.primaryGold.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 30,
                decoration: BoxDecoration(
                  color: WebColors.primaryGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'YARATICI EKİP',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: WebColors.primaryGold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCrewMember('Yazar', 'Yekta Kopan', Icons.create, isMobile),
          const SizedBox(height: 16),
          _buildCrewMember('Yönetmen', 'Gürkan Candan', Icons.movie, isMobile),
          const SizedBox(height: 16),
          _buildCrewMember(
              'Işık-Ses', 'Ferdi Durgun', Icons.lightbulb, isMobile),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: WebColors.darkBlueAccent.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Yekta Kopan\'ın güçlü kalemi, zaman kavramını eğip bükerek insan ruhunun en kırılgan yönlerine dokunuyor. '
              'Gürkan Candan\'ın yönetmenliğindeki sahne dili ise bu derin metni görsel ve duyusal bir anlatıya dönüştürüyor.',
              style: TextStyle(
                fontSize: isMobile ? 13 : 15,
                color: WebColors.textSecondary,
                height: 1.7,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrewMember(
      String role, String name, IconData icon, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebColors.darkBlueAccent.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WebColors.primaryGold.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WebColors.primaryGold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: WebColors.veryDarkBlue,
              size: isMobile ? 20 : 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: WebColors.primaryGold,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 17,
                    color: WebColors.whiteText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCTA({required bool isMobile}) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringCTA = true),
      onExit: (_) => setState(() => _isHoveringCTA = false),
      child: GestureDetector(
        onTap: () async {
          const url = 'https://maps.app.goo.gl/CnW99UqhxyBJt1fL6';
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 32 : 48,
            vertical: isMobile ? 20 : 28,
          ),
          decoration: BoxDecoration(
            color: _isHoveringCTA
                ? WebColors.primaryGoldLight
                : WebColors.primaryGold,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: WebColors.primaryGold
                    .withOpacity(_isHoveringCTA ? 0.6 : 0.4),
                blurRadius: _isHoveringCTA ? 40 : 30,
                spreadRadius: _isHoveringCTA ? 8 : 5,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                color: WebColors.veryDarkBlue,
                size: isMobile ? 24 : 28,
              ),
              const SizedBox(width: 16),
              Text(
                'Altunizade Kültür Merkezi',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  color: WebColors.veryDarkBlue,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward,
                color: WebColors.veryDarkBlue,
                size: isMobile ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
