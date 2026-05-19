import 'package:flutter/painting.dart';

class AppSizes {
  // Buton yükseklikleri - 50+ yaş için optimize edildi
  static const double buttonHeightPrimary = 64.0; // +8
  static const double buttonHeightSecondary = 56.0; // +8
  static const double buttonHeightSmall = 48.0; // Küçük butonlar için

  // İkon + dokunma alanı - 50+ yaş için optimize edildi
  static const double iconTouchTarget = 56.0; // +8 (minimum 48dp)
  static const double iconSize = 28.0; // +4
  static const double iconSizeSmall = 20.0; // Küçük ikonlar için
  static const double iconSizeLarge = 32.0; // Büyük ikonlar için

  // Boşluklar - Daha fazla breathing space
  static const double spacingXS = 6.0; // +2
  static const double spacingS = 12.0; // +4
  static const double spacingM = 20.0; // +4
  static const double spacingFieldSpacing = 14.0; // TextField arası
  static const double spacingL = 28.0; // +4
  static const double spacingXL = 36.0; // +4
  static const double spacingXXL = 56.0; // +8

  // Kart ve köşe - Daha yuvarlak ve modern
  static const double cardRadius = 16.0; // +4
  static const double buttonRadius = 12.0; // +2
  static const double inputRadius = 12.0; // +2
  static const double dialogRadius = 20.0; // Dialog'lar için

  // Liste öğesi yüksekliği - Daha kolay tıklanabilir
  static const double listItemHeight = 80.0; // +8
  static const double listItemHeightSmall = 64.0; // Küçük listeler için

  // Form alanları - Daha büyük ve kolay kullanımlı
  static const double inputHeight = 56.0; // Standart input yüksekliği
  static const double inputHeightLarge = 64.0; // Önemli input'lar için

  // Minimum dokunma alanları
  static const double minTouchTarget = 48.0; // Apple/Google standard
  static const double minTouchTargetComfort = 56.0; // 50+ yaş konfor

  // Özel boyutlar
  static const double fabSize = 64.0; // +8
  static const double avatarSize = 56.0; // +8
  static const double checkboxSize = 24.0; // +4
  static const double radioSize = 24.0; // +4

  // Padding ve margin
  static const double screenPadding = 24.0; // Ekran kenar boşluğu

  /// Tab / tam ekran gövde yatay kenarı — dikeyde `spacingL`.
  static const double dashboardScreenPaddingHorizontal = 16.0;

  /// [ListView] / [SingleChildScrollView] ana içerik padding'i (yatay dar).
  static const EdgeInsets screenBodyScrollPadding = EdgeInsets.fromLTRB(
    dashboardScreenPaddingHorizontal,
    spacingL,
    dashboardScreenPaddingHorizontal,
    spacingL,
  );
  static const double cardPadding = 20.0; // Kart iç boşluğu
  static const double sectionSpacing = 32.0; // Bölüm arası boşluk
}
