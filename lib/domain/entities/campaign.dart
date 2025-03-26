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

  factory Campaign.fromMap(final Map<String, dynamic>? data) => Campaign(
        id: data?['_id'] as String? ?? '0',
        createdAt: data?['_createdAt'] as String? ?? 'Tarih bulunamadı',
        updatedAt: data?['_updatedAt'] as String? ?? 'Tarih bulunamadı',
        endDate: data?['endDate'] as String? ?? 'Tarih bulunamadı',
        imageUrl: data?['imageUrl'] as String? ??
            'https://example.com/default-image.png',
        startDate: data?['startDate'] as String? ?? 'Tarih bulunamadı',
        title: data?['title'] as String? ?? 'İsimsiz Kampanya',
        url: data?['url'] as String? ?? 'https://example.com',
      );

  Map<String, dynamic> toMap() => {
        '_createdAt': createdAt,
        '_updatedAt': updatedAt,
        '_id': id,
        'endDate': endDate,
        'imageUrl': imageUrl,
        'startDate': startDate,
        'title': title,
        'url': url,
      };
}
