import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class MizanSmsLauncher {
  /// Opens the native SMS app for Mizan PLC administrators.
  /// Standard 2026 Implementation for Ethiopian Telecom Infrastructure.
  static Future<void> launchNativeSMS({
    required List<String> recipients,
    required String message,
  }) async {
    try {
      // 1. Logic: Clean recipients and handle platform separators
      // Note: Some Android versions ignore ';' and only accept ','
      final cleanRecipients = recipients.map((e) => e.trim()).toList();
      final String separator = Platform.isAndroid ? ';' : ',';
      final String joinedNumbers = cleanRecipients.join(separator);

      // 2. Build the URI manually to ensure 'body' encoding is perfect
      // Some Android OS versions fail with Uri(queryParameters: ...)
      final String encodedMessage = Uri.encodeComponent(message);
      final String uriString = 'sms:$joinedNumbers?body=$encodedMessage';
      final Uri smsUri = Uri.parse(uriString);

      // 3. Execution with Fallback Logic
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Try launching only to the primary recipient
        debugPrint(
          "Mizan SMS: Bulk launch failed. Attempting primary fallback...",
        );
        final Uri fallbackUri = Uri.parse(
          'sms:${cleanRecipients.first}?body=$encodedMessage',
        );

        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch SMS app. Please check system settings.';
        }
      }
    } catch (e) {
      debugPrint("Mizan SMS Sentinel Exception: $e");
      rethrow;
    }
  }
}
