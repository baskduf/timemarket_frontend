import "user_model.dart";

class Post {
  final int id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String type;
  final int price;
  final DateTime createdAt;
  final User author;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.price,
    required this.createdAt,
    required this.author, // ✅ 여기에 required 추가
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    assert(json['user'] != null, "author 필드는 null일 수 없습니다");

    return Post(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      type: json['type'],
      price: json['price'],
      createdAt: DateTime.parse(json['created_at']),
      author: User.fromJson(json['user']),
    );
  }
}
