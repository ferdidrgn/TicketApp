import 'package:flutter/material.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(final BuildContext context) {
    // 💡 Senin responsive utils uzantılarını kullanarak web/tablet kontrolü yapıyoruz
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        safeAreaTop: true,
      ),
      title: 'DANIŞMA MASASI',
      subtitle: 'Serüveninde sana rehberlik edelim...',
      rightIcon: Icons.support_agent_rounded,
      child: Center( // ✅ Web'de içeriği ortalamak için
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // ✅ Web'de 800px genişliği geçmemesi için kısıt koyuyoruz
            maxWidth: isLargeScreen ? 800 : double.infinity,
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildSearchBox(context),
              const SizedBox(height: 32),
              _buildSupportActions(context),
              const SizedBox(height: 48),
              _buildSectionTitle(context, 'SIKÇA SORULANLAR'),
              const SizedBox(height: 16),
              _buildFaqItem(context, 'Biletimi nasıl bulabilirim?',
                  'Biletlerim sekmesinden geçmiş ve gelecek tüm biletlerine ulaşabilirsin.'),
              _buildFaqItem(context, 'Sanatçı profili nasıl açılır?',
                  'Profil düzenleme ekranından yeteneklerini belirterek başlayabilirsin.'),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Arama Kutusu (Modern & Keskin Border)
  Widget _buildSearchBox(final BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: context.colors.surfaceVariant.withOpacity(0.5),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: context.colors.outlineVariant),
    ),
    child: const TextField(
      decoration: InputDecoration(
        hintText: 'Sorunun cevabını burada ara...',
        border: InputBorder.none,
        icon: Icon(Icons.search),
      ),
    ),
  );

  // İletişim Kartları (Hızlı Aksiyon)
  Widget _buildSupportActions(final BuildContext context) => Row(
    children: [
      Expanded(
          child: _buildActionCard(context, Icons.chat_bubble_outline,
              'Canlı Destek', 'Küratörle Konuş')),
      const SizedBox(width: 16),
      Expanded(
          child: _buildActionCard(
              context, Icons.mail_outline, 'E-posta', 'Mektup Gönder')),
    ],
  );

  Widget _buildActionCard(final BuildContext context, final IconData icon,
      final String title, final String sub) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.colors.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: context.colors.primary, size: 32),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(sub,
                style: TextStyle(
                    fontSize: 10, color: context.colors.onSurfaceVariant)),
          ],
        ),
      );

  // Accordion (FAQ) Item
  Widget _buildFaqItem(final BuildContext context, final String question,
      final String answer) =>
      Theme(
        // FAQ çizgilerini temizlemek için
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(question,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          children: [
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(answer,
                    style: TextStyle(color: context.colors.onSurfaceVariant)))
          ],
        ),
      );

  Widget _buildSectionTitle(final BuildContext context, final String title) =>
      Text(title,
          style: context.textTheme.labelSmall
              ?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w900));
}