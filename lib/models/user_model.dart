

class User {
  final int id;
  final String username;
  final String email;
  final String? profileImageUrl; // 추가 (null 가능)

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['nickname'],
      email: json['email'],
      profileImageUrl: json['profile_image'], // 추가
    );
  }
}