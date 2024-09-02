import 'package:ticketapp/domain/model/show.dart';

class Player {
  final String id;
  final String name;
  final String surname;
  final String bio;
  final String? imageUrl;
  final List<Show> shows;

  Player({
    required this.id,
    required this.name,
    required this.surname,
    required this.bio,
    this.imageUrl,
    required this.shows,
  });
}
