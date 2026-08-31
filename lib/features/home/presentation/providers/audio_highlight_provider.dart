import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/audio_highlight.dart';

/// 🎙️ "Sesli Deneyim" bölümü için Firestore'daki `AudioHighlight`
/// koleksiyonunu doğrudan okur. Küratör ayrı bir panel yerine doğrudan
/// Firestore Console'dan doküman ekleyip yönetir; bu yüzden
/// `nearbySortedEventsProvider` gibi diğer hafif provider'larda olduğu gibi
/// repository/usecase katmanı olmadan doğrudan bir okuma yeterli.
///
/// `audioUrl` boş olan dokümanlar (henüz ses dosyası eklenmemiş taslaklar)
/// listeye hiç girmez.
final audioHighlightsProvider =
    FutureProvider.autoDispose<List<AudioHighlight>>((final ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('AudioHighlight')
      .limit(12)
      .get();

  return snapshot.docs
      .map((final doc) {
        final data = doc.data();
        final audioUrl = data['audioUrl'] as String?;
        if (audioUrl == null || audioUrl.trim().isEmpty) return null;
        return AudioHighlight(
          id: doc.id,
          title: (data['title'] as String?) ?? 'İsimsiz Kayıt',
          subtitle: (data['subtitle'] as String?) ?? '',
          audioUrl: audioUrl,
          coverImageUrl: (data['coverImageUrl'] as String?) ?? '',
        );
      })
      .whereType<AudioHighlight>()
      .toList();
});
