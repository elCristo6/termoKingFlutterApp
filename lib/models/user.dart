// lib/models/user.dart

class User {
  final String userId;
  final String name;
  final String userType;
  final String deviceId;

  User({
    required this.userId,
    required this.name,
    required this.userType,
    required this.deviceId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      name: json['name'],
      userType: json['userType'],
      deviceId: json['deviceId'],
    );
  }
}
