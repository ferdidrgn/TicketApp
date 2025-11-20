import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import '../../../../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// 1. GÖZ YAP VAZ YAP LANDING
// ═══════════════════════════════════════════════════════════
class GozYapVazYapLanding extends StatefulWidget {
  const GozYapVazYapLanding({super.key});

  @override
  State<GozYapVazYapLanding> createState() => _GozYapVazYapLandingState();
}

class _GozYapVazYapLandingState extends State<GozYapVazYapLanding>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
      color: WebColors.darkBlueBackground,
      child: context.isMobile ? _buildMobile() : _buildDesktop(),
    );
  }

  Widget _buildMobile() {
    return Column(
      children: [
        _buildImageCard(context,
            'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgÃ¶zKapVazYap%2F20220610_165452.jpg?alt=media&token=1ebd1bc9-0df5-46fd-bce5-b7400d5d81ae',
            height: context.screenHeight * 0.4),
        _buildContentSection(),
        _buildImageCard(context,
            'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgÃ¶zKapVazYap%2F20220610_174009.jpg?alt=media&token=40652d5a-31fe-4dec-9df1-61e516dfda27',
            height: context.screenHeight * 0.4),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDesktop() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildImageCard(context,
              'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgÃ¶zKapVazYap%2F20220610_165452.jpg?alt=media&token=1ebd1bc9-0df5-46fd-bce5-b7400d5d81ae',
              height: context.screenHeight),
        ),
        Expanded(
          flex: 4,
          child: _buildContentSection(),
        ),
        Expanded(
          flex: 3,
          child: _buildImageCard(context,
              'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FgÃ¶zKapVazYap%2F20220610_174009.jpg?alt=media&token=40652d5a-31fe-4dec-9df1-61e516dfda27',
              height: context.screenHeight),
        ),
      ],
    );
  }

  Widget _buildImageCard(final BuildContext context, final String url,
      {required final double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              WebColors.darkBlueBackground.withOpacity(0.4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: WebColors.backgroundGradient,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: TheaterPatternPainter(),
            ),
          ),
          Padding(
            padding: context.paddingAll,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    ShaderMask(
                      shaderCallback: (final bounds) =>
                          WebColors.goldGradient.createShader(bounds),
                      child: Text(
                        'GÖZLERİMİ KAPARIM\nVAZİFEMİ YAPARIM',
                        style: TextStyle(
                          fontSize: context.titleSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Konum
                    _buildInfoBox(
                      icon: Icons.location_on_rounded,
                      title: '1889 SES TİYATROSU',
                      subtitle: '(TAKSİM)',
                    ),

                    const SizedBox(height: 32),

                    _buildCrewInfo('Yazan', 'Haldun Taner', Icons.create),
                    const SizedBox(height: 16),
                    _buildCrewInfo(
                        'Yönetmen', 'Efsun Kaygusuz', Icons.theater_comedy),

                    const SizedBox(height: 32),

                    _buildDivider(),

                    const SizedBox(height: 32),

                    // Açıklama
                    Text(
                      'Haldun Taner\'in bu iki perdelik oyunu, Türkiye\'nin yaklaşık 70 yıllık siyasi, ekonomik ve toplumsal durumunu birbirine zıt iki kimlik üzerinden ele alarak, toplumumuza bir ayna tutuyor.',
                      style: TextStyle(
                        fontSize: context.bodySize,
                        color: WebColors.lightWhite,
                        height: 1.8,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'İki çocukluk arkadaşı olan baş karakterlerden Vicdani, saf, iyi niyetli, dürüst ve uysal bir kişiliğe sahipken; Efruz ise köşe dönücü, iş bitirici ve fırsatçı biridir.',
                      style: TextStyle(
                        fontSize: context.bodySize,
                        color: WebColors.textSecondary,
                        height: 1.8,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Ekip
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: WebColors.darkBlueAccent.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: WebColors.primaryGold.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EKİP',
                            style: TextStyle(
                              fontSize: context.subtitleSize,
                              fontWeight: FontWeight.bold,
                              color: WebColors.primaryGold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildCrewMember('Işık Tasarımı', 'Emre Kahraman'),
                          _buildCrewMember('Ses & Efekt', 'Gökhan Şener'),
                          _buildCrewMember('Afiş Tasarımı', 'Tayfun Kızıldağ'),
                          _buildCrewMember('Dansçı', 'Burcu Koçyiğit'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(
      {required final IconData icon,
      required final String title,
      required final String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: WebColors.goldGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: WebColors.primaryGold.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: WebColors.darkBlueBackground, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: context.subtitleSize,
                  fontWeight: FontWeight.bold,
                  color: WebColors.darkBlueBackground,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: context.bodySize,
                  color: WebColors.darkBlueSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCrewInfo(
      final String role, final String name, final IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: WebColors.goldGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: WebColors.darkBlueBackground, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: TextStyle(
                  fontSize: context.captionSize,
                  color: WebColors.textSecondary,
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  fontSize: context.bodySize + 2,
                  fontWeight: FontWeight.bold,
                  color: WebColors.whiteText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCrewMember(final String role, final String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: WebColors.primaryGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: context.bodySize, color: WebColors.lightWhite),
                children: [
                  TextSpan(
                    text: '$role: ',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: WebColors.primaryGoldLight),
                  ),
                  TextSpan(text: name),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            WebColors.primaryGold,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CUSTOM PAINTER
// ═══════════════════════════════════════════════════════════
class TheaterPatternPainter extends CustomPainter {
  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..color = WebColors.primaryGold.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final spacing = 50.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => false;
}
