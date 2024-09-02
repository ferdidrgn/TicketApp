import 'package:ticketapp/domain/model/show.dart';

class Stage {
  final String id;
  final String name;
  final String desc;
  final String? imageUrl;
  final List<Show> shows;

  Stage({
    required this.id,
    required this.name,
    required this.desc,
    this.imageUrl,
    required this.shows,
  });
}
