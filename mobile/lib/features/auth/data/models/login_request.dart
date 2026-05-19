/// Belge §3 `POST /auth/login`: body `identifier` (email **veya** telefon)
/// + `password`. Field adı `identifier` çünkü backend her iki formatı kabul
/// eder ve sunucu tarafında parse edilir.
class LoginRequest {
  final String identifier;
  final String password;

  LoginRequest({
    required this.identifier,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'password': password,
    };
  }
}
