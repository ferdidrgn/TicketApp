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

class _MetaforLandingState extends State<MetaforLanding> with SingleTickerProviderStateMixin {
  bool _isHoveringAction = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
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
            padding: context.responsive(
              mobile: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              desktop: const EdgeInsets.symmetric(horizontal: 50, vertical: 60),
            ),
            child: Column(
              children: [
                _buildElegantHeader(context),
                SizedBox(height: context.gridSpacing * 3),
                _buildHeroImageSection(context),
                SizedBox(height: context.gridSpacing * 2),
                _buildContentGrid(context),
                SizedBox(height: context.gridSpacing * 4),
              ],
            ),
          ),
        );
      },
    );
  }

  // ████████ ELEGANT HEADER - Minimal & Modern ████████
  Widget _buildElegantHeader(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Modern Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: WebColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_outline, size: 14, color: WebColors.primaryGold),
                  const SizedBox(width: 8),
                  Text(
                    'YENİ SEZON',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: WebColors.primaryGold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.gridSpacing * 1.5),

            // Ana Başlık - Minimal Tasarım
            Text(
              'METAFOR',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.responsive(mobile: 48.0, desktop: 72.0),
                fontWeight: FontWeight.w300, // İnce font daha şık
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                color: Colors.white,
                letterSpacing: 3,
                height: 0.9,
              ),
            ),

            SizedBox(height: context.gridSpacing),

            // Alt Başlık
            Text(
              'Zamanın, Hafızanın ve İnsan Ruhunun Labirentleri',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodySize,
                color: WebColors.textSecondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ████████ HERO IMAGE SECTION - Dramatik Görsel ████████
  Widget _buildHeroImageSection(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value * 0.7),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Ana Görsel Container
            Container(
              height: context.responsive(mobile: 300.0, desktop: 500.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2Fai_metafor_image.png?alt=media&token=6f20f048-b88c-46c0-beb6-da4f4eb76c49',
                  ),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              // Gradient Overlay
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      WebColors.veryDarkBlue.withOpacity(0.9),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Floating Question Card
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildQuestionCard(context),
            ),
          ],
        ),
      ),
    );
  }

  // ████████ QUESTION CARD - Minimal Tasarım ████████
  Widget _buildQuestionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WebColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
            ),
            child: Icon(Icons.psychology_outlined, color: WebColors.primaryGold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hangisi daha zordur:",
                  style: TextStyle(
                    fontSize: 12,
                    color: WebColors.textSecondary,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Metaforlar mı yoksa Klişeler mi?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ████████ CONTENT GRID - Modern Kart Tasarımı ████████
  Widget _buildContentGrid(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value * 0.5),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: context.isMobile ? _buildMobileContent(context) : _buildDesktopContent(context),
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return Column(
      children: [
        _buildStoryCard(context),
        SizedBox(height: context.gridSpacing),
        _buildTeamCard(context),
      ],
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildStoryCard(context)),
        SizedBox(width: context.gridSpacing),
        Expanded(child: _buildTeamCard(context)),
      ],
    );
  }

  // ████████ STORY CARD - Minimal Tasarım ████████
  Widget _buildStoryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_stories_outlined, color: WebColors.primaryGold, size: 20),
              const SizedBox(width: 12),
              Text(
                "OYUN HAKKINDA",
                style: TextStyle(
                  color: WebColors.primaryGold,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          SizedBox(height: context.gridSpacing * 1.5),

          // Content
          const Text(
            "Zamanın olmadığı bir yerde, eski kitaplarla dolu tozlu bir sahaf dükkânında üç kişi bir araya gelir: "
                "Hayata küsmüş, geçmişin sayfalarına sığınmış içedönük bir sahaf; yanından hiç ayrılmayan, yazar olma hayaliyle dolu genç bir adam; "
                "ve geçmişin gölgesinden çıkıp gelen bir genç kadın.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WebColors.textSecondary,
              height: 1.7,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),

          SizedBox(height: context.gridSpacing * 1.5),

          // Characters Button
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: WebColors.primaryGold.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              "Karakterler",
              style: TextStyle(
                color: WebColors.primaryGold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ████████ TEAM CARD - Modern Liste Tasarımı ████████
  Widget _buildTeamCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, color: WebColors.primaryGold, size: 20),
              const SizedBox(width: 12),
              Text(
                "YARATICI EKİP",
                style: TextStyle(
                  color: WebColors.primaryGold,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          SizedBox(height: context.gridSpacing * 1.5),

          // Team Members
          _buildTeamMember(context, "Yazar", "Yekta Kopan", Icons.edit_outlined),
          const Divider(color: Colors.white10, height: 32),
          _buildTeamMember(context, "Yönetmen", "Gürkan Candan", Icons.movie_creation_outlined),
          const Divider(color: Colors.white10, height: 32),
          _buildTeamMember(context, "Işık-Ses", "Ferdi Durgun", Icons.lightbulb_outline),

          SizedBox(height: context.gridSpacing),

          // Creative Description
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: WebColors.darkBlueAccent.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Yekta Kopan'ın güçlü kalemi ve Gürkan Candan'ın yönetmenliğinde, "
                  "zamanın labirentlerinde unutulmaz bir yolculuk.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WebColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w300,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ████████ TEAM MEMBER - Minimal Liste Öğesi ████████
  Widget _buildTeamMember(BuildContext context, String role, String name, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: WebColors.textTertiary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: WebColors.primaryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
          ),
          child: Icon(icon, color: WebColors.primaryGold, size: 18),
        ),
      ],
    );
  }
}

// ████████ BOTTOM NAVIGATION - Sabit Bilet Butonu ████████
class MetaforBottomBar extends StatelessWidget {
  const MetaforBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebColors.veryDarkBlue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: MouseRegion(
        onEnter: (_) => {},
        onExit: (_) => {},
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Bilet alma sayfasına yönlendiriliyorsunuz...'),
                backgroundColor: WebColors.primaryGold,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [WebColors.primaryGold, WebColors.primaryGoldLight],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: WebColors.primaryGold.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.confirmation_number_outlined, color: WebColors.veryDarkBlue),
                const SizedBox(width: 12),
                Text(
                  "Biletleri Şimdi Al",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: WebColors.veryDarkBlue,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: WebColors.veryDarkBlue, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}