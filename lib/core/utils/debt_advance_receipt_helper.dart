import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/debt_advance_model.dart';
import '../../models/debt_advance_payment_model.dart';
import 'currency_formatter.dart';
import 'date_helper.dart';

class DebtAdvanceReceiptHelper {
  static Future<void> printReceipt({
    BuildContext? context,
    required DebtAdvanceModel item,
    List<DebtAdvancePaymentModel>? payments,
  }) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final sortedPayments = payments != null
        ? (List<DebtAdvancePaymentModel>.from(payments)
          ..sort((a, b) => a.paymentDate.compareTo(b.paymentDate)))
        : <DebtAdvancePaymentModel>[];

    final isSettled = item.isSettled;

    String receiptTitle;
    String legalText;
    PdfColor headerColor;

    if (item.type == 'advance') {
      receiptTitle = 'إيصال استلام سلفة نقدية';
      headerColor = PdfColors.amber800;
      legalText =
          'أقر أنا الموقع أدناه باستلام المبلغ الموضح أعلاه نقداً كـ (سلفة شخصية) من خزينة مصنع STARS HOMES، وأتعهد بسداد هذا المبلغ بالكامل أو خصمه حسب الاتفاق المعتمد، وفي حالة التأخر يحق للإدارة اتخاذ ما تراه مناسباً.';
    } else if (item.type == 'debt_receivable') {
      receiptTitle = 'سند إثبات مديونية مستحقة';
      headerColor = PdfColors.blueGrey800;
      legalText =
          'أقر أنا الموقع أدناه بصحة المديونية المستحقة عليّ والموضحة بياناتها أعلاه لصالح مصنع STARS HOMES، وأتعهد بالوفاء بالسداد التام في الموعد المحدد أو على دفعات متفق عليها.';
    } else {
      receiptTitle = 'سند التزام مالي ومديونية';
      headerColor = PdfColors.teal800;
      legalText =
          'سند التزام مالي معتمد لصالح المستفيد الموضح أعلاه طبقاً لحسابات مصنع STARS HOMES.';
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Factory Header
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'STARS HOMES',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 18,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.Text(
                          'مصنع ستارز هومز للأثاث والمصنوعات الخشبية • إدارة م/ ابراهيم نجم',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          'القاهرة • المقر الرئيسي ومصنع الأثاث',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: pw.BoxDecoration(
                            color: headerColor,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            receiptTitle,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'رقم السند: #${item.id.length >= 8 ? item.id.substring(0, 8).toUpperCase() : item.id.toUpperCase()}',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.Text(
                          'تاريخ الإصدار: ${DateHelper.formatDisplay(item.transactionDate)}',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // 2. Beneficiary / Person Information Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                  color: PdfColors.grey50,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(fontBold, fontRegular, 'الاسم / المستفيد:', item.personName),
                          pw.SizedBox(height: 5),
                          _buildInfoRow(fontBold, fontRegular, 'رقم الهاتف:', item.phone?.isNotEmpty == true ? item.phone! : 'غير مسجل'),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(fontBold, fontRegular, 'نوع المعاملة:', item.typeLabel),
                          pw.SizedBox(height: 5),
                          _buildInfoRow(
                            fontBold,
                            fontRegular,
                            'تاريخ السداد / الاستحقاق:',
                            item.dueDate != null ? DateHelper.formatDisplay(item.dueDate!) : 'حسب الاتفاق الجاري',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // 3. Amount Summary Table (Cards)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Center(
                          child: pw.Text('إجمالي مبلغ السلفة / المديونية', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Center(
                          child: pw.Text('إجمالي المسدد حتى الآن', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Center(
                          child: pw.Text('المتبقي المستحق', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Center(
                          child: pw.Text('حالة السند', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Center(
                          child: pw.Text(
                            CurrencyFormatter.format(item.amount),
                            style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blueGrey900),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Center(
                          child: pw.Text(
                            CurrencyFormatter.format(item.paidAmount),
                            style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.green800),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Center(
                          child: pw.Text(
                            CurrencyFormatter.format(item.remainingAmount),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: item.remainingAmount > 0 ? PdfColors.red800 : PdfColors.green800,
                            ),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Center(
                          child: pw.Text(
                            isSettled ? 'مسددة بالكامل' : 'سارية / متبقية',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 11,
                              color: isSettled ? PdfColors.green800 : PdfColors.orange800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              // 4. Notes / Reason Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'بيان وسبب السلفة / المديونية:',
                      style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blueGrey800),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      item.notes?.isNotEmpty == true ? item.notes! : 'سلفة نقدية منصرفة من خزينة المصنع بناءً على طلب المستفيد.',
                      style: pw.TextStyle(font: fontRegular, fontSize: 10, lineSpacing: 1.4),
                    ),
                  ],
                ),
              ),

              // 5. Payments History (If Any)
              if (sortedPayments.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  'سجل الدفعات وأقساط السداد المسجلة:',
                  style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blueGrey900),
                ),
                pw.SizedBox(height: 4),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('م', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('تاريخ الدفعة', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('المبلغ المسدد', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('ملاحظات وسجل الدفعة', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        ),
                      ],
                    ),
                    ...sortedPayments.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final p = entry.value;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('$idx', style: pw.TextStyle(font: fontRegular, fontSize: 8.5)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(DateHelper.formatDisplay(p.paymentDate), style: pw.TextStyle(font: fontRegular, fontSize: 8.5)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              CurrencyFormatter.format(p.amount),
                              style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.green900),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(p.notes?.isNotEmpty == true ? p.notes! : '-', style: pw.TextStyle(font: fontRegular, fontSize: 8.5)),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],

              pw.Spacer(),

              // 6. Legal Undertaking
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                  color: PdfColors.grey50,
                ),
                child: pw.Text(
                  legalText,
                  style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey800, lineSpacing: 1.3),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.SizedBox(height: 18),

              // 7. Signatures Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('توقيع المستلم / المقر:', style: pw.TextStyle(font: fontBold, fontSize: 9.5)),
                      pw.SizedBox(height: 25),
                      pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('المسئول / المحاسب:', style: pw.TextStyle(font: fontBold, fontSize: 9.5)),
                      pw.SizedBox(height: 25),
                      pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('اعتماد إدارة المصنع (م/ ابراهيم نجم):', style: pw.TextStyle(font: fontBold, fontSize: 9.5)),
                      pw.SizedBox(height: 25),
                      pw.Container(width: 150, height: 1, color: PdfColors.grey400),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('STARS HOMES • نظام الإدارة المالية المحمي', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('تاريخ الطباعة: ${DateHelper.formatDisplay(DateTime.now())} - ${DateHelper.formatTime(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    final cleanName = item.personName.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '_').trim();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'ايصال_${item.type}_${cleanName}_${DateHelper.formatYMD(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildInfoRow(
    pw.Font fontBold,
    pw.Font fontRegular,
    String label,
    String value,
  ) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColors.grey800),
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          value,
          style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: PdfColors.blueGrey900),
        ),
      ],
    );
  }
}
