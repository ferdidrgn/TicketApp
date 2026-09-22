import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_html_css/simple_html_css.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/widgets/footers/footer.dart';
import '../providers/app_tools_provider.dart';

class ContractsPage extends ConsumerWidget {
  const ContractsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // 🖥️ Masaüstü/web: mobil zırhı (gradient başlık, FAB, parçacık
    // arkaplanı) tamamen atlanır, kendi sade web kabuğu kullanılır.
    if (context.isDesktop) return _buildDesktopPage(context, ref);

    // 💡 Responsive değerlerimizi alalım
    final bool isWebOrTablet = context.isTablet || context.isDesktop;

    return DefaultTabController(
      length: 2,
      child: BasePageWrapper(
        title: 'Yasal Bilgiler',
        subtitle: 'Gizlilik politikası ve kullanım şartları.',
        rightIcon: Icons.gavel_rounded,
        showBackButton: true,
        layoutConfig: BasePageLayoutConfig(
          backgroundColor: context.colors.surface,
          safeAreaTop: true,
        ),
        // 🎨 Web'de içeriği ortalamak için Center ve ConstrainedBox kullanıyoruz
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  isWebOrTablet ? 800 : double.infinity, // Web'de 800px sınırı
            ),
            child: Column(
              children: [
                _buildModernTabBar(context),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPrivacyTab(context, ref),
                      _buildTermsTab(context, ref),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MODERN TABBAR ---
  Widget _buildModernTabBar(final BuildContext context) {
    final color = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Semantics(
        container: true,
        label: 'Gizlilik ve şartlar sekmeleri',
        child: TabBar(
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: color.primary,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: color.onPrimary,
          unselectedLabelColor: color.onSurfaceVariant,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'GİZLİLİK'),
            Tab(text: 'ŞARTLAR'),
          ],
        ),
      ),
    );
  }

  // --- İÇERİK TABLARI ---
  Widget _buildPrivacyTab(final BuildContext context, final WidgetRef ref) {
    final privacyAsync = ref.watch(privacyPolicyProvider);
    return privacyAsync.when(
      data: (final content) => _buildContentTab(
          context, ref, content, () => ref.invalidate(privacyPolicyProvider)),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (final err, final _) => _buildErrorState(
          context, err.toString(), () => ref.invalidate(privacyPolicyProvider)),
    );
  }

  Widget _buildTermsTab(final BuildContext context, final WidgetRef ref) {
    final termsAsync = ref.watch(termsConditionProvider);
    return termsAsync.when(
      data: (final content) => _buildContentTab(
          context, ref, content, () => ref.invalidate(termsConditionProvider)),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (final err, final _) => _buildErrorState(context, err.toString(),
          () => ref.invalidate(termsConditionProvider)),
    );
  }

