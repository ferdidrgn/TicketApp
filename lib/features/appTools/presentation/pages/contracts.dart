import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_html_css/simple_html_css.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/core/util/comminucation_actions.dart';
import 'package:ticketapp/shared/widgets/background/shimmer_components.dart';
import 'package:ticketapp/shared/widgets/footers/footer.dart';
import 'package:ticketapp/shared/widgets/ticket/ticket_kit.dart';
import 'package:ticketapp/shared/widgets/ticket/ticket_listing.dart';
import 'package:ticketapp/shared/widgets/top_header_with_back_button.dart';
import '../providers/app_tools_provider.dart';

/// Okuma sütununun genişliği (satır ≤ ~75 karakter).
const double _kReadingWidth = 720;

/// YASAL BİLGİLER — sade bir okuma sayfası.
///
/// - telefon/tablet: `BasePageWrapper` (geri butonlu başlık) + iki sekme
///   (kaydırılabilir `TabBarView`), okuma sütunu tablette ≤720.
/// - masaüstü web: kendi `Scaffold`'u (önceden YOKTU — metinler Material
///   atası olmadan çiziliyordu) + temanın zemini; başlık, sekmeler ve seçili
///   belge tek bir kayan sütunda, en altta tam genişlikte `Footer`.
///
/// Veri: `privacyPolicyProvider` / `termsConditionProvider`, yenileme
/// `ref.invalidate` — değişmedi. Yüklenirken metin iskeleti, hata/boş
/// durumda bilet dilindeki `TicketNotice`.
class ContractsPage extends ConsumerWidget {
  const ContractsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (context.isDesktop) return _buildDesktopPage(context, ref);

    return DefaultTabController(
      length: 2,
      child: BasePageWrapper(
        title: 'Yasal bilgiler',
        subtitle: 'Gizlilik politikası ve kullanım şartları.',
        rightIcon: Icons.gavel_rounded,
        showBackButton: true,
        layoutConfig: BasePageLayoutConfig(
          backgroundColor: context.colors.surface,
          safeAreaTop: true,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kReadingWidth),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _buildTabBar(context),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildMobileTab(
                        context,
                        ref.watch(privacyPolicyProvider),
                        () => ref.invalidate(privacyPolicyProvider),
                      ),
                      _buildMobileTab(
                        context,
                        ref.watch(termsConditionProvider),
                        () => ref.invalidate(termsConditionProvider),
                      ),
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

  // --- SEKMELER ---
  // Bilet alanları gibi sade: alt çizgili sekme, seçili olan temanın
  // vurgusuyla çizili. 48dp yükseklik, odak/hover katmanı temadan.
  Widget _buildTabBar(final BuildContext context) {
    final cs = context.colors;
    return Semantics(
      container: true,
      label: 'Gizlilik ve şartlar sekmeleri',
      child: TabBar(
        dividerColor: cs.outlineVariant,
        indicatorColor: cs.primary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: cs.onSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        overlayColor: WidgetStateProperty.resolveWith((final states) {
          if (states.contains(WidgetState.focused))
            return cs.primary.withOpacity(0.14);
          if (states.contains(WidgetState.hovered))
            return cs.onSurface.withOpacity(0.05);
          if (states.contains(WidgetState.pressed))
            return cs.primary.withOpacity(0.10);
          return null;
        }),
        tabs: const [
          Tab(height: 48, text: 'Gizlilik politikası'),
          Tab(height: 48, text: 'Kullanım şartları'),
        ],
      ),
    );
  }

  // --- 📱 TELEFON / TABLET SEKMESİ ---
  Widget _buildMobileTab(final BuildContext context,
      final AsyncValue<String?> doc, final VoidCallback onRefresh) {
    final Widget body = doc.when(
      data: (final content) => content == null
          ? const _DocumentMissing()
          : _DocumentText(content: content),
      loading: () => const _DocumentSkeleton(),
      error: (final err, final _) => _DocumentError(onRetry: onRefresh),
    );

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: context.colors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.huge),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [body],
      ),
    );
  }

  // 🔥 DÜZELTME (korunuyor): Burada eskiden "Son Güncelleme:
  // ${DateTime.now()...}" vardı — belge gerçekte ne zaman değiştiğinden
  // bağımsız olarak HER ZAMAN "bugün" güncellenmiş gibi görünüyordu.
  // Firestore'daki AppTools dokümanında gerçek bir "son güncelleme" alanı
  // yok; uydurma tarih gösterilmiyor.

  // --- 🖥️ MASAÜSTÜ / WEB ---
  Widget _buildDesktopPage(final BuildContext context, final WidgetRef ref) {
    // İki belge de ConsumerWidget'ın kendi build'inde izlenir; seçili sekme
    // aşağıda sadece hangisinin gösterileceğini belirler.
    final AsyncValue<String?> privacyDoc = ref.watch(privacyPolicyProvider);
    final AsyncValue<String?> termsDoc = ref.watch(termsConditionProvider);
    return Scaffold(
        backgroundColor: context.colors.surface,
        body: TicketStage(
          themed: true,
          spotlight: false,
          child: DefaultTabController(
            length: 2,
            child: Builder(
              builder: (final context) {
                final TabController tabs = DefaultTabController.of(context);
                return ListView(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: _kReadingWidth),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                              AppSpacing.huge, AppSpacing.xxl, AppSpacing.section),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const TopHeaderWithBackButton(
                                title: 'Yasal bilgiler',
                                subtitle:
                                    'Gizlilik politikası ve kullanım şartları.',
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              _buildTabBar(context),
                              const SizedBox(height: AppSpacing.xxxl),
                              // Seçili belge — tek kayan sütunda, footer
                              // sayfanın en altında tam genişlikte kalsın.
                              AnimatedBuilder(
                                animation: tabs,
                                builder: (final context, final _) {
                                  final bool privacy = tabs.index == 0;
                                  final AsyncValue<String?> doc =
                                      privacy ? privacyDoc : termsDoc;
                                  void retry() {
                                    if (privacy) {
                                      ref.invalidate(privacyPolicyProvider);
                                    } else {
                                      ref.invalidate(termsConditionProvider);
                                    }
                                  }

                                  return doc.when(
                                    data: (final content) => content == null
                                        ? const _DocumentMissing()
                                        : SelectionArea(
                                            child:
                                                _DocumentText(content: content),
                                          ),
                                    loading: () => const _DocumentSkeleton(),
                                    error: (final err, final _) =>
                                        _DocumentError(onRetry: retry),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Footer(),
                  ],
                );
              },
            ),
          ),
        ),
      );
  }
}

