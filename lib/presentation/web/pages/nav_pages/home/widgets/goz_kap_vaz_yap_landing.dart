import 'package:flutter/material.dart';

// Ses çalmak için kütüphane import edilmeli
import 'package:audioplayers/audioplayers.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/record_card.dart';
import '../../../../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM LANDING (FİNAL)
// ═══════════════════════════════════════════════════════════
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

  // ---------------- ANA BAŞLIK BÖLÜMÜ ----------------
  Widget _buildTopHeader(final BuildContext context) {
    return Container(
      width: double.infinity,
      padding: context.paddingAll,
      decoration: const BoxDecoration(
        gradient: WebColors.backgroundGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (final bounds) =>
                WebColors.goldGradient.createShader(bounds),
            child: Text(
              'GÖZLERİMİ KAPARIM\nVAZİFEMİ YAPARIM',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.responsive(mobile: 30.0, desktop: 48.0),
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '1889 SES TİYATROSU (TAKSİM)',
            style: TextStyle(
              fontSize: context.bodySize + 2,
              fontWeight: FontWeight.w600,
              color: WebColors.primaryGoldLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildDivider(),
        ],
      ),
    );
  }

// ---------------- MERKEZ GÖRSELİ (DÖNEN PLAK / 399 NUMARA) ----------------
  Widget _buildMainImageSection(final BuildContext context) {
    return Container(
      height: context.responsive(mobile: 350.0, desktop: 500.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: WebColors.darkBlueBackground,
        boxShadow: [
          BoxShadow(
            // İkinci görselin gölge stili
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

          // ✅ SAĞ ÜST KÖŞE: Dönen Plak / 399 Numara
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

  // ---------------- İÇERİK BÖLÜMÜ ----------------
  Widget _buildContentSection(final BuildContext context) {
    return Container(
      width: double.infinity,
      padding: context.paddingAll,
      decoration: const BoxDecoration(
        gradient: WebColors.backgroundGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDivider(),
          const SizedBox(height: 40),
          _buildCreativeTeamSection(context),
          const SizedBox(height: 40),
          _buildResponsiveGameDetails(context),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildOtherCrewBox(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------- RESPONSIVE OYUN DETAYLARI ----------------
  Widget _buildResponsiveGameDetails(final BuildContext context) {
    if (context.isMobile) {
      return Column(
        children: [
          _buildSecondImageManifesto(context, isMobile: true),
          const SizedBox(height: 30),
          _buildTextContentAndCrew(context),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: _buildTextContentAndCrew(context)),
          const SizedBox(width: 40),
          Expanded(flex: 5, child: _buildSecondImageManifesto(context)),
        ],
      );
    }
  }

  // ---------------- YARATICI EKİP BÖLÜMÜ ----------------
  Widget _buildCreativeTeamSection(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (final bounds) =>
              WebColors.goldGradient.createShader(bounds),
          child: Text(
            'YARATICI EKİP',
            style: TextStyle(
              fontSize: context.responsive(mobile: 20, desktop: 28),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 3,
          width: 80,
          decoration: const BoxDecoration(gradient: WebColors.goldGradient),
        ),
        const SizedBox(height: 30),
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
          child: _buildTeamMemberCard(
            context: context,
            role: 'YAZAN',
            name: 'HALDUN TANER',
            icon: Icons.edit_outlined,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildTeamMemberCard(
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
        _buildTeamMemberCard(
          context: context,
          role: 'YAZAN',
          name: 'HALDUN TANER',
          icon: Icons.edit_outlined,
        ),
        const SizedBox(height: 16),
        _buildTeamMemberCard(
          context: context,
          role: 'YÖNETMEN',
          name: 'EFSUN KAYGUSUZ',
          icon: Icons.theater_comedy_outlined,
        ),
      ],
    );
  }

  // ---------------- YARDIMCI METOTLAR ----------------
  Widget _buildTeamMemberCard({
    required final BuildContext context,
    required final String role,
    required final String name,
    required final IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: WebColors.primaryGold.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: WebColors.primaryGold.withOpacity(0.2),
            blurRadius: 25,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient,
              borderRadius: BorderRadius.circular(10),
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
                  fontSize: context.captionSize,
                  color: WebColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  fontSize: context.bodySize + 2,
                  fontWeight: FontWeight.w900,
                  color: WebColors.whiteText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildTextContentAndCrew(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'OYUN HAKKINDA'),
        const SizedBox(height: 10),
        Container(
          height: 3,
          width: 80,
          decoration: const BoxDecoration(gradient: WebColors.goldGradient),
        ),
        const SizedBox(height: 20),
        _buildParagraph(
          context,
          'Haldun Taner\'in bu iki perdelik oyunu, Türkiye\'nin yaklaşık 70 yıllık siyasi, ekonomik ve toplumsal durumunu birbirine zıt iki kimlik üzerinden ele alarak, toplumumuza bir ayna tutuyor. Vicdani (Saf ve Dürüst) ile Efruz (Köşe Dönücü ve Fırsatçı) arasındaki çatışma, devleti sömürenler ve itaat edenler arasındaki dengesizliği gözler önüne seriyor.',
        ),
        const SizedBox(height: 16),
        _buildParagraph(
          context,
          '"Gözlerimi Kaparım Vazifemi Yaparım" aynı zamanda değişen toplumsal değerleri ve bireyin bu değişim karşısındaki duruşunu mizahi bir dille sorguluyor.',
          isEmphasis: true,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildOtherCrewBox(final BuildContext context) {
    final List<Map<String, dynamic>> crewList = [
      {'role': 'Işık Tasarımı', 'name': 'Emre Kahraman'},
      {'role': 'Ses & Efekt', 'name': 'Gökhan Şener'},
      {'role': 'Afiş Tasarımı', 'name': 'Tayfun Kızıldağ'},
      {'role': 'Dansçı', 'name': 'Burcu Koçyiğit'},
    ];

    return Container(
      padding: context.responsive(
          mobile: const EdgeInsets.all(20), desktop: const EdgeInsets.all(28)),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: WebColors.primaryGold.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: WebColors.primaryGold.withOpacity(0.15),
            blurRadius: 15,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'TEKNİK EKİP'),
          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),
          Wrap(
            spacing: context.responsive(mobile: 10.0, desktop: 25.0),
            runSpacing: 10,
            children: crewList.map((final crew) {
              return _buildCrewMember(
                  context, crew['role']! as String, crew['name']! as String);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(final BuildContext context, final String title) {
    return ShaderMask(
      shaderCallback: (final bounds) =>
          WebColors.goldGradient.createShader(bounds),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.responsive(mobile: 20.0, desktop: 28.0),
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildParagraph(final BuildContext context, final String text,
      {final bool isEmphasis = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(isEmphasis ? 0.4 : 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WebColors.primaryGold.withOpacity(isEmphasis ? 0.5 : 0.2),
          width: isEmphasis ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 16),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              gradient: WebColors.goldGradient,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: context.bodySize,
                color: WebColors.lightWhite,
                height: 1.8,
                fontStyle: isEmphasis ? FontStyle.italic : FontStyle.normal,
                fontWeight: isEmphasis ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrewMember(
      final BuildContext context, final String role, final String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: context.bodySize - 1,
            color: WebColors.lightWhite,
            height: 1.5,
          ),
          children: [
            const TextSpan(
              text: '• ',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: WebColors.primaryGold,
              ),
            ),
            TextSpan(
              text: '$role: ',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: WebColors.primaryGoldLight,
              ),
            ),
            TextSpan(
                text: name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: WebColors.lightWhite,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            WebColors.primaryGold,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