  Widget _buildContentTab(final BuildContext context, final WidgetRef ref,
      final String? content, final VoidCallback onRefresh) {
    if (content == null) return const Center(child: Text("İçerik Bulunamadı"));

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: context.colors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHtmlContent(context, content),
          const SizedBox(height: AppSpacing.xxl),
          _buildLastUpdated(context),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  Widget _buildHtmlContent(final BuildContext context, final String content) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xxl), // Web için padding arttırıldı
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border:
              Border.all(color: context.colors.outlineVariant.withOpacity(0.5)),
        ),
        child: RichText(
          text: HTML.toTextSpan(
            context,
            content,
            defaultTextStyle: TextStyle(
              fontSize: 16, // Web'de okunabilirlik için 16px
              height: 1.7,
              color: context.colors.onSurface,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );

  Widget _buildLastUpdated(final BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded,
              size: 14, color: context.colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Son Güncelleme: ${DateTime.now().toString().split(' ')[0]}',
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );

  Widget _buildErrorState(
          final BuildContext context, final String message, final VoidCallback onRetry) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: context.colors.error),
          const SizedBox(height: AppSpacing.lg),
          Text("Döküman yüklenirken bir hata oluştu.",
              style: context.textTheme.bodyMedium),
          Semantics(
            button: true,
            label: 'Dökümanı tekrar yüklemeyi dene',
            child: TextButton(onPressed: onRetry, child: const Text("Tekrar Dene")),
          ),
        ],
      );

  // --- 🖥️ MASAÜSTÜ / WEB KABUĞU ---
  // Aynı privacyPolicyProvider/termsConditionProvider verisi, aynı
  // yenileme akışı; sadece mobil BasePageWrapper zırhı yerine sade,
  // WebColors temalı bir sekmeli görünüm. Her sekmenin kendi kaydırılabilir
  // içeriğinin sonuna, sitenin diğer masaüstü sayfalarıyla aynı paylaşılan
  // `Footer` eklenir.
  Widget _buildDesktopPage(final BuildContext context, final WidgetRef ref) =>
      ColoredBox(
        color: WebColors.darkBlueBackground,
        child: DefaultTabController(
          length: 2,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl,
                    vertical: AppSpacing.section),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yasal Bilgiler',
                      style: TextStyle(
                        color: WebColors.whiteText,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Gizlilik politikası ve kullanım şartları.',
                      style: TextStyle(
                        color: WebColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildDesktopTabBar(),
                    const SizedBox(height: AppSpacing.xxl),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildDesktopPrivacyTab(context, ref),
                          _buildDesktopTermsTab(context, ref),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildDesktopTabBar() => Container(
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface,
          borderRadius: AppRadius.asymSm,
        ),
        child: Semantics(
          container: true,
          label: 'Gizlilik ve şartlar sekmeleri',
          child: TabBar(
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              borderRadius: AppRadius.asymSm,
              color: WebColors.primaryGold,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: WebColors.whiteText,
            unselectedLabelColor: WebColors.textSecondary,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'GİZLİLİK'),
              Tab(text: 'ŞARTLAR'),
            ],
          ),
        ),
      );

  Widget _buildDesktopPrivacyTab(
      final BuildContext context, final WidgetRef ref) {
    final privacyAsync = ref.watch(privacyPolicyProvider);
    return privacyAsync.when(
      data: (final content) => _buildDesktopContentTab(
          context, content, () => ref.invalidate(privacyPolicyProvider)),
      loading: () => const Center(
          child: CircularProgressIndicator(color: WebColors.primaryGold)),
      error: (final err, final _) => _buildDesktopErrorState(
          err.toString(), () => ref.invalidate(privacyPolicyProvider)),
    );
  }

  Widget _buildDesktopTermsTab(
      final BuildContext context, final WidgetRef ref) {
    final termsAsync = ref.watch(termsConditionProvider);
    return termsAsync.when(
      data: (final content) => _buildDesktopContentTab(
          context, content, () => ref.invalidate(termsConditionProvider)),
      loading: () => const Center(
          child: CircularProgressIndicator(color: WebColors.primaryGold)),
      error: (final err, final _) => _buildDesktopErrorState(
          err.toString(), () => ref.invalidate(termsConditionProvider)),
    );
  }

  Widget _buildDesktopContentTab(final BuildContext context,
      final String? content, final VoidCallback onRefresh) {
    if (content == null)
      return const Center(
          child: Text("İçerik Bulunamadı",
              style: TextStyle(color: WebColors.whiteText)));

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: WebColors.primaryGold,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildDesktopHtmlContent(context, content),
          const SizedBox(height: AppSpacing.xxl),
          _buildDesktopLastUpdated(),
          const SizedBox(height: AppSpacing.massive),
          // Web masaüstü deneyiminde sekme içeriğinin sonuna site geneli
          // footer eklenir.
          const Footer(),
        ],
      ),
    );
  }

  Widget _buildDesktopHtmlContent(
          final BuildContext context, final String content) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface,
          borderRadius: AppRadius.asymLg,
          border:
              Border.all(color: WebColors.darkBlueAccent.withOpacity(0.8)),
        ),
        child: RichText(
          text: HTML.toTextSpan(
            context,
            content,
            defaultTextStyle: const TextStyle(
              fontSize: 16,
              height: 1.7,
              color: WebColors.whiteText,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );

  Widget _buildDesktopLastUpdated() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_rounded,
              size: 14, color: WebColors.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Son Güncelleme: ${DateTime.now().toString().split(' ')[0]}',
            style: const TextStyle(
              color: WebColors.textTertiary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );

  Widget _buildDesktopErrorState(
          final String message, final VoidCallback onRetry) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: WebColors.error),
          const SizedBox(height: AppSpacing.lg),
          const Text("Döküman yüklenirken bir hata oluştu.",
              style: TextStyle(color: WebColors.whiteText)),
          Semantics(
            button: true,
            label: 'Dökümanı tekrar yüklemeyi dene',
            child: TextButton(
              onPressed: onRetry,
              style:
                  TextButton.styleFrom(foregroundColor: WebColors.primaryGoldLight),
              child: const Text("Tekrar Dene"),
            ),
          ),
        ],
      );
}
