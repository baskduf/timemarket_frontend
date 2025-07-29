class Post {
  final int id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String type; // 'sale' 또는 'help'
  final int price;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.price,
    required this.createdAt
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      type: json['type'],
      price: json['price'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
