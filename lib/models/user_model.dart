class UserModel {
  final String email;
  final String? name;
  final bool isEmailVerified;

  const UserModel({
    required this.email,
    this.name,
    this.isEmailVerified = false,
  });

  UserModel copyWith({
    String? email,
    String? name,
    bool? isEmailVerified,
  }) {
    return UserModel(
      email: email ?? this.email,
      name: name ?? this.name,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}