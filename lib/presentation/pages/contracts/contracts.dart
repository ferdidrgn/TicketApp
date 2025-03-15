import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_html_css/simple_html_css.dart';
import '../../../data/providers/appTools/app_tools_provider.dart';

class ContractsPage extends ConsumerWidget {
  const ContractsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final appToolsState = ref.watch(appToolsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy & Terms & Conditions'),
        centerTitle: true,
      ),
      body: appToolsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : appToolsState.errorMessage != null
              ? _buildErrorState(appToolsState.errorMessage!)
              : _buildContentState(context, appToolsState.privacyPolicy,
                  appToolsState.termsCondition),
    );
  }

  Widget _buildErrorState(final String message) {
    return Center(child: Text(message));
  }

  Widget _buildContentState(final BuildContext context,
      final String? privacyPolicy, final String? termsCondition) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: privacyPolicy != null
                            ? RichText(
                                text: HTML.toTextSpan(
                                  context,
                                  privacyPolicy,
                                  defaultTextStyle: const TextStyle(
                                    fontSize: 18,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 2, thickness: 1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          child: const Text(
                            'Terms And Conditions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: termsCondition != null
                            ? RichText(
                                text: HTML.toTextSpan(
                                  context,
                                  termsCondition,
                                  defaultTextStyle: const TextStyle(
                                    fontSize: 18,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
