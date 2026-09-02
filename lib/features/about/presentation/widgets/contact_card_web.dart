import 'package:flutter/material.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';

class ContactCard extends StatefulWidget {
  const ContactCard({super.key});

  @override
  State<ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<ContactCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: double.infinity,
      padding: context.responsive(
        mobile: const EdgeInsets.all(24),
        desktop: const EdgeInsets.all(60),
      ),
      decoration: const BoxDecoration(
        gradient: WebColors.backgroundGradient,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (final bounds) =>
                  WebColors.goldGradient.createShader(bounds),
              child: Text(
                'İLETİŞİM',
                style: TextStyle(
                  fontSize: context.responsive(mobile: 36.0, desktop: 56.0),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 4,
              decoration: BoxDecoration(
                gradient: WebColors.goldGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 48),
            LayoutBuilder(
              builder: (final context, final constraints) {
                return constraints.maxWidth > 800
                    ? _buildWideLayout(context)
                    : _buildNarrowLayout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(final BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _ContactForm()),
        SizedBox(width: 60),
        Expanded(child: _ContactInfo()),
      ],
    );
  }

  Widget _buildNarrowLayout(final BuildContext context) {
    return const Column(
      children: [
        _ContactForm(),
        SizedBox(height: 40),
        _ContactInfo(),
      ],
    );
  }
}

/// 📧 Gerçek çalışan iletişim formu — arka planda sunucu yok, cihazın
/// e-posta uygulamasını (mailto:) açarak `iletisim@tiyatrol.com` adresine
/// doğrudan iletiyor. Eskiden bu form dekoratifti (girilen değerler hiçbir
/// yere gitmiyordu, "GÖNDER" sadece "henüz aktif değil" uyarısı veriyordu).
class _ContactForm extends StatefulWidget {
  const _ContactForm();

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final message = _messageController.text.trim();
    if (name.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en azından adını ve mesajını yaz.'),
          backgroundColor: WebColors.warning,
        ),
      );
      return;
    }

    final subject = _subjectController.text.trim().isNotEmpty
        ? _subjectController.text.trim()
        : 'Web sitesi iletişim formu';
    final email = _emailController.text.trim();
    final body = 'Gönderen: $name'
        '${email.isNotEmpty ? ' ($email)' : ''}'
        '\n\n$message';

    TiyatrolCommunicationActions.sendEmail(subject: subject, body: body);
  }

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WebColors.darkBlueSurface.withOpacity(0.5),
            WebColors.darkBlueAccent.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: WebColors.primaryGold.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: WebColors.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.email,
                    color: WebColors.darkBlueBackground, size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                'Bize Ulaşın',
                style: TextStyle(
                  fontSize: context.subtitleSize,
                  fontWeight: FontWeight.w900,
                  color: WebColors.primaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gönder\'e bastığında e-posta uygulaman açılır, mesajın doğrudan '
            'ekibimize gider.',
            style: TextStyle(
              fontSize: context.captionSize,
              color: WebColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _FormField(
              label: 'Adınız Soyadınız',
              icon: Icons.person,
              controller: _nameController),
          _FormField(
              label: 'E-posta Adresiniz',
              icon: Icons.email,
              controller: _emailController),
          _FormField(
              label: 'Konu', icon: Icons.subject, controller: _subjectController),
          _FormField(
              label: 'Mesajınız',
              icon: Icons.message,
              maxLines: 4,
              controller: _messageController),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ).copyWith(
                backgroundColor:
                    MaterialStateProperty.resolveWith<Color>((final states) {
                  return WebColors.primaryGold;
                }),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: WebColors.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                alignment: Alignment.center,
                child: Text(
                  'GÖNDER',
                  style: TextStyle(
                    fontSize: context.bodySize,
                    fontWeight: FontWeight.w900,
                    color: WebColors.darkBlueBackground,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// FORM FIELD AYRI WIDGET
class _FormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final int maxLines;
  final TextEditingController controller;

  const _FormField({
    required this.label,
    required this.icon,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: WebColors.primaryGoldLight, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.captionSize,
                  color: WebColors.primaryGoldLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
                color: WebColors.whiteText, fontSize: context.bodySize),
            decoration: InputDecoration(
              filled: true,
              fillColor: WebColors.darkBlueBackground.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: WebColors.primaryGold.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: WebColors.primaryGold.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: WebColors.primaryGold, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// INFO BÖLÜMÜ AYRI WIDGET — SADECE GERÇEK/ÇALIŞAN KANALLAR.
// Eskiden burada "---------- Caddesi No: ---", "+90 -----" gibi hiç
// doldurulmamış sahte yer tutucular vardı; gerçek adres/telefon bilgisi
// elimizde olmadığı için uydurmak yerine, ELİMİZDEKİ gerçek ve ÇALIŞAN
// kanallar (e-posta, Instagram, uygulama içi Yardım Merkezi) gösteriliyor.
class _ContactInfo extends StatelessWidget {
  const _ContactInfo();

  @override
  Widget build(final BuildContext context) {
    final contacts = [
      {
        'icon': Icons.email,
        'title': 'E-posta',
        'info': TiyatrolCommunicationActions.officialEmail,
        'color': WebColors.info,
        'onTap': () => TiyatrolCommunicationActions.sendEmail(),
      },
      {
        'icon': Icons.camera_alt_rounded,
        'title': 'Instagram',
        'info': '@${TiyatrolCommunicationActions.instagramHandle}',
        'color': WebColors.error,
        'onTap': () => TiyatrolCommunicationActions.openInstagram(),
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': 'Yardım Merkezi',
        'info': 'Bilet ve rezervasyonlarınla ilgili sorular için '
            'uygulama içi Yardım Merkezi.',
        'color': WebColors.success,
        'onTap': () => NavigationHandler.goToHelpSupport(context),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contacts.map((final contact) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: contact['onTap']! as VoidCallback,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    WebColors.darkBlueSurface.withOpacity(0.5),
                    WebColors.darkBlueAccent.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(
                    color: contact['color']! as Color,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (contact['color']! as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      contact['icon']! as IconData,
                      color: contact['color']! as Color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact['title']! as String,
                          style: TextStyle(
                            fontSize: context.bodySize,
                            fontWeight: FontWeight.w900,
                            color: contact['color']! as Color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          contact['info']! as String,
                          style: TextStyle(
                            fontSize: context.captionSize + 1,
                            color: WebColors.lightWhite,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.3), size: 14),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
