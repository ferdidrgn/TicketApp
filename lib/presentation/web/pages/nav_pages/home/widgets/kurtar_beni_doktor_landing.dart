import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import '../../../../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// 3. KURTAR BENİ DOKTOR LANDING
// ═══════════════════════════════════════════════════════════
class KurtarBeniDoktorLanding extends StatelessWidget {
  const KurtarBeniDoktorLanding({super.key});

  @override
  Widget build(final BuildContext context) {
    return Container(
      color: WebColors.darkBlueBackground,
      child: context.isMobile ? _buildMobile(context) : _buildDesktop(context),
    );
  }

  Widget _buildMobile(final BuildContext context) {
    return Column(
        children: [
          _buildHeader(context),
          _buildMainImage(context, height: context.screenHeight * 0.6),
          _buildContentMobile(context),
        ],
    );
  }

  Widget _buildDesktop(final BuildContext context) {
    return Row(
      children: [
        // Sol dekoratif bant
        Container(
          width: context.screenWidth * 0.06,
          decoration: BoxDecoration(
            gradient: WebColors.goldGradient,
          ),
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'SEVGİLİ DOKTOR',
                style: TextStyle(
                  fontSize: context.subtitleSize,
                  fontWeight: FontWeight.w900,
                  color: WebColors.darkBlueBackground,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ),

        // Orta görsel
        Expanded(
          flex: 6,
          child: _buildMainImage(context, height: context.screenHeight),
        ),

        // Sağ içerik
        Container(
          width: context.screenWidth * 0.25,
          decoration: const BoxDecoration(
            gradient: WebColors.backgroundGradient,
          ),
          child: _buildContentDesktop(context),
        ),
      ],
    );
  }

  Widget _buildHeader(final BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: WebColors.goldGradient,
      ),
      child: Text(
        'KURTAR BENİ DOKTOR',
        style: TextStyle(
          fontSize: context.titleSize,
          fontWeight: FontWeight.w900,
          color: WebColors.darkBlueBackground,
          letterSpacing: 2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMainImage(final BuildContext context,
      {required final double height}) {
    return Stack(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: Image.network(
            'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FkurtarBeniDoktor%2F21903122132.png?alt=media&token=21913d43-e257-45fb-8d2e-4d1065b0be8b',
            fit: BoxFit.cover,
            errorBuilder: (final context, final error, final stackTrace) {
              return Container(
                color: WebColors.darkBlueSurface,
                child: const Icon(Icons.image_not_supported, size: 80),
              );
            },
          ),
        ),

        // Overlay
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                WebColors.darkBlueBackground.withOpacity(0.6),
              ],
            ),
          ),
        ),

        // Quote
        if (!context.isMobile)
          Positioned(
            top: 40,
            left: 40,
            right: 40,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: WebColors.goldGradient.scale(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: WebColors.primaryGold.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Text(
                '"Yalnızlık bazen en iyi doktordur;\ninsan kendini o zaman daha iyi tanır."',
                style: TextStyle(
                  fontSize: context.bodySize + 2,
                  fontWeight: FontWeight.w600,
                  color: WebColors.darkBlueBackground,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        // Konum Badge
        Positioned(
          bottom: 30,
          left: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: WebColors.primaryGold.withOpacity(0.4),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Text(
              'KADIKÖY\n(İSTANBUL)',
              style: TextStyle(
                fontSize: context.subtitleSize,
                fontWeight: FontWeight.w900,
                color: WebColors.darkBlueBackground,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentMobile(final BuildContext context) {
    return Container(
      width: double.infinity,
      padding: context.paddingAll,
      decoration: const BoxDecoration(
        gradient: WebColors.backgroundGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'YAZAN - UYARLAYAN & YÖNETEN'),
          const SizedBox(height: 12),
          _buildInfoText(context, 'ANTON ÇEHOV\nİSKENDER ATİLLA ATASOY'),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'CAST'),
          const SizedBox(height: 16),
          _buildCastItem(
              context, 'Yönetmen Yardımcısı', 'UĞUR KILIÇ - EBRU AKGÜN'),
          _buildCastItem(context, 'Makyaj', 'DİALRA SEKMEN'),
          _buildCastItem(context, 'Kostüm', 'DERYA DİNÇER'),
          _buildCastItem(context, 'Işık', 'SEYİT ÇOLAK'),
          _buildCastItem(context, 'Asistan', 'DUYGU ŞAHİN'),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'OYUNCULAR'),
          const SizedBox(height: 16),
          ..._buildActorsList(context),
        ],
      ),
    );
  }

  Widget _buildContentDesktop(final BuildContext context) {
    return SingleChildScrollView(
      padding: context.paddingAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'YAZAN - UYARLAYAN & YÖNETEN'),
          const SizedBox(height: 12),
          _buildInfoText(context, 'ANTON ÇEHOV\nİSKENDER ATİLLA ATASOY'),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'CAST'),
          const SizedBox(height: 16),
          _buildCastItem(
              context, 'Yönetmen Yardımcısı', 'UĞUR KILIÇ\nEBRU AKGÜN'),
          _buildCastItem(context, 'Makyaj', 'DİALRA SEKMEN'),
          _buildCastItem(context, 'Kostüm', 'DERYA DİNÇER'),
          _buildCastItem(context, 'Işık', 'SEYİT ÇOLAK'),
          _buildCastItem(context, 'Asistan', 'DUYGU ŞAHİN'),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'OYUNCULAR'),
          const SizedBox(height: 16),
          ..._buildActorsList(context),
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
          fontSize: context.subtitleSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildInfoText(final BuildContext context, final String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: context.bodySize,
        color: WebColors.lightWhite,
        height: 1.6,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCastItem(
      final BuildContext context, final String role, final String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role,
              style: TextStyle(
                fontSize: context.captionSize,
                color: WebColors.primaryGoldLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: context.bodySize - 1,
                color: WebColors.whiteText,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActorsList(final BuildContext context) {
    final actors = [
      'ADEM SOY',
      'NEVZAT KAYAOKAY',
      'GÜRKAN CANDAN',
      'ZEYNEP ÜĞÜDÜR',
      'SİTEM ARSLAN GENÇ',
    ];

    return actors.map((final actor) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
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
            Text(
              actor,
              style: TextStyle(
                fontSize: context.bodySize - 1,
                color: WebColors.lightWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
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
