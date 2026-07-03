// filepath: lib/core/l10n/l10n.dart

import 'package:flutter/material.dart';

class L10n {
  /// The list of all supported locales for Mizan PLC.
  static final all = [
    const Locale('en'), // English
    const Locale('am'), // Amharic
    const Locale('ti'), // Tigrigna
    const Locale('om'), // Afaan Oromoo
    const Locale('so'), // Somali
  ];

  /// Returns the native/common name of the language based on the code.
  static String getLanguageName(String code) {
    switch (code.toLowerCase()) {
      case 'am':
        return 'አማርኛ (Amharic)';
      case 'ti':
        return 'ትግርኛ (Tigrigna)';
      case 'om':
        return 'Afaan Oromoo';
      case 'so':
        return 'Soomaali (Somali)';
      case 'en':
        return 'English';
      default:
        return 'አማርኛ (Amharic)';
    }
  }

  /// Returns the appropriate flag emoji for the language.
  /// Using the Ethiopian flag for regional languages as per Mizan PLC focus.
  static String getFlag(String code) {
    switch (code.toLowerCase()) {
      case 'en':
        return '🇺🇸';
      case 'am':
      case 'ti':
      case 'om':
      case 'so':
      default:
        return '🇪🇹';
    }
  }
}
