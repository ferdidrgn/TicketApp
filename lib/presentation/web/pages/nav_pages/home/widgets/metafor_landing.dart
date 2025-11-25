import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/util/responsive_utils.dart';

class MetaforLanding extends StatefulWidget {
  const MetaforLanding({super.key});

  @override
  State<MetaforLanding> createState() => _MetaforLandingState();
}

class _MetaforLandingState extends State<MetaforLanding>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
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
      builder: (final context, final child) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: WebColors.darkBlueBackground,
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

  Widget _buildElegantHeader(final BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                _buildCornerDecoration(true),
                _buildCornerDecoration(false),
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            WebColors.primaryGold,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: context.gridSpacing * 2),
                    Stack(
                      children: [
                        Text(
                          'METAFOR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize:
                                context.responsive(mobile: 52.0, desktop: 84.0),
                            fontWeight: FontWeight.w300,
                            fontFamily: 'Playfair Display',
                            color: WebColors.primaryGold.withOpacity(0.1),
                            letterSpacing: 8,
                            height: 0.9,
                          ),
                        ),
                        Text(
                          'METAFOR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize:
                                context.responsive(mobile: 52.0, desktop: 84.0),
                            fontWeight: FontWeight.w300,
                            fontFamily: 'Playfair Display',
                            color: Colors.white,
                            letterSpacing: 8,
                            height: 0.9,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.gridSpacing),
                    Container(
                      width: 120,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            WebColors.primaryGold.withOpacity(0.5),
                            WebColors.primaryGold,
                            WebColors.primaryGold.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: context.gridSpacing * 1.5),
                    SizedBox(
                      width: context.responsive(mobile: 300, desktop: 600),
                      child: Text(
                        'Zamanın, Hafızanın ve İnsan Ruhunun Labirentlerinde Bir Tiyatro Deneyimi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize:
                              context.responsive(mobile: 14.0, desktop: 18.0),
                          color: WebColors.textSecondary,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerDecoration(final bool isLeft) {
    return Positioned(
      top: 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: Transform.rotate(
        angle: isLeft ? 0 : 3.14,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: WebColors.primaryGold, width: 1),
              left: BorderSide(color: WebColors.primaryGold, width: 1),
            ),
          ),
          child: Icon(
            Icons.star_outline,
            color: WebColors.primaryGold,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImageSection(final BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value * 0.7),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: context.isMobile
            ? _buildMobileHeroSection(context)
            : _buildDesktopHeroSection(context),
      ),
    );
  }

  // Mobil için özel hero section
  Widget _buildMobileHeroSection(final BuildContext context) {
    return Column(
      children: [
        // Görsel
        Container(
          height: 280,
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
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 3,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Soru kartı aşağıda
        _buildQuestionCard(context),
      ],
    );
  }

  // Desktop için eski stil
  Widget _buildDesktopHeroSection(final BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 500,
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
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: _buildQuestionCard(context),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(final BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 16 : 20),
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
            padding: EdgeInsets.all(context.isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: WebColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.psychology_outlined,
              color: WebColors.primaryGold,
              size: context.isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: context.isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "HAYATIN LABİRENTLERİNDE",
                  style: TextStyle(
                    fontSize: context.isMobile ? 10 : 12,
                    color: WebColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: context.isMobile ? 6 : 8),
                Text(
                  "Hangisi daha Tehlikelidir:\nMetaforlar mı yoksa Klişeler mi?",
                  style: TextStyle(
                    fontSize: context.isMobile ? 14 : 18,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 1,
                    height: 1.3,
                    fontFamily: 'Playfair Display',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentGrid(final BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value * 0.5),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: context.isMobile
            ? _buildMobileContent(context)
            : _buildDesktopContent(context),
      ),
    );
  }

  Widget _buildMobileContent(final BuildContext context) {
    return Column(
      children: [
        _buildModernStoryCard(context),
        SizedBox(height: context.gridSpacing * 1.5),
        _buildModernTeamCard(context),
      ],
    );
  }

  Widget _buildDesktopContent(final BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildModernStoryCard(context)),
        SizedBox(width: context.gridSpacing * 2),
        Expanded(flex: 1, child: _buildModernTeamCard(context)),
      ],
    );
  }

  Widget _buildModernStoryCard(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: WebColors.primaryGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                "OYUN HAKKINDA",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gridSpacing * 1.5),
          const Text(
            "Zamanın durduğu bir limanda, eski ciltlerin solgun kokuları arasında üç yalnız ruhun kesişen kaderleri... "
            "Tozlu rafların sessiz tanığı bir sahaf, kelimelerin büyüsüne tutkun genç bir yazar, "
            "ve geçmişin gölgelerinden sıyrılıp gelen bir kadın. ",
            style: TextStyle(
              color: Colors.white70,
              height: 1.6,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: context.gridSpacing),
          const Text(
            "Metafor, insan ruhunun labirentlerinde unutulmaz bir yolculuk vaat ediyor. "
            "Yekta Kopan'ın incelikli kalemi ve Gürkan Candan'ın ustalıklı yönetmenliğiyle, "
            "izleyiciyi zamanın ötesine taşıyan bir tiyatro deneyimi.",
            style: TextStyle(
              color: Colors.white70,
              height: 1.6,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTeamCard(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: WebColors.primaryGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8),
              Text(
                "YARATICI EKİP",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  fontSize: 16,
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: WebColors.primaryGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          SizedBox(height: context.gridSpacing * 1.5),
          Column(
            children: [
              _buildCompactTeamMember(
                context,
                "YAZAR",
                "Yekta Kopan",
                Icons.auto_awesome_mosaic,
              ),
              SizedBox(height: 12),
              _buildCompactTeamMember(
                context,
                "YÖNETMEN",
                "Gürkan Candan",
                Icons.visibility,
              ),
              SizedBox(height: 12),
              _buildCompactTeamMember(
                context,
                "IŞIK & SES",
                "Ferdi Durgun",
                Icons.lightbulb_outline,
              ),
            ],
          ),
          SizedBox(height: context.gridSpacing),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  WebColors.primaryGold.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          SizedBox(height: context.gridSpacing),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.format_quote,
                  color: WebColors.primaryGold.withOpacity(0.5),
                  size: 20,
                ),
                SizedBox(height: 8),
                Text(
                  "Sanat, gerçeğin metaforudur. Hayatın en derin gerçeklerini en güzel metaforlarla buluşturuyoruz.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "- Yekta Kopan",
                  style: TextStyle(
                    color: WebColors.primaryGold.withOpacity(0.7),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTeamMember(final BuildContext context, final String role,
      final String name, final IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: WebColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
            ),
            child: Icon(icon, color: WebColors.primaryGold, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    color: WebColors.textTertiary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
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
          ),
        ],
      ),
    );
  }
}
