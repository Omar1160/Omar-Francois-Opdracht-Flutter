class Appliance {
  final String id;
  final String title;
  final String description;
  final double pricePerDay;
  final String category;
  final String ownerId;
  final String imageUrl;
  final String location;
  final List<String> availability;

  Appliance({
    required this.id,
    required this.title,
    required this.description,
    required this.pricePerDay,
    required this.category,
    required this.ownerId,
    required this.imageUrl,
    required this.location,
    required this.availability,
  });

  factory Appliance.fromMap(Map<String, dynamic> map) {
    return Appliance(
      id: map['id'] ?? '',
      title: map['title'] ?? 'No title',
      description: map['description'] ?? '',
      pricePerDay: (map['pricePerDay'] != null)
          ? (map['pricePerDay'] as num).toDouble()
          : 0.0,
      category: map['category'] ?? 'Unknown',
      ownerId: map['ownerId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      location: map['location'] ?? '',
      availability: (map['availability'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pricePerDay': pricePerDay,
      'category': category,
      'ownerId': ownerId,
      'imageUrl': imageUrl,
      'location': location,
      'availability': availability,
    };
  }
}