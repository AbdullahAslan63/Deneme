import 'user_data.dart';

class JoinResponse {
  final String accessToken;
  final String refreshToken;
  final UserData user;

  JoinResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory JoinResponse.fromJson(Map<String, dynamic> json) {
    return JoinResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserData.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
