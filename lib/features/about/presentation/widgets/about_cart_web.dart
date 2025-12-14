import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import '../../../../../core/theme/app_colors.dart';

class AboutCard extends StatefulWidget {
  const AboutCard({super.key});

  @override
  State<AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<AboutCard>
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
      // Responsive Padding
      padding: context.responsive(
        mobile: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        desktop: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
      ),
      decoration: const BoxDecoration(
        gradient: WebColors.backgroundGradient,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Başlık
            ShaderMask(
              shaderCallback: (final bounds) =>
                  WebColors.goldGradient.createShader(bounds),
              child: Text(
                'HAKKIMIZDA',
                style: TextStyle(
                  fontSize: context.responsive(mobile: 32.0, desktop: 56.0),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: context.isMobile ? 2 : 3,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: context.responsive(mobile: 60.0, desktop: 100.0),
              height: 4,
              decoration: BoxDecoration(
                gradient: WebColors.goldGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 48),

            // Mobil/Tablet/Desktop Düzeni
            context.isDesktop
                ? _buildWideLayout(context)
                : _buildNarrowLayout(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(final BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: _buildAboutText(context)),
        const SizedBox(width: 60),
        Expanded(flex: 4, child: _buildStatsGrid(context)),
      ],
    );
  }

  Widget _buildNarrowLayout(final BuildContext context) {
    return Column(
      children: [
        _buildAboutText(context),
        const SizedBox(height: 40),
        _buildStatsGrid(context),
      ],
    );
  }

  Widget _buildAboutText(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildParagraph(
          context,
          'TiyatRol Sahne Sanatları Tiyatro Topluluğu, 2018 yılında kurulan ve İstanbul merkezli faaliyet gösteren amatör - profesyonel bir tiyatro grubudur. Amacımız, klasik eserleri ya da farklı oyunları modern yorumlarla sahneye taşımak ve özgün metinlerle çağdaş tiyatro sanatına katkıda bulunmaktır.',
          isFirst: true,
        ),
        const SizedBox(height: 24),
        _buildParagraph(
          context,
          'Ekibimiz, deneyimli oyuncular, yaratıcı yönetmenler ve yetenekli sahne sanatçılarından oluşmaktadır. Her oyunumuzda kaliteyi ve sanatsal bütünlüğü ön planda tutarak, seyircilerimize unutulmaz deneyimler yaşatmayı hedefliyoruz.',
        ),
        const SizedBox(height: 24),
        _buildParagraph(
          context,
          'Tiyatro sanatını sadece sahne performansı olarak görmeyip, toplumsal dönüşüme katkıda bulunan bir araç olarak değerlendiriyoruz. Bu anlayışla hareket ederek, her yaştan seyirciye hitap eden, düşündüren ve duygulandıran yapımlar üretiyoruz.',
        ),
      ],
    );
  }

  Widget _buildParagraph(final BuildContext context, final String text,
      {final bool isFirst = false}) {
    return Container(
      padding: EdgeInsets.all(context.responsive(mobile: 16.0, desktop: 20.0)),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFirst
              ? WebColors.primaryGold.withOpacity(0.5)
              : WebColors.primaryGold.withOpacity(0.2),
          width: isFirst ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 12),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              gradient: WebColors.goldGradient,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: context.bodySize + (context.isDesktop ? 1 : 0),
                color: WebColors.lightWhite,
                height: 1.6,
                fontWeight: isFirst ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(final BuildContext context) {
    final stats = [
      {
        'icon': Icons.theater_comedy,
        'number': '10+',
        'label': 'Sahnelenen Oyun',
        'color': WebColors.primaryGold,
      },
      {
        'icon': Icons.people,
        'number': '10k+',
        'label': 'Seyirci',
        'color': WebColors.info,
      },
      {
        'icon': Icons.calendar_today,
        'number': '7',
        'label': 'Yıllık Deneyim',
        'color': WebColors.success,
      },
      {
        'icon': Icons.favorite,
        'number': '10',
        'label': 'Gönül Vermiş Kişiler',
        'color': WebColors.error,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.responsive(mobile: 2, desktop: 2),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        // Kartın en/boy oranı
        childAspectRatio:
            context.responsive(mobile: 1.1, tablet: 1.5, desktop: 1.2),
      ),
      itemCount: stats.length,
      itemBuilder: (final context, final index) {
        final stat = stats[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 800 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (final context, final value, final child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: EdgeInsets.all(
                    context.responsive(mobile: 12.0, desktop: 20.0)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      WebColors.darkBlueSurface,
                      WebColors.darkBlueAccent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (stat['color']! as Color).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (stat['color']! as Color).withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      stat['icon']! as IconData,
                      color: stat['color']! as Color,
                      size: context.iconLarge,
                    ),
                    SizedBox(
                        height: context.responsive(mobile: 8.0, desktop: 12.0)),
                    Text(
                      stat['number']! as String,
                      style: TextStyle(
                        fontSize:
                            context.responsive(mobile: 20.0, desktop: 32.0),
                        fontWeight: FontWeight.w900,
                        color: stat['color']! as Color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['label']! as String,
                      style: TextStyle(
                        fontSize: context.captionSize,
                        color: WebColors.lightWhite,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
