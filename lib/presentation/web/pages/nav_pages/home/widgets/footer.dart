import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';

class ArtFooter extends StatelessWidget {
  const ArtFooter({super.key});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WebColors.darkBlueBackground,
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (final context, final constraints) {
          final isMobile = constraints.maxWidth < 600;
          return isMobile ? _buildMobileFooter() : _buildDesktopFooter();
        },
      ),
    );
  }

  Widget _buildDesktopFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Marka ve Telif Hakkı
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'TiyatRol Sahne Sanatları',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '© 2025 TiyatRol Sahne Sanatları - Tüm Hakları Saklıdır. - Ferdi Durgun',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),

        // Hızlı Linkler
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.location_on, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text(
                "Ataşehir, İSTANBUL, Türkiye",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),

        // İletişim Bilgileri
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'İletişim',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              Text('E-posta: ----@----.com',
                  style: TextStyle(color: Colors.white70)),
              SizedBox(height: 6),
              Text('Telefon: +90 -----',
                  style: TextStyle(color: Colors.white70)),
              SizedBox(height: 6),
              Text('Adres: Ataşehir, İSTANBUL, Türkiye',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),

        // Sosyal Medya İkonları
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bizi Takip Edin',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _socialIcon(Icons.facebook),
                  const SizedBox(width: 12),
                  _socialIcon(Icons.access_alarm),
                  const SizedBox(width: 12),
                  _socialIcon(Icons.theater_comedy),
                  const SizedBox(width: 12),
                  _socialIcon(Icons.youtube_searched_for),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TiyatRol Sahne Sanatları',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '© 2025 TiyatRol Sahne Sanatları - Tüm Hakları Saklıdır. - Ferdi Durgun',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Divider(color: Colors.white24, height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.location_on, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              "Ataşehir, İSTANBUL, Türkiye",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        const Divider(color: Colors.white24, height: 30),
        const Text(
          'İletişim',
          style: TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        const Text('E-posta: ----@----.com',
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        const Text('Telefon: +90 ----',
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        const Text('Adres: Ataşehir, İSTANBUL, Türkiye',
            style: TextStyle(color: Colors.white70)),
        const Divider(color: Colors.white24, height: 30),
        const Text(
          'Bizi Takip Edin',
          style: TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _socialIcon(Icons.facebook),
            const SizedBox(width: 12),
            _socialIcon(Icons.access_alarm),
            const SizedBox(width: 12),
            _socialIcon(Icons.theater_comedy_rounded),
            const SizedBox(width: 12),
            _socialIcon(Icons.youtube_searched_for),
          ],
        ),
      ],
    );
  }

  Widget _footerLink(final String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _socialIcon(final IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amberAccent.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: Colors.amberAccent, size: 20),
    );
  }
}
