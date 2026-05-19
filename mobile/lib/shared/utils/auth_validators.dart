/// Auth validasyon yardımcı fonksiyonları
/// Tüm validasyon mantıkları bu class içinde toplanmıştır
class AuthValidators {
  AuthValidators._();

  /// Email format kontrolü
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Telefon numarası format kontrolü (5 ile başlayan 10 haneli)
  static bool isValidPhone(String phone) {
    return RegExp(r'^5[0-9]{9}$').hasMatch(phone);
  }

  // Davet kodu regex'i backend üretimi ile birebir hizalı tutulur.
  // Backend `POST /api/v1/apartments/:apartmentId/invite-code` ucu kodu
  // `AP` + 1 hex + `-` + 3 hex + `-` + 4 hex (örn. `AP3-B12-A9F0`) olarak
  // üretir; `POST /auth/join` gövdesinde `inviteCode` için trim + uppercase +
  // iç boşluk silme uygular. Client da aynı normalizasyonu uyguladığı için
  // hex dışı alfabe (ör. X, K, Y) kabul edilmez.
  static final RegExp _inviteCodeRegex = RegExp(
    r'^AP[0-9A-F]-[0-9A-F]{3}-[0-9A-F]{4}$',
  );

  /// Davet kodunu sunucuya gönderilecek hâle getirir:
  /// trim → toUpperCase → iç boşlukları sil.
  /// Backend join ucu da aynı normalizasyonu yaptığı için canlı doğrulama
  /// ile sunucu davranışı birebir aynı olur.
  static String normalizeInviteCode(String code) {
    return code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  /// Davet kodu format kontrolü (örn: `AP3-B12-A9F0`).
  /// Girişe normalize uygulanır; küçük harfli veya iç boşluklu giriş de
  /// doğru biçimdeyse `true` döner.
  static bool isValidInviteCode(String code) {
    return _inviteCodeRegex.hasMatch(normalizeInviteCode(code));
  }

  /// Şifre uzunluk kontrolü (minimum 6 karakter)
  static bool isValidPasswordLength(String password) {
    return password.length >= 6;
  }

  /// Şifre karmaşıklık kontrolü (opsiyonel - ileride eklenebilir)
  static bool isStrongPassword(String password) {
    // En az 6 karakter, en az 1 harf, en az 1 sayı
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{6,}$').hasMatch(password);
  }
}
