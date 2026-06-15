import 'user_model.dart';

class AuthSessionModel {
  final String accessToken;
  final UserModel user;

  const AuthSessionModel({
    required this.accessToken,
    required this.user,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken: json['accessToken'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'user': user.toJson(),
    };
  }
}
