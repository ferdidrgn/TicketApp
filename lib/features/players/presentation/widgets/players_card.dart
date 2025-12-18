import 'package:flutter/material.dart';
import 'package:ticketapp/features/players/domain/entities/player.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/section_header.dart';

class PlayersCard extends StatelessWidget {
  final List<Player> players;
  final String title;
  final bool isGrayscale;
  final Function(String) onPlayerTap;

  const PlayersCard({
    super.key,
    required this.players,
    required this.title,
    required this.onPlayerTap,
    this.isGrayscale = false,
  });

  @override
  Widget build(final BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BAŞLIK KISMI (Burası aynı kalsın ki sayfa bütünlüğü bozulmasın)
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
            child: SectionHeader(title: title, fontSize: 20)),

        // SENİN İSTEDİĞİN TASARIM BURADA BAŞLIYOR
        SizedBox(
          height: 210, // Kart yapısı olduğu için yüksekliği biraz artırdım
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: players.length,
            itemBuilder: (final context, final index) {
              final player = players[index];
              final fullName = "${player.firstName} ${player.lastName}";

              return Container(
                width: 125,
                margin: const EdgeInsets.only(right: 5),
                child: InkWell(
                  onTap: () => onPlayerTap(player.id),
                  borderRadius: const BorderRadius.all(Radius.circular(60)),
                  child: Card(
                    elevation: 3,
                    // Kart rengini temaya uygun hale getirdim
                    color: theme.cardColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(60)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Yuvarlak Resim
                        ClipOval(
                          child: isGrayscale
                              ? ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
                                      Colors.grey, BlendMode.saturation),
                                  child: OptimizedCachedImage(
                                    imageUrl: player.imageUrl,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : OptimizedCachedImage(
                                  imageUrl: player.imageUrl,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                        ),

                        // Senin özel boşluk mantığın
                        SizedBox(height: fullName.length <= 18 ? 17 : 8),

                        // İsim Soyisim
                        Flexible(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              fullName,
                              style: TextStyle(
                                fontSize: 14,
                                color: isGrayscale
                                    ? textColor.withOpacity(0.6)
                                    : textColor,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10), // Alt boşluk
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
