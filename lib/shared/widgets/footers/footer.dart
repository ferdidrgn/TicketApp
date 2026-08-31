import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(final BuildContext context) {
    return Container(
      // Responsive Padding
      padding: context.responsive(
        mobile: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        desktop: const EdgeInsets.symmetric(vertical: 50, horizontal: 60),
      ),
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
      // Mobil ise Column, Desktop ise Row kullan
      child: context.isMobile
          ? _buildMobileFooter(context)
          : _buildDesktopFooter(context),
    );
  }

  Widget _buildDesktopFooter(final BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Marka
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TiyatRol Sahne Sanatları',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.subtitleSize + 2,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '© ${DateTime.now().year} TiyatRol Sahne Sanatları - Tüm Hakları Saklıdır.',
                style: TextStyle(
                    color: Colors.white70, fontSize: context.captionSize),
              ),
            ],
          ),
        ),

        // 2. Konum
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on,
                  color: Colors.white, size: context.iconSmall),
              const SizedBox(width: 4),
              Text(
                "Ataşehir, İSTANBUL, Türkiye",
                style: TextStyle(
                    color: Colors.white70, fontSize: context.bodySize),
              ),
            ],
          ),
        ),

        // 3. İletişim
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'İletişim',
                style: TextStyle(
                  color: WebColors.primaryGoldLight,
                  fontWeight: FontWeight.bold,
                  fontSize: context.bodySize + 2,
                ),
              ),
              const SizedBox(height: 10),
              _contactRow(context, 'Adres:', 'Ataşehir, İSTANBUL, Türkiye'),
            ],
          ),
        ),

      ],
    );
  }

  Widget _buildMobileFooter(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TiyatRol Sahne Sanatları',
          style: TextStyle(
            color: Colors.white,
            fontSize: context.subtitleSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '© ${DateTime.now().year} TiyatRol Sahne Sanatları - Tüm Hakları Saklıdır.',
          style:
              TextStyle(color: Colors.white70, fontSize: context.captionSize),
        ),
        const Divider(color: Colors.white24, height: 30),
        Row(
          children: [
            Icon(Icons.location_on,
                color: Colors.white, size: context.iconSmall),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Ataşehir, İSTANBUL, Türkiye",
                style: TextStyle(
                    color: Colors.white70, fontSize: context.bodySize),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _contactRow(final BuildContext context, final String label, final String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
              fontSize: context.captionSize + 1, color: Colors.white70),
          children: [
            TextSpan(
                text: '$label ',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
