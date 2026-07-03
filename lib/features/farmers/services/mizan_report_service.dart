// filepath: lib/features/farmers/services/mizan_report_service.dart

import 'package:share_plus/share_plus.dart';

class MizanReportService {
  static void generateAndShareReport({
    required String location,
    required int headCount,
    required String advice,
    required String category,
  }) {
    final String report =
        '''
🌿 MIZAN PLC: FARMER ADVISORY REPORT
Location: $location
Livestock: $headCount heads ($category)
Date: ${DateTime.now().toString().split(' ')[0]}
-------------------------------------------
TECHNICAL ADVICE:
$advice

MIZAN STANDARDS FOR $headCount HEADS:
- Space: ${headCount / 10} sqm required.
- Equipment: ${(headCount / 33).ceil()} drinkers and feeders.
- Feed: Use Mizan [Starter/Grower/Finisher] as recommended.

Verified by: Mizan AI Expert 
(Standards by CEO Mizan Seifu, Msc & Tariku G/Tsadik, Msc)
-------------------------------------------
Contact Mizan HQ: +251 936 262387 / +251 935 707075
    ''';

    Share.share(report, subject: 'Mizan Health Report - $location');
  }
}
