import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/models/inventory_report_model.dart';
import 'package:olt_inventory/utils/date_formatter.dart';

class ReportCsvService {
  ReportCsvService._();

  static String buildCsv(InventoryReportData data) {
    final buffer = StringBuffer();

    buffer.writeln(
      '${AppConstants.churchMinistryName} UPDATED INVENTORY AS OF '
      '${DateFormatter.formatReportDate(data.generatedAt).toUpperCase()}',
    );
    buffer.writeln('Department,${data.filterDepartmentName}');
    buffer.writeln('Report Type,${data.reportType}');
    buffer.writeln(
      'Generated,${DateFormatter.formatReportDate(data.generatedAt)} '
      '${DateFormatter.formatReportTime(data.generatedAt)}',
    );
    buffer.writeln();

    buffer.writeln(
      'ITEM ID,ITEM NAME/ DESCRIPTION,DETAILS,ITEM STATUS,OWNED BY,REMARKS',
    );

    for (var i = 0; i < data.items.length; i++) {
      final item = data.items[i];
      buffer.writeln([
        InventoryReportData.itemIdDisplay(item, i + 1),
        _escape(item.productName),
        _escape(InventoryReportData.itemDetails(item)),
        _escape(item.status),
        _escape(InventoryReportData.ownedBy(item)),
        _escape(item.notes ?? ''),
      ].join(','));
    }

    return buffer.toString();
  }

  static Future<void> shareCsv(InventoryReportData data) async {
    final csv = buildCsv(data);
    final dir = await getTemporaryDirectory();
    final fileName =
        'inventory_report_${data.generatedAt.millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv', name: fileName)],
      subject: 'OLT Inventory Report',
      text: 'Inventory report for ${data.filterDepartmentName}',
    );
  }

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
