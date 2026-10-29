import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/attendance_model.dart';
import '../../providers/workers_provider.dart';
import 'currency_formatter.dart';
import 'date_helper.dart';

class WorkerPayrollReceiptHelper {
  /// 1. Print Individual Worker Weekly Payslip (إيصال تصفية راتب أسبوعي لكل عامل على حدة)
  static Future<void> printSingleWorkerReceipt({
    required BuildContext context,
    required WorkerPayrollSummary summary,
    required DateTime weekStart,
    required DateTime weekEnd,
    List<AttendanceModel>? attendanceList,
  }) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final worker = summary.worker;
    final workerAttendances = attendanceList
            ?.where((a) => a.workerId == worker.id && a.status == 'present')
            .toList() ??
        [];

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
              // Header
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
                          'مصنع ستارز هومز للأثاث • إدارة م/ ابراهيم نجم',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blueGrey800,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'إيصال تصفية راتب أسبوعي لعامل',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'تاريخ الطباعة: ${DateHelper.formatDisplay(DateTime.now())} - ${DateHelper.formatTime(DateTime.now())}',
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

              // Worker & Week Info Card
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildFieldRow(fontBold, fontRegular, 'اسم العامل:', worker.fullName),
                          pw.SizedBox(height: 4),
                          _buildFieldRow(fontBold, fontRegular, 'رقم الهاتف:', worker.phone?.isNotEmpty == true ? worker.phone! : 'غير مسجل'),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildFieldRow(fontBold, fontRegular, 'أجر اليومية الأساسي:', CurrencyFormatter.format(worker.dailyWage)),
                          pw.SizedBox(height: 4),
                          _buildFieldRow(
                            fontBold,
                            fontRegular,
                            'الأسبوع المحاسبي:',
                            '${DateHelper.formatDisplay(weekStart)} إلى ${DateHelper.formatDisplay(weekEnd)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // Earnings & Deductions Tables (Two Columns Side by Side)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // 1. المستحقات والإنتاج (Earnings)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            color: PdfColors.grey200,
                            width: double.infinity,
                            child: pw.Text('أولاً: الاستحقاقات والأجور (+)', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.green900)),
                          ),
                          pw.SizedBox(height: 6),
                          _buildFinanceItem(fontBold, fontRegular, 'أيام الحضور الفعلي:', '${summary.daysAttended} يوم'),
                          _buildFinanceItem(fontBold, fontRegular, 'إجمالي أجور الأيام:', CurrencyFormatter.format(summary.dailyWagesEarned)),
                          _buildFinanceItem(fontBold, fontRegular, 'ساعات العمل الإضافي:', '${summary.overtimeHours} ساعة'),
                          _buildFinanceItem(fontBold, fontRegular, 'أجر الساعات الإضافية:', CurrencyFormatter.format(summary.overtimeEarnings)),
                          _buildFinanceItem(fontBold, fontRegular, 'المكافآت والحوافز:', CurrencyFormatter.format(summary.bonusesTotal)),
                          pw.Divider(thickness: 1, color: PdfColors.grey300),
                          _buildFinanceItem(fontBold, fontRegular, 'إجمالي الاستحقاق (Gross):', CurrencyFormatter.format(summary.grossEarnings), isBold: true, color: PdfColors.green900),
                        ],
                      ),
                    ),
                  ),

                  pw.SizedBox(width: 10),

                  // 2. الاستقطاعات والسلف (Deductions)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            color: PdfColors.grey200,
                            width: double.infinity,
                            child: pw.Text('ثانياً: الاستقطاعات والسلف (-)', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.red900)),
                          ),
                          pw.SizedBox(height: 6),
                          _buildFinanceItem(fontBold, fontRegular, 'إجمالي السلف الأسبوعية:', CurrencyFormatter.format(summary.advancesTotal)),
                          _buildFinanceItem(fontBold, fontRegular, 'الخصومات والجزاءات:', CurrencyFormatter.format(summary.deductionsTotal)),
                          pw.SizedBox(height: 38), // Align with left column
                          pw.Divider(thickness: 1, color: PdfColors.grey300),
                          _buildFinanceItem(
                            fontBold,
                            fontRegular,
                            'إجمالي الاستقطاع:',
                            CurrencyFormatter.format(summary.advancesTotal + summary.deductionsTotal),
                            isBold: true,
                            color: PdfColors.red900,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // Final Settlement Card
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey400, width: 1.2),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildFinalBox(fontBold, fontRegular, 'صافي الأجر المستحق', CurrencyFormatter.format(summary.netAmountDue), PdfColors.blueGrey900),
                    pw.Container(width: 1, height: 35, color: PdfColors.grey300),
                    _buildFinalBox(fontBold, fontRegular, 'المبلغ المسلم نقداً للعامل', CurrencyFormatter.format(summary.amountAlreadyPaid), PdfColors.green800),
                    pw.Container(width: 1, height: 35, color: PdfColors.grey300),
                    _buildFinalBox(
                      fontBold,
                      fontRegular,
                      'المتبقي على العامل',
                      CurrencyFormatter.format(summary.remainingDue),
                      summary.remainingDue > 0 ? PdfColors.red800 : PdfColors.green800,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Attendance breakdown if available
              if (workerAttendances.isNotEmpty) ...[
                pw.Text('سجل أيام الحضور الفعلي المسجلة خلال الأسبوع:', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey800)),
                pw.SizedBox(height: 4),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey200),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('التاريخ', style: pw.TextStyle(font: fontBold, fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('الحضور', style: pw.TextStyle(font: fontBold, fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('الانصراف', style: pw.TextStyle(font: fontBold, fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ساعات إضافي', style: pw.TextStyle(font: fontBold, fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('اليومية المحتسبة', style: pw.TextStyle(font: fontBold, fontSize: 8))),
                      ],
                    ),
                    ...workerAttendances.map(
                      (att) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(DateHelper.formatDisplay(att.attendanceDate), style: pw.TextStyle(font: fontRegular, fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(DateHelper.formatTimeStringTo12Hour(att.arrivalTime), style: pw.TextStyle(font: fontRegular, fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(DateHelper.formatTimeStringTo12Hour(att.departureTime), style: pw.TextStyle(font: fontRegular, fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${att.overtimeHours} س', style: pw.TextStyle(font: fontRegular, fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(CurrencyFormatter.format(att.dailyWageApplied), style: pw.TextStyle(font: fontRegular, fontSize: 8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              pw.Spacer(),

              // Acknowledgment & Signatures
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'إقرار: أقر أنا العامل المذكور أعلاه بأنني استلمت كافة مستحقاتي المالية عن الأسبوع الموضح براءة لذمة مصنع STARS HOMES ولا يحق لي المطالبة بأي مبالغ أخرى عن هذه الفترة.',
                  style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.SizedBox(height: 18),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('توقيع واستلام العامل:', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                      pw.SizedBox(height: 24),
                      pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('اعتماد مالك المصنع (م/ ابراهيم نجم):', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                      pw.SizedBox(height: 24),
                      pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('STARS HOMES • نظام الإدارة المالية المحمي', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('صفحة 1 من 1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'ايصال_راتب_${worker.fullName}_${DateHelper.formatYMD(weekStart)}.pdf',
    );
  }

  /// 2. Print Factory Management Master Payroll Statement (كشف مسير رواتب العمال الأسبوعي - نسخة إدارة المصنع)
  static Future<void> printFactoryManagementPayrollReport({
    required BuildContext context,
    required List<WorkerPayrollSummary> summaries,
    required DateTime weekStart,
    required DateTime weekEnd,
    required Map<String, double> grandTotals,
  }) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape, // Landscape for full data columns
        margin: const pw.EdgeInsets.all(22),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'STARS HOMES - مصنع ستارز هومز للأثاث',
                          style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blueGrey900),
                        ),
                        pw.Text(
                          'مالك المصنع: م/ ابراهيم نجم • كشف مسير وتصفية الرواتب الأسبوعية الشامل (نسخة الإدارة)',
                          style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.amber800,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'كشف أسبوعي معتمد',
                            style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'عن الفترة: ${DateHelper.formatDisplay(weekStart)} إلى ${DateHelper.formatDisplay(weekEnd)}',
                          style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.blueGrey800),
                        ),
                        pw.Text(
                          'تاريخ الطباعة: ${DateHelper.formatDisplay(DateTime.now())} - ${DateHelper.formatTime(DateTime.now())}',
                          style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Master Payroll Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FixedColumnWidth(24),  // #
                  1: const pw.FlexColumnWidth(3),    // Name
                  2: const pw.FlexColumnWidth(1.4),  // Days
                  3: const pw.FlexColumnWidth(1.8),  // Daily Wage
                  4: const pw.FlexColumnWidth(2),    // Wages Total
                  5: const pw.FlexColumnWidth(1.5),  // OT Hours
                  6: const pw.FlexColumnWidth(1.8),  // OT Pay
                  7: const pw.FlexColumnWidth(1.8),  // Bonuses
                  8: const pw.FlexColumnWidth(2),    // Advances
                  9: const pw.FlexColumnWidth(1.8),  // Deductions
                  10: const pw.FlexColumnWidth(2.2), // Net Due
                  11: const pw.FlexColumnWidth(2.2), // Paid
                  12: const pw.FlexColumnWidth(2),   // Remaining
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTh(fontBold, 'م'),
                      _buildTh(fontBold, 'اسم العامل'),
                      _buildTh(fontBold, 'أيام'),
                      _buildTh(fontBold, 'اليومية'),
                      _buildTh(fontBold, 'إجمالي الأجر'),
                      _buildTh(fontBold, 'إضافي'),
                      _buildTh(fontBold, 'أجر إضافي'),
                      _buildTh(fontBold, 'مكافآت'),
                      _buildTh(fontBold, 'السلف (-)'),
                      _buildTh(fontBold, 'خصومات (-)'),
                      _buildTh(fontBold, 'الصافي'),
                      _buildTh(fontBold, 'المدفوع'),
                      _buildTh(fontBold, 'المتبقي'),
                    ],
                  ),

                  // Worker Rows
                  ...summaries.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final s = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        _buildTd(fontRegular, '$idx', center: true),
                        _buildTd(fontBold, s.worker.fullName),
                        _buildTd(fontRegular, '${s.daysAttended}', center: true),
                        _buildTd(fontRegular, CurrencyFormatter.formatWithoutSymbol(s.worker.dailyWage)),
                        _buildTd(fontRegular, CurrencyFormatter.formatWithoutSymbol(s.dailyWagesEarned)),
                        _buildTd(fontRegular, s.overtimeHours > 0 ? '${s.overtimeHours}س' : '-', center: true),
                        _buildTd(fontRegular, CurrencyFormatter.formatWithoutSymbol(s.overtimeEarnings)),
                        _buildTd(fontRegular, CurrencyFormatter.formatWithoutSymbol(s.bonusesTotal)),
                        _buildTd(fontRegular, CurrencyFormatter.formatWithoutSymbol(s.advancesTotal), color: s.advancesTotal > 0 ? PdfColors.amber900 : null),
                        _buildTd(fontRegular, CurrencyFormatter.formatWithoutSymbol(s.deductionsTotal), color: s.deductionsTotal > 0 ? PdfColors.red800 : null),
                        _buildTd(fontBold, CurrencyFormatter.formatWithoutSymbol(s.netAmountDue), color: PdfColors.blueGrey900),
                        _buildTd(fontBold, CurrencyFormatter.formatWithoutSymbol(s.amountAlreadyPaid), color: PdfColors.green900),
                        _buildTd(fontBold, CurrencyFormatter.formatWithoutSymbol(s.remainingDue), color: s.remainingDue > 0 ? PdfColors.red800 : PdfColors.grey700),
                      ],
                    );
                  }),

                  // Grand Totals Summary Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTh(fontBold, '—'),
                      _buildTh(fontBold, 'الإجمالي العام (${summaries.length} عمال)'),
                      _buildTh(fontBold, '${summaries.fold<int>(0, (sum, s) => sum + s.daysAttended)}'),
                      _buildTh(fontBold, '—'),
                      _buildTh(fontBold, CurrencyFormatter.formatWithoutSymbol(grandTotals['gross'] ?? 0)),
                      _buildTh(fontBold, '—'),
                      _buildTh(fontBold, '—'),
                      _buildTh(fontBold, CurrencyFormatter.formatWithoutSymbol(grandTotals['bonuses'] ?? 0)),
                      _buildTh(fontBold, CurrencyFormatter.formatWithoutSymbol(grandTotals['advances'] ?? 0)),
                      _buildTh(fontBold, CurrencyFormatter.formatWithoutSymbol(grandTotals['deductions'] ?? 0)),
                      _buildTh(fontBold, CurrencyFormatter.formatWithoutSymbol(grandTotals['netDue'] ?? 0)),
                      _buildTh(fontBold, CurrencyFormatter.formatWithoutSymbol(grandTotals['paid'] ?? 0)),
                      _buildTh(fontBold, CurrencyFormatter.formatWithoutSymbol(grandTotals['remaining'] ?? 0)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // Summary Cards
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryBadge(fontBold, fontRegular, 'إجمالي أجور واستحقاقات العمال:', CurrencyFormatter.format(grandTotals['gross'] ?? 0), PdfColors.blueGrey800),
                  _buildSummaryBadge(fontBold, fontRegular, 'إجمالي السلف والخصومات:', CurrencyFormatter.format((grandTotals['advances'] ?? 0) + (grandTotals['deductions'] ?? 0)), PdfColors.amber800),
                  _buildSummaryBadge(fontBold, fontRegular, 'إجمالي المنصرف نقداً من الخزينة:', CurrencyFormatter.format(grandTotals['paid'] ?? 0), PdfColors.green800),
                  _buildSummaryBadge(fontBold, fontRegular, 'إجمالي المتبقي المستحق:', CurrencyFormatter.format(grandTotals['remaining'] ?? 0), PdfColors.red800),
                ],
              ),

              pw.Spacer(),

              // Signatures Area
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('إعداد ومراجعة الحسابات:', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                      pw.SizedBox(height: 22),
                      pw.Container(width: 160, height: 1, color: PdfColors.grey400),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('اعتماد مدير المصنع:', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                      pw.SizedBox(height: 22),
                      pw.Container(width: 160, height: 1, color: PdfColors.grey400),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('اعتماد مالك المصنع (م/ ابراهيم نجم):', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                      pw.SizedBox(height: 22),
                      pw.Container(width: 180, height: 1, color: PdfColors.grey400),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('STARS HOMES • نظام الإدارة المالية المحمي', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('وثيقة رسمية معتمدة لإدارة المصنع', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'كشف_رواتب_العمال_المجمع_STARS_HOMES_${DateHelper.formatYMD(weekStart)}.pdf',
    );
  }

  // --- Helper Widgets ---

  static pw.Widget _buildTh(pw.Font fontBold, String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      child: pw.Center(
        child: pw.Text(
          title,
          style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blueGrey900),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _buildTd(pw.Font font, String text, {bool center = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      child: pw.Align(
        alignment: center ? pw.Alignment.center : pw.Alignment.centerRight,
        child: pw.Text(
          text,
          style: pw.TextStyle(font: font, fontSize: 7.5, color: color ?? PdfColors.blueGrey900),
          textAlign: center ? pw.TextAlign.center : pw.TextAlign.right,
          maxLines: 1,
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryBadge(pw.Font fontBold, pw.Font fontRegular, String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(width: 4),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildFieldRow(pw.Font fontBold, pw.Font fontRegular, String label, String value) {
    return pw.Row(
      children: [
        pw.Text(label, style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey800)),
        pw.SizedBox(width: 6),
        pw.Text(value, style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.blueGrey900)),
      ],
    );
  }

  static pw.Widget _buildFinanceItem(
    pw.Font fontBold,
    pw.Font fontRegular,
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: isBold ? fontBold : fontRegular, fontSize: 9, color: PdfColors.grey800)),
          pw.Text(value, style: pw.TextStyle(font: isBold ? fontBold : fontRegular, fontSize: 9.5, color: color ?? PdfColors.blueGrey900)),
        ],
      ),
    );
  }

  static pw.Widget _buildFinalBox(pw.Font fontBold, pw.Font fontRegular, String title, String amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(title, style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 3),
        pw.Text(amount, style: pw.TextStyle(font: fontBold, fontSize: 12, color: color)),
      ],
    );
  }
}
