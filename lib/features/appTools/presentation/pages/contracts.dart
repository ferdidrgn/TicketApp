import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_html_css/simple_html_css.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import '../providers/app_tools_provider.dart';

class ContractsPage extends ConsumerStatefulWidget {
  const ContractsPage({super.key});

  @override
  ConsumerState<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends ConsumerState<ContractsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late ColorScheme color;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    color = context.colors;

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPrivacyTab(),
            _buildTermsTab(),
          ],
        ),
      ),
    );
  }

  // --- GİZLİLİK POLİTİKASI TABI ---
  Widget _buildPrivacyTab() {
    final privacyAsync = ref.watch(privacyPolicyProvider);

    return privacyAsync.when(
      data: (final content) => _buildContentTab(content, 'Privacy Policy',
          Icons.privacy_tip, () => ref.invalidate(privacyPolicyProvider)),
      loading: () => _buildLoadingState(),
      error: (final err, final stack) => _buildErrorState(
          err.toString(), () => ref.invalidate(privacyPolicyProvider)),
    );
  }

  // --- KULLANIM ŞARTLARI TABI ---
  Widget _buildTermsTab() {
    final termsAsync = ref.watch(termsConditionProvider);

    return termsAsync.when(
      data: (final content) => _buildContentTab(content, 'Terms & Conditions',
          Icons.description, () => ref.invalidate(termsConditionProvider)),
      loading: () => _buildLoadingState(),
      error: (final err, final stack) => _buildErrorState(
          err.toString(), () => ref.invalidate(termsConditionProvider)),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        title: const Text('Legal Dökümanlar',
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: color.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: color.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.primary,
                ),
                indicatorPadding:
                    const EdgeInsets.symmetric(horizontal: -10, vertical: 5),
                indicatorSize: TabBarIndicatorSize.tab,
                tabAlignment: TabAlignment.fill,
                labelColor: color.onPrimary,
                unselectedLabelColor: color.onSurfaceVariant,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: const [
                  Tab(icon: Icon(Icons.privacy_tip, size: 20), text: 'Privacy'),
                  Tab(icon: Icon(Icons.description, size: 20), text: 'Terms'),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildContentTab(final String? content, final String title,
      final IconData icon, final VoidCallback onRefresh) {
    if (content == null) return const Center(child: Text("İçerik Bulunamadı"));

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        // RefreshIndicator için gerekli
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(title, icon),
            const SizedBox(height: 24),
            _buildHtmlContent(content),
            const SizedBox(height: 32),
            _buildLastUpdated(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(final String title, final IconData icon) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.primaryContainer,
              color.primaryContainer.withOpacity(0.7)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color.surface),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: color.onPrimaryContainer)),
                  Text('Lütfen Dikkatli Okuyunuz',
                      style: TextStyle(
                          fontSize: 14,
                          color: color.onPrimaryContainer.withOpacity(0.7))),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildHtmlContent(final String content) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.outline.withOpacity(0.2)),
        ),
        child: RichText(
          text: HTML.toTextSpan(context, content,
              defaultTextStyle: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: color.onSurface,
                  decoration: TextDecoration.none)),
        ),
      );

  Widget _buildLoadingState() =>
      const Center(child: CircularProgressIndicator());

  Widget _buildErrorState(final String message, final VoidCallback onRetry) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: color.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: onRetry, child: const Text("Tekrar Dene")),
          ],
        ),
      );

  Widget _buildLastUpdated() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: color.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bu dökümanın en son güncellenme tarihi : This document was last updated on ${DateTime.now().toString().split(' ')[0]}',
                style: TextStyle(
                    fontSize: 14,
                    color: color.onSurfaceVariant,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
}
