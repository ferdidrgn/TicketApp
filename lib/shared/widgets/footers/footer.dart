import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';

/// Web sayfalarının ortak alt bilgisi. Önceden yazılmıştı ama hiçbir
/// gerçek sayfaya bağlanmamıştı — kodda duruyordu, kullanıcı hiç görmüyordu.
/// İletişim/sosyal medya butonları artık gerçekten çalışıyor
/// (`TiyatrolCommunicationActions` — sitenin başka yerlerinde de kullandığı
/// aynı gerçek Instagram/Facebook/e-posta bağlantıları), süs değil.
class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(final BuildContext context) {
    return Container(
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
            WebColors.darkBlueAccent,
            Color(0xFF3A2E24),
          ],
        ),
      ),
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
                '© 2026 TiyatRol Sahne Sanatları - Tüm Hakları Saklıdır.',
                style: TextStyle(
                    color: Colors.white70, fontSize: context.captionSize),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kurumsal',
                style: TextStyle(
                  color: WebColors.primaryGoldLight,
                  fontWeight: FontWeight.bold,
                  fontSize: context.bodySize + 2,
                ),
              ),
              const SizedBox(height: 10),
              _linkRow(context, 'Sözleşmeler',
                  () => NavigationHandler.goToContracts(context)),
              _linkRow(context, 'Yardım & Destek',
                  () => NavigationHandler.goToHelpSupport(context)),
            ],
          ),
        ),
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
              _actionRow(context, Icons.mail_outline, 'E-posta gönder',
                  TiyatrolCommunicationActions.sendEmail),
              _actionRow(context, Icons.chat_bubble_outline, 'WhatsApp',
                  TiyatrolCommunicationActions.contactWhatsApp),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bizi Takip Edin',
                style: TextStyle(
                  color: WebColors.primaryGoldLight,
                  fontWeight: FontWeight.bold,
                  fontSize: context.bodySize + 2,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _socialIcon(context, Icons.facebook,
                      TiyatrolCommunicationActions.openFacebook),
                  _socialIcon(context, Icons.camera_alt_outlined,
                      TiyatrolCommunicationActions.openInstagram),
                ],
              ),
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
          '© 2026 TiyatRol Sahne Sanatları - Tüm Hakları Saklıdır.',
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
        const Divider(color: Colors.white24, height: 30),
        Text(
          'Kurumsal',
          style: TextStyle(
            color: WebColors.primaryGoldLight,
            fontWeight: FontWeight.bold,
            fontSize: context.bodySize + 1,
          ),
        ),
        const SizedBox(height: 10),
        _linkRow(context, 'Sözleşmeler',
            () => NavigationHandler.goToContracts(context)),
        _linkRow(context, 'Yardım & Destek',
            () => NavigationHandler.goToHelpSupport(context)),
        const Divider(color: Colors.white24, height: 30),
        Text(
          'İletişim',
          style: TextStyle(
            color: WebColors.primaryGoldLight,
            fontWeight: FontWeight.bold,
            fontSize: context.bodySize + 1,
          ),
        ),
        const SizedBox(height: 10),
        _actionRow(context, Icons.mail_outline, 'E-posta gönder',
            TiyatrolCommunicationActions.sendEmail),
        _actionRow(context, Icons.chat_bubble_outline, 'WhatsApp',
            TiyatrolCommunicationActions.contactWhatsApp),
        const Divider(color: Colors.white24, height: 30),
        Text(
          'Bizi Takip Edin',
          style: TextStyle(
            color: WebColors.primaryGoldLight,
            fontWeight: FontWeight.bold,
            fontSize: context.bodySize + 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _socialIcon(context, Icons.facebook,
                TiyatrolCommunicationActions.openFacebook),
            const SizedBox(width: 12),
            _socialIcon(context, Icons.camera_alt_outlined,
                TiyatrolCommunicationActions.openInstagram),
          ],
        ),
      ],
    );
  }

  Widget _linkRow(
          final BuildContext context, final String label, final VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          child: Text(label,
              style:
                  TextStyle(fontSize: context.bodySize, color: Colors.white70)),
        ),
      );

  Widget _actionRow(final BuildContext context, final IconData icon,
          final String label, final VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: context.iconSmall, color: Colors.white70),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: context.bodySize, color: Colors.white70)),
            ],
          ),
        ),
      );

  Widget _socialIcon(
      final BuildContext context, final IconData icon, final VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        decoration: BoxDecoration(
          color: WebColors.primaryGoldLight.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child:
            Icon(icon, color: WebColors.primaryGoldLight, size: context.iconSmall),
      ),
    );
  }
}
