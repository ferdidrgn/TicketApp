import 'package:flutter/material.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/footers/footer.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(final BuildContext context) {
    // 🖥️ Masaüstü/web: mobil zırhı (gradient başlık, FAB, parçacık
    // arkaplanı) atlanır, kendi sade web kabuğu kullanılır.
    if (context.isDesktop) return _buildDesktopPage(context);

    // 💡 Senin responsive utils uzantılarını kullanarak web/tablet kontrolü yapıyoruz
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        safeAreaTop: true,
      ),
      title: 'Yardım ve Destek',
      subtitle: 'Sorularına hızlıca cevap bul.',
      rightIcon: Icons.support_agent_rounded,
      child: Center(
        // ✅ Web'de içeriği ortalamak için
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // ✅ Web'de 800px genişliği geçmemesi için kısıt koyuyoruz
            maxWidth: isLargeScreen ? 800 : double.infinity,
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildSearchBox(context),
              const SizedBox(height: AppSpacing.xxxl),
              _buildSupportActions(context),
              const SizedBox(height: AppSpacing.massive),
              _buildSectionTitle(context, 'SIKÇA SORULANLAR'),
              const SizedBox(height: AppSpacing.lg),
              _buildFaqItem(context, 'Biletimi nasıl bulabilirim?',
                  'Biletlerim sekmesinden geçmiş ve gelecek tüm biletlerine ulaşabilirsin.'),
              _buildFaqItem(context, 'Sanatçı profili nasıl açılır?',
                  'Profil düzenleme ekranından yeteneklerini belirterek başlayabilirsin.'),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }

  // Arama Kutusu (Modern & Keskin Border)
  Widget _buildSearchBox(final BuildContext context) => Semantics(
        textField: true,
        label: 'Yardım merkezinde ara',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Sorunun cevabını burada ara...',
              border: InputBorder.none,
              icon: Icon(Icons.search),
            ),
          ),
        ),
      );

  // İletişim Kartları (Hızlı Aksiyon)
  Widget _buildSupportActions(final BuildContext context) => Row(
        children: [
          Expanded(
              child: _buildActionCard(context, Icons.chat_bubble_outline,
                  'Canlı Destek', 'Temsilciyle Konuş')),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
              child: _buildActionCard(
                  context, Icons.mail_outline, 'E-posta', 'Bize Yaz')),
        ],
      );

  Widget _buildActionCard(final BuildContext context, final IconData icon,
          final String title, final String sub) =>
      Semantics(
        label: '$title. $sub',
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: context.colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.colors.primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: context.colors.primary, size: 32),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(sub,
                  style: TextStyle(
                      fontSize: 10, color: context.colors.onSurfaceVariant)),
            ],
          ),
        ),
      );

  // Accordion (FAQ) Item
  Widget _buildFaqItem(final BuildContext context, final String question,
          final String answer) =>
      Semantics(
        button: true,
        label: '$question. Cevabı görmek için dokun.',
        child: Theme(
          // FAQ çizgilerini temizlemek için
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(question,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            children: [
              Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Text(answer,
                      style: TextStyle(color: context.colors.onSurfaceVariant)))
            ],
          ),
        ),
      );

  Widget _buildSectionTitle(final BuildContext context, final String title) =>
      Text(title,
          style: context.textTheme.labelSmall
              ?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w900));

  // --- 🖥️ MASAÜSTÜ / WEB KABUĞU ---
  // Aynı arama kutusu, aynı iletişim kartları, aynı SSS listesi; sadece
  // mobil BasePageWrapper zırhı yerine sade, WebColors temalı bir kabuk.
  // Sayfanın en altına, sitenin diğer masaüstü sayfalarıyla aynı tam
  // genişlikte paylaşılan `Footer` eklenir.
  Widget _buildDesktopPage(final BuildContext context) => ColoredBox(
        color: WebColors.darkBlueBackground,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxxl,
                      vertical: AppSpacing.section),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yardım ve Destek',
                        style: TextStyle(
                          color: WebColors.whiteText,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Sorularına hızlıca cevap bul.',
                        style: TextStyle(
                          color: WebColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      _buildDesktopSearchBox(),
                      const SizedBox(height: AppSpacing.xxxl),
                      _buildDesktopSupportActions(),
                      const SizedBox(height: AppSpacing.massive),
                      _buildDesktopSectionTitle('SIKÇA SORULANLAR'),
                      const SizedBox(height: AppSpacing.lg),
                      _buildDesktopFaqItem(context, 'Biletimi nasıl bulabilirim?',
                          'Biletlerim sekmesinden geçmiş ve gelecek tüm biletlerine ulaşabilirsin.'),
                      _buildDesktopFaqItem(context, 'Sanatçı profili nasıl açılır?',
                          'Profil düzenleme ekranından yeteneklerini belirterek başlayabilirsin.'),
                    ],
                  ),
                ),
              ),
            ),
            const Footer(),
          ],
        ),
      );

  Widget _buildDesktopSearchBox() => Semantics(
        textField: true,
        label: 'Yardım merkezinde ara',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: WebColors.darkBlueAccent.withOpacity(0.8)),
          ),
          child: TextField(
            style: const TextStyle(color: WebColors.whiteText),
            decoration: InputDecoration(
              hintText: 'Sorunun cevabını burada ara...',
              hintStyle: TextStyle(color: WebColors.textTertiary),
              border: InputBorder.none,
              icon: const Icon(Icons.search, color: WebColors.textSecondary),
            ),
          ),
        ),
      );

  Widget _buildDesktopSupportActions() => Row(
        children: [
          Expanded(
              child: _buildDesktopActionCard(Icons.chat_bubble_outline,
                  'Canlı Destek', 'Temsilciyle Konuş')),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
              child: _buildDesktopActionCard(
                  Icons.mail_outline, 'E-posta', 'Bize Yaz')),
        ],
      );

  Widget _buildDesktopActionCard(
          final IconData icon, final String title, final String sub) =>
      Semantics(
        label: '$title. $sub',
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: AppRadius.asymLg,
            border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: WebColors.primaryGold, size: 32),
              const SizedBox(height: AppSpacing.md),
              Text(title,
                  style: const TextStyle(
                      color: WebColors.whiteText, fontWeight: FontWeight.bold)),
              Text(sub,
                  style: TextStyle(fontSize: 10, color: WebColors.textSecondary)),
            ],
          ),
        ),
      );

  Widget _buildDesktopSectionTitle(final String title) => Text(title,
      style: const TextStyle(
          color: WebColors.primaryGoldLight,
          letterSpacing: 2,
          fontWeight: FontWeight.w900,
          fontSize: 12));

  Widget _buildDesktopFaqItem(final BuildContext context,
          final String question, final String answer) =>
      Semantics(
        button: true,
        label: '$question. Cevabı görmek için dokun.',
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: AppRadius.asymSm,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              iconColor: WebColors.primaryGold,
              collapsedIconColor: WebColors.textSecondary,
              title: Text(question,
                  style: const TextStyle(
                      color: WebColors.whiteText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              children: [
                Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Text(answer,
                        style: TextStyle(color: WebColors.textSecondary)))
              ],
            ),
          ),
        ),
      );
}
