// AuthValidators — davet kodu normalize + doğrulama testleri.
//
// Backend uçları (referans):
//   - Üretim:   POST /api/v1/apartments/:apartmentId/invite-code
//                Kod formatı: `AP` + 1 hex + `-` + 3 hex + `-` + 4 hex
//                (örn. `AP3-B12-A9F0`).
//   - Kullanım: POST /auth/join — gövdedeki `inviteCode` sunucu tarafında
//                trim + uppercase + iç boşluk silme normalizasyonundan geçer.
//
// Client-side de aynı normalizasyonu uyguluyoruz; bu sayede kullanıcı küçük
// harf, baştaki/sondaki boşluk veya iç boşluk girse bile UI canlı olarak
// doğru karar verir ve sunucuya doğru gövde gider.

import 'package:flutter_test/flutter_test.dart';
import 'package:aidatpanel/shared/utils/auth_validators.dart';

void main() {
  group('AuthValidators.normalizeInviteCode', () {
    test('trim uygular', () {
      expect(
        AuthValidators.normalizeInviteCode('  AP3-B12-A9F0  '),
        'AP3-B12-A9F0',
      );
    });

    test('uppercase uygular', () {
      expect(
        AuthValidators.normalizeInviteCode('ap3-b12-a9f0'),
        'AP3-B12-A9F0',
      );
    });

    test('iç boşlukları siler', () {
      expect(
        AuthValidators.normalizeInviteCode('ap3- b12 -a9f0'),
        'AP3-B12-A9F0',
      );
    });

    test('karışık (boşluk + küçük harf + sekme) girişi normalize eder', () {
      expect(
        AuthValidators.normalizeInviteCode('\t aP3 -\tb12-A9f0 '),
        'AP3-B12-A9F0',
      );
    });

    test('boş string boş döner', () {
      expect(AuthValidators.normalizeInviteCode(''), '');
      expect(AuthValidators.normalizeInviteCode('   '), '');
    });
  });

  group('AuthValidators.isValidInviteCode', () {
    test('kanonik hex kodu kabul eder', () {
      expect(AuthValidators.isValidInviteCode('AP3-B12-A9F0'), isTrue);
      expect(AuthValidators.isValidInviteCode('AP0-000-0000'), isTrue);
      expect(AuthValidators.isValidInviteCode('APF-FFF-FFFF'), isTrue);
    });

    test('küçük harf girişini normalize edip kabul eder', () {
      expect(AuthValidators.isValidInviteCode('ap3-b12-a9f0'), isTrue);
    });

    test('iç ve dış boşlukları normalize edip kabul eder', () {
      expect(AuthValidators.isValidInviteCode('  AP3-B12-A9F0  '), isTrue);
      expect(AuthValidators.isValidInviteCode('ap3- b12 -a9f0'), isTrue);
    });

    test('hex dışı karakter reddedilir', () {
      // X, K, Y, Z hex değil.
      expect(AuthValidators.isValidInviteCode('AP3-B12-X7K9'), isFalse);
      expect(AuthValidators.isValidInviteCode('APZ-B12-A9F0'), isFalse);
      expect(AuthValidators.isValidInviteCode('AP3-BG2-A9F0'), isFalse);
    });

    test('yanlış prefix reddedilir', () {
      expect(AuthValidators.isValidInviteCode('XP3-B12-A9F0'), isFalse);
      expect(AuthValidators.isValidInviteCode('A3-B12-A9F0'), isFalse);
    });

    test('yanlış uzunluk reddedilir', () {
      // İlk grup 2 hex.
      expect(AuthValidators.isValidInviteCode('AP33-B12-A9F0'), isFalse);
      // İkinci grup 2 hex.
      expect(AuthValidators.isValidInviteCode('AP3-B1-A9F0'), isFalse);
      // Üçüncü grup 3 hex.
      expect(AuthValidators.isValidInviteCode('AP3-B12-A9F'), isFalse);
      // Üçüncü grup 5 hex.
      expect(AuthValidators.isValidInviteCode('AP3-B12-A9F00'), isFalse);
    });

    test('ayraç eksik / yanlış reddedilir', () {
      expect(AuthValidators.isValidInviteCode('AP3B12A9F0'), isFalse);
      expect(AuthValidators.isValidInviteCode('AP3_B12_A9F0'), isFalse);
    });

    test('boş string reddedilir', () {
      expect(AuthValidators.isValidInviteCode(''), isFalse);
      expect(AuthValidators.isValidInviteCode('   '), isFalse);
    });
  });
}
