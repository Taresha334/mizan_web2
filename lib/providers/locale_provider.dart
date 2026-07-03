// filepath: lib/providers/locale_provider.dart

import 'package:flutter/material.dart';

/// Manages the application-wide locale for Mizan Market.
///
/// Supports English (en), Amharic (am), Tigrinya (ti), Oromo (om), and Somali (so).
class LocaleProvider extends ChangeNotifier {
  // Default to Amharic as per Mizan PLC standard operations
  Locale _locale = const Locale('am');

  Locale get locale => _locale;

  /// Returns the current language name for UI display
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'am':
        return 'አማርኛ';
      case 'om':
        return 'Afaan Oromoo';
      case 'so':
        return 'Somali';
      case 'ti':
        return 'ትግርኛ';
      default:
        return 'አማርኛ';
    }
  }

  /// Updates the application locale and notifies all listeners (rebuilds UI).
  void setLocale(Locale locale) {
    const supportedCodes = ['en', 'am', 'ti', 'om', 'so'];

    // Safety check to ensure we only set supported languages
    if (!supportedCodes.contains(locale.languageCode)) return;

    // Prevent redundant rebuilds if the locale is the same
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();
  }

  /// Resets to the default Mizan PLC standard (Amharic)
  void clearLocale() {
    _locale = const Locale('am');
    notifyListeners();
  }
}
