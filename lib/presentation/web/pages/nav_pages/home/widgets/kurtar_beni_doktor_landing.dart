import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

class KurtarBeniDoktorLanding extends StatelessWidget {
  const KurtarBeniDoktorLanding({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Container(
      color: WebColors.darkBlueBackground,
      child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHeader(isMobile: true),
        _buildMainVisual(isMobile: true),
        _buildQuoteSection(isMobile: true),
        _buildCreditsSection(isMobile: true),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sol - Dekoratif Bant
        Container(
          width: 80,
          color: WebColors.primaryGold,
          child: const Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'ANTON ÇEHOV',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: WebColors.darkBlueBackground,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ),
        // Orta - Görsel
        Expanded(
          flex: 5,
          child: _buildMainVisual(isMobile: false),
        ),
        // Sağ - İçerik
        SizedBox(
          width: 400,
          child: Container(
            color: WebColors.darkBlueSurface,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildQuoteSection(isMobile: false),
                  _buildCreditsSection(isMobile: false),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      color: WebColors.primaryGold,
      child: Text(
        'KURTAR BENİ DOKTOR',
        style: TextStyle(
          fontSize: isMobile ? 28 : 36,
          fontWeight: FontWeight.w900,
          color: WebColors.darkBlueBackground,
          letterSpacing: 3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMainVisual({required bool isMobile}) {
    return Stack(
      children: [
        SizedBox(
          height: isMobile ? 500 : 800,
          width: double.infinity,
          child: Image.network(
            'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FkurtarBeniDoktor%2F21903122132.png?alt=media&token=21913d43-e257-45fb-8d2e-4d1065b0be8b',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: WebColors.darkBlueAccent,
                child: const Center(
                  child: Icon(
                    Icons.theater_comedy,
                    size: 100,
                    color: WebColors.primaryGold,
                  ),
                ),
              );
            },
          ),
        ),
        // Gradient overlay
        Container(
          height: isMobile ? 500 : 800,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                WebColors.veryDarkBlue.withOpacity(0.7),
              ],
            ),
          ),
        ),
        // Konum badge
        Positioned(
          bottom: 32,
          left: 32,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: WebColors.primaryGold,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.location_on,
                        color: WebColors.darkBlueBackground, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'KADIKÖY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: WebColors.darkBlueBackground,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'İstanbul',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: WebColors.darkBlueBackground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteSection({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface,
        border: Border(
          bottom: BorderSide(
            color: WebColors.primaryGold.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const Text(
            '"',
            style: TextStyle(
              fontSize: 80,
              fontFamily: 'Georgia',
              color: WebColors.primaryGold,
              height: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Yalnızlık bazen en iyi doktordur;\ninsan kendini o zaman daha iyi tanır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              color: WebColors.lightWhite,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '"',
            style: TextStyle(
              fontSize: 80,
              fontFamily: 'Georgia',
              color: WebColors.primaryGold,
              height: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 150,
            height: 1,
            color: WebColors.primaryGold.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            '— Anton Çehov',
            style: TextStyle(
              fontSize: 14,
              color: WebColors.primaryGold,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsSection({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      color: WebColors.darkBlueSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('YAZAN - UYARLAYAN & YÖNETEN'),
          const SizedBox(height: 16),
          const Text(
            'ANTON ÇEHOV',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: WebColors.primaryGoldLight,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İSKENDER ATİLLA ATASOY',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: WebColors.lightWhite,
            ),
          ),
          const SizedBox(height: 32),
          _buildDivider(),
          const SizedBox(height: 32),
          _buildSectionTitle('YARATICI KADRO'),
          const SizedBox(height: 20),
          _buildCrewItem('Yönetmen Yardımcısı', 'UĞUR KILIÇ\nEBRU AKGÜN'),
          _buildCrewItem('Makyaj', 'DİALRA SEKMEN'),
          _buildCrewItem('Kostüm', 'DERYA DİNÇER'),
          _buildCrewItem('Işık', 'SEYİT ÇOLAK'),
          _buildCrewItem('Asistan', 'DUYGU ŞAHİN'),
          const SizedBox(height: 32),
          _buildDivider(),
          const SizedBox(height: 32),
          _buildSectionTitle('OYUNCULAR'),
          const SizedBox(height: 20),
          _buildActorItem('ADEM SOY'),
          _buildActorItem('NEVZAT KAYAOKAY'),
          _buildActorItem('GÜRKAN CANDAN'),
          _buildActorItem('ZEYNEP ÜĞÜDÜR'),
          _buildActorItem('SİTEM ARSLAN GENÇ'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          color: WebColors.primaryGold,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: WebColors.primaryGold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildCrewItem(String role, String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebColors.darkBlueAccent.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WebColors.primaryGold.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: const TextStyle(
              fontSize: 12,
              color: WebColors.primaryGoldLight,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              color: WebColors.whiteText,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActorItem(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: WebColors.primaryGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              color: WebColors.lightWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            WebColors.primaryGold.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
