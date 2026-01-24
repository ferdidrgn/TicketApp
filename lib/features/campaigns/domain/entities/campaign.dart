import 'package:equatable/equatable.dart';

class Campaign extends Equatable {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String endDate;
  final String imageUrl;
  final String startDate;
  final String title;
  final String url;

  const Campaign({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.endDate,
    required this.imageUrl,
    required this.startDate,
    required this.title,
    required this.url,
  });

  @override
  List<Object?> get props => [
        id,
        createdAt,
        updatedAt,
        endDate,
        imageUrl,
        startDate,
        title,
        url,
      ];
}
