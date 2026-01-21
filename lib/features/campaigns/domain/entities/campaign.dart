import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'campaign.g.dart';

@JsonSerializable()
class Campaign extends Equatable {
  // JSON'da '_id' olarak gelir ama biz 'id' olarak kullanırız
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: '_createdAt')
  final String createdAt;

  @JsonKey(name: '_updatedAt')
  final String updatedAt;

  final String endDate;

  // Eğer null gelirse varsayılan resim atanır
  @JsonKey(defaultValue: 'https://example.com/default-image.png')
  final String imageUrl;

  final String startDate;

  @JsonKey(defaultValue: 'İsimsiz Kampanya')
  final String title;

  @JsonKey(defaultValue: 'https://example.com')
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

  /// 🏭 OTO-JENERASYON (g.dart kullanır)
  factory Campaign.fromJson(final Map<String, dynamic> json) =>
      _$CampaignFromJson(json);

  /// 📦 JSON'A ÇEVİRME
  Map<String, dynamic> toJson() => _$CampaignToJson(this);

  /// 🕸️ BOŞ NESNE (Loading veya Hata durumları için)
  factory Campaign.empty() => const Campaign(
        id: '0',
        createdAt: '',
        updatedAt: '',
        endDate: '',
        imageUrl: '',
        startDate: '',
        title: '',
        url: '',
      );

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
