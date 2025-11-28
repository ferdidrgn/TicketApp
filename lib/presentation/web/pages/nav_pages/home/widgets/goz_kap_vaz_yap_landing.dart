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

  // Teknik Ekip Listesi
  static const List<Map<String, String>> _techCrew = [
    {'role': 'Işık Tasarımı', 'name': 'Emre Kahraman'},
    {'role': 'Ses & Efekt', 'name': 'Gökhan Şener'},
    {'role': 'Afiş Tasarımı', 'name': 'Tayfun Kızıldağ'},
    {'role': 'Dansçı', 'name': 'Burcu Koçyiğit'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WebColors.darkBlueBackground,
      child: Column(
        children: [
          _buildHeader(context),
          _buildHeroSection(context),

          // İçerik Alanı
          Padding(
            padding: context.responsive(
              mobile: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              desktop: const EdgeInsets.symmetric(horizontal: 50, vertical: 48),
            ),
            child: context.isDesktop
                ? _buildDesktopContent(context)
                : _buildMobileContent(context),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // LAYOUT YAPILARI
  // ═══════════════════════════════════════════════════

  Widget _buildDesktopContent(BuildContext context) {
    return Column(
      children: [
        // Yeni tasarım entegre edildi
        _buildCreativeTeam(context, isRow: true),
        const SizedBox(height: 40),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _buildAboutSection(context)),
            const SizedBox(width: 32),
            Expanded(flex: 5, child: _buildSecondImageManifesto(context)),
          ],
        ),
        const SizedBox(height: 40),
        _buildTechnicalTeam(context),
      ],
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return Column(
      children: [
        // Yeni tasarım entegre edildi
        _buildCreativeTeam(context, isRow: false),
        const SizedBox(height: 24),
        _buildSecondImageManifesto(context),
        const SizedBox(height: 24),
        _buildAboutSection(context),
        const SizedBox(height: 24),
        _buildTechnicalTeam(context),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // YARATICI EKİP (GÜNCELLENEN KISIM)
  // ═══════════════════════════════════════════════════
  Widget _buildCreativeTeam(BuildContext context, {required bool isRow}) {
    // Senin tasarımını kullanan kartlar
    final writer =
        _buildSymbolicCrewCard(context, 'YAZAN', 'HALDUN TANER', Icons.book);
    final director = _buildSymbolicCrewCard(
        context, 'YÖNETMEN', 'EFSUN KAYGUSUZ', Icons.theater_comedy_rounded);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  gradient: WebColors.goldGradient,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.stars,
                  color: WebColors.darkBlueBackground, size: 20),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) =>
                  WebColors.goldGradient.createShader(bounds),
              child: Text(
                'YARATICI EKİP',
                style: TextStyle(
                  fontSize: context.responsive(mobile: 20.0, desktop: 26.0),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Layout mantığı
        isRow
            ? Row(children: [
                Expanded(child: writer),
                const SizedBox(width: 20),
                Expanded(child: director)
              ])
            : Column(children: [writer, const SizedBox(height: 16), director]),
      ],
    );
  }

  // ✅ SENİN TASARIMIN ENTEGRE EDİLDİ
  Widget _buildSymbolicCrewCard(
      BuildContext context, String role, String name, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      // Margin sadece dikeyde tutuldu
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // İkon Tasarımı
          Icon(icon, color: WebColors.primaryGold, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rol Tasarımı
              Text(role,
                  style: TextStyle(
                      fontSize: context.captionSize,
                      color: Colors
                          .white70 // Fallback to safe color or use WebColors.textSecondary if exists
                      )),
              // İsim Tasarımı (Extra Bold)
              Text(name,
                  style: TextStyle(
                      fontSize: context.bodySize + 2,
                      fontWeight: FontWeight.w900,
                      color: Colors
                          .white // Fallback to safe color or use WebColors.whiteText if exists
                      )),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // DİĞER BİLEŞENLER (MEVCUT RESPONSIVE YAPI)
  // ═══════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: context.responsive(
        mobile: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        desktop: const EdgeInsets.symmetric(horizontal: 50, vertical: 48),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.borderRadius(1.5)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: context.paddingAll,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04)
                ],
              ),
              borderRadius: BorderRadius.circular(context.borderRadius(1.5)),
              border: Border.all(
                  color: WebColors.primaryGold.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      WebColors.goldGradient.createShader(bounds),
                  child: Text(
                    'GÖZLERİMİ KAPARIM\nVAZİFEMİ YAPARIM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.responsive(mobile: 26.0, desktop: 40.0),
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
                        color: WebColors.primaryGold.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on,
                          color: WebColors.primaryGoldLight, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '1889 SES TİYATROSU (TAKSİM)',
                        style: TextStyle(
                          fontSize: context.captionSize + 2,
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

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      height: context.responsive(mobile: 350.0, desktop: 500.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: WebColors.darkBlueBackground,
        boxShadow: [
          BoxShadow(
              color: WebColors.primaryGold.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2)
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(_mainImage, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    WebColors.darkBlueBackground.withOpacity(0.9)
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
                          color: Colors.black.withOpacity(1.0), blurRadius: 15)
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

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
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
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Text(
                'OYUN HAKKINDA',
                style: TextStyle(
                    fontSize: context.responsive(mobile: 18.0, desktop: 22.0),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildText(context,
              'Haldun Taner\'in bu iki perdelik oyunu, Türkiye\'nin yaklaşık 70 yıllık siyasi, ekonomik ve toplumsal durumunu birbirine zıt iki kimlik üzerinden ele alarak, toplumumuza bir ayna tutuyor.'),
          const SizedBox(height: 12),
          _buildText(context,
              'Vicdani (Saf ve Dürüst) ile Efruz (Köşe Dönücü ve Fırsatçı) arasındaki çatışma, devleti sömürenler ve itaat edenler arasındaki dengesizliği gözler önüne seriyor.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.format_quote,
                    color: WebColors.primaryGold.withOpacity(0.6), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '"Gözlerimi Kaparım Vazifemi Yaparım" aynı zamanda değişen toplumsal değerleri ve bireyin bu değişim karşısındaki duruşunu mizahi bir dille sorguluyor.',
                    style: TextStyle(
                        fontSize: context.captionSize + 2,
                        color: WebColors.primaryGoldLight,
                        fontStyle: FontStyle.italic,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalTeam(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
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
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Text(
                'TEKNİK EKİP',
                style: TextStyle(
                    fontSize: context.responsive(mobile: 18.0, desktop: 22.0),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: context.responsive(mobile: 16.0, desktop: 24.0),
            runSpacing: 12,
            children: _techCrew
                .map((member) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  gradient: WebColors.goldGradient,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member['role']!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: WebColors.primaryGoldLight,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                              Text(member['name']!,
                                  style: TextStyle(
                                      fontSize: context.captionSize + 2,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondImageManifesto(BuildContext context) {
    final height = context.responsive(mobile: 350.0, desktop: 500.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: WebColors.primaryGold.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2)
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(_secondImage, fit: BoxFit.cover))),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    WebColors.darkBlueBackground.withOpacity(0.9)
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: context.responsive(mobile: 50.0, desktop: 80.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HANGİ GÖZ DAHA KÖRDÜR?',
                  style: TextStyle(
                      fontSize: context.responsive(mobile: 14.0, desktop: 16.0),
                      color: WebColors.warning,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Text(
                  '"Körlüğe terfi etmek mi, gerçeğe mahkum olmak mı? Bir tercihin anatomisi."',
                  style: TextStyle(
                      fontSize: context.responsive(mobile: 18.0, desktop: 24.0),
                      color: WebColors.primaryGoldLight,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
          fontSize: context.bodySize,
          color: Colors.white.withOpacity(0.9),
          height: 1.6),
    );
  }
}
