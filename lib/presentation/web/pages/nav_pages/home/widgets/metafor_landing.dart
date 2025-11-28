import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/util/responsive_utils.dart'; // Core dosyanız

class MetaforLanding extends StatefulWidget {
  const MetaforLanding({super.key});

  @override
  State<MetaforLanding> createState() => _MetaforLandingState();
}

class _MetaforLandingState extends State<MetaforLanding>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (final context, final child) {
        return Container(
          color: WebColors.darkBlueBackground,
          child: Center(
            // Desktop'ta çok genişlemeyi önle
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: context.paddingAll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. HEADER (Her zaman en üstte)
                    _buildElegantHeader(context),
                    SizedBox(height: context.gridSpacing * 2),

                    // 2. ANA LAYOUT (Desktop'ta Yan Yana, Mobilde Alt Alta)
                    if (context.isDesktop)
                      _buildDesktopLayout(context)
                    else
                      _buildMobileLayout(context),

                    SizedBox(height: context.gridSpacing * 4),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ANA LAYOUT MANTIKLARI
  // ═══════════════════════════════════════════════════════════

  /// DESKTOP LAYOUT: Sağdaki boşluğu değerlendirir
  /// Sol Taraf (%75): Görsel + Hikaye + Ekip
  /// Sağ Taraf (%25): 3'lü Bilgi Kartları (Sidebar gibi)
  Widget _buildDesktopLayout(final BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SOL ANA KOLON
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildExtendedHeroSection(context),
              SizedBox(height: context.gridSpacing * 2),
              // İçerik Grid (Hikaye ve Ekip yan yana)
              _buildContentGrid(context),
            ],
          ),
        ),

        SizedBox(width: context.gridSpacing), // Ara boşluk

