import 'package:flutter/material.dart';

/// Input validation utilities for AidatPanel forms
/// Provides comprehensive validation with Turkish error messages
class InputValidators {
  // Regex patterns
  static final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final phoneRegex = RegExp(r'^[0-9]{10}$');
  static final _phoneStripRegex = RegExp(r'[^0-9]');

  static final nameRegex = RegExp(r'^[a-zA-ZçğıöşüÇĞİÖŞÜ\s]{2,50}$');

  static final passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.])[A-Za-z\d@$!%*?&.]{6,}$',
  );

  static final _pwUpperRegex = RegExp(r'[A-Z]');
  static final _pwLowerRegex = RegExp(r'[a-z]');
  static final _pwDigitRegex = RegExp(r'[0-9]');
  static final _pwSpecialRegex = RegExp(r'[@$!%*?&.]');

  /// Email validation - returns error keys for localization
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'email_required';
    }

    if (!emailRegex.hasMatch(value.trim())) {
      return 'email_invalid';
    }

    if (value.length > 100) {
      return 'email_too_long';
    }

    return null;
  }

  /// Phone number validation (10 digits without country code)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'phone_required';
    }

    final cleanPhone = value.replaceAll(_phoneStripRegex, '');

    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'phone_invalid';
    }

    return null;
  }

  /// Password validation - returns error keys for localization
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required';
    }

    if (value.length < 6) {
      return 'password_too_short';
    }

    if (value.length > 50) {
      return 'password_too_long';
    }

    if (!value.contains(_pwUpperRegex)) {
      return 'password_uppercase_required';
    }

    if (!value.contains(_pwLowerRegex)) {
      return 'password_lowercase_required';
    }

    if (!value.contains(_pwDigitRegex)) {
      return 'password_number_required';
    }

    if (!value.contains(_pwSpecialRegex)) {
      return 'password_special_char_required';
    }

    return null;
  }

  /// Name validation (first and last name)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ad soyad boş bırakılamaz';
    }

    if (value.length < 2) {
      return 'Ad soyad en az 2 karakter olmalıdır';
    }

    if (value.length > 50) {
      return 'Ad soyad çok uzun';
    }

    if (!nameRegex.hasMatch(value.trim())) {
      return 'Geçerli bir ad soyad giriniz';
    }

    return null;
  }

  /// Building name validation
  static String? validateBuildingName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bina adı boş bırakılamaz';
    }

    if (value.length < 3) {
      return 'Bina adı en az 3 karakter olmalıdır';
    }

    if (value.length > 100) {
      return 'Bina adı çok uzun';
    }

    return null;
  }

  /// Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Adres boş bırakılamaz';
    }

    if (value.length < 10) {
      return 'Adres en az 10 karakter olmalıdır';
    }

    if (value.length > 200) {
      return 'Adres çok uzun';
    }

    return null;
  }

  /// Apartment number validation
  static String? validateApartmentNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Daire numarası boş bırakılamaz';
    }

    if (value.length > 10) {
      return 'Daire numarası çok uzun';
    }

    return null;
  }

  /// Amount validation (for dues, payments, etc.)
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tutar boş bırakılamaz';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Geçerli bir tutar giriniz';
    }

    if (amount < 0) {
      return 'Tutar negatif olamaz';
    }

    if (amount > 1000000) {
      return 'Tutar çok büyük';
    }

    return null;
  }

  /// Generic field validation with custom rules
  static String? validateField({
    required String? value,
    required String fieldName,
    int? minLength,
    int? maxLength,
    bool required = true,
    String? customRegex,
    String? customMessage,
  }) {
    if (required && (value == null || value.isEmpty)) {
      return '$fieldName boş bırakılamaz';
    }

    if (value != null) {
      if (minLength != null && value.length < minLength) {
        return '$fieldName en az $minLength karakter olmalıdır';
      }

      if (maxLength != null && value.length > maxLength) {
        return '$fieldName çok uzun';
      }

      if (customRegex != null && !RegExp(customRegex).hasMatch(value)) {
        return customMessage ?? 'Geçerli bir $fieldName giriniz';
      }
    }

    return null;
  }

  /// Password strength indicator (0-4 scale)
  static int getPasswordStrength(String password) {
    int strength = 0;

    if (password.length >= 6) strength++;
    if (password.contains(_pwUpperRegex)) strength++;
    if (password.contains(_pwLowerRegex)) strength++;
    if (password.contains(_pwDigitRegex)) strength++;
    if (password.contains(_pwSpecialRegex)) strength++;

    return strength;
  }

  /// Password strength text
  static String getPasswordStrengthText(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Zayıf';
      case 2:
      case 3:
        return 'Orta';
      case 4:
      case 5:
        return 'Güçlü';
      default:
        return 'Bilinmeyen';
    }
  }

  /// Password strength color
  static Color getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
      case 3:
        return Colors.orange;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
