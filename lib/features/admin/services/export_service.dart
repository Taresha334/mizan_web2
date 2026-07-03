import 'dart:convert';
import 'dart:html' as html; // Specifically for Flutter Web downloads
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

class MizanExportService {
  /// Generates and downloads a CSV (Excel compatible) of approved listings
  static void exportListingsToCSV(List<Map<String, dynamic>> data) {
    List<List<dynamic>> rows = [];

    // Header Row
    rows.add([
      "ID",
      "Title",
      "Agent ID",
      "Farmer ID",
      "Price (ETB)",
      "Quantity",
      "Location",
      "Approved At",
      "Status"
    ]);

    for (var item in data) {
      rows.add([
        item['id'],
        item['title'],
        item['agent_id'],
        item['farmer_id'],
        item['unit_price'],
        item['quantity'],
        item['location'],
        item['approved_at'],
        item['status'],
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download",
          "Mizan_Report_${DateTime.now().millisecondsSinceEpoch}.csv")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  /// Generates a formal PDF Report for Mizan PLC Management
  static Future<void> exportToPDF(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("MIZAN PLC - AGRI MARKET REPORT",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 18)),
                pw.Text(dateStr),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Product', 'Price', 'Location', 'Status'],
            data: data
                .map((item) => [
                      item['title'],
                      "${item['unit_price']} ETB",
                      item['location'],
                      item['status']
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1B5E20)),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
            },
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "Mizan_Official_Report_$dateStr.pdf")
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
