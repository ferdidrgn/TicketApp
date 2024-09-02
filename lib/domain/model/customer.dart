class Customer {
  final String id;
  final String name;
  final String surname;
  final String? imageUrl;
  final String phone;
  final String? age;
  final String? mail;
  final String? city;
  final bool isPhoneActive;

  Customer({
    required this.id,
    required this.name,
    required this.surname,
    this.imageUrl,
    required this.phone,
    this.age,
    this.mail,
    this.city,
    required this.isPhoneActive,
  });
}