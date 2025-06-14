import 'package:flutter/material.dart';

// 1. EKİP TANIŞMA BÖLÜMÜ - Yaratıcı grid layout
class TeamIntroSection extends StatelessWidget {
  const TeamIntroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Column(
        children: [
          // Başlık
          Text(
            'SANATIMIZDAKİ RUHLAR',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Her oyunun arkasında tutkulu bir hikaye, her karakterin içinde deneyimli bir sanatçı var',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 60),

          // Asymmetric Grid Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol Kolon
              Expanded(
                child: Column(
                  children: [
                    _buildTeamCard(
                      'assets/director.jpg',
                      'YÖNETMEN',
                      'Ahmet Kaya',
                      '15 yıllık deneyim ile sahneye hayat veren vizyon sahibi',
                      Colors.orange.shade400,
                    ),
                    const SizedBox(height: 30),
                    _buildTeamCard(
                      'assets/lighting.jpg',
                      'IŞIK TASARIM',
                      'Elif Demir',
                      'Işığın büyüsü ile atmosfer yaratan sanatçı',
                      Colors.blue.shade400,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),

              // Sağ Kolon (Offset)
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 60), // Offset
                    _buildTeamCard(
                      'assets/sound.jpg',
                      'SES TASARIM',
                      'Murat Özkan',
                      'Sesin gücü ile duyguları harekete geçiren teknisyen',
                      Colors.green.shade400,
                    ),
                    const SizedBox(height: 30),
                    _buildTeamCard(
                      'assets/costume.jpg',
                      'KOSTÜM TASARIM',
                      'Zeynep Yılmaz',
                      'Kumaşlarla karakter yaratan yaratıcı tasarımcı',
                      Colors.purple.shade400,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(String imagePath, String role, String name, String description, Color accentColor) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.4,
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

// 2. YARATICI SÜREÇ BÖLÜMÜ - Behind the scenes
class CreativeProcessSection extends StatelessWidget {
  const CreativeProcessSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade50,
            Colors.grey.shade100,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'YARATICI SÜRECİMİZ',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 60),

          // Process Timeline
          Row(
            children: [
              Expanded(child: _buildProcessStep('1', 'HAYAL', 'Hikayenin doğuşu', Icons.lightbulb_outline)),
              _buildArrow(),
              Expanded(child: _buildProcessStep('2', 'TASARIM', 'Görsel kimlik', Icons.palette_outlined)),
              _buildArrow(),
              Expanded(child: _buildProcessStep('3', 'PROVA', 'Sahne çalışması', Icons.theater_comedy_outlined)),
              _buildArrow(),
              Expanded(child: _buildProcessStep('4', 'SAHNE', 'İzleyiciyle buluşma', Icons.star_outline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String number, String title, String subtitle, IconData icon) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 40,
            color: Colors.orange.shade400,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          number,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60),
      child: Icon(
        Icons.arrow_forward,
        color: Colors.grey.shade400,
        size: 30,
      ),
    );
  }
}

// 3. EKİP DEĞERLERİ BÖLÜMÜ - Values showcase
class TeamValuesSection extends StatelessWidget {
  const TeamValuesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Column(
        children: [
          Text(
            'SANAT FELSEFEMİZ',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 60),

          // Values Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 30,
            crossAxisSpacing: 30,
            childAspectRatio: 1.2,
            children: [
              _buildValueCard(
                'ÖZGÜNLÜK',
                'Her oyunumuzda kendi sesimizi bulmaya odaklanıyoruz',
                Icons.fingerprint,
                Colors.blue.shade400,
              ),
              _buildValueCard(
                'TUTKU',
                'Sahneye olan sevgimizle her performansı özelleştiriyoruz',
                Icons.favorite_border,
                Colors.red.shade400,
              ),
              _buildValueCard(
                'YENILIK',
                'Geleneksel tiyatroyu modern yorumlarla harmanlıyoruz',
                Icons.auto_awesome,
                Colors.purple.shade400,
              ),
              _buildValueCard(
                'TOPLUM',
                'İzleyicimizle güçlü bağlar kurarak sanatı paylaşıyoruz',
                Icons.people_outline,
                Colors.green.shade400,
              ),
              _buildValueCard(
                'KALİTE',
                'Her detayda mükemmelliği hedefleyen titiz çalışma',
                Icons.diamond_outlined,
                Colors.orange.shade400,
              ),
              _buildValueCard(
                'HAYAT',
                'Sanatın günlük yaşamı dönüştürme gücüne inanıyoruz',
                Icons.wb_sunny_outlined,
                Colors.amber.shade600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: color,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// 4. BAŞARILARIMIZ VE İSTATİSTİKLER
class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade800,
            Colors.black87,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'BİZİMLE GURUR DUYDUKLARIMIZ',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 60),

          // Stats Row
          Row(
            children: [
              Expanded(child: _buildStat('150+', 'OYNANAN OYUN', Icons.theater_comedy)),
              Expanded(child: _buildStat('50K+', 'MUTLU İZLEYİCİ', Icons.people)),
              Expanded(child: _buildStat('25+', 'ÖDÜL & BAŞARI', Icons.emoji_events)),
              Expanded(child: _buildStat('12', 'YILLIK DENEYİM', Icons.timeline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String number, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 50,
          color: Colors.orange.shade400,
        ),
        const SizedBox(height: 20),
        Text(
          number,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade300,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}