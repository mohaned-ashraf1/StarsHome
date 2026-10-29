import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/purchase_model.dart';
import '../../models/income_model.dart';
import 'currency_formatter.dart';
import 'date_helper.dart';

class ExportHelper {
  static String _convertToCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        final str = cell?.toString() ?? '';
        if (str.contains(',') || str.contains('"') || str.contains('\n')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
    }).join('\n');
  }

  static String exportPurchasesToCsv(List<PurchaseModel> purchases) {
    List<List<dynamic>> rows = [
      ['المعرف', 'اسم البند / المصروف', 'التصنيف', 'الكمية', 'سعر الوحدة', 'المبلغ الإجمالي', 'التاريخ', 'ملاحظات', 'المستخدم المسجل']
    ];

    for (var p in purchases) {
      rows.add([
        p.id,
        p.itemName,
        p.category,
        p.quantity ?? '',
        p.unitPrice ?? '',
        p.totalAmount,
        DateHelper.formatYMD(p.transactionDate),
        p.notes ?? '',
        p.createdBy,
      ]);
    }

    return _convertToCsv(rows);
  }

  static String exportIncomesToCsv(List<IncomeModel> incomes) {
    List<List<dynamic>> rows = [
      ['المعرف', 'مصدر الإيراد / الوارد', 'المبلغ', 'التاريخ', 'ملاحظات', 'المستخدم المسجل']
    ];

    for (var inc in incomes) {
      rows.add([
        inc.id,
        inc.sourceName,
        inc.amount,
        DateHelper.formatYMD(inc.transactionDate),
        inc.notes ?? '',
        inc.createdBy,
      ]);
    }

    return _convertToCsv(rows);
  }

  static Future<void> printFinancialSummaryReport({
    required BuildContext context,
    required String periodTitle,
    required double totalIncome,
    required double totalExpenses,
    required double workerBalances,
    required double netCashFlow,
    required List<PurchaseModel> topPurchases,
    required List<IncomeModel> topIncomes,
  }) async {
    final doc = pw.Document();

    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'STARS HOMES - مصنع ستارز هومز للأثاث',
                    style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.blueGrey900),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'تقرير الملخص المالي والتشغيلي - $periodTitle',
                    style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.amber800),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1.5, color: PdfColors.grey400),
                pw.SizedBox(height: 10),

                // Financial Cards Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('إجمالي الداخل', style: pw.TextStyle(font: fontBold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('إجمالي الخارج', style: pw.TextStyle(font: fontBold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('حساب العمال', style: pw.TextStyle(font: fontBold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('صافي النقد', style: pw.TextStyle(font: fontBold))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(CurrencyFormatter.format(totalIncome))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(CurrencyFormatter.format(totalExpenses))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(CurrencyFormatter.format(workerBalances))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(CurrencyFormatter.format(netCashFlow), style: pw.TextStyle(font: fontBold, color: netCashFlow >= 0 ? PdfColors.green800 : PdfColors.red800))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),

                pw.Text('المصروفات والمشتريات الأخيرة:', style: pw.TextStyle(font: fontBold, fontSize: 13)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey200),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('البند', style: pw.TextStyle(font: fontBold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('التصنيف', style: pw.TextStyle(font: fontBold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('المبلغ', style: pw.TextStyle(font: fontBold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('التاريخ', style: pw.TextStyle(font: fontBold))),
                      ],
                    ),
                    ...topPurchases.take(15).map((p) => pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p.itemName)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p.category)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(CurrencyFormatter.format(p.totalAmount))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateHelper.formatYMD(p.transactionDate))),
                          ],
                        )),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('تم استخراج هذا التقرير آلياً من نظام STARS HOMES', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    pw.Text(DateHelper.formatLong(DateTime.now()), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }
}
