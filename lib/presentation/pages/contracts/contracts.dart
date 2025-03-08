import 'package:flutter/material.dart';
import 'package:simple_html_css/simple_html_css.dart';
import '../../../data/repository/app_tools_service.dart';

class ContractsPage extends StatefulWidget {
  const ContractsPage({super.key});

  @override
  _ContractsPageState createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> {
  String? termsAndConditionsHtml;
  String? privacyPolicyHtml;
  final AppToolsService appToolsService = AppToolsService();

  @override
  void initState() {
    super.initState();
    fetchHtmlContent();
  }

  Future<void> fetchHtmlContent() async {
    final privacy = await appToolsService.getPrivacyPolicy();
    final terms = await appToolsService.getTermsCondition();
    setState(() {
      privacyPolicyHtml = privacy;
      termsAndConditionsHtml = terms;
    });
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy & Terms & Conditions'),
        centerTitle: true,
      ),
      body: Padding(
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
                        width: double.infinity, // Makes the card full-width
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
                      child: privacyPolicyHtml != null
                          ? RichText(
                        text: HTML.toTextSpan(
                          context,
                          privacyPolicyHtml!,
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
                        width: double.infinity, // Makes the card full-width
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
                      child: termsAndConditionsHtml != null
                          ? RichText(
                        text: HTML.toTextSpan(
                          context,
                          termsAndConditionsHtml!,
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
    );
  }
}
