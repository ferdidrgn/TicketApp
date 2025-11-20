import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import '../../../../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM LANDING - SON REVİZYON (YAZAR/YÖNETMEN TEK NOKTADA)
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

  // ---------------- ANA BAŞLIK BÖLÜMÜ (ORTALANMIŞ) ----------------
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
          // BAŞLIK
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
          // Konum bilgisi
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

  Widget _buildMainImageSection(final BuildContext context) {
    return Container(
      height: context.responsive(mobile: 350.0, desktop: 500.0),
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              _mainImage,
              fit: BoxFit.cover,
            ),
          ),
          // Siyaha ve Hafif Sarı Işığa Çalan Gradient (Dramatik Görünüm)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
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

          // ✅ SOL ÜST KÖŞE: YAZAR ve YÖNETMEN (Alt Alta)
          Positioned(
            top: context.responsive(mobile: 20.0, desktop: 40.0),
            left: context.responsive(mobile: 20.0, desktop: 40.0),
            child: _buildCreatorInfoBox(context), // Yazar/Yönetmen burada
          ),

          // Alıntı Metni
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: Text(
              '"Türkiye’nin 70 yıllık siyasi ve toplumsal durumu üzerine hiciv dolu bir ayna."',
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
          ),
        ],
      ),
    );
  }

  // ✅ YENİ: Yazar ve Yönetmen Bilgisini Alt Alta Tutacak Kutu
  Widget _buildCreatorInfoBox(final BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive(mobile: 16.0, desktop: 20.0)),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.95), // Koyu zemin
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: WebColors.primaryGold.withOpacity(0.8),
            width: 3), // Kalın altın çerçeve
        boxShadow: [
          BoxShadow(
            color: WebColors.primaryGold.withOpacity(0.5),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // İçeriğe göre boyut
        children: [
          // 1. YAZAR
          _buildCreatorLine(
            context,
            role: 'YAZAN',
            name: 'HALDUN TANER',
            icon: Icons.edit_outlined,
            isPrimary: true,
          ),
          const SizedBox(height: 12), // ✅ Hafif boşluk
          // 2. YÖNETMEN
          _buildCreatorLine(
            context,
            role: 'YÖNETMEN',
            name: 'EFSUN KAYGUSUZ',
            icon: Icons.theater_comedy_outlined,
            isPrimary: false,
          ),
        ],
      ),
    );
  }

  // ✅ YENİ YARDIMCI: Tek bir yazar/yönetmen satırı
  Widget _buildCreatorLine(
    final BuildContext context, {
    required final String role,
    required final String name,
    required final IconData icon,
    required final bool isPrimary,
  }) {
    final double nameSize = context.responsive(mobile: 16.0, desktop: 20.0);
    final double roleSize = context.responsive(mobile: 12.0, desktop: 14.0);
    final double iconSize = context.responsive(mobile: 20.0, desktop: 24.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // İKON KUTUSU (Altın Vurgu)
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: WebColors.goldGradient,
            borderRadius: BorderRadius.circular(6),
          ),
          child:
              Icon(icon, color: WebColors.darkBlueBackground, size: iconSize),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role,
              style: TextStyle(
                fontSize: roleSize,
                fontWeight: FontWeight.w600,
                color: WebColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: isPrimary ? nameSize : nameSize - 2,
                fontWeight: isPrimary ? FontWeight.w900 : FontWeight.w800,
                color: WebColors.primaryGoldLight,
                letterSpacing: 1.2,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
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
          // Alt alta sade akış
          _buildDivider(),
          const SizedBox(height: 40),
          _buildResponsiveGameDetails(context),
          const SizedBox(height: 40),
          _buildDivider(),
          const SizedBox(height: 40),
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

  // ---------------- OYUN METNİ VE İKİNCİ GÖRSEL ----------------

  Widget _buildSecondImageManifesto(final BuildContext context,
      {final bool isMobile = false}) {
    // Aynı kalır
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
              child: Image.network(
                _secondImage,
                fit: BoxFit.cover,
              ),
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
                  'TOPLUMSAL VİCDANIN İKİ YÜZÜ:',
                  style: TextStyle(
                    fontSize: context.responsive(mobile: 14.0, desktop: 16.0),
                    color: WebColors.warning,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '"Körlükle kazanılan zenginlik ve dürüstlükle kaybedilen hayatlar."',
                  style: TextStyle(
                    fontSize: context.responsive(mobile: 20.0, desktop: 28.0),
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
          decoration: const BoxDecoration(
            gradient: WebColors.goldGradient,
          ),
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

  // ---------------- TEKNİK EKİP KUTUSU ----------------
  Widget _buildOtherCrewBox(final BuildContext context) {
    final crewList = [
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
          Text(
            'TEKNİK EKİP',
            style: TextStyle(
              fontSize: context.subtitleSize,
              fontWeight: FontWeight.w900,
              color: WebColors.primaryGoldLight,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),
          Wrap(
            spacing: context.responsive(mobile: 10.0, desktop: 25.0),
            runSpacing: 10,
            children: crewList.map((final crew) {
              return _buildCrewMember(context, crew['role']!, crew['name']!);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------- YARDIMCI WIDGETLAR ----------------

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
