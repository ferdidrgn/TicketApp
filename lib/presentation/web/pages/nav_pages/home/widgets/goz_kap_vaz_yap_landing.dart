import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import '../../../../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM LANDING
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
      // ✅ Arka plan rengi (Görseldeki koyu lacivert)
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (final bounds) =>
                WebColors.goldGradient.createShader(bounds),
            child: Text(
              'GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM',
              style: TextStyle(
                fontSize: context.titleSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLocationCard(context, '1889 SES TİYATROSU', '(TAKSİM)'),
          const SizedBox(height: 16),
          _buildDivider(),
        ],
      ),
    );
  }

  // ---------------- MERKEZ GÖRSELİ ----------------
  Widget _buildMainImageSection(final BuildContext context) {
    // ... (Aynı kalır)
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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    WebColors.darkBlueBackground.withOpacity(0.4),
                    WebColors.darkBlueBackground.withOpacity(0.8),
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
                fontSize: context.subtitleSize,
                fontWeight: FontWeight.w500,
                color: WebColors.primaryGoldLight,
                fontStyle: FontStyle.italic,
                shadows: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.8), blurRadius: 10),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- İÇERİK BÖLÜMÜ (YÖNETMEN/EKİP/2.GÖRSEL) ----------------
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
          // Yazar/Yönetmen Kartları (Görseldeki yeni stile uyarlandı)
          _buildSymbolicCrewCard(context, 'Yazan', 'Haldun Taner', Icons.book),
          _buildSymbolicCrewCard(context, 'Yönetmen', 'Efsun Kaygusuz',
              Icons.theater_comedy_rounded),

          const SizedBox(height: 32),

          // Responsive olarak alt görsel ve metin yerleşimi
          _buildBottomResponsiveSection(context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------- RESPONSIVE ALT BÖLÜM (2. Görseli Yönetir) ----------------
  Widget _buildBottomResponsiveSection(final BuildContext context) {
    return context.isMobile
        ? _buildBottomMobile(context)
        : _buildBottomDesktop(context);
  }

  // --- 2.1 DESKTOP GÖRÜNÜMÜ (Görsel Üzeri Metin) ---
  Widget _buildBottomDesktop(final BuildContext context) {
    return Container(
      height: context.responsive(mobile: 350.0, desktop: 450.0),
      width: double.infinity,
      child: Stack(
        children: [
          // ... Görsel ve Gradient Overlay ...
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
                    Colors.black.withOpacity(0.5),
                    WebColors.darkBlueBackground.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
          // Metin ve Ekip Kutu İçeriği (Yazı stilleri güncellendi)
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HALDUN TANER CÜMLESİ
                Text(
                  'Haldun Taner\'in bu iki perdelik oyunu, Türkiye\'nin yaklaşık 70 yıllık siyasi, ekonomik ve toplumsal durumunu birbirine zıt iki kimlik üzerinden ele alarak, toplumumuza bir ayna tutuyor.',
                  style: TextStyle(
                    fontSize: context.bodySize,
                    color: WebColors.lightWhite, // ✅ lightWhite
                    height: 1.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Zıtlık Vurgusu
                Text(
                  'Vicdani (Saf ve Dürüst) ile Efruz (Köşe Dönücü ve Fırsatçı) arasındaki çatışma, devleti sömürenler ve itaat edenler arasındaki dengesizliği gözler önüne seriyor.',
                  style: TextStyle(
                    fontSize: context.bodySize,
                    color: WebColors.textSecondary,
                    height: 1.7,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),

                // Ekip Kutusu (Yeni stili kullanacak)
                _buildOtherCrewBox(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2.2 MOBİL GÖRÜNÜMÜ (Yeni Dramatik Stil) ---
  Widget _buildBottomMobile(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. METİN BLOKLARI
        Padding(
          padding: context.paddingHorizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HALDUN TANER CÜMLESİ
              Text(
                'Haldun Taner\'in bu iki perdelik oyunu, Türkiye\'nin yaklaşık 70 yıllık siyasi, ekonomik ve toplumsal durumunu birbirine zıt iki kimlik üzerinden ele alarak, toplumumuza bir ayna tutuyor.',
                style: TextStyle(
                  fontSize: context.bodySize,
                  color: WebColors.lightWhite,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Zıtlık Vurgusu
              Text(
                'Vicdani (Saf ve Dürüst) ile Efruz (Köşe Dönücü ve Fırsatçı) arasındaki çatışma, devleti sömürenler ve itaat edenler arasındaki dengesizliği gözler önüne seriyor.',
                style: TextStyle(
                  fontSize: context.bodySize,
                  color: WebColors.textSecondary,
                  height: 1.7,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 2. EKİP KUTUSU (Görseldeki stile göre güncellenmiş metot)
        Padding(
          padding: context.paddingHorizontal,
          child: _buildOtherCrewBox(context),
        ),

        const SizedBox(height: 40),

        // 3. İKİNCİ DRAMATİK GÖRSEL (Filigranlı ve Alıntılı)
        _buildDramaticSecondImage(context),

        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------- YARDIMCI WIDGETLAR (Yeni Tasarıma Uyarlandı) ----------------

  // ✅ Yazar/Yönetmen Kartları - Yeni stilde kalın çizgi ve ikon kullanımı
  Widget _buildSymbolicCrewCard(final BuildContext context, final String role,
      final String name, final IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // İKON (Altın renginde)
          Icon(icon, color: WebColors.primaryGold, size: 28),
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
                ),
              ),
              // İSİM (Kalın ve belirgin)
              Text(
                name,
                style: TextStyle(
                  fontSize: context.bodySize + 2,
                  fontWeight: FontWeight.w900, // ✅ Ekstra Kalın
                  color: WebColors.whiteText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Konum Kartı (Altın zeminli, aynı kalır)
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
                    fontWeight: FontWeight.w900, // ✅ Ekstra Kalın
                    color: WebColors.darkBlueBackground,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: context.bodySize,
                    color: WebColors.darkBlueSurface,
                    fontWeight: FontWeight.w600, // ✅ Kalınlaştırıldı
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DİĞER EKİP Kutusu - En son tasarımdaki siyah zemin, kalın başlık ve dolgu
  Widget _buildOtherCrewBox(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface, // Koyu mavi/gri zemin
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BAŞLIK
          Text(
            'DİĞER EKİP',
            style: TextStyle(
              fontSize: context.subtitleSize,
              fontWeight: FontWeight.w900, // ✅ Ekstra Kalın
              color: WebColors.primaryGold,
              letterSpacing: 2,
            ),
          ),
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

  // ✅ Ekip Üyesi Listesi - Altın nokta ve kalın rol metni
  Widget _buildCrewMember(
      final BuildContext context, final String role, final String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Altın Nokta
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: WebColors.primaryGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Rol ve İsmin birleştirilmesi
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
                      fontWeight: FontWeight.w800, // ✅ Kalın
                      color: WebColors.primaryGoldLight,
                    ),
                  ),
                  // İSİM: Normal beyaz renk
                  TextSpan(
                      text: name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500, // İsim de okunur olsun
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Dramatik İkinci Görsel Metodu (Görseldeki gibi)
  Widget _buildDramaticSecondImage(final BuildContext context) {
    return Container(
      height: context.screenHeight * 0.45,
      width: double.infinity,
      child: Stack(
        children: [
          // Arka Plan Görseli
          Positioned.fill(
            child: Image.network(
              _secondImage,
              fit: BoxFit.cover,
            ),
          ),
          // Siyah Filigran/Degrade
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    WebColors.darkBlueBackground.withOpacity(0.9),
                    // Koyu alt zemin
                  ],
                ),
              ),
            ),
          ),
          // Görsel üzerine alıntı
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: Text(
              '"Vicdani ve Efruz: İki Yüz, Tek Toplum."',
              style: TextStyle(
                fontSize: context.subtitleSize,
                color: WebColors.primaryGoldLight,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                shadows: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.9), blurRadius: 8),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

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
