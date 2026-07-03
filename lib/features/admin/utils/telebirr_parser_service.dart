// filepath: lib/features/admin/utils/telebirr_parser_service.dart
class TelebirrTransaction {
  final String tid;
  final double amount;
  final String senderPhone;
  final String rawBody;

  TelebirrTransaction({
    required this.tid,
    required this.amount,
    required this.senderPhone,
    required this.rawBody,
  });
}

class TelebirrParserService {
  static TelebirrTransaction? parse(String rawBody) {
    try {
      final tidRegex = RegExp(
        r'(?:transaction number is|Trans ID:|Transaction ID:|የመለያ ቁጥር|ID:)\s*([A-Z0-9]{10,})',
        caseSensitive: false,
      );
      final amountRegex = RegExp(
        r'(?:received ETB|ETB|Birr|ብር)\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      );

      final tidMatch = tidRegex.firstMatch(rawBody);
      final amountMatch = amountRegex.firstMatch(rawBody);

      if (tidMatch == null || amountMatch == null) return null;

      final String tid = tidMatch.group(1)!.trim().toUpperCase();
      final double amount = double.parse(
        amountMatch.group(1)!.replaceAll(',', ''),
      );

      final phoneRegex = RegExp(r'(?:251|0)(9|7)[0-9]{8}');
      final phoneMatch = phoneRegex.firstMatch(rawBody);
      final String senderPhone = phoneMatch?.group(0) ?? "Unknown";

      return TelebirrTransaction(
        tid: tid,
        amount: amount,
        senderPhone: senderPhone,
        rawBody: rawBody,
      );
    } catch (e) {
      return null;
    }
  }
}
