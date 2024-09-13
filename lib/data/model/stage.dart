class Stage {
  final String? id;
  final String? name;
  final String? imageUrl;
  final int? capacity;
  final String? description;
  final String? communication;
  final String? address;
  final double? locationLat;
  final double? locationLng;
  final String? createdAt;
  final String? updatedAt;
  final List<String>? showsId;

  Stage({
    this.id,
    this.name,
    this.imageUrl,
    this.capacity,
    this.description,
    this.communication,
    this.address,
    this.locationLat,
    this.locationLng,
    this.createdAt,
    this.updatedAt,
    this.showsId,
  });
}
