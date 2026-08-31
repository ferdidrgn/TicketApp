import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_html_css/simple_html_css.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/shared/widgets/bento/bento_primitives.dart';
import '../providers/app_tools_provider.dart';

class ContractsPage extends ConsumerWidget {
  const ContractsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // 💡 Responsive değerlerimizi alalım
    final bool isWebOrTablet = context.isTablet || context.isDesktop;

    return DefaultTabController(
      length: 2,
      child: BasePageWrapper(
        title: 'LEGAL DÖKÜMANLAR',
        subtitle: 'Koleksiyon kurallarını ve güvenliğini incele...',
        rightIcon: Icons.gavel_rounded,
        showBackButton: true,
        layoutConfig: const BasePageLayoutConfig(
          backgroundColor: BentoColors.canvas,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: BentoColors.highlight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: BentoColors.indigo,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFFA1A1AA),
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
      loading: () => const Center(child: CircularProgressIndicator(color: BentoColors.indigoLight)),
      error: (final err, final _) => _buildErrorState(context, () => ref.invalidate(privacyPolicyProvider)),
    );
  }

  Widget _buildTermsTab(final BuildContext context, final WidgetRef ref) {
    final termsAsync = ref.watch(termsConditionProvider);
    return termsAsync.when(
      data: (final content) => _buildContentTab(context, ref, content, () => ref.invalidate(termsConditionProvider)),
      loading: () => const Center(child: CircularProgressIndicator(color: BentoColors.indigoLight)),
      error: (final err, final _) => _buildErrorState(context, () => ref.invalidate(termsConditionProvider)),
    );
  }

  Widget _buildContentTab(final BuildContext context, final WidgetRef ref, final String? content, final VoidCallback onRefresh) {
    if (content == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: BentoEmptyState(
            icon: Icons.description_outlined,
            title: 'İçerik bulunamadı',
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: BentoColors.indigoLight,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHtmlContent(context, content),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHtmlContent(final BuildContext context, final String content) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24), // Web için padding arttırıldı
    decoration: BoxDecoration(
      color: BentoColors.card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: BentoColors.microBorder),
    ),
    child: RichText(
      text: HTML.toTextSpan(
        context,
        content,
        defaultTextStyle: const TextStyle(
          fontSize: 16, // Web'de okunabilirlik için 16px
          height: 1.7,
          color: Color(0xFFD4D4D8),
          decoration: TextDecoration.none,
        ),
      ),
    ),
  );

  Widget _buildErrorState(final BuildContext context, final VoidCallback onRetry) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: BentoErrorState(
        message: 'Döküman yüklenirken bir hata oluştu.',
        onRetry: onRetry,
      ),
    ),
  );
}