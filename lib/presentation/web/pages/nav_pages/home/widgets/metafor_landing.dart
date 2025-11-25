import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/util/responsive_utils.dart';

class MetaforLanding extends StatefulWidget {
  const MetaforLanding({Key? key}) : super(key: key);

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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: WebColors.darkBlueBackground, // SADECE BURASI DEĞİŞTİ
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

  // Geri kalan tüm kodlar aynı kalacak...
  Widget _buildElegantHeader(BuildContext context) {
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

  Widget _buildCornerDecoration(bool isLeft) {
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

  Widget _buildHeroImageSection(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value * 0.7),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
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
        ),
      ),
    );
  }

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
            child: Icon(Icons.psychology_outlined,
                color: WebColors.primaryGold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "HAYATIN LABİRENTLERİNDE",
                  style: TextStyle(
                    fontSize: 12,
                    color: WebColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Hangisi daha Tehlikelidir:\nMetaforlar mı yoksa Klişeler mi?",
                  style: TextStyle(
                    fontSize: 18,
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

  Widget _buildContentGrid(BuildContext context) {
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

  Widget _buildMobileContent(BuildContext context) {
    return Column(
      children: [
        _buildLuxuryStoryCard(context),
        SizedBox(height: context.gridSpacing * 2),
        _buildLuxuryTeamCard(context),
      ],
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildLuxuryStoryCard(context)),
        SizedBox(width: context.gridSpacing * 3),
        Expanded(flex: 1, child: _buildLuxuryTeamCard(context)),
      ],
    );
  }

  Widget _buildLuxuryStoryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Opacity(
              opacity: 0.05,
              child: Icon(
                Icons.auto_stories,
                color: WebColors.primaryGold,
                size: 120,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 1,
                    color: WebColors.primaryGold,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "OYUN HAKKINDA",
                    style: TextStyle(
                      color: WebColors.primaryGold,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 3,
                      fontSize: 12,
                      fontFamily: 'Playfair Display',
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.gridSpacing * 2),
              const Text(
                "Zamanın durduğu bir limanda, eski ciltlerin solgun kokuları arasında üç yalnız ruhun kesişen kaderleri... "
                "Tozlu rafların sessiz tanığı bir sahaf, kelimelerin büyüsüne tutkun genç bir yazar, "
                "ve geçmişin gölgelerinden sıyrılıp gelen bir kadın. ",
                style: TextStyle(
                  color: WebColors.textSecondary,
                  height: 1.8,
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: context.gridSpacing * 2),
              const Text(
                "Metafor, insan ruhunun labirentlerinde unutulmaz bir yolculuk vaat ediyor. "
                "Yekta Kopan'ın incelikli kalemi ve Gürkan Candan'ın ustalıklı yönetmenliğiyle, "
                "izleyiciyi zamanın ötesine taşıyan bir tiyatro deneyimi.",
                style: TextStyle(
                  color: WebColors.textSecondary,
                  height: 1.8,
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: context.gridSpacing * 3),
              Center(
                child: Container(
                  width: 100,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLuxuryTeamCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 1,
                color: WebColors.primaryGold,
              ),
              const SizedBox(width: 12),
              Text(
                "YARATICI EKİP",
                style: TextStyle(
                  color: WebColors.primaryGold,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 3,
                  fontSize: 12,
                  fontFamily: 'Playfair Display',
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 20,
                height: 1,
                color: WebColors.primaryGold,
              ),
            ],
          ),
          SizedBox(height: context.gridSpacing * 2),
          _buildLuxuryTeamMember(context, "YAZAR", "Yekta Kopan",
              Icons.edit_outlined, "Metnin Yaratıcısı"),
          SizedBox(height: context.gridSpacing * 1.5),
          _buildLuxuryTeamMember(context, "YÖNETMEN", "Gürkan Candan",
              Icons.theater_comedy, "Sahne Vizyoneri"),
          SizedBox(height: context.gridSpacing * 1.5),
          _buildLuxuryTeamMember(context, "IŞIK & SES", "Ferdi Durgun",
              Icons.lightbulb_outline, "Atmosfer Mimarı"),
          SizedBox(height: context.gridSpacing * 2),
          Container(
            width: 60,
            height: 1,
            color: WebColors.primaryGold.withOpacity(0.5),
          ),
          SizedBox(height: context.gridSpacing * 2),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: WebColors.primaryGold.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.format_quote,
                  color: WebColors.primaryGold.withOpacity(0.3),
                  size: 32,
                ),
                SizedBox(height: context.gridSpacing),
                Text(
                  "Sanat, gerçeğin metaforudur. Biz de bu sahnede, hayatın en derin gerçeklerini en güzel metaforlarla buluşturuyoruz.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: WebColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: context.gridSpacing),
                Text(
                  "- Yekta Kopan",
                  style: TextStyle(
                    color: WebColors.primaryGold.withOpacity(0.7),
                    fontSize: 11,
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

  Widget _buildLuxuryTeamMember(BuildContext context, String role, String name,
      IconData icon, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
            ),
            child: Icon(icon, color: WebColors.primaryGold, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 10,
                    color: WebColors.textTertiary,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'Playfair Display',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: WebColors.textSecondary,
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
}
