import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart'; // ✅ Yeni Kütüphane
import 'package:url_launcher/url_launcher.dart'; // Linklere tıklanabilmesi için (Opsiyonel ama önerilir)
import '../../../../data/providers/appTools/app_tools_provider.dart';
import '../../../../data/providers/appTools/app_tools_state.dart';

class ContractsPage extends ConsumerStatefulWidget {
  const ContractsPage({super.key});

  @override
  ConsumerState<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends ConsumerState<ContractsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(_loadData);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final notifier = ref.read(appToolsProvider.notifier);
    notifier.fetchPrivacyPolicy();
    notifier.fetchTermsCondition();
  }

  @override
  Widget build(final BuildContext context) {
    final state = ref.watch(appToolsProvider);
    final theme = Theme.of(context);

    return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme),
        body: _buildBody(state, theme));
  }

  PreferredSizeWidget _buildAppBar(final ThemeData theme) {
    return AppBar(
      title: const Text('Legal Dökümanlar',
          style: TextStyle(fontWeight: FontWeight.w600)),
      centerTitle: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        // Biraz yükselttim, tablar sıkışmasın
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary),
              indicatorPadding: EdgeInsets.zero,
              // Padding sorunu olmasın diye sıfırladım
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              // Tab altındaki çizgiyi kaldırdım
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              // Sığması için fontu hafif küçülttüm
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.privacy_tip_outlined, size: 20),
                  text: 'Privacy Policy',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.description_outlined, size: 20),
                  text: 'Terms & Conditions',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(final AppToolsState state, final ThemeData theme) {
    if (state.isLoading) return _buildLoadingState(theme);
    if (state.errorMessage != null) {
      return _buildErrorState(state.errorMessage!, theme);
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildContentTab(
            state.privacyPolicy, 'Privacy Policy', Icons.privacy_tip, theme),
        _buildContentTab(state.termsCondition, 'Terms & Conditions',
            Icons.description, theme)
      ],
    );
  }

  Widget _buildLoadingState(final ThemeData theme) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                color: theme.colorScheme.primary, strokeWidth: 3),
            const SizedBox(height: 16),
            Text('Dökümanlar Yükleniyor...',
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _buildErrorState(final String message, final ThemeData theme) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildErrorIcon(theme),
              const SizedBox(height: 24),
              Text('Dökümanlara Erişilemiyor!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Deneyin'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12)),
              ),
            ],
          ),
        ),
      );

  Widget _buildErrorIcon(final ThemeData theme) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(50),
        ),
        child:
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
      );

  Widget _buildContentTab(final String? content, final String title,
      final IconData icon, final ThemeData theme) {
    if (content == null) return _buildLoadingState(theme);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(title, icon, theme),
          const SizedBox(height: 24),
          // ✅ GÜNCELLENEN KISIM BURASI
          _buildHtmlContent(content, theme),
          const SizedBox(height: 32),
          _buildLastUpdated(theme)
        ],
      ),
    );
  }

  Widget _buildHeader(
          final String title, final IconData icon, final ThemeData theme) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer.withOpacity(0.7)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            _buildIcon(icon, theme),
            const SizedBox(width: 16),
            _buildTitleText(title, theme)
          ],
        ),
      );

  Widget _buildIcon(final IconData icon, final ThemeData theme) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 28, color: theme.colorScheme.primary));

  Widget _buildTitleText(final String title, final ThemeData theme) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 5),
            Text(
              'Lütfen dikkatlice okuyunuz',
              style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7)),
            ),
          ],
        ),
      );

  // ✅ BU METOD TAMAMEN GÜNCELLENDİ
  Widget _buildHtmlContent(final String content, final ThemeData theme) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: HtmlWidget(
          content,
          // Temel Metin Stili
          textStyle: TextStyle(
            fontSize: 15, // Biraz daha okunaklı boyut
            height: 1.6,
            color: theme.colorScheme.onSurface,
            fontFamily:
                theme.textTheme.bodyMedium?.fontFamily, // Uygulama fontunu koru
          ),

          // Linklere tıklandığında ne olacağı
          onTapUrl: (url) async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
              return true;
            }
            return false;
          },

          // İstersen özel CSS stilleri de tanımlayabilirsin,
          // ama HtmlWidget genelde otomatik halleder.
        ),
      );

  Widget _buildLastUpdated(final ThemeData theme) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Son Güncelleme Tarihi: ${DateTime.now().toString().split(' ')[0]}',
                style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
}
