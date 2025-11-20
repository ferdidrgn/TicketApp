import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// 1. GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM LANDING
// ═══════════════════════════════════════════════════════════
class GozYapVazYapLanding extends StatelessWidget {
  const GozYapVazYapLanding({super.key});

  // Eskiden kullanılan görseller
  static const String _imageLeftTop =
      'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_165452.jpg?alt=media&token=1ebd1bc9-0df5-46fd-bce5-b7400d5d81ae';
  static const String _imageRightBottom =
      'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgözKapVazYap%2F20220610_174009.jpg?alt=media&token=40652d5a-31fe-4dec-9df1-61e516dfda27';

  @override
  Widget build(final BuildContext context) {
    // Scaffold KALDIRILDI, Container kullanıldı
    return Container(
      color: WebColors.darkBlueBackground,
      child: context.isMobile ? _buildMobile(context) : _buildDesktop(context),
    );
  }

  Widget _buildMobile(final BuildContext context) {
    // SingleChildScrollView KALDIRILDI, ana sayfa zaten scroll ediyor.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageCard(context, _imageLeftTop,
            height: context.screenHeight * 0.4),
        _buildContentSection(context),
        _buildImageCard(context, _imageRightBottom,
            height: context.screenHeight * 0.4),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDesktop(final BuildContext context) {
    // Tablet/Desktop ayrımı yerine responsive utils kullanıldı
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildImageCard(context, _imageLeftTop,
              height: context.screenHeight),
        ),
        Expanded(
          flex: 4,
          child: _buildContentSection(context),
        ),
        Expanded(
          flex: 3,
          child: _buildImageCard(context, _imageRightBottom,
              height: context.screenHeight),
        ),
      ],
    );
  }

  Widget _buildImageCard(final BuildContext context, final String url,
      {required final double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          // Karanlık overlay eklendi (Mevcut UI'a uyum)
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              WebColors.darkBlueBackground.withOpacity(0.4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection(final BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: WebColors.backgroundGradient,
      ),
      padding: context.paddingAll,
      // İç scroll kaldırıldı, ana sayfa scroll ediyor
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          ShaderMask(
            shaderCallback: (final bounds) =>
                WebColors.goldGradient.createShader(bounds),
            child: Text(
              'GÖZLERİMİ KAPARIM VAZİFEMİ YAPARIM',
              style: TextStyle(
                fontSize: context.titleSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Konum Kartı
          _buildLocationCard(context, '1889 SES TİYATROSU', '(TAKSİM)'),

          const SizedBox(height: 32),

          // Yazar / Yönetmen Bilgisi
          _buildCrewInfo(context, 'Yazan', 'Haldun Taner', Icons.create),
          const SizedBox(height: 16),
          _buildCrewInfo(
              context, 'Yönetmen', 'Efsun Kaygusuz', Icons.theater_comedy),

          const SizedBox(height: 32),

          _buildDivider(),

          const SizedBox(height: 32),

          // Açıklama
          Text(
            'Haldun Taner\'in bu iki perdelik oyunu, Türkiye\'nin yaklaşık 70 yıllık siyasi, ekonomik ve toplumsal durumunu birbirine zıt iki kimlik üzerinden ele alarak, toplumumuza bir ayna tutuyor.',
            style: TextStyle(
              fontSize: context.bodySize,
              color: WebColors.lightWhite,
              height: 1.8,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'İki çocukluk arkadaşı olan baş karakterlerden Vicdani, saf, iyi niyetli, dürüst ve uysal bir kişiliğe sahipken; Efruz ise köşe dönücü, iş bitirici ve fırsatçı biridir. Oyun, bu karakterler üzerinden devleti sömürenler ile devlete itaat edenler arasındaki dengesizliği gözler önüne seriyor.',
            style: TextStyle(
              fontSize: context.bodySize,
              color: WebColors.textSecondary,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 32),

          // Ekip Kutu
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: WebColors.darkBlueAccent.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
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

  Widget _buildCrewInfo(final BuildContext context, final String role,
      final String name, final IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
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
