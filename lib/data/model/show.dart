import 'package:ticketapp/data/model/player.dart';
import '../../presentation/pages/main_pages/discovery.dart';

class Show {
  final String id;
  final String name;
  final String desc;
  final String? imageUrl;
  final String ageRule;
  final String eventRule;
  final List<Player> players;
  final List<Event> events;

  Show({
    required this.id,
    required this.name,
    required this.desc,
    this.imageUrl,
    required this.ageRule,
    required this.eventRule,
    required this.players,
    required this.events,
  });
}
