import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM LANDING (YENİ TASARIM)
// ═══════════════════════════════════════════════════════════
class GozYapVazYapLanding extends StatelessWidget {
  const GozYapVazYapLanding({super.key});

  // Merkezi, güçlü bir görsel seçildi (örneğin ana afiş)
  static const String _mainImage =
      'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_165452.jpg?alt=media&token=1ebd1bc9-0df5-46fd-bce5-b7400d5d81ae';

  @override
  Widget build(final BuildContext context) {
    // Scaffold KALDIRILDI ve Container kullanıldı.
    return Container(
      color: WebColors.darkBlueBackground,
      child: Column(
        children: [
          // 1. ÜST BAŞLIK VE GİRİŞ BİLGİLERİ
          _buildTopHeader(context),

          // 2. TEK VE GÜÇLÜ MERKEZ GÖRSEL
          _buildMainImageSection(context),

          // 3. DETAYLI İÇERİK VE EKİP
          _buildContentSection(context),
        ],
      ),
    );
  }

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
          // Ana Başlık
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
          const SizedBox(height: 16),
          // Konum Kartı
          _buildLocationCard(context, '1889 SES TİYATROSU', '(TAKSİM)'),
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
          // Merkezi Görsel
          Positioned.fill(
            child: Image.network(
              _mainImage,
              fit: BoxFit.cover,
            ),
          ),
          // Dramatik Gölge
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
          // Vurgu Metni
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
          // Yazar/Yönetmen (Daha vurgulu kartlar)
          _buildSymbolicCrewCard(context, 'Yazan', 'Haldun Taner', Icons.book),
          _buildSymbolicCrewCard(context, 'Yönetmen', 'Efsun Kaygusuz',
              Icons.theater_comedy_rounded),

          const SizedBox(height: 32),

          // Açıklama
          Text(
            'Haldun Taner\'in bu iki perdelik oyunu, Türkiye\'nin yaklaşık 70 yıllık siyasi, ekonomik ve toplumsal durumunu birbirine zıt iki kimlik üzerinden ele alarak, toplumumuza bir ayna tutuyor.',
            style: TextStyle(
              fontSize: context.bodySize,
              color: WebColors.lightWhite,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 20),

          // Zıtlık Vurgusu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WebColors.darkBlueSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Vicdani (Saf ve Dürüst) ile Efruz (Köşe Dönücü ve Fırsatçı) arasındaki çatışma, devleti sömürenler ve itaat edenler arasındaki dengesizliği gözler önüne seriyor.',
              style: TextStyle(
                fontSize: context.bodySize,
                color: WebColors.textSecondary,
                height: 1.7,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          const SizedBox(height: 32),

          _buildDivider(),

          const SizedBox(height: 32),

          // Ekip Kutu
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: WebColors.darkBlueAccent.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DİĞER EKİP',
                  style: TextStyle(
                    fontSize: context.subtitleSize,
                    fontWeight: FontWeight.bold,
                    color: WebColors.primaryGold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCrewMember(context, 'Işık Tasarımı', 'Emre Kahraman'),
                _buildCrewMember(context, 'Ses & Efekt', 'Gökhan Şener'),
                _buildCrewMember(context, 'Afiş Tasarımı', 'Tayfun Kızıldağ'),
                _buildCrewMember(context, 'Dansçı', 'Burcu Koçyiğit'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Yardımcı Widgetlar (Önceki yanıtta detayları verilenler)

  Widget _buildLocationCard(
      final BuildContext context, final String title, final String subtitle) {
    // ... (Önceki kodunuzdaki altın renkli konum kartı)
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: context.subtitleSize,
                  fontWeight: FontWeight.bold,
                  color: WebColors.darkBlueBackground,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: context.bodySize,
                  color: WebColors.darkBlueSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
          Icon(icon, color: WebColors.primaryGold, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: TextStyle(
                  fontSize: context.captionSize,
                  color: WebColors.textSecondary,
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  fontSize: context.bodySize + 2,
                  fontWeight: FontWeight.bold,
                  color: WebColors.whiteText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCrewMember(
      final BuildContext context, final String role, final String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
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
                    fontSize: context.bodySize, color: WebColors.lightWhite),
                children: [
                  TextSpan(
                    text: '$role: ',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: WebColors.primaryGoldLight),
                  ),
                  TextSpan(text: name),
                ],
              ),
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
