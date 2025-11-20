import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import '../../../../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM LANDING - CANLANDIRILMIŞ VERSİYON
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

  // ---------------- ANA BAŞLIK BÖLÜMÜ (UYUMLU) ----------------
  Widget _buildTopHeader(final BuildContext context) {
    return Container(
      width: double.infinity,
      padding: context.paddingAll,
      decoration: const BoxDecoration(
        gradient: WebColors.backgroundGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BAŞLIK
          ShaderMask(
            shaderCallback: (final bounds) =>
                WebColors.goldGradient.createShader(bounds),
            child: Text(
              'GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM',
              style: TextStyle(
                fontSize: context.responsive(mobile: 30.0, desktop: 48.0),
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // KONUM KARTI
          _buildLocationCard(context, '1889 SES TİYATROSU', '(TAKSİM)'),
          const SizedBox(height: 16),
          // AYRAÇ
          _buildDivider(),
        ],
      ),
    );
  }

  // ---------------- MERKEZ GÖRSELİ (DRAMATİK) ----------------
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
          // ✅ Siyaha Çalan Güçlü Gradient (Okunabilirlik İçin)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    // Üstten hafif siyah
                    WebColors.darkBlueBackground.withOpacity(0.9),
                    // Alttan koyu
                  ],
                ),
              ),
            ),
          ),
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

  // ---------------- İÇERİK BÖLÜMÜ (YARATICI EKİP + OYUN BÖLÜMÜ) ----------------
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
          // YARATICI EKİP
          _buildCreativeTeamSection(context),

          const SizedBox(height: 40),

          // AYRAÇ
          _buildDivider(),
          const SizedBox(height: 40),

          // ✅ RESPONSIVE OYUN/EKİP BÖLÜMÜ (2. Görsel ile Metin Birleşimi)
          _buildResponsiveGameDetails(context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------- RESPONSIVE OYUN DETAYLARI ----------------
  Widget _buildResponsiveGameDetails(final BuildContext context) {
    // Mobil: Görsel ve metin alt alta
    if (context.isMobile) {
      return Column(
        children: [
          _buildSecondImageManifesto(context, isMobile: true),
          const SizedBox(height: 30),
          _buildTextContentAndCrew(context),
        ],
      );
    }
    // Masaüstü: Görsel ve metin yan yana
    else {
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

  // ✅ 2. GÖRSELİ MANİFESTOYA ÇEVİREN YENİ WIDGET
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
          // Görsel
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                _secondImage,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient Overlay (Daha Opak)
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
          // Manifesto Metni
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

  // ✅ OYUN METNİ VE EKİP LİSTESİNİ İÇEREN YENİ WIDGET
  Widget _buildTextContentAndCrew(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'OYUN HAKKINDA'),
        const SizedBox(height: 20),
        // Ana Metin
        _buildParagraph(
          context,
          'Haldun Taner\'in bu iki perdelik oyunu, Türkiye\'nin yaklaşık 70 yıllık siyasi, ekonomik ve toplumsal durumunu birbirine zıt iki kimlik üzerinden ele alarak, toplumumuza bir ayna tutuyor. Vicdani (Saf ve Dürüst) ile Efruz (Köşe Dönücü ve Fırsatçı) arasındaki çatışma, devleti sömürenler ve itaat edenler arasındaki dengesizliği gözler önüne seriyor.',
        ),
        const SizedBox(height: 16),
        // Vurgulu Metin
        _buildParagraph(
          context,
          '"Gözlerimi Kaparım Vazifemi Yaparım" aynı zamanda değişen toplumsal değerleri ve bireyin bu değişim karşısındaki duruşunu mizahi bir dille sorguluyor.',
          isEmphasis: true,
        ),
        const SizedBox(height: 40),
        // Ekip Kutusu artık burada
        _buildOtherCrewBox(context),
      ],
    );
  }

  // ---------------- YARATICI EKİP BÖLÜMÜ (YENİ STİL VE TUTARLI AYRAÇ) ----------------
  Widget _buildCreativeTeamSection(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BAŞLIK - Altın gradient
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
        // Sarı Ayraç (Tutarlı)
        Container(
          height: 3,
          width: 80,
          decoration: const BoxDecoration(
            gradient: WebColors.goldGradient,
          ),
        ),
        const SizedBox(height: 30),

        // YAZAR VE YÖNETMEN KARTLARI
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

  // ✅ YENİ YARDIMCI METOT: Creative Team Kart Stili (Elevation/Derinlik Eklendi)
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
        // ✅ GÖLGELER VE DERİNLİK EFEKTİ EKLENDİ
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
          // İKON
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
              // ROL
              Text(
                role,
                style: TextStyle(
                  fontSize: context.captionSize,
                  color: WebColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // İSİM
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

  // ---------------- YARDIMCI WIDGETLAR ----------------

  // Başlık stilini korur
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

  // Paragraf stili (Hakkımızda kartından uyarlanmıştır)
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

  // Konum Kartı (Aynı kalır)
  Widget _buildLocationCard(
      final BuildContext context, final String title, final String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: WebColors.goldGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: WebColors.primaryGold.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded,
              color: WebColors.darkBlueBackground, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.responsive(
                        mobile: 14.0, desktop: context.subtitleSize),
                    fontWeight: FontWeight.w900,
                    color: WebColors.darkBlueBackground,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: context.bodySize,
                    color: WebColors.darkBlueSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Diğer Ekip Kutusu (Yeni konuma taşındı, stili güncellendi)
  Widget _buildOtherCrewBox(final BuildContext context) {
    return Container(
      padding: context.responsive(
          mobile: const EdgeInsets.all(20), desktop: const EdgeInsets.all(28)),
      decoration: BoxDecoration(
          color: WebColors.darkBlueSurface.withOpacity(0.9), // Daha opak
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: WebColors.primaryGold.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: WebColors.primaryGold.withOpacity(0.15),
              blurRadius: 15,
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BAŞLIK
          Text(
            'OYUN EKİBİ',
            style: TextStyle(
              fontSize: context.subtitleSize,
              fontWeight: FontWeight.w900,
              color: WebColors.primaryGoldLight,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _buildDivider(), // Başlık altı ayraç
          const SizedBox(height: 16),

          // Liste Elemanları
          _buildCrewMember(context, 'Işık Tasarımı', 'Emre Kahraman'),
          _buildCrewMember(context, 'Ses & Efekt', 'Gökhan Şener'),
          _buildCrewMember(context, 'Afiş Tasarımı', 'Tayfun Kızıldağ'),
          _buildCrewMember(context, 'Dansçı', 'Burcu Koçyiğit'),
        ],
      ),
    );
  }

  // Ekip Üyesi Satırı (Stil korundu)
  Widget _buildCrewMember(
      final BuildContext context, final String role, final String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sarı Madde İşareti
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: WebColors.primaryGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: context.bodySize,
                  color: WebColors.lightWhite,
                  height: 1.5,
                ),
                children: [
                  // ROL: Kalın ve Sarımsı Altın Renk
                  TextSpan(
                    text: '$role: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: WebColors.primaryGoldLight,
                    ),
                  ),
                  // İSİM: Normal Beyaz Renk
                  TextSpan(
                      text: name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: WebColors.lightWhite,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Tutarlı Ayraç (Divider) Metodu
  Widget _buildDivider() {
    return Container(
      height: 2,
      decoration: BoxDecoration(
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
