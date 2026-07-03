// filepath: lib/features/admin/utils/sentinel_test_suite.dart
// MIZAN PLC: SENTINEL TEST SUITE (V2026.STABLE)
// ARCHITECT: Mizan PLC Chief Systems Architect

import 'dart:math';
import 'telebirr_parser_service.dart';

class SentinelTestSuite {
  /// 0.1% ENGINEERING: Synthetic SMS Injection
  /// Verifies the regex logic of the TelebirrParserService.
  static void runTelebirrDetectionTest() {
    // 1. Generate a random Transaction ID and Amount
    final String mockTID = _generateMockTID();
    final int mockAmount = (Random().nextInt(9) + 1) * 100;

    // 2. Construct a realistic 2026 Telebirr SMS String
    final String mockSmsBody =
        """
      telebirr: 
      You have received ETB $mockAmount.00 
      from MIZAN TEST CUSTOMER (251911223344) 
      at 2026-04-29 16:30:00. 
      Your current balance is ETB 15,420.50. 
      Transaction ID: $mockTID. 
      Thank you for using telebirr!
    """;

    print("🧪 MIZAN TEST: Injecting Synthetic Payload [$mockTID]");

    // 3. EXECUTION: Use the new Static Parse method
    final transaction = TelebirrParserService.parse(mockSmsBody);

    // 4. VERIFICATION
    if (transaction != null) {
      print("✅ TEST PASSED: Match Found!");
      print("   - TID: ${transaction.tid}");
      print("   - Amount: ${transaction.amount} ETB");
      print("   - Phone: ${transaction.senderPhone}");
    } else {
      print("❌ TEST FAILED: Parser could not identify the Telebirr pattern.");
    }
  }

  /// Generates a unique 10-character alphanumeric ID
  static String _generateMockTID() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      10,
      (index) => chars[Random().nextInt(chars.length)],
    ).join();
  }
}
