import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Mevcut import'larınız korundu
import '../../../../../../core/util/responsive_utils.dart';
import '../../../../../../core/theme/app_colors.dart';

class MetaforLanding extends StatefulWidget {
  const MetaforLanding({Key? key}) : super(key: key);

  @override
  State<MetaforLanding> createState() => _MetaforLandingState();
}

class _MetaforLandingState extends State<MetaforLanding>
    with SingleTickerProviderStateMixin {
  bool _isHoveringAction = false;
  bool _isHoveringImage = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: WebColors.backgroundGradient,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: context.responsive(
                  mobile: context.paddingAll
                      .copyWith(left: 20, right: 20, top: 32, bottom: 40),
                  desktop: context.paddingAll
                      .copyWith(left: 50, right: 50, top: 60, bottom: 80),
                ),
                child: Column(
                  children: [
                    _buildModernHeader(context),
                    SizedBox(height: context.gridSpacing * 2.5),
                    _buildLayout(context),
                    SizedBox(height: context.gridSpacing * 3),
                    _buildModernActionButton(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // MODERN HEADER - YENİ TASARIM
  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: context.responsive(
        mobile: const EdgeInsets.all(24),
        desktop: const EdgeInsets.all(32),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WebColors.darkBlueAccent.withOpacity(0.9),
            WebColors.mediumDarkBlue.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(context.borderRadius(2.0)),
        border: Border.all(
          color: WebColors.primaryGold.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: WebColors.primaryGold.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Modern Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 16, color: WebColors.veryDarkBlue),
                const SizedBox(width: 8),
                Text(
                  'YENİ SEZON',
                  style: TextStyle(
                    fontSize: context.captionSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: WebColors.veryDarkBlue,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.gridSpacing),

          // Ana Başlık
          Stack(
            children: [
              // Altın gölge efekti
              Text(
                'METAFOR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.responsive(mobile: 52.0, desktop: 90.0),
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Georgia',
                  fontStyle: FontStyle.italic,
                  color: WebColors.primaryGold.withOpacity(0.3),
                  letterSpacing: 6,
                  height: 1,
                ),
              ),
              // Ana metin
              Text(
                'METAFOR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.responsive(mobile: 52.0, desktop: 90.0),
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Georgia',
                  fontStyle: FontStyle.italic,
                  foreground: Paint()
                    ..shader = WebColors.goldGradient.createShader(
                      const Rect.fromLTWH(0, 0, 400, 100),
                    ),
                  letterSpacing: 6,
                  height: 1,
                ),
              ),
            ],
          ),

          SizedBox(height: context.gridSpacing),

          // Alt Başlık
          Text(
            'Zamanın, Hafızanın ve İnsan Ruhunun Labirentleri',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.subtitleSize,
              color: WebColors.textSecondary,
              letterSpacing: 1.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    final isMobile = context.isMobile;

    if (isMobile) {
      return Column(
        children: [
          _buildModernImageSection(context),
          SizedBox(height: context.gridSpacing * 1.5),
          _buildModernStorySection(context),
          SizedBox(height: context.gridSpacing * 1.5),
          _buildModernCrewSection(context),
        ],
      );
    } else {
      return Column(
        children: [
          _buildModernImageSection(context),
          SizedBox(height: context.gridSpacing * 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildModernStorySection(context),
              ),
              SizedBox(width: context.gridSpacing),
              Expanded(
                child: _buildModernCrewSection(context),
              ),
            ],
          ),
        ],
      );
    }
  }

  // MODERN IMAGE SECTION
  Widget _buildModernImageSection(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringImage = true),
      onExit: (_) => setState(() => _isHoveringImage = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.borderRadius(2.0)),
          border: Border.all(
            color: _isHoveringImage
                ? WebColors.primaryGoldLight
                : WebColors.darkBlueAccent.withOpacity(0.5),
            width: _isHoveringImage ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: WebColors.primaryGold
                  .withOpacity(_isHoveringImage ? 0.3 : 0.1),
              blurRadius: _isHoveringImage ? 40 : 20,
              spreadRadius: _isHoveringImage ? 8 : 4,
              offset: Offset(0, _isHoveringImage ? 15 : 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.borderRadius(2.0) - 2),
          child: Stack(
            children: [
              // Ana Görsel
              Image.network(
                'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG-20250610-WA0011.jpg?alt=media&token=c6d06f59-ebd0-4737-8ed5-1f779e683970',
                fit: BoxFit.cover,
                height:
                    context.responsive(mobile: 450.0, desktop: context.hp(50)),
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: context.responsive(
                        mobile: 450.0, desktop: context.hp(50)),
                    decoration: BoxDecoration(
                      gradient: WebColors.cardGradient,
                    ),
                    child: Center(
                      child: Icon(Icons.auto_stories,
                          size: context.iconLarge * 1.5,
                          color: WebColors.primaryGold),
                    ),
                  );
                },
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Question Card
              Positioned(
                top: context.responsive(mobile: 20, desktop: 40),
                right: context.responsive(mobile: 20, desktop: 40),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WebColors.veryDarkBlue.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: WebColors.primaryGold),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology,
                          color: WebColors.primaryGoldLight, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Hangisi daha zor?',
                        style: TextStyle(
                          color: WebColors.whiteText,
                          fontWeight: FontWeight.w700,
                          fontSize: context.captionSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: context.responsive(
                    mobile: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    desktop: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 28),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        WebColors.veryDarkBlue.withOpacity(0.95),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: WebColors.primaryGold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.lightbulb_outline,
                                color: WebColors.veryDarkBlue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hangisi Daha Tehlikelidir? Metaforlar mı Klişeler mi?',
                              style: TextStyle(
                                fontSize: context.responsive(
                                    mobile: 18.0, desktop: 24.0),
                                color: WebColors.whiteText,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
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

  // MODERN STORY SECTION
  Widget _buildModernStorySection(BuildContext context) {
    return Container(
      padding: context.responsive(
        mobile: const EdgeInsets.all(24),
        desktop: const EdgeInsets.all(32),
      ),
      decoration: BoxDecoration(
        gradient: WebColors.cardGradient,
        borderRadius: BorderRadius.circular(context.borderRadius(2.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernSectionHeader(
              'OYUN HAKKINDA', Icons.theater_comedy, context),
          SizedBox(height: context.gridSpacing),

          // Modern Text Content
          _buildModernTextCard(
            context,
            'Zamanın olmadığı bir yerde, eski kitaplarla dolu tozlu bir sahaf dükkânında üç kişi bir araya gelir: '
            'Hayata küsmüş, geçmişin sayfalarına sığınmış içedönük bir sahaf; yanından hiç ayrılmayan, yazar olma hayaliyle dolu genç bir adam; '
            've geçmişin gölgesinden çıkıp gelen bir genç kadın.',
          ),

          SizedBox(height: context.gridSpacing - 4),

          _buildModernTextCard(
            context,
            'Kadın, annesinin geçmişine dair cevaplar ararken, sahaf yıllardır sakladığı sessizliğiyle yüzleşmek zorunda kalır. '
            'Genç adam ve genç kadın arasında filizlenen kırılgan bir aşk, saklı kalan sırlar ve zamanın dışında salınan hayatlar…, '
            '"Metafor", dram ve mizahın iç içe geçtiği bu oyunla, hafızanın labirentlerinde gezinirken insan olmanın karmaşık duygularını sahneye taşıyor.',
          ),

          SizedBox(height: context.gridSpacing),

          // Modern Characters Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: WebColors.darkBlueAccent.withOpacity(0.6),
              borderRadius: BorderRadius.circular(context.borderRadius(1.5)),
              border: Border.all(
                color: WebColors.primaryGold.withOpacity(0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_alt,
                        color: WebColors.primaryGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Karakterler',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: context.subtitleSize - 2,
                        color: WebColors.primaryGoldLight,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Sahaf, genç adam, genç kadın... Her biri kendi geçmişinin yükünü taşıyor. '
                  'Kelimelerle, sessizlikle ve zamanla örülmüş bir hikâyede izleyicinin zihnine işleyen metaforlar sunuyorlar.',
                  style: TextStyle(
                    fontSize: context.bodySize,
                    color: WebColors.lightWhite,
                    height: 1.6,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MODERN CREW SECTION
  Widget _buildModernCrewSection(BuildContext context) {
    return Container(
      padding: context.responsive(
        mobile: const EdgeInsets.all(24),
        desktop: const EdgeInsets.all(32),
      ),
      decoration: BoxDecoration(
        gradient: WebColors.cardGradient,
        borderRadius: BorderRadius.circular(context.borderRadius(2.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernSectionHeader(
              'YARATICI EKİP', Icons.emoji_events, context),
          SizedBox(height: context.gridSpacing),

          _buildModernCrewMember(
              context, 'Yazar', 'Yekta Kopan', Icons.auto_stories),
          SizedBox(height: 12),
          _buildModernCrewMember(
              context, 'Yönetmen', 'Gürkan Candan', Icons.movie_creation),
          SizedBox(height: 12),
          _buildModernCrewMember(
              context, 'Işık-Ses', 'Ferdi Durgun', Icons.lightbulb),

          SizedBox(height: context.gridSpacing),

          // Modern Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: WebColors.darkBlueAccent.withOpacity(0.6),
              borderRadius: BorderRadius.circular(context.borderRadius(1.5)),
              border: Border.all(
                color: WebColors.primaryGold.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.format_quote,
                    color: WebColors.primaryGold.withOpacity(0.7), size: 30),
                const SizedBox(height: 12),
                Text(
                  'Yekta Kopan\'ın güçlü kalemi, zaman kavramını eğip bükerek insan ruhunun en kırılgan yönlerine dokunuyor. '
                  'Gürkan Candan\'ın yönetmenliğindeki sahne dili ise bu derin metni görsel ve duyusal bir anlatıya dönüştürüyor.',
                  style: TextStyle(
                    fontSize: context.bodySize,
                    color: WebColors.textSecondary,
                    height: 1.7,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // YARDIMCI METOT: Modern Section Header
  Widget _buildModernSectionHeader(
      String title, IconData icon, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: WebColors.primaryGold,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: WebColors.goldGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: WebColors.veryDarkBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: context.subtitleSize,
                fontWeight: FontWeight.w800,
                color: WebColors.whiteText,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // YARDIMCI METOT: Modern Crew Member
  Widget _buildModernCrewMember(
      BuildContext context, String role, String name, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebColors.mediumDarkBlue.withOpacity(0.4),
        borderRadius: BorderRadius.circular(context.borderRadius(1.2)),
        border: Border.all(
          color: WebColors.darkBlueAccent.withOpacity(0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: WebColors.veryDarkBlue,
              size: context.iconSmall,
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
                    fontSize: context.captionSize,
                    color: WebColors.primaryGoldLight,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: context.bodySize + 1,
                    color: WebColors.whiteText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: WebColors.primaryGold.withOpacity(0.7)),
        ],
      ),
    );
  }

  // YARDIMCI METOT: Modern Text Card
  Widget _buildModernTextCard(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.bodySize,
          color: WebColors.textSecondary,
          height: 1.7,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // MODERN ACTION BUTTON
  Widget _buildModernActionButton(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringAction = true),
      onExit: (_) => setState(() => _isHoveringAction = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        transform: Matrix4.identity()..scale(_isHoveringAction ? 1.05 : 1.0),
        child: GestureDetector(
          onTap: () {
            _showTicketDialog(context);
          },
          child: Container(
            padding: context.responsive(
              mobile: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              desktop: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
            ),
            decoration: BoxDecoration(
              gradient: WebColors.goldButtonGradient,
              borderRadius: BorderRadius.circular(context.borderRadius(3.0)),
              boxShadow: [
                BoxShadow(
                  color: WebColors.primaryGold
                      .withOpacity(_isHoveringAction ? 0.6 : 0.3),
                  blurRadius: _isHoveringAction ? 40 : 20,
                  spreadRadius: _isHoveringAction ? 8 : 4,
                  offset: Offset(0, _isHoveringAction ? 10 : 5),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: WebColors.veryDarkBlue,
                  size: context.iconMedium,
                ),
                const SizedBox(width: 16),
                Text(
                  'BİLETLERİ ŞİMDİ AL',
                  style: TextStyle(
                    fontSize: context.subtitleSize,
                    color: WebColors.veryDarkBlue,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  transform: Matrix4.translationValues(
                    _isHoveringAction ? 8 : 0,
                    0,
                    0,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: WebColors.veryDarkBlue,
                    size: context.iconMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTicketDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WebColors.darkBlueSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: WebColors.primaryGold, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.confirmation_number, color: WebColors.primaryGold),
            const SizedBox(width: 12),
            Text(
              'Bilet Satın Al',
              style: TextStyle(
                color: WebColors.whiteText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Bilet satın alma sayfasına yönlendirileceksiniz. Devam etmek istiyor musunuz?',
          style: TextStyle(color: WebColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('İptal', style: TextStyle(color: WebColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bilet alma sayfasına yönlendiriliyorsunuz...'),
                  backgroundColor: WebColors.primaryGold,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WebColors.primaryGold,
            ),
            child: Text('Devam Et',
                style: TextStyle(color: WebColors.veryDarkBlue)),
          ),
        ],
      ),
    );
  }
}
