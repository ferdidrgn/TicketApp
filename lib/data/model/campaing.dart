class Campaign {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String endDate;
  final String imageUrl;
  final String startDate;
  final String title;
  final String url;

  Campaign({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.endDate,
    required this.imageUrl,
    required this.startDate,
    required this.title,
    required this.url,
  });

  // Function to map Firestore document to Campaign object
  factory Campaign.fromDocumentSnapshot(Map<String, dynamic> data, String docId) {
    return Campaign(
      id: docId,
      createdAt: data['_createdAt'] ?? '',
      updatedAt: data['_updatedAt'] ?? '',
      endDate: data['endDate'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      startDate: data['startDate'] ?? '',
      title: data['title'] ?? '',
      url: data['url'] ?? '',
    );
  }

  // Function to convert Campaign object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
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
