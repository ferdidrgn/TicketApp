import 'package:ticketapp/data/model/show.dart';

class Stage {
  final String id;
  final String name;
  final String desc;
  final String? capacity;
  final double? lat;
  final double? long;
  final String address;
  final String? imageUrl;
  final List<Show> shows;

  Stage({
    required this.id,
    required this.name,
    required this.desc,
    this.capacity,
    this.lat,
    this.long,
    required this.address,
    this.imageUrl,
    required this.shows,
  });
}
