import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/features/players/domain/entities/player.dart';

class ShowCastList extends StatelessWidget {
  final List<Player> players;
  final String title;
  final bool isGrayscale;
  final Function(String) onPlayerTap;

  const ShowCastList({
    super.key,
    required this.players,
    required this.title,
    required this.onPlayerTap,
    this.isGrayscale = false,
  });

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bölüm Başlığı
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
            child: Row(
              children: [
                Container(width: 4, height: 24, color: const Color(0xFFD4AF37)),
                const SizedBox(width: 10),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // Liste
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: players.length,
              itemBuilder: (final context, final index) {
                final player = players[index];
                return GestureDetector(
                  onTap: () => onPlayerTap(player.id),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 15),
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isGrayscale
                                  ? Colors.grey
                                  : const Color(0xFFD4AF37),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 4))
                            ],
                          ),
                          child: ClipOval(
                            child: isGrayscale
                                ? ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                        Colors.grey, BlendMode.saturation),
                                    child: CachedNetworkImage(
                                        imageUrl: player.imageUrl,
                                        fit: BoxFit.cover),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: player.imageUrl,
                                    fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${player.firstName}\n${player.lastName}",
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isGrayscale ? Colors.white54 : Colors.white,
                            fontSize: 12,
                            fontWeight: isGrayscale
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
}
