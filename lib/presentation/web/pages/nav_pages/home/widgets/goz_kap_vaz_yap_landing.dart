import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/record_card.dart';
import '../../../../../../core/theme/app_colors.dart';

class GozYapVazYapLanding extends StatelessWidget {
  const GozYapVazYapLanding({super.key});

  static const String _mainImage =
      'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_165452.jpg?alt=media&token=1ebd1bc9-0df5-46fd-bce5-b7400d5d81ae';
  static const String _secondImage =
      'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_174009.jpg?alt=media&token=40652d5a-31fe-4dec-9df1-61e516dfda27';

  @override
  Widget build(final BuildContext context) {
    return Container(
      color: WebColors.darkBlueBackground,
      child: Column(
        children: [
          _buildTopHeader(context),
          _buildMainImageSection(context),
          _buildContentSection(context),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // MODERN BAŞLIK (Glassmorphism)
  // ═══════════════════════════════════════════════════
  Widget _buildTopHeader(final BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? 20 : 50,
        vertical: context.isMobile ? 32 : 48,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.isMobile ? 20 : 24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(context.isMobile ? 24 : 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(context.isMobile ? 20 : 24),
              border: Border.all(
                color: WebColors.primaryGold.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (final bounds) =>
                      WebColors.goldGradient.createShader(bounds),
                  child: Text(
                    'GÖZLERİMİ KAPARIM\nVAZİFEMİ YAPARIM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.responsive(mobile: 26.0, desktop: 42.0),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: WebColors.primaryGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: WebColors.primaryGold.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: WebColors.primaryGoldLight,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '1889 SES TİYATROSU (TAKSİM)',
                        style: TextStyle(
                          fontSize: context.isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: WebColors.primaryGoldLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // GÖRSEL BÖLÜMÜ (DEĞİŞMEDİ)
  // ═══════════════════════════════════════════════════
  Widget _buildMainImageSection(final BuildContext context) {
    return Container(
      height: context.responsive(mobile: 350.0, desktop: 500.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: WebColors.darkBlueBackground,
        boxShadow: [
          BoxShadow(
            color: WebColors.primaryGold.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(_mainImage, fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    WebColors.darkBlueBackground.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: context.responsive(mobile: 15.0, desktop: 40.0),
            right: context.responsive(mobile: 15.0, desktop: 40.0),
            child: const RecordPlayerCard(),
          ),
          Positioned(
            bottom: 20,
            left: 30,
            right: 30,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TOPLUMSAL VİCDANIN İKİ YÜZÜ:',
                  style: TextStyle(
                    fontSize: context.responsive(mobile: 14.0, desktop: 16.0),
                    color: WebColors.warning,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '"Körlükle kazanılan zenginlik ve dürüstlükle kaybedilen hayatlar."',
                  style: TextStyle(
                    fontSize: context.responsive(mobile: 18.0, desktop: 24.0),
                    fontWeight: FontWeight.w500,
                    color: WebColors.primaryGoldLight,
                    fontStyle: FontStyle.italic,
                    shadows: [
                      BoxShadow(
                          color: Colors.black.withOpacity(1.0), blurRadius: 15),
                    ],
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

  // ═══════════════════════════════════════════════════
  // İÇERİK BÖLÜMÜ
  // ═══════════════════════════════════════════════════
  Widget _buildContentSection(final BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? 20 : 50,
        vertical: context.isMobile ? 32 : 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCreativeTeamSection(context),
          const SizedBox(height: 40),
          _buildResponsiveGameDetails(context),
          const SizedBox(height: 40),
          _buildTechnicalTeam(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // YARATICI EKİP (Modern Card Design)
  // ═══════════════════════════════════════════════════
  Widget _buildCreativeTeamSection(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: WebColors.goldGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.stars,
                color: WebColors.darkBlueBackground,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (final bounds) =>
                  WebColors.goldGradient.createShader(bounds),
              child: Text(
                'YARATICI EKİP',
                style: TextStyle(
                  fontSize: context.responsive(mobile: 20, desktop: 26),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        context.isMobile
            ? _buildCreativeTeamMobile(context)
            : _buildCreativeTeamDesktop(context),
      ],
    );
  }

  Widget _buildCreativeTeamDesktop(final BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildModernTeamCard(
            context: context,
            role: 'YAZAN',
            name: 'HALDUN TANER',
            icon: Icons.edit_outlined,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildModernTeamCard(
            context: context,
            role: 'YÖNETMEN',
            name: 'EFSUN KAYGUSUZ',
            icon: Icons.theater_comedy_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildCreativeTeamMobile(final BuildContext context) {
    return Column(
      children: [
        _buildModernTeamCard(
          context: context,
          role: 'YAZAN',
          name: 'HALDUN TANER',
          icon: Icons.edit_outlined,
        ),
        const SizedBox(height: 16),
        _buildModernTeamCard(
          context: context,
          role: 'YÖNETMEN',
          name: 'EFSUN KAYGUSUZ',
          icon: Icons.theater_comedy_outlined,
        ),
      ],
    );
  }

  Widget _buildModernTeamCard({
    required final BuildContext context,
    required final String role,
    required final String name,
    required final IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WebColors.primaryGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: WebColors.primaryGold.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: WebColors.darkBlueBackground, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: TextStyle(
                  fontSize: 11,
                  color: WebColors.primaryGoldLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  fontSize: context.isMobile ? 15 : 17,
                  fontWeight: FontWeight.w800,
                  color: WebColors.whiteText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // OYUN DETAYLARI (Responsive)
  // ═══════════════════════════════════════════════════
  Widget _buildResponsiveGameDetails(final BuildContext context) {
    if (context.isMobile) {
      return Column(
        children: [
          _buildSecondImageManifesto(context, isMobile: true),
          const SizedBox(height: 24),
          _buildAboutSection(context),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: _buildAboutSection(context)),
          const SizedBox(width: 32),
          Expanded(flex: 5, child: _buildSecondImageManifesto(context)),
        ],
      );
    }
  }

  Widget _buildSecondImageManifesto(final BuildContext context,
      {final bool isMobile = false}) {
    return Container(
      height: isMobile ? 350 : 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: WebColors.primaryGold.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(_secondImage, fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    WebColors.darkBlueBackground.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: isMobile ? 50 : 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HANGİ GÖZ DAHA KÖRDÜR?',
                  style: TextStyle(
                    fontSize: context.responsive(mobile: 14.0, desktop: 16.0),
                    color: WebColors.warning,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '"Körlüğe terfi etmek mi, gerçeğe mahkum olmak mı? Bir tercihin anatomisi."',
                  style: TextStyle(
                    fontSize: context.responsive(mobile: 18.0, desktop: 24.0),
                    color: WebColors.primaryGoldLight,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // OYUN HAKKINDA (Modern Card)
  // ═══════════════════════════════════════════════════
  Widget _buildAboutSection(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WebColors.primaryGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: WebColors.goldGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'OYUN HAKKINDA',
                style: TextStyle(
                  fontSize: context.responsive(mobile: 18.0, desktop: 22.0),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildContentParagraph(
            context,
            'Haldun Taner\'in bu iki perdelik oyunu, Türkiye\'nin yaklaşık 70 yıllık siyasi, ekonomik ve toplumsal durumunu birbirine zıt iki kimlik üzerinden ele alarak, toplumumuza bir ayna tutuyor.',
          ),
          const SizedBox(height: 12),
          _buildContentParagraph(
            context,
            'Vicdani (Saf ve Dürüst) ile Efruz (Köşe Dönücü ve Fırsatçı) arasındaki çatışma, devleti sömürenler ve itaat edenler arasındaki dengesizliği gözler önüne seriyor.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: WebColors.primaryGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.format_quote,
                  color: WebColors.primaryGold.withOpacity(0.6),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '"Gözlerimi Kaparım Vazifemi Yaparım" aynı zamanda değişen toplumsal değerleri ve bireyin bu değişim karşısındaki duruşunu mizahi bir dille sorguluyor.',
                    style: TextStyle(
                      fontSize: context.isMobile ? 13 : 14,
                      color: WebColors.primaryGoldLight,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentParagraph(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: context.isMobile ? 13 : 14,
        color: WebColors.lightWhite.withOpacity(0.9),
        height: 1.6,
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TEKNİK EKİP (Compact & Clean)
  // ═══════════════════════════════════════════════════
  Widget _buildTechnicalTeam(final BuildContext context) {
    final List<Map<String, String>> crew = [
      {'role': 'Işık Tasarımı', 'name': 'Emre Kahraman'},
      {'role': 'Ses & Efekt', 'name': 'Gökhan Şener'},
      {'role': 'Afiş Tasarımı', 'name': 'Tayfun Kızıldağ'},
      {'role': 'Dansçı', 'name': 'Burcu Koçyiğit'},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WebColors.primaryGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: WebColors.goldGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'TEKNİK EKİP',
                style: TextStyle(
                  fontSize: context.responsive(mobile: 18.0, desktop: 22.0),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: context.isMobile ? 16 : 24,
            runSpacing: 12,
            children: crew.map((member) {
              return _buildCrewMember(
                context,
                member['role']!,
                member['name']!,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCrewMember(BuildContext context, String role, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: TextStyle(
                  fontSize: 10,
                  color: WebColors.primaryGoldLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  fontSize: context.isMobile ? 12 : 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
