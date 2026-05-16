import 'user_data.dart';

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final UserData user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserData.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
