import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_html_css/simple_html_css.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/shared/widgets/top_normal_header.dart'; // Senin sanatsal headerın
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../providers/app_tools_provider.dart';
import '../providers/app_tools_state.dart';

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

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: CustomAppBackground(
        child: Column(
          children: [
            // 🎨 SANATSAL HEADER
            const TopNormalHeader(
              title: 'LEGAL PROTOKOLLER',
              subtitle: 'Serüvenin yasal çerçevesini inceleyin...',
              rightIcon: Icons.gavel_rounded,
            ),

            // 📑 TAB SELECTOR (Biletlerim sayfasındaki stilde)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: _buildTabSelector(context),
            ),

            Expanded(
              child: _buildBody(state, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector(final BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.3)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [colors.primary, colors.primaryContainer],
          ),
        ),
        labelColor: colors.onPrimary,
        unselectedLabelColor: colors.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Gizlilik'),
          Tab(text: 'Şartlar'),
        ],
      ),
    );
  }

  Widget _buildBody(final AppToolsState state, final BuildContext context) {
    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (state.errorMessage != null)
      return _buildErrorState(state.errorMessage!, context);

    return TabBarView(
      controller: _tabController,
      children: [
        _buildContentTab(state.privacyPolicy, 'Gizlilik Politikası', context),
        _buildContentTab(state.termsCondition, 'Kullanım Şartları', context),
      ],
    );
  }

  Widget _buildContentTab(
      final String? content, final String title, final BuildContext context) {
    final colors = context.colors;
    if (content == null)
      return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📜 KAĞIT EFEKTLİ İÇERİK KUTUSU
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: context.textTheme.labelLarge?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                    color: colors.primary,
                  ),
                ),
                const Divider(height: 32),
                RichText(
                  text: HTML.toTextSpan(
                    context,
                    content,
                    defaultTextStyle: context.textTheme.bodyMedium?.copyWith(
                      height: 1.7,
                      color: colors.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildLastUpdated(context),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(final BuildContext context) => Center(
        child: Text(
          'Son Güncelleme: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
          style: context.textTheme.labelSmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: context.colors.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      );

  Widget _buildErrorState(final String message, final BuildContext context) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_rounded, size: 64, color: context.colors.outline),
            const SizedBox(height: 16),
            Text(message),
            TextButton(onPressed: _loadData, child: const Text("Tekrar Dene"))
          ],
        ),
      );
}
