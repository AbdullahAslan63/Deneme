import 'package:flutter/material.dart';

class AppTypography {
  static const String fontFamily = 'Nunito';

  // Başlıklar - 50+ yaş için optimize edildi
  static const TextStyle h1 = TextStyle(
    fontSize: 30, // -2
    fontWeight: FontWeight.w800,
    height: 1.2,
    fontFamily: fontFamily,
    letterSpacing: 0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24, // -2
    fontWeight: FontWeight.w800,
    height: 1.2,
    fontFamily: fontFamily,
    letterSpacing: 0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18, // -2
    fontWeight: FontWeight.w700,
    height: 1.3,
    fontFamily: fontFamily,
    letterSpacing: 0.2,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 16, // -2
    fontWeight: FontWeight.w700,
    height: 1.3,
    fontFamily: fontFamily,
    letterSpacing: 0.2,
  );

  // Gövde metni - 50+ yaş için optimize edildi
  static const TextStyle body1 = TextStyle(
    fontSize: 16, // -1
    fontWeight: FontWeight.w500,
    height: 1.5,
    fontFamily: fontFamily,
    letterSpacing: 0.1,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 16, // -1
    fontWeight: FontWeight.w700,
    height: 1.5,
    fontFamily: fontFamily,
    letterSpacing: 0.1,
  );

  // Etiket ve küçük metinler - Minimum 14sp
  static const TextStyle label = TextStyle(
    fontSize: 14, // -2
    fontWeight: FontWeight.w700,
    height: 1.3,
    fontFamily: fontFamily,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13, // -3
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFamily: fontFamily,
    letterSpacing: 0.1,
  );

  // Buton metni - Daha büyük ve bold
  static const TextStyle button = TextStyle(
    fontSize: 16, // -2
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
    fontFamily: fontFamily,
  );

  // Yeni: Large body text - Önemli bilgiler için
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17, // -2
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFamily: fontFamily,
    letterSpacing: 0.1,
  );

  // Yeni: Small but readable - Yardım metinleri için
  static const TextStyle small = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    fontFamily: fontFamily,
    letterSpacing: 0.1,
  );
}
