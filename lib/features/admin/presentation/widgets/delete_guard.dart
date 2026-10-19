import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Silmeden önce koruma: bu oyuna/sahneye bağlı BİLET varsa silmeyi engeller.
///
/// Neden: biletler `showId`/`stageId`/`eventId` ile bağlanır; "Biletlerim"
/// geçmiş biletleri bu kayıtlardan okur. Silinirse eski biletler "Bilinmeyen
/// oyun" olur. Tarihi geçen oyun zaten ana sayfa/keşfetten otomatik düşer —
/// silmek GEREKMEZ, silinmemelidir.
///
/// Kontrol başarısız olursa (ağ/izin) silme ENGELLENİR (güvenli taraf).
Future<bool> blockDeleteIfTickets(
  final BuildContext context, {
  final String? showId,
  final String? stageId,
  required final String label,
}) async {
  assert((showId == null) != (stageId == null));
  int count;
  try {
    final snap = await FirebaseFirestore.instance
        .collection('Ticket')
        .where(showId != null ? 'showId' : 'stageId',
            isEqualTo: showId ?? stageId)
        .count()
        .get();
    count = snap.count ?? 0;
  } catch (_) {
    if (!context.mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Bilet kontrolü yapılamadı; güvenlik için silme durduruldu.'),
      backgroundColor: Colors.red,
    ));
    return true;
  }
  if (count == 0) return false;
  if (!context.mounted) return true;
  await showDialog<void>(
    context: context,
    builder: (final ctx) => AlertDialog(
      title: const Text('Silinemez'),
      content: Text(
          '"$label" için $count bilet var. Silinirse kullanıcıların geçmiş '
          'biletleri bozulur. Tarihi geçen oyunlar ana sayfa ve Keşfet\'ten '
          'zaten otomatik kalkar; silmene gerek yok.'),
      actions: [
        FilledButton(
            onPressed: () => Navigator.of(ctx).pop(), child: const Text('Tamam')),
      ],
    ),
  );
  return true;
}
