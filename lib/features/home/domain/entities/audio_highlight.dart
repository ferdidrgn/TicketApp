import 'package:equatable/equatable.dart';

/// 🎙️ Web ana sayfasındaki "Sesli Deneyim" bölümü için — monolog/tirat
/// kayıtları gibi kısa ses klipleri. Küratör Firestore'daki
/// `AudioHighlight` koleksiyonuna doküman ekleyerek yönetir, ayrı bir
/// panel gerekmez.
class AudioHighlight extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String audioUrl;
  final String coverImageUrl;

  const AudioHighlight({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.audioUrl,
    required this.coverImageUrl,
  });

  @override
  List<Object?> get props => [id, title, subtitle, audioUrl, coverImageUrl];
}
