import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/top_header_with_back_button.dart';

/// SSS listesi — gerçek arama filtrelemesi bunun üzerinde çalışır. Her
/// cevap uygulamanın GERÇEK davranışını anlatır (eski "Sanatçı profili:
/// profil düzenlemede yeteneklerini belirt" maddesi kaldırıldı — kullanıcı
/// modelinde böyle bir alan/ekran yok).
const List<(String, String)> _kFaqEntries = [
  (
    'Biletimi nasıl bulabilirim?',
    'Profil sayfasındaki Biletlerim bölümünden (ya da ana sayfanın üstündeki '
        'bilet simgesinden) yaklaşan ve geçmiş tüm biletlerine ulaşırsın. '
        'Her biletin QR kodu bilet detayında.'
  ),
  (
    'Favorilerimi nerede görürüm?',
    'Giriş yaptıktan sonra Profil sayfasındaki Favorilerim bölümünde.'
  ),
  (
    'Bazı oyunlarda neden başka bir siteye yönlendiriliyorum?',
    'O oyunların biletleri resmi satış platformunda satılıyor. TiyatRol seni '
        'doğrudan o oyunun satış sayfasına götürür.'
  ),
  (
    'Uygulamanın görünümünü nasıl değiştiririm?',
    'Profil sayfasından Ayarlar\'a gir; Tema bölümünden Gündüz, Gece, Oto '
        '(cihazına göre), Doğa, Ahenk ya da Özel seçebilirsin. Özel temada '
        'vurgu rengini de orada belirlersin.'
  ),
  (
    'Bildirimlerimi nereden görürüm?',
    'Giriş yaptıysan ana sayfanın üstündeki zil simgesinden. Okunmamış '
        'bildirim sayısı simgenin üstünde görünür.'
  ),
];

