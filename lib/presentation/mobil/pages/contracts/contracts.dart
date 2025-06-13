import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_html_css/simple_html_css.dart';
import '../../../../data/providers/appTools/app_tools_provider.dart';

class ContractsPage extends ConsumerWidget {
  const ContractsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final appToolsState = ref.watch(appToolsProvider);

    return Scaffold(
        body: appToolsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : appToolsState.errorMessage != null
                ? _buildErrorState(appToolsState.errorMessage!)
                : _buildContentState(context, appToolsState.privacyPolicy,
                    appToolsState.termsCondition));
  }

  Widget _buildErrorState(final String message) {
    return Center(child: Text(message));
  }

  // Content state with the actual HTML content
  Widget _buildContentState(final BuildContext context,
      final String? privacyPolicy, final String? termsCondition) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy & Terms & Conditions'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPrivacyPolicyAndTermsConditionCard(
                context, privacyPolicy, true),
            const Divider(height: 2, thickness: 1),
            _buildPrivacyPolicyAndTermsConditionCard(
                context, termsCondition, false),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicyAndTermsConditionCard(final BuildContext context,
      final String? privacyPolicyOrTermsCondition, final bool isPrivacyPolicy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
            isPrivacyPolicy ? 'Privacy Policy' : 'Terms and Conditions'),
        const SizedBox(height: 10),
        if (privacyPolicyOrTermsCondition != null)
          RichText(
            text: HTML.toTextSpan(
              context,
              privacyPolicyOrTermsCondition,
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