/// Belge metni (Firestore'daki HTML) — rahat satır aralığı, temanın metin
/// rengi, kutusuz.
class _DocumentText extends StatelessWidget {
  final String content;
  const _DocumentText({required this.content});

  @override
  Widget build(final BuildContext context) => Text.rich(
        HTML.toTextSpan(
          context,
          content,
          defaultTextStyle: TextStyle(
            fontSize: 16,
            height: 1.65,
            color: context.colors.onSurface,
            decoration: TextDecoration.none,
          ),
        ),
      );
}

/// Yüklenirken: metin satırı şeklinde iskelet (çıplak spinner değil).
class _DocumentSkeleton extends StatelessWidget {
  const _DocumentSkeleton();

  static const List<double> _lines = [
    0.55, 1, 1, 0.9, 1, 0.7, 0, 1, 1, 0.85, 1, 0.6, //
  ];

  @override
  Widget build(final BuildContext context) => Semantics(
        label: 'Belge yükleniyor',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final double f in _lines)
              f == 0
                  ? const SizedBox(height: AppSpacing.xl)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: FractionallySizedBox(
                        widthFactor: f,
                        child: const ShimmerLoading(
                            height: 14,
                            width: double.infinity,
                            borderRadius: AppRadius.xs),
                      ),
                    ),
          ],
        ),
      );
}

class _DocumentError extends StatelessWidget {
  final VoidCallback onRetry;
  const _DocumentError({required this.onRetry});

  @override
  Widget build(final BuildContext context) => Center(
        child: TicketNotice(
          label: 'BELGE',
          title: 'Belge yüklenemedi',
          message: 'Bağlantını kontrol edip tekrar dene.',
          actionLabel: 'Tekrar dene',
          actionIcon: Icons.refresh_rounded,
          onAction: onRetry,
        ),
      );
}

class _DocumentMissing extends StatelessWidget {
  const _DocumentMissing();

  @override
  Widget build(final BuildContext context) => Center(
        child: TicketNotice(
          label: 'BELGE',
          title: 'Metin henüz yayımlanmadı',
          message:
              'Bu belge şu an görüntülenemiyor. Sorun için bize e-posta ile '
              'ulaşabilirsin.',
          actionLabel: 'E-posta gönder',
          actionIcon: Icons.mail_outline_rounded,
          onAction: () => TiyatrolCommunicationActions.sendEmail(
              subject: 'TiyatRol Yasal Bilgiler'),
        ),
      );
}
