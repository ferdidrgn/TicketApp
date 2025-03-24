import 'package:equatable/equatable.dart';

class Campaign extends Equatable {
  final String? id;
  final String? createdAt;
  final String? updatedAt;
  final String? endDate;
  final String? imageUrl;
  final String? startDate;
  final String? title;
  final String? url;

  const Campaign({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.endDate,
    this.imageUrl,
    this.startDate,
    this.title,
    this.url,
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

  factory Campaign.fromMap(final Map<String, dynamic>? data) {
    if (data == null) return const Campaign();
    return Campaign(
      id: data['_id'] as String?,
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      endDate: data['endDate'] as String?,
      imageUrl: data['imageUrl'] as String?,
      startDate: data['startDate'] as String?,
      title: data['title'] as String?,
      url: data['url'] as String?,
    );
  }

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
