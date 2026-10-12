import 'package:flutter/material.dart';

import '../../../../core/util/geo_guard.dart';
import '../../../../core/util/nominatim_geocoder.dart';

/// "Adresten konum bul" — ücretsiz OpenStreetMap araması. Sonuçları listeler;
/// yönetici birini seçince [onPick] ile enlem/boylam alanlarına yazılır.
class GeoLookupButton extends StatefulWidget {
  /// Aranacak metin (mekân adı + adres).
  final String Function() query;
  final void Function(GeoHit hit) onPick;

  const GeoLookupButton({super.key, required this.query, required this.onPick});

  @override
  State<GeoLookupButton> createState() => _GeoLookupButtonState();
}

class _GeoLookupButtonState extends State<GeoLookupButton> {
  bool _busy = false;

  Future<void> _search() async {
    final messenger = ScaffoldMessenger.of(context);
    final String q = widget.query().trim();
    if (q.length < 4) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Önce mekân adı ve adresi yaz (ilçe/şehirle birlikte).')));
      return;
    }
    setState(() => _busy = true);
    try {
      final List<GeoHit> hits = await NominatimGeocoder.search(q);
      if (!mounted) return;
      setState(() => _busy = false);
      if (hits.isEmpty) {
        messenger.showSnackBar(const SnackBar(
            content: Text(
                'Bulunamadı. Adresi mahalle, ilçe ve şehirle yazmayı dene.')));
        return;
      }
      final GeoHit? chosen = await showModalBottomSheet<GeoHit>(
        context: context,
        showDragHandle: true,
        builder: (final ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text('Konum seç (kaynak: OpenStreetMap)',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final GeoHit h in hits)
                ListTile(
                  leading: const Icon(Icons.place_rounded),
                  title: Text(h.label, maxLines: 3, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${h.lat.toStringAsFixed(5)}, ${h.lng.toStringAsFixed(5)}'),
                  onTap: () => Navigator.of(ctx).pop(h),
                ),
            ],
          ),
        ),
      );
      if (chosen != null) widget.onPick(chosen);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(const SnackBar(
          content: Text('Konum servisine ulaşılamadı. İnterneti kontrol edip tekrar dene.')));
    }
  }

  @override
  Widget build(final BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _busy ? null : _search,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.travel_explore_rounded),
          label: const Text('Adresten konum bul'),
        ),
      );
}

/// Uyarı (kayıt engelli değil) için "yine de kaydet?" onayı.
Future<bool> confirmGeoWarning(
    final BuildContext context, final String message) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (final ctx) => AlertDialog(
      title: const Text('Konumu kontrol et'),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Düzelt')),
        FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yine de kaydet')),
      ],
    ),
  );
  return ok ?? false;
}

/// Koordinatı doğrular: engelleyiciyse snackbar + false; uyarıysa onay iste.
Future<bool> validateGeoOrWarn(
  final BuildContext context, {
  required final double lat,
  required final double lng,
  final String address = '',
}) async {
  final issue = GeoGuard.check(lat: lat, lng: lng, address: address);
  if (issue == null) return true;
  if (issue.blocking) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(issue.message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 6),
    ));
    return false;
  }
  return confirmGeoWarning(context, issue.message);
}
