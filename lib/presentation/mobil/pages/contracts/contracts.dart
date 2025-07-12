import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_html_css/simple_html_css.dart';
import '../../../../data/providers/appTools/app_tools_provider.dart';

class ContractsPage extends ConsumerStatefulWidget {
  const ContractsPage({super.key});

  @override
  ConsumerState<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends ConsumerState<ContractsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  void _loadData() {
    final notifier = ref.read(appToolsProvider.notifier);
    notifier.fetchPrivacyPolicy();
    notifier.fetchTermsCondition();
  }

  @override
  Widget build(final BuildContext context) {
    final appToolsState = ref.watch(appToolsProvider);

    if (appToolsState.isLoading)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );

    if (appToolsState.errorMessage != null)
      return Scaffold(
        body: _buildErrorState(appToolsState.errorMessage!),
      );

    return _buildContentState(
      context,
      appToolsState.privacyPolicy,
      appToolsState.termsCondition,
    );
  }

  Widget _buildErrorState(final String message) => Center(child: Text(message));

  Widget _buildContentState(
    final BuildContext context,
    final String? privacyPolicy,
    final String? termsCondition,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy & Terms & Conditions'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildContractCard(context, privacyPolicy, true),
            const Divider(height: 2, thickness: 1),
            _buildContractCard(context, termsCondition, false),
          ],
        ),
      ),
    );
  }

  Widget _buildContractCard(
    final BuildContext context,
    final String? content,
    final bool isPrivacyPolicy,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
            isPrivacyPolicy ? 'Privacy Policy' : 'Terms and Conditions'),
        const SizedBox(height: 10),
        if (content != null)
          RichText(
            text: HTML.toTextSpan(
              context,
              content,
              defaultTextStyle: const TextStyle(
                  fontSize: 18, decoration: TextDecoration.none),
            ),
          )
        else
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  // Common title widget for sections
  Widget _buildSectionTitle(final String title) {
    return Align(
      alignment: Alignment.topLeft,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
