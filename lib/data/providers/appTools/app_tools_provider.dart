import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/data/repository/appTools/app_tools_provider.dart';
import 'package:ticketapp/domain/useCase/appTools/get_privacy_policy_use_case_impl.dart';
import 'package:ticketapp/domain/useCase/appTools/get_terms_condition_use_case_impl.dart';

import 'app_tools_notifier.dart';
import 'app_tools_state.dart';

/// Uygulama araçları ViewModel provider'ı
final appToolsProvider = NotifierProvider.autoDispose<AppToolsNotifier, AppToolsState>(
  AppToolsNotifier.new,
);

/// Gizlilik politikası use case provider'ı
final getPrivacyPolicyUseCaseProvider = Provider<GetPrivacyPolicyUseCase>(
  (final ref) => GetPrivacyPolicyUseCaseImpl(
    ref.watch(appToolsRepositoryProvider),
  ),
);

/// Kullanım şartları use case provider'ı
final getTermsConditionUseCaseProvider = Provider<GetTermsConditionUseCase>(
  (final ref) => GetTermsConditionUseCaseImpl(
    ref.watch(appToolsRepositoryProvider),
  ),
);

// ==============================================================================
// USAGE EXAMPLES
// ==============================================================================

/// Örnek 1: Tema değiştirme
/// ```dart
/// class SettingsScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final currentTheme = ref.watch(themeProvider);
///
///     return SwitchListTile(
///       title: const Text('Dark Mode'),
///       value: currentTheme == ThemeMode.dark,
///       onChanged: (value) {
///         ref.read(themeProvider.notifier).setTheme(
///           value ? ThemeMode.dark : ThemeMode.light,
///         );
///       },
///     );
///   }
/// }
/// ```

/// Örnek 2: MaterialApp'te tema kullanımı
/// ```dart
/// class MyApp extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final themeMode = ref.watch(themeProvider);
///
///     return MaterialApp(
///       themeMode: themeMode,
///       theme: ThemeData.light(),
///       darkTheme: ThemeData.dark(),
///       home: HomeScreen(),
///     );
///   }
/// }
/// ```

/// Örnek 3: Gizlilik politikasını görüntüleme
/// ```dart
/// class PrivacyPolicyScreen extends ConsumerStatefulWidget {
///   @override
///   ConsumerState<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
/// }
///
/// class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
///   @override
///   void initState() {
///     super.initState();
///     WidgetsBinding.instance.addPostFrameCallback((_) {
///       ref.read(appToolsProvider.notifier).fetchPrivacyPolicy();
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     final appToolsState = ref.watch(appToolsProvider);
///
///     if (appToolsState.isLoading) {
///       return const Center(child: CircularProgressIndicator());
///     }
///
///     if (appToolsState.hasError) {
///       return Center(child: Text(appToolsState.errorMessage!));
///     }
///
///     return SingleChildScrollView(
///       padding: const EdgeInsets.all(16),
///       child: Text(appToolsState.privacyPolicy ?? 'Politika yükleniyor...'),
///     );
///   }
/// }
/// ```

/// Örnek 4: Kullanım şartlarını görüntüleme
/// ```dart
/// class TermsConditionScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final appToolsState = ref.watch(appToolsProvider);
///
///     // İlk render'da fetch
///     ref.listen(appToolsProvider, (previous, next) {
///       if (previous == null && !next.hasTermsCondition) {
///         ref.read(appToolsProvider.notifier).fetchTermsCondition();
///       }
///     });
///
///     return Scaffold(
///       appBar: AppBar(title: const Text('Kullanım Şartları')),
///       body: appToolsState.isLoading
///           ? const Center(child: CircularProgressIndicator())
///           : SingleChildScrollView(
///               padding: const EdgeInsets.all(16),
///               child: Text(appToolsState.termsCondition ?? ''),
///             ),
///     );
///   }
/// }
/// ```

/// Örnek 5: Onboarding'de hem politika hem şartları yükleme
/// ```dart
/// class OnboardingScreen extends ConsumerStatefulWidget {
///   @override
///   ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
/// }
///
/// class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
///   @override
///   void initState() {
///     super.initState();
///     WidgetsBinding.instance.addPostFrameCallback((_) {
///       final notifier = ref.read(appToolsProvider.notifier);
///       notifier.fetchPrivacyPolicy();
///       notifier.fetchTermsCondition();
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     final appToolsState = ref.watch(appToolsProvider);
///
///     return Scaffold(
///       body: Column(
///         children: [
///           const Text('Hoş Geldiniz!'),
///           TextButton(
///             onPressed: appToolsState.hasPrivacyPolicy
///                 ? () => _showPrivacyPolicy(context, appToolsState.privacyPolicy!)
///                 : null,
///             child: const Text('Gizlilik Politikası'),
///           ),
///           TextButton(
///             onPressed: appToolsState.hasTermsCondition
///                 ? () => _showTerms(context, appToolsState.termsCondition!)
///                 : null,
///             child: const Text('Kullanım Şartları'),
///           ),
///         ],
///       ),
///     );
///   }
///
///   void _showPrivacyPolicy(BuildContext context, String policy) {
///     showDialog(
///       context: context,
///       builder: (_) => AlertDialog(
///         title: const Text('Gizlilik Politikası'),
///         content: SingleChildScrollView(child: Text(policy)),
///         actions: [
///           TextButton(
///             onPressed: () => Navigator.pop(context),
///             child: const Text('Kapat'),
///           ),
///         ],
///       ),
///     );
///   }
///
///   void _showTerms(BuildContext context, String terms) {
///     // Similar implementation
///   }
/// }
/// ```

/// Örnek 6: Web platformunda tema kontrolü
/// ```dart
/// class PlatformAwareThemeButton extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     if (kIsWeb) {
///       return const Text('Web\'de tema değiştirme devre dışı');
///     }
///
///     final themeMode = ref.watch(themeProvider);
///
///     return IconButton(
///       icon: Icon(
///         themeMode == ThemeMode.dark
///             ? Icons.light_mode
///             : Icons.dark_mode,
///       ),
///       onPressed: () {
///         ref.read(themeProvider.notifier).setTheme(
///           themeMode == ThemeMode.dark
///               ? ThemeMode.light
///               : ThemeMode.dark,
///         );
///       },
///     );
///   }
/// }
/// ```

/// Örnek 7: Error handling ile politika yükleme
/// ```dart
/// ref.listen<AppToolsState>(
///   appToolsProvider,
///   (previous, next) {
///     if (next.hasError) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(
///           content: Text(next.errorMessage!),
///           action: SnackBarAction(
///             label: 'Tekrar Dene',
///             onPressed: () {
///               ref.read(appToolsProvider.notifier).fetchPrivacyPolicy();
///             },
///           ),
///         ),
///       );
///     }
///   },
/// );
/// ```
