import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: const _ContactForm()),
        // Const kullanarak optimize ettik
        const SizedBox(width: 60),
        Expanded(child: const _ContactInfo()),
      ],
    );
  }

  Widget _buildNarrowLayout(final BuildContext context) {
    return Column(
      children: [
        const _ContactForm(),
        const SizedBox(height: 40),
        const _ContactInfo(),
      ],
    );
  }
}

// FORM ALANI AYRI BİR WIDGET OLARAK ÇIKARILDI (Performans için)
class _ContactForm extends StatelessWidget {
  const _ContactForm();

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
            '(HENÜZ AKTİF DEĞİLDİR)',
            style: TextStyle(
              fontSize: context.captionSize,
              color: WebColors.warning,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          const _FormField(label: 'Adınız Soyadınız', icon: Icons.person),
          const _FormField(label: 'E-posta Adresiniz', icon: Icons.email),
          const _FormField(label: 'Konu', icon: Icons.subject),
          const _FormField(
              label: 'Mesajınız', icon: Icons.message, maxLines: 4),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Form henüz aktif değil!'),
                    backgroundColor: WebColors.warning,
                  ),
                );
              },
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

  const _FormField({
    required this.label,
    required this.icon,
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

// INFO BÖLÜMÜ AYRI WIDGET
class _ContactInfo extends StatelessWidget {
  const _ContactInfo();

  @override
  Widget build(final BuildContext context) {
    final contacts = [
      {
        'icon': Icons.location_on,
        'title': 'Adres',
        'info': '--------- Caddesi No: ---\nAtaşehir/İSTANBUL',
        'color': WebColors.error,
      },
      {
        'icon': Icons.phone,
        'title': 'Telefon',
        'info': '+90 -----',
        'color': WebColors.success,
      },
      {
        'icon': Icons.email,
        'title': 'E-posta',
        'info': '----@-----',
        'color': WebColors.info,
      },
      {
        'icon': Icons.confirmation_number,
        'title': 'Bilet Rezervasyon',
        'info': '----@----\n+90 ------',
        'color': WebColors.primaryGold,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contacts.map((final contact) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
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
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
