import 'package:equatable/equatable.dart';

class Team extends Equatable {
  final String id;
  final String createdAt, updatedAt;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> photosId;
  final List<String> showsId;

  /// Harici bağış/destek sayfası (yalnız https). Boşsa düğme gösterilmez.
  final String donationUrl;

  /// Harici gönüllü başvuru formu (yalnız https). Boşsa düğme gösterilmez.
  final String volunteerUrl;

  const Team({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.photosId,
    required this.showsId,
    this.donationUrl = '',
    this.volunteerUrl = '',
  });

  @override
  List<Object?> get props => [
        id,
        createdAt,
        updatedAt,
        name,
        description,
        imageUrl,
        photosId,
        showsId,
        donationUrl,
        volunteerUrl,
      ];
}
