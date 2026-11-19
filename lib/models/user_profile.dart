class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.greenhouseId,
  });

  final String uid;
  final String name;
  final String email;
  final String greenhouseId;

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'greenhouseId': greenhouseId,
      };

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      greenhouseId: data['greenhouseId'] as String? ?? '',
    );
  }
}
