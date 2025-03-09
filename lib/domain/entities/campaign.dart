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

  factory Campaign.fromMap(final Map<String, dynamic> data) {
    return Campaign(
      id: data['id'],
      createdAt: data['_createdAt'] ?? '',
      updatedAt: data['_updatedAt'] ?? '',
      endDate: data['endDate'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      startDate: data['startDate'] ?? '',
      title: data['title'] ?? '',
      url: data['url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      '_createdAt': createdAt,
      '_updatedAt': updatedAt,
      'endDate': endDate,
      'imageUrl': imageUrl,
      'startDate': startDate,
      'title': title,
      'url': url,
    };
  }
}
