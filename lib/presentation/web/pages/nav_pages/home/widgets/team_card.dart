import 'package:flutter/material.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';

class TeamCard extends StatelessWidget {
  const TeamCard({super.key});

  final teamRow1 = const <TeamMember>[
    TeamMember(
      name: 'Ahmet Kaya',
      role: 'YÖNETMEN',
      description: 'Sahneye hayat veren vizyon sahibi yönetmen',
      color: Colors.blue,
    ),
    TeamMember(
      name: 'Elif Demir',
      role: 'IŞIK TASARIM',
      description: 'Işığın büyüsü ile atmosfer yaratan sanatçı',
      color: Colors.yellow,
    ),
    TeamMember(
      name: 'Murat Özkan',
      role: 'SES TASARIM',
      description: 'Sesle duyguları harekete geçiren teknisyen',
      color: Colors.green,
    ),
  ];

  final List<TeamMember> teamRow2 = const [
    TeamMember(
      name: 'Zeynep Yılmaz',
      role: 'KOSTÜM TASARIM',
      description: 'Karaktere ruh veren kostüm ustası',
      color: Colors.purple,
    ),
    TeamMember(
      name: 'Ali Vural',
      role: 'OYUNCU',
      description: 'Rolüne hayat veren güçlü oyunculuk',
      color: Colors.orange,
    ),
    TeamMember(
      name: 'Merve Yıldız',
      role: 'OYUNCU',
      description: 'Seyirciyle bağ kuran etkileyici sahne dili',
      color: Colors.orange,
    ),
  ];

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CustomSectionTitle(
              title: 'SANATIMIZDAKİ RUHLAR',
              textColor: Colors.amber,
              fontSize: 50),
          const SizedBox(height: 20),
          Text(
            'Her oyunun arkasında tutkulu bir hikaye, her karakterin içinde deneyimli bir sanatçı var',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.amber.shade600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),

          // İlk satır
          _buildScrollableRow(teamRow1),

          const SizedBox(height: 40),

          // İkinci satır
          _buildScrollableRow(teamRow2),
        ],
      ),
    );
  }

  Widget _buildScrollableRow(final List<TeamMember> members) {
    return SizedBox(
      height: 320,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (final _, final __) => const SizedBox(width: 20),
        itemBuilder: (final context, final index) {
          return _TeamCard(member: members[index]);
        },
      ),
    );
  }
}

class TeamMember {
  final String name;
  final String role;
  final String description;
  final Color color;

  const TeamMember({
    required this.name,
    required this.role,
    required this.description,
    required this.color,
  });
}

class _TeamCard extends StatelessWidget {
  final TeamMember member;

  const _TeamCard({required this.member});

  String _getInitials(final String name) {
    final parts = name.split(' ');
    final initials = parts.map((final e) => e.isNotEmpty ? e[0] : '').join();
    return initials.toUpperCase();
  }

  @override
  Widget build(final BuildContext context) {
    final initials = _getInitials(member.name);

    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade400, width: 2),
        boxShadow: [
          // Üst ve yanlara hafif gölge
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          // Alt kısma ekstra güçlü gölge
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sarı daire ve baş harfler
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.amber.shade400,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Rol etiketi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: member.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              member.role,
              style: TextStyle(
                color: member.color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // İsim
          Text(
            member.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Açıklama
          Text(
            member.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
