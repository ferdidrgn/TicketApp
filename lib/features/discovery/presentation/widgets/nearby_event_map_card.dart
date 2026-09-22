import 'package:flutter/material.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../providers/nearby_events_provider.dart';

// ==============================================================================
// HARİTA İLE SENKRON "YAKINIMDAKİLER" KARTI
// ==============================================================================
//
// Kullanıcının isteği (birebir): "hem mobilde hem web de scroll yapalım.
// yani kartlar olsun, oyunlarla ilgili yatay scroll ya da dikey yanda
// scroll yapıp haritada o sahne hangi konumda ise o konuma gitsin. yol
// tarifi gibi de açabilsin google fotoyu açabilsinler."
//
// Bu kart `NearbyEventEntry` (gerçek show/stage/dateTime — bkz.
// `nearby_events_provider.dart`) gösterir. Karta dokunmak `onSelect` ile
// haritayı o sahnenin GERÇEK koordinatına odaklar (bkz.
// `nearby_events_page.dart` + `nearby_events_map.dart`'taki `focusedStage`
// senkronu). İki GERÇEK aksiyon içerir:
//   - "Yol Tarifi Al" -> `TiyatrolCommunicationActions.openStageLocation`
//     (var olan, gerçek navigasyon açan metot — yeniden yazılmadı).
//   - "Fotoğraflar" -> sahnenin GERÇEK `imageUrl`'i varsa büyütülmüş halde
//     gösterilir; yoksa bu buton yerine sahnenin GERÇEK adıyla/adresiyle
//     Google Maps'te arayan "Google'da Gör" aksiyonu sunulur (Stage
//     entity'sinde bir Place ID alanı YOK — uydurma bir ID icat edilmedi).
class NearbyEventMapCard extends StatelessWidget {
  final NearbyEventEntry entry;
  final bool isSelected;
  final double width;
  final Color surfaceColor;
  final Color borderColor;
  final Color selectedColor;
  final Color foregroundColor;
  final Color mutedColor;
  final Color accentColor;
  final Color onAccentColor;
  final VoidCallback onSelect;
  final VoidCallback onOpenShow;

  const NearbyEventMapCard({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.onSelect,
    required this.onOpenShow,
    required this.surfaceColor,
    required this.borderColor,
    required this.selectedColor,
    required this.foregroundColor,
    required this.mutedColor,
    required this.accentColor,
    this.width = 260,
    this.onAccentColor = Colors.white,
  });

  bool get _hasRealStagePhoto =>
      entry.stage.imageUrl.trim().isNotEmpty &&
      entry.stage.imageUrl.startsWith('http');

  String get _stageSearchQuery {
    final String name = entry.stage.name.trim();
    final String address = entry.stage.address.trim();
    if (name.isEmpty) return address;
    if (address.isEmpty) return name;
    return '$name, $address';
  }

  @override
  Widget build(final BuildContext context) {
    final String day = entry.dateTime.day.toString().padLeft(2, '0');
    const List<String> months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara', //
    ];
    final String monthName = months[entry.dateTime.month - 1];
    final String time =
        '${entry.dateTime.hour.toString().padLeft(2, '0')}:${entry.dateTime.minute.toString().padLeft(2, '0')}';

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${entry.show.name}, ${entry.stage.name}, $day $monthName $time. Haritada göstermek için dokunun.',
      child: GestureDetector(
        onTap: onSelect,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          width: width,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected ? selectedColor : borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? AppShadows.level3(selectedColor)
                : AppShadows.level1(Colors.black),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    OptimizedCachedImage(
                      imageUrl: entry.show.imageUrl,
                      fit: BoxFit.cover,
                      borderRadius: 0,
                    ),
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: _Pill(
                        text: '$day $monthName · $time',
                        background: accentColor,
                        foreground: onAccentColor,
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Semantics(
                          label: 'Haritada seçili',
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: selectedColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.place_rounded,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.show.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 13, color: mutedColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            entry.stage.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: _CardActionButton(
                        icon: Icons.directions_rounded,
                        label: 'Yol Tarifi',
                        foreground: accentColor,
                        semanticsLabel:
                            '${entry.stage.name} için yol tarifi al',
                        onTap: () => TiyatrolCommunicationActions
                            .openStageLocation(
                          lat: entry.stage.locationLat,
                          lng: entry.stage.locationLng,
                          stageName: entry.stage.name,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _hasRealStagePhoto
                          ? _CardActionButton(
                              icon: Icons.photo_library_rounded,
                              label: 'Fotoğraflar',
                              foreground: accentColor,
                              semanticsLabel:
                                  '${entry.stage.name} fotoğrafını büyüt',
                              onTap: () => _showStagePhoto(context),
                            )
                          : _CardActionButton(
                              icon: Icons.travel_explore_rounded,
                              label: "Google'da Gör",
                              foreground: accentColor,
                              semanticsLabel:
                                  '${entry.stage.name} konumunu Google Haritalar\'da ara',
                              onTap: () =>
                                  TiyatrolCommunicationActions
                                      .openAddressOnGoogleMaps(
                                          _stageSearchQuery),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Semantics(
                      button: true,
                      label: '${entry.show.name} detayına git',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: onOpenShow,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 18, color: mutedColor),
                        ),
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

  void _showStagePhoto(final BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (final dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InteractiveViewer(
                child: OptimizedCachedImage(
                  imageUrl: entry.stage.imageUrl,
                  fit: BoxFit.contain,
                  borderRadius: 0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Semantics(
                button: true,
                label: 'Fotoğrafı kapat',
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: const CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Pill(
      {required this.text, required this.background, required this.foreground});

  @override
  Widget build(final BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: foreground,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final String semanticsLabel;
  final VoidCallback onTap;

  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.semanticsLabel,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) => Semantics(
        button: true,
        label: semanticsLabel,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs, vertical: 6),
            decoration: BoxDecoration(
              color: foreground.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
