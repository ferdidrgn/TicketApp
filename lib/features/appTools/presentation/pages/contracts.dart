import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_html_css/simple_html_css.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
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
        title: 'LEGAL DÖKÜMANLAR',
        subtitle: 'Koleksiyon kurallarını ve güvenliğini incele...',
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
              maxWidth: isWebOrTablet ? 800 : double.infinity, // Web'de 800px sınırı
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
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.primary,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: color.onPrimary,
        unselectedLabelColor: color.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: 'GİZLİLİK'),
          Tab(text: 'ŞARTLAR'),
        ],
      ),
    );
  }

  // --- İÇERİK TABLARI ---
  Widget _buildPrivacyTab(final BuildContext context, final WidgetRef ref) {
    final privacyAsync = ref.watch(privacyPolicyProvider);
    return privacyAsync.when(
      data: (final content) => _buildContentTab(context, ref, content, () => ref.invalidate(privacyPolicyProvider)),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (final err, final _) => _buildErrorState(context, err.toString(), () => ref.invalidate(privacyPolicyProvider)),
    );
  }

  Widget _buildTermsTab(final BuildContext context, final WidgetRef ref) {
    final termsAsync = ref.watch(termsConditionProvider);
    return termsAsync.when(
      data: (final content) => _buildContentTab(context, ref, content, () => ref.invalidate(termsConditionProvider)),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (final err, final _) => _buildErrorState(context, err.toString(), () => ref.invalidate(termsConditionProvider)),
    );
  }

  Widget _buildContentTab(final BuildContext context, final WidgetRef ref, final String? content, final VoidCallback onRefresh) {
    if (content == null) return const Center(child: Text("İçerik Bulunamadı"));

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: context.colors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHtmlContent(context, content),
          const SizedBox(height: 24),
          _buildLastUpdated(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHtmlContent(final BuildContext context, final String content) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24), // Web için padding arttırıldı
    decoration: BoxDecoration(
      color: context.colors.surfaceVariant.withOpacity(0.1),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: context.colors.outlineVariant.withOpacity(0.5)),
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
      Icon(Icons.history_rounded, size: 14, color: context.colors.onSurfaceVariant),
      const SizedBox(width: 8),
      Text(
        'Son Güncelleme: ${DateTime.now().toString().split(' ')[0]}',
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    ],
  );

  Widget _buildErrorState(final BuildContext context, final String message, final VoidCallback onRetry) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.error_outline_rounded, size: 48, color: context.colors.error),
      const SizedBox(height: 16),
      Text("Döküman yüklenirken bir hata oluştu.", style: context.textTheme.bodyMedium),
      TextButton(onPressed: onRetry, child: const Text("Tekrar Dene")),
    ],
  );

  // --- 🖥️ MASAÜSTÜ / WEB KABUĞU ---
  // Aynı privacyPolicyProvider/termsConditionProvider verisi, aynı
  // yenileme akışı; sadece mobil BasePageWrapper zırhı yerine sade,
  // WebColors temalı bir sekmeli görünüm.
  Widget _buildDesktopPage(final BuildContext context, final WidgetRef ref) =>
      ColoredBox(
        color: WebColors.darkBlueBackground,
        child: DefaultTabController(
          length: 2,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LEGAL DÖKÜMANLAR',
                      style: TextStyle(
                        color: WebColors.whiteText,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Koleksiyon kurallarını ve güvenliğini incele...',
                      style: TextStyle(
                        color: WebColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDesktopTabBar(),
                    const SizedBox(height: 24),
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
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(6),
          ),
        ),
        child: TabBar(
          dividerColor: Colors.transparent,
          indicator: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
              topRight: Radius.circular(6),
              bottomLeft: Radius.circular(6),
            ),
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
          const SizedBox(height: 24),
          _buildDesktopLastUpdated(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDesktopHtmlContent(
          final BuildContext context, final String content) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
            topRight: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
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
          const SizedBox(width: 8),
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
          const SizedBox(height: 16),
          const Text("Döküman yüklenirken bir hata oluştu.",
              style: TextStyle(color: WebColors.whiteText)),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: WebColors.primaryGoldLight),
            child: const Text("Tekrar Dene"),
          ),
        ],
      );
}