        // SAĞ SIDEBAR (3'lü Kartlar buraya taşındı)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Başlık veya dekoratif bir çizgi eklenebilir
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: WebColors.primaryGold.withOpacity(0.3)))),
                child: Text(
                  "OYUN DETAYLARI",
                  style: TextStyle(
                    color: WebColors.primaryGold,
                    letterSpacing: 2,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Kartları dikey dizer
              ..._buildFeatureCards(context).map((final widget) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: widget,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  /// MOBILE/TABLET LAYOUT: Klasik alt alta sıralama
  Widget _buildMobileLayout(final BuildContext context) {
    return Column(
      children: [
        _buildExtendedHeroSection(context),
        SizedBox(height: context.gridSpacing * 2),

        // Kartlar (Mobilde yatay scroll veya alt alta, burada alt alta tercih ettik)
        Column(
          children: _buildFeatureCards(context)
              .map((final w) => Padding(
                    padding: EdgeInsets.only(bottom: context.gridSpacing),
                    child: w,
                  ))
              .toList(),
        ),

        SizedBox(height: context.gridSpacing),
        _buildContentGrid(context),
      ],
    );
  }

// ═══════════════════════════════════════════════════════════
  // 1. HEADER SECTION (GÖRSEL İLE BİREBİR TASARIM)
  // ═══════════════════════════════════════════════════════════
  Widget _buildElegantHeader(final BuildContext context) {
    // Responsive boyutlar
    final double bracketSize = context.responsive(mobile: 30.0, desktop: 50.0);
    final double spacing =
        context.responsive(mobile: 16.0, tablet: 30.0, desktop: 45.0);
    final double titleSize =
        context.responsive(mobile: 42.0, tablet: 64.0, desktop: 90.0);

    return Column(
      children: [
        // 1. Üst Soluk Çizgi
        Container(
          width: context.responsive(mobile: 60.0, desktop: 100.0),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                WebColors.primaryGold.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),

        SizedBox(height: context.responsive(mobile: 20.0, desktop: 30.0)),

        // 2. ANA SATIR: [Sol Desen] - [Boşluk] - [METAFOR] - [Boşluk] - [Sağ Desen]
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          // Desenler ve yazı dikeyde ortalı
          children: [
            // SOL DESEN (┌ Şekli)
            _buildCornerBracket(size: bracketSize, isLeft: true),

            // BOŞLUK
            SizedBox(width: spacing),

            // METAFOR YAZISI
            Stack(
              alignment: Alignment.center,
              children: [
                // Arkadaki Gölge Efekti
                Text(
                  'METAFOR',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'Playfair Display',
                    color: WebColors.primaryGold.withOpacity(0.1),
                    letterSpacing:
                        context.responsive(mobile: 4.0, desktop: 12.0),
                    height: 1.0,
                  ),
                ),
                // Öndeki Ana Beyaz Yazı
                Text(
                  'METAFOR',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'Playfair Display',
                    color: Colors.white,
                    letterSpacing:
                        context.responsive(mobile: 4.0, desktop: 12.0),
                    height: 1.0,
                  ),
                ),
              ],
            ),

            // BOŞLUK
            SizedBox(width: spacing),

            // SAĞ DESEN (┐ Şekli)
            _buildCornerBracket(size: bracketSize, isLeft: false),
          ],
        ),

        SizedBox(height: context.responsive(mobile: 20.0, desktop: 30.0)),

        // 3. Alt Parlak Çizgi
        Container(
          width: context.responsive(mobile: 100.0, desktop: 180.0),
          height: 1.5, // Biraz daha belirgin
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                WebColors.primaryGold,
                Colors.transparent,
              ],
            ),
          ),
        ),

        SizedBox(height: context.gridSpacing),

        // 4. Alt Metin (Slogan)
        Padding(
          padding: context.paddingHorizontal,
          child: Text(
            'Zamanın, Hafızanın ve İnsan Ruhunun Labirentlerinde Bir\nTiyatro Deneyimi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.responsive(mobile: 12.0, desktop: 16.0),
              color: WebColors.textSecondary,
              // Gri/Gümüş rengi
              letterSpacing: 1.2,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  /// Görseldeki gibi ince köşe desenini oluşturan yardımcı metot
  Widget _buildCornerBracket(
      {required final double size, required final bool isLeft}) {
    return Container(
      width: size,
      height: size,
      // Yıldızı sol üst veya sağ üst köşeye hizalar
      alignment: isLeft ? Alignment.topLeft : Alignment.topRight,
      decoration: BoxDecoration(
        border: Border(
          // Üst kenar her ikisinde de var
          top: const BorderSide(color: WebColors.primaryGold, width: 1),
          // Sol kenar sadece "isLeft" true ise, Sağ kenar false ise
          left: isLeft
              ? const BorderSide(color: WebColors.primaryGold, width: 1)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: WebColors.primaryGold, width: 1)
              : BorderSide.none,
        ),
      ),
      // Yıldız İkonu
      child: Padding(
        padding: EdgeInsets.all(size * 0.2), // Köşeden biraz uzaklaştırma
        child: Icon(
          Icons.star_outline,
          color: WebColors.primaryGold,
          size: size * 0.4, // Kutu boyutuna göre oranlı yıldız
        ),
      ),
    );
  }

  Widget _buildCornerDecoration(final bool isLeft) {
    return Positioned(
      top: 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: Transform.rotate(
        angle: isLeft ? 0 : 3.14,
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: WebColors.primaryGold, width: 1),
              left: BorderSide(color: WebColors.primaryGold, width: 1),
            ),
          ),
          child: const Icon(
            Icons.star_outline,
            color: WebColors.primaryGold,
            size: 16,
          ),
        ),
      ),
    );
  }

  // YENİ HERO SECTION: Arkaplanı ve Görseli Bütünleştiren Tasarım
  Widget _buildExtendedHeroSection(final BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value * 0.7),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.borderRadius(1.5)),
            // Arkaplan rengini görselin altına doğru uzatıyoruz
            color: WebColors.veryDarkBlue,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. GÖRSEL (Üst Kısım - Tam Genişlik)
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(context.borderRadius(1.5))),
                child: Container(
                  height: context.responsive(
                      mobile: 250.0, tablet: 350.0, desktop: 450.0),
                  // Eski heybetli yükseklik
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2Fai_metafor_image.png?alt=media&token=6f20f048-b88c-46c0-beb6-da4f4eb76c49',
                      ),
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
                          WebColors.veryDarkBlue.withOpacity(0.3),
                          WebColors.veryDarkBlue, // Görselin altı ile birleşsin
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. SORU KARTI (Görselin hemen devamı, bütünleşik arkaplan)
              Container(
                padding: context.paddingAll,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(context.borderRadius(1.5))),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      WebColors.veryDarkBlue,
                      WebColors.darkBlueSurface,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                          context.responsive(mobile: 10.0, desktop: 16.0)),
                      decoration: BoxDecoration(
                        color: WebColors.primaryGold.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: WebColors.primaryGold.withOpacity(0.5)),
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: WebColors.primaryGold,
                        size: context.iconLarge,
                      ),
                    ),
                    SizedBox(
                        width: context.responsive(mobile: 16.0, desktop: 24.0)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "HAYATIN LABİRENTLERİNDE",
                            style: TextStyle(
                              fontSize: context.captionSize,
                              color: WebColors.primaryGold,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Hangisi daha Tehlikelidir: Metaforlar mı yoksa Klişeler mi?",
                            style: TextStyle(
                              fontSize: context.responsive(
                                  mobile: 18.0, desktop: 24.0),
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              height: 1.3,
                              fontFamily: 'Playfair Display',
                            ),
                          ),
                        ],
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

  // 3'lü Özellik Kartlarını Widget Listesi olarak döndürür
  // Böylece hem Row hem Column içinde kullanılabilir
  List<Widget> _buildFeatureCards(final BuildContext context) {
    return [
      _buildInfoCard(
        context,
        icon: Icons.hourglass_empty,
        title: 'ZAMAN KAVRAMI',
        description: 'Doğrusal olmayan akışta, geçmiş ve gelecek yolculuğu.',
      ),
      _buildInfoCard(
        context,
        icon: Icons.fingerprint,
        title: 'KİMLİK ARAYIŞI',
        description:
            'Maskelerin ardındaki gerçek yüzler ve özünü bulma çabası.',
      ),
      _buildInfoCard(
        context,
        icon: Icons.theater_comedy,
        title: 'YENİLİKÇİ SAHNE',
        description: 'Işık, ses ve dijital sanatın harmanlandığı atmosfer.',
      ),
    ];
  }

  Widget _buildInfoCard(
    final BuildContext context, {
    required final IconData icon,
    required final String title,
    required final String description,
  }) {
    return Container(
      width: double.infinity, // Bulunduğu alanı doldursun
      padding: EdgeInsets.all(context.responsive(mobile: 16.0, desktop: 20.0)),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: WebColors.textSecondary, size: 28),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: context.subtitleSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: context.captionSize,
              // Biraz daha küçülttük ki sağa sığsın
              color: WebColors.lightWhite,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentGrid(final BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value * 0.5),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: context.isMobile
            ? _buildMobileContent(context)
            : _buildDesktopContent(context),
      ),
    );
  }

  Widget _buildMobileContent(final BuildContext context) {
    return Column(
      children: [
        _buildModernStoryCard(context),
        SizedBox(height: context.gridSpacing * 1.5),
        _buildModernTeamCard(context),
      ],
    );
  }

  Widget _buildDesktopContent(final BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildModernStoryCard(context)),
        SizedBox(width: context.gridSpacing),
        Expanded(flex: 2, child: _buildModernTeamCard(context)),
      ],
    );
  }

  Widget _buildModernStoryCard(final BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive(mobile: 20.0, desktop: 24.0)),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: WebColors.primaryGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "OYUN HAKKINDA",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gridSpacing * 1.5),
          Text(
            'Zamanın olmadığı bir yerde, eski kitaplarla dolu tozlu bir sahaf dükkânında üç kişi bir araya gelir: '
            'Hayata küsmüş, geçmişin sayfalarına sığınmış içedönük bir sahaf; yanından hiç ayrılmayan, yazar olma hayaliyle dolu genç bir adam; '
            've geçmişin gölgesinden çıkıp gelen bir genç kadın.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.6,
              fontSize: context.bodySize,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: context.gridSpacing),
          Text(
            "Metafor, insan ruhunun labirentlerinde unutulmaz bir yolculuk vaat ediyor.",
            style: TextStyle(
              color: Colors.white70,
              height: 1.6,
              fontSize: context.bodySize,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTeamCard(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: WebColors.primaryGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "YARATICI EKİP",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: WebColors.primaryGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          SizedBox(height: context.gridSpacing * 1.5),
          Column(
            children: [
              _buildCompactTeamMember(
                  context, "YAZAR", "Yekta Kopan", Icons.auto_awesome_mosaic),
              const SizedBox(height: 12),
              _buildCompactTeamMember(
                  context, "YÖNETMEN", "Gürkan Candan", Icons.visibility),
              const SizedBox(height: 12),
              _buildCompactTeamMember(context, "IŞIK & SES", "Ferdi Durgun",
                  Icons.lightbulb_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTeamMember(final BuildContext context, final String role,
      final String name, final IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: WebColors.primaryGold, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 11,
                    color: WebColors.textTertiary,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