/// YARDIM VE DESTEK — sakin bir okuma/yardım sayfası.
///
/// Sıra kullanıcının işine göre: önce ARA → SSS'de cevabı bul; bulamazsa
/// "destek bileti" (bilet dili) ile bize ulaş. Tek birincil aksiyon:
/// "E-posta gönder" (damga butonu); WhatsApp ikincil, Instagram/Facebook
/// koçanda. Hepsi gerçek `TiyatrolCommunicationActions`.
///
/// - telefon/tablet: `BasePageWrapper` + tek sütun (tablette ≤720).
/// - masaüstü web: kendi `Scaffold`'u + temanın zemini; solda SSS okuma
///   sütunu, sağda destek bileti ("kenar çubuğu + sütun"); en altta
///   tam genişlikte `Footer`.
class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<(String, String)> get _filteredFaq => _query.isEmpty
      ? _kFaqEntries
      : _kFaqEntries
          .where((final entry) =>
              entry.$1.toLowerCase().contains(_query) ||
              entry.$2.toLowerCase().contains(_query))
          .toList();

  @override
  Widget build(final BuildContext context) {
    if (context.isDesktop) return _buildDesktopPage(context);
    if (context.isTablet) return _buildTabletPage(context);
    return _buildMobilePage(context);
  }

  Widget _buildMobilePage(final BuildContext context) {
    final double bottom = MediaQuery.paddingOf(context).bottom;
    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        safeAreaTop: true,
      ),
      title: 'Yardım ve destek',
      subtitle: 'Sorularına hızlıca cevap bul.',
      rightIcon: Icons.support_agent_rounded,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.pagePadding.left,
            AppSpacing.lg,
            context.pagePadding.right,
            AppSpacing.huge + bottom,
          ),
          children: [
            _buildSearchBox(context),
            const SizedBox(height: AppSpacing.xxxl),
            ..._buildFaqSection(context),
            const SizedBox(height: AppSpacing.huge),
            const _SupportTicket(),
          ],
        ),
      ),
    );
  }

  /// Tablet: SSS sütunu + sabit genişlikte destek bileti (masaüstü gibi).
  Widget _buildTabletPage(final BuildContext context) => BasePageWrapper(
        showBackButton: true,
        showFab: false,
        layoutConfig: BasePageLayoutConfig(
          backgroundColor: context.colors.surface,
          safeAreaTop: true,
        ),
        title: 'Yardım ve destek',
        subtitle: 'Sorularına hızlıca cevap bul.',
        rightIcon: Icons.support_agent_rounded,
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: context.pagePadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearchBox(context),
                          const SizedBox(height: AppSpacing.xxxl),
                          ..._buildFaqSection(context),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxxl),
                    const SizedBox(width: 320, child: _SupportTicket()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  // --- 🖥️ MASAÜSTÜ / WEB ---
  Widget _buildDesktopPage(final BuildContext context) => Scaffold(
        backgroundColor: context.colors.surface,
        body: TicketStage(
          themed: true,
          spotlight: false,
          child: ListView(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.huge,
                        AppSpacing.huge, AppSpacing.huge, AppSpacing.section),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TopHeaderWithBackButton(
                          title: 'Yardım ve destek',
                          subtitle: 'Sorularına hızlıca cevap bul.',
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 680),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildSearchBox(context),
                                      const SizedBox(height: AppSpacing.xxxl),
                                      ..._buildFaqSection(context),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.massive),
                            const SizedBox(
                              width: 340,
                              child: _SupportTicket(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Footer(),
            ],
          ),
        ),
      );

  // --- ARAMA ---
  Widget _buildSearchBox(final BuildContext context) {
    final cs = context.colors;
    OutlineInputBorder border(final Color c, [final double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: c, width: w),
        );
    return Semantics(
      textField: true,
      label: 'Sık sorulan sorularda ara',
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: cs.onSurface, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Sorunu yaz: bilet, favori, tema…',
          hintStyle: TextStyle(color: cs.onSurfaceVariant),
          filled: true,
          fillColor: cs.surfaceContainerHigh,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: cs.onSurfaceVariant),
                  tooltip: 'Aramayı temizle',
                  onPressed: _searchController.clear,
                ),
          border: border(cs.outlineVariant),
          enabledBorder: border(cs.outlineVariant),
          focusedBorder: border(cs.primary, 2),
        ),
      ),
    );
  }

  // --- SSS ---
  List<Widget> _buildFaqSection(final BuildContext context) {
    final cs = context.colors;
    final faq = _filteredFaq;
    return [
      Semantics(
        header: true,
        child: Text(
          'Sıkça sorulanlar',
          style: GoogleFonts.playfairDisplay(
            color: cs.onSurface,
            fontSize: context.responsive(
              mobile: 22,
              tablet: 26,
              desktop: 28,
            ),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      if (faq.isEmpty)
        _buildFaqEmptyState(context)
      else
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: Column(
            children: [
              for (final entry in faq)
                _FaqItem(question: entry.$1, answer: entry.$2),
            ],
          ),
        ),
    ];
  }

  Widget _buildFaqEmptyState(final BuildContext context) {
    final cs = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.search_off_rounded, size: 22, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Bu aramaya uyan bir soru bulunamadı. Başka bir kelime dene '
              'ya da destek biletinden bize yaz.',
              style: TextStyle(
                  color: cs.onSurfaceVariant, fontSize: 15, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Erişilebilir açılır SSS satırı. `ExpansionTile` açık/kapalı durumunu
/// ekran okuyucuya kendisi bildirir; satırlar ince çizgiyle ayrılır.
class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final ShapeBorder line =
        Border(bottom: BorderSide(color: cs.outlineVariant));
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, 0, AppSpacing.xxl, AppSpacing.lg),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      shape: line,
      collapsedShape: line,
      iconColor: cs.primary,
      collapsedIconColor: cs.onSurfaceVariant,
      textColor: cs.onSurface,
      collapsedTextColor: cs.onSurface,
      title: Text(
        question,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      children: [
        Text(
          answer,
          style:
              TextStyle(color: cs.onSurfaceVariant, fontSize: 15, height: 1.5),
        ),
      ],
    );
  }
}

/// "Destek bileti": gövdede tek birincil aksiyon (E-posta) + ikincil
/// WhatsApp; koçanda sosyal hesaplar.
class _SupportTicket extends StatefulWidget {
  const _SupportTicket();

  @override
  State<_SupportTicket> createState() => _SupportTicketState();
}

class _SupportTicketState extends State<_SupportTicket> {
  bool _emailBusy = false;
  bool _whatsappBusy = false;

  Future<void> _runContact(
    final Future<void> Function() action, {
    required final void Function(bool) setBusy,
  }) async {
    if (_emailBusy || _whatsappBusy) return;
    HapticFeedback.lightImpact();
    setBusy(true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Bağlantı açılamadı. Biraz sonra tekrar dene.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setBusy(false);
    }
  }

  @override
  Widget build(final BuildContext context) => AdmitTicket(
        direction: Axis.vertical,
        shadows: AppShadows.level2(TicketInk.ink),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TicketHeaderStrip(kind: 'DESTEK'),
              const SizedBox(height: AppSpacing.xl),
              Text('Cevabını bulamadın mı?', style: TicketInk.headline(22)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bize yaz, sorunu birlikte çözelim.',
                style: TextStyle(
                  color: TicketInk.inkSoft(0.72),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TicketStampButton(
                label: 'E-posta gönder',
                leading: const Icon(Icons.mail_outline_rounded),
                loading: _emailBusy,
                loadingLabel: 'Açılıyor…',
                onTap: _emailBusy || _whatsappBusy
                    ? null
                    : () => _runContact(
                          () => TiyatrolCommunicationActions.sendEmail(),
                          setBusy: (final v) =>
                              setState(() => _emailBusy = v),
                        ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TicketStampButton(
                label: 'WhatsApp ile yaz',
                leading: const Icon(Icons.chat_bubble_outline_rounded),
                primary: false,
                loading: _whatsappBusy,
                loadingLabel: 'Açılıyor…',
                onTap: _emailBusy || _whatsappBusy
                    ? null
                    : () => _runContact(
                          TiyatrolCommunicationActions.contactWhatsApp,
                          setBusy: (final v) =>
                              setState(() => _whatsappBusy = v),
                        ),
              ),
            ],
          ),
        ),
        stub: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BİZİ TAKİP ET', style: TicketInk.label()),
              Wrap(
                children: [
                  TicketTextLink(
                    label: 'Instagram',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      TiyatrolCommunicationActions.openInstagram();
                    },
                  ),
                  TicketTextLink(
                    label: 'Facebook',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      TiyatrolCommunicationActions.openFacebook();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
