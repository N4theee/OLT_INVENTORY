import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/models/inventory_report_model.dart';
import 'package:olt_inventory/utils/date_formatter.dart';

class ReportPdfService {
  static final PdfColor _gold = PdfColor.fromHex('#C8A951');
  static final PdfColor _lightGray = PdfColor.fromHex('#F8F8F8');
  static final PdfColor _borderGray = PdfColor.fromHex('#E8E8E8');
  static final PdfColor _darkText = PdfColor.fromHex('#222222');
  static final PdfColor _mutedText = PdfColor.fromHex('#666666');

  static Future<Uint8List> buildPdf(InventoryReportData data) async {
    final doc = pw.Document();
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final fontSerif = await PdfGoogleFonts.notoSerifRegular();
    final fontSerifBold = await PdfGoogleFonts.notoSerifBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          _buildHeader(fontSerif, fontSerifBold),
          pw.SizedBox(height: 14),
          _buildMetaRow(data, fontRegular, fontBold),
          pw.SizedBox(height: 14),
          _buildSummaryBoxes(data, fontRegular, fontBold),
          pw.SizedBox(height: 16),
          _buildMinistryTitleRow(data, fontBold, fontRegular),
          pw.SizedBox(height: 12),
          _buildInventoryTable(data, fontRegular, fontBold),
          pw.SizedBox(height: 24),
          _buildFacilitatedBy(fontBold, fontRegular),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(font: fontRegular, fontSize: 9, color: _mutedText),
          ),
        ),
      ),
    );

    return doc.save();
  }

  static Future<void> printReport(InventoryReportData data) async {
    final bytes = await buildPdf(data);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'inventory_report_${data.generatedAt.millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<void> shareReport(InventoryReportData data) async {
    final bytes = await buildPdf(data);
    await Printing.sharePdf(bytes: bytes, filename: 'inventory_report.pdf');
  }

  static pw.Widget _buildHeader(pw.Font serif, pw.Font serifBold) {
    return pw.Column(
      children: [
        pw.Text(
          AppConstants.churchName,
          style: pw.TextStyle(font: serifBold, fontSize: 22, color: _gold),
        ),
        pw.Text(
          AppConstants.churchLocation,
          style: pw.TextStyle(font: serif, fontSize: 12, color: _gold),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: _borderGray, thickness: 1),
        pw.SizedBox(height: 8),
        pw.Text(
          'INVENTORY REPORT',
          style: pw.TextStyle(font: serifBold, fontSize: 18, color: _darkText),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _borderGray, thickness: 1),
      ],
    );
  }

  static pw.Widget _buildMetaRow(
    InventoryReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final leftStyle = pw.TextStyle(font: regular, fontSize: 10, color: _darkText);
    final labelStyle = pw.TextStyle(font: bold, fontSize: 10, color: _darkText);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Department: ', style: labelStyle),
                    pw.TextSpan(text: data.filterDepartmentName, style: leftStyle),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Report Type: ', style: labelStyle),
                    pw.TextSpan(text: data.reportType, style: leftStyle),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Report Scope: ', style: labelStyle),
                    pw.TextSpan(
                      text: 'Active Inventory Items',
                      style: leftStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _metaLine(
                'Report Date:',
                DateFormatter.formatReportDate(data.generatedAt),
                regular,
                bold,
              ),
              pw.SizedBox(height: 4),
              _metaLine(
                'Report Time:',
                DateFormatter.formatReportTime(data.generatedAt),
                regular,
                bold,
              ),
              pw.SizedBox(height: 4),
              _metaLine(
                'Generated By:',
                AppConstants.reportGeneratedBy,
                regular,
                bold,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _metaLine(
    String label,
    String value,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label ',
            style: pw.TextStyle(font: bold, fontSize: 10, color: _darkText),
          ),
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(font: regular, fontSize: 10, color: _darkText),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryBoxes(
    InventoryReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    final boxes = [
      ('TOTAL ITEMS', '${data.totalItems}'),
      ('TOTAL QUANTITY', '${data.totalQuantity}'),
      ('GOOD CONDITION', '${data.goodConditionQuantity}'),
      ('NEEDS REPAIR', '${data.needsRepairQuantity}'),
      ('DEPRECIATED', '${data.depreciatedQuantity}'),
    ];

    return pw.Row(
      children: boxes
          .map(
            (box) => pw.Expanded(
              child: pw.Container(
                margin: const pw.EdgeInsets.symmetric(horizontal: 3),
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _borderGray),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      box.$1,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 8,
                        color: _mutedText,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      box.$2,
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 14,
                        color: _darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _buildMinistryTitleRow(
    InventoryReportData data,
    pw.Font bold,
    pw.Font regular,
  ) {
    final dateText = DateFormatter.formatReportDate(data.generatedAt).toUpperCase();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          '${AppConstants.churchMinistryName} UPDATED INVENTORY AS OF',
          style: pw.TextStyle(font: bold, fontSize: 11, color: _darkText),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                dateText,
                style: pw.TextStyle(font: regular, fontSize: 11, color: _darkText),
              ),
              pw.Container(
                height: 1,
                color: _darkText,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInventoryTable(
    InventoryReportData data,
    pw.Font regular,
    pw.Font bold,
  ) {
    if (data.items.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: _borderGray)),
        child: pw.Text(
          'No inventory items found for this report.',
          style: pw.TextStyle(font: regular, fontSize: 10),
        ),
      );
    }

    final headerStyle = pw.TextStyle(font: bold, fontSize: 9, color: _darkText);
    final cellStyle = pw.TextStyle(font: regular, fontSize: 9, color: _darkText);

    return pw.Table(
      border: pw.TableBorder.all(color: _darkText, width: 0.8),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.7),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.3),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _lightGray),
          children: [
            _tableCell('ITEM ID', headerStyle, align: pw.Alignment.center),
            _tableCell('ITEM NAME/ DESCRIPTION', headerStyle),
            _tableCell('DETAILS', headerStyle),
            _tableCell('ITEM STATUS', headerStyle),
            _tableCell('OWNED BY', headerStyle),
            _tableCell('REMARKS', headerStyle),
          ],
        ),
        ...data.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _tableCell(
                InventoryReportData.itemIdDisplay(item, index + 1),
                cellStyle,
                align: pw.Alignment.center,
              ),
              _tableCell(item.productName, cellStyle),
              _tableCell(InventoryReportData.itemDetails(item), cellStyle),
              _tableCell(item.status, cellStyle),
              _tableCell(InventoryReportData.ownedBy(item), cellStyle),
              _tableCell(item.notes ?? '', cellStyle),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildFacilitatedBy(pw.Font bold, pw.Font regular) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.SizedBox(width: 180),
        pw.Text(
          'FACILITATED BY',
          style: pw.TextStyle(font: bold, fontSize: 10, color: _darkText),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.SizedBox(height: 18),
              pw.Container(height: 1, color: _darkText),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text,
    pw.TextStyle style, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      alignment: align,
      child: pw.Text(text, style: style),
    );
  }
}
