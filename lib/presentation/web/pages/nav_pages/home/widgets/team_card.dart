import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/widgets/custom_title.dart';
import '../../../../../../data/datasources/player/player_remote_data_source_and_impl.dart';
import '../../../../../../data/datasources/show/show_remote_data_source_and_impl.dart';
import '../../../../../../domain/entities/player.dart';

class TeamCard extends StatefulWidget {
  const TeamCard({super.key});

  @override
  _TeamCardState createState() => _TeamCardState();
}

class _TeamCardState extends State<TeamCard> {
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  late final PlayerRemoteDataSourceImpl playerService;
  List<Player?> nowPlayerDataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    playerService = PlayerRemoteDataSourceImpl(firestore: firestore);
    _fetchShowData();
  }

  Future<void> _fetchShowData() async {
    try {
      final showService =
          ShowRemoteDataSourceImpl(firestore: firestore, storage: storage);
      final show =
          (await showService.getShowsByIds(["XqKkUbIflyWxZbNLZvqV"]))?.first;

      if (show != null)
        await _fetchNowPlayers(show.nowPlayersId?.cast<String>());
      else
        print("No show found.");
    } catch (error) {
      print('Error fetching shows: $error');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching shows: $error')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchNowPlayers(final List<String>? playersId) async {
    if (playersId != null) {
      try {
        final players = await playerService.getPlayersByIds(playersId);
        setState(() {
          nowPlayerDataList.addAll(players
                  ?.map((final e) => e?.toEntity())
                  .toList()
                  .whereType<Player>() ??
              []);
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching players: $error')));
      }
    }
  }

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
            fontSize: 50,
          ),
          const SizedBox(height: 20),
          Text(
            'Her oyunun arkasında tutkulu bir hikaye, her karakterin içinde deneyimli bir sanatçı var',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18, color: Colors.amber.shade600, height: 1.6),
          ),
          const SizedBox(height: 40),
          isLoading ? CircularProgressIndicator() : _buildScrollableRow(),
        ],
      ),
    );
  }

  Widget _buildScrollableRow() {
    return nowPlayerDataList.isNotEmpty
        ? SizedBox(
            height: 320,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: nowPlayerDataList.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (final context, final index) {
                  return _TeamCard(member: nowPlayerDataList[index]);
                },
              ),
            ),
          )
        : const Center(
            child: Text('Oyuncu bilgisi mevcut değil.'),
          );
  }
}

class _TeamCard extends StatelessWidget {
  final Player? member;

  const _TeamCard({required this.member});

  String _getInitials(final String name) {
    final parts = name.split(' ');
    final initials = parts.map((final e) => e.isNotEmpty ? e[0] : '').join();
    return initials.toUpperCase();
  }

  @override
  Widget build(final BuildContext context) {
    final initials = _getInitials('${member?.firstName} ${member?.lastName}');

    return Container(
      width: 240,
      height: 330,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade400, width: 2),
        image: member?.imageUrl != null
            ? DecorationImage(
                image: NetworkImage(member?.imageUrl ?? ''),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4)),
          BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          // Siyah transparan katman
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // İçerik
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
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
                Text(
                  member?.firstName ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  member?.bio ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.white70,
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
