import 'dart:convert';

/// Persisted user entity — stored in [SharedPreferences] as JSON.
///
/// [token]  — JWT returned by the login / register endpoints.
/// [userId] — server-assigned integer primary key.
///
/// In production the token is all that matters for auth; the password
/// is never stored on-device (only kept in memory during the sign-in flow).
class UserModel {
  final int?    userId;
  final String  email;
  final String? username;
  final String? fullName;
  final String? organizationType;
  final String? token;
  final bool    isEmailVerified;
  final bool    rememberMe;

  const UserModel({
    this.userId,
    required this.email,
    this.username,
    this.fullName,
    this.organizationType,
    this.token,
    this.isEmailVerified = false,
    this.rememberMe      = false,
  });

  UserModel copyWith({
    int?    userId,
    String? email,
    String? username,
    String? fullName,
    String? organizationType,
    String? token,
    bool?   isEmailVerified,
    bool?   rememberMe,
  }) {
    return UserModel(
      userId:           userId           ?? this.userId,
      email:            email            ?? this.email,
      username:         username         ?? this.username,
      fullName:         fullName         ?? this.fullName,
      organizationType: organizationType ?? this.organizationType,
      token:            token            ?? this.token,
      isEmailVerified:  isEmailVerified  ?? this.isEmailVerified,
      rememberMe:       rememberMe       ?? this.rememberMe,
    );
  }

  // ── JSON (for SharedPreferences) ─────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'userId':           userId,
    'email':            email,
    'username':         username,
    'fullName':         fullName,
    'organizationType': organizationType,
    'token':            token,
    'isEmailVerified':  isEmailVerified,
    'rememberMe':       rememberMe,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId:           json['userId']           as int?,
    email:            json['email']            as String,
    username:         json['username']         as String?,
    fullName:         json['fullName']         as String?,
    organizationType: json['organizationType'] as String?,
    token:            json['token']            as String?,
    isEmailVerified:  json['isEmailVerified']  as bool? ?? false,
    rememberMe:       json['rememberMe']       as bool? ?? false,
  );

  String toJsonString()                => jsonEncode(toJson());

  factory UserModel.fromJsonString(String source) =>
      UserModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
