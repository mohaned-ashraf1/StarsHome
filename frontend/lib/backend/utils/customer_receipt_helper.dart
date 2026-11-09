import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:stars_home/backend/models/customer_order_model.dart';
import 'package:stars_home/backend/models/order_payment_model.dart';
import 'currency_formatter.dart';
import 'date_helper.dart';

class CustomerReceiptHelper {
  static Future<void> printReceipt({
    required BuildContext context,
    required CustomerOrderModel order,
    required List<OrderPaymentModel> payments,
  }) async {
    final doc = await generateReceiptDocument(order: order, payments: payments);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'ايصال_طلب_${order.customerName}_${DateHelper.formatYMD(DateTime.now())}.pdf',
    );
  }

  static Future<Uint8List> generateReceiptPdfBytes({
    required CustomerOrderModel order,
    required List<OrderPaymentModel> payments,
  }) async {
    final doc = await generateReceiptDocument(order: order, payments: payments);
    return doc.save();
  }

  static Future<pw.Document> generateReceiptDocument({
    required CustomerOrderModel order,
    required List<OrderPaymentModel> payments,
  }) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final logoBytes = await rootBundle.load('assets/images/logo_transparent.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final sortedPayments = List<OrderPaymentModel>.from(payments)
      ..sort((a, b) => a.paymentDate.compareTo(b.paymentDate));

    final totalPaid = order.calculateTotalPaid(payments);
    final remainingBalance = order.calculateRemainingBalance(payments);
    final isSettled = remainingBalance <= 0 && order.totalAmount > 0;

    // Pre-load section images for PDF rendering
    final sectionImages = <String, pw.MemoryImage>{};
    for (final s in order.sections) {
      if (s.imageBase64 != null && s.imageBase64!.trim().isNotEmpty) {
        try {
          final cleanBase64 = s.imageBase64!.contains(',')
              ? s.imageBase64!.split(',').last
              : s.imageBase64!;
          final bytes = base64Decode(cleanBase64.trim());
          sectionImages[s.id] = pw.MemoryImage(bytes);
        } catch (_) {}
      } else if (s.imagePath != null && s.imagePath!.trim().isNotEmpty && !kIsWeb) {
        try {
          final file = File(s.imagePath!.trim());
          if (file.existsSync()) {
            sectionImages[s.id] = pw.MemoryImage(file.readAsBytesSync());
          }
        } catch (_) {}
      }
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
          return pw.Stack(
            children: [
              // Transparent watermark in the center of the page
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.08,
                    child: pw.Image(
                      logoImage,
                      width: 290,
                      height: 290,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Main Receipt Content
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // 1. Factory Header & Receipt Title
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // Right (RTL start): Document Title
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.amber700,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'إيصال طلبية ودفعات',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                          ),
                        ),

                        // Center: Brand Title
                        pw.Text(
                          'STARS HOMES',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 20,
                            letterSpacing: 1.2,
                            color: PdfColors.blueGrey900,
                          ),
                        ),

                        // Left (RTL end): Order Number and Print Date
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'رقم الطلب: #${order.id.substring(0, 8).toUpperCase()}',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 10,
                                color: PdfColors.grey800,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'تاريخ الطباعة: ${DateHelper.formatDisplay(DateTime.now())}',
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

              // 2. Customer Information Grid
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildInfoItem(
                            fontBold,
                            fontRegular,
                            label: 'اسم العميل:',
                            value: order.customerName,
                          ),
                        ),
                        pw.Expanded(
                          child: _buildInfoItem(
                            fontBold,
                            fontRegular,
                            label: 'رقم الهاتف:',
                            value: order.phone?.isNotEmpty == true ? order.phone! : 'غير مسجل',
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildInfoItem(
                            fontBold,
                            fontRegular,
                            label: 'تاريخ بدء الطلب:',
                            value: DateHelper.formatDisplay(order.startDate),
                          ),
                        ),
                        pw.Expanded(
                          child: _buildInfoItem(
                            fontBold,
                            fontRegular,
                            label: 'تاريخ التسليم المتفق عليه:',
                            value: order.deliveryDate != null
                                ? DateHelper.formatDisplay(order.deliveryDate!)
                                : 'حسب الاتفاق والجاهزية',
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildInfoItem(
                            fontBold,
                            fontRegular,
                            label: 'حالة الطلب:',
                            value: order.statusArabicName,
                          ),
                        ),
                        pw.Expanded(
                          child: _buildInfoItem(
                            fontBold,
                            fontRegular,
                            label: 'حالة الحساب:',
                            value: isSettled ? 'خالص السداد بالكامل' : 'يوجد متبقي مستحق',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // 3. Order Details & Sections Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          order.sections.isNotEmpty
                              ? 'أقسام وموديلات الطلب المتفق عليها:'
                              : 'بيانات وتفاصيل الطلب المطلوب:',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 11,
                            color: PdfColors.blueGrey800,
                          ),
                        ),
                        if (order.sections.isNotEmpty)
                          pw.Text(
                            'عدد الأقسام: ${order.sections.length}',
                            style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600),
                          ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    if (order.sections.isEmpty) ...[
                      pw.Text(
                        order.orderDescription,
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 10.5,
                          lineSpacing: 1.4,
                        ),
                      ),
                    ] else ...[
                      ...order.sections.map((sec) {
                        final img = sectionImages[sec.id];
                        return pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 6),
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            border: pw.Border.all(color: PdfColors.grey300, width: 0.7),
                            borderRadius: pw.BorderRadius.circular(5),
                          ),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Row(
                                      children: [
                                        pw.Container(
                                          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: pw.BoxDecoration(
                                            color: PdfColors.amber100,
                                            borderRadius: pw.BorderRadius.circular(3),
                                          ),
                                          child: pw.Text(
                                            sec.sectionType,
                                            style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.amber900),
                                          ),
                                        ),
                                        pw.SizedBox(width: 5),
                                        pw.Expanded(
                                          child: pw.Text(
                                            sec.title,
                                            style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blueGrey900),
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    pw.SizedBox(height: 3),
                                    pw.Text(
                                      sec.description,
                                      style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey800, lineSpacing: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                              if (img != null) ...[
                                pw.SizedBox(width: 8),
                                pw.Container(
                                  width: 75,
                                  height: 60,
                                  decoration: pw.BoxDecoration(
                                    borderRadius: pw.BorderRadius.circular(4),
                                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                                  ),
                                  child: pw.ClipRRect(
                                    horizontalRadius: 4,
                                    verticalRadius: 4,
                                    child: pw.Image(img, fit: pw.BoxFit.cover),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'ملاحظات إضافية: ${order.notes!}',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 8.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // 4. Financial Summary Cards
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Center(
                          child: pw.Text('إجمالي سعر الطلب', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Center(
                          child: pw.Text('إجمالي المدفوع حتى الآن', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Center(
                          child: pw.Text('المتبقي المستحق', style: pw.TextStyle(font: fontBold, fontSize: 10)),
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
                            CurrencyFormatter.format(order.totalAmount),
                            style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blueGrey900),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Center(
                          child: pw.Text(
                            CurrencyFormatter.format(totalPaid),
                            style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.green800),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Center(
                          child: pw.Text(
                            CurrencyFormatter.format(remainingBalance),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: remainingBalance > 0 ? PdfColors.red800 : PdfColors.green800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // 5. Payment Installments Breakdown Table
              pw.Text(
                'سجل الدفعات والأقساط المسددة:',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 11,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 6),

              if (sortedPayments.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border.all(color: PdfColors.grey200),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'لم يتم تسجيل أي دفعات حتى الآن',
                      style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey600),
                    ),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey200),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Center(child: pw.Text('م', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('تاريخ الدفعة', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('المبلغ المسدد', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('طريقة الدفع', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('البيان / ملاحظات الدفعة', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        ),
                      ],
                    ),
                    ...sortedPayments.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final p = entry.value;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Center(child: pw.Text('$idx', style: pw.TextStyle(font: fontRegular, fontSize: 9))),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(DateHelper.formatDisplay(p.paymentDate), style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              CurrencyFormatter.format(p.amount),
                              style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.green900),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(p.paymentMethod, style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(p.notes?.isNotEmpty == true ? p.notes! : '-', style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                          ),
                        ],
                      );
                    }),
                  ],
                ),

              pw.Spacer(),

              // 6. Terms, Quality Guarantee & Signatures
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'تنبيه: يعتبر هذا الإيصال وثيقة رسمية بحركات الدفع والمواصفات المتفق عليها. يتم فحص وتسليم المنتجات بالمصنع أو عند التوصيل طبقاً للمواصفات المدونة أعلاه.',
                  style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.SizedBox(height: 16),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('توقيع العميل المستلم:', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.SizedBox(height: 28),
                      pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ختم وتوقيع إدارة المصنع:', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        width: 120,
                        height: 52,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey400,
                            width: 1,
                            style: pw.BorderStyle.dashed,
                          ),
                          borderRadius: pw.BorderRadius.circular(26),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'ختم المصنع',
                            style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: PdfColors.grey500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'م / ابراهيم نجم',
                    style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.Text('صفحة 1 من 1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ],
          ),
        ],
      );
        },
      ),
    );

    // If any section has an image, append a dedicated Design Photos Appendix Page!
    final sectionsWithImages = order.sections.where((s) => sectionImages.containsKey(s.id)).toList();
    if (sectionsWithImages.isNotEmpty) {
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
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'ملحق صور وموديلات التصميم المعتمدة للطلب',
                        style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blueGrey900),
                      ),
                      pw.Text(
                        'طلب: #${order.id.substring(0, 8).toUpperCase()} - ${order.customerName}',
                        style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // Large photos with descriptions
                pw.Expanded(
                  child: pw.ListView(
                    children: [
                      ...sectionsWithImages.map((sec) {
                        final img = sectionImages[sec.id]!;
                        return pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 12),
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey50,
                            borderRadius: pw.BorderRadius.circular(8),
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // Large Photo
                              pw.Container(
                                width: 180,
                                height: 130,
                                decoration: pw.BoxDecoration(
                                  borderRadius: pw.BorderRadius.circular(6),
                                  border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                                ),
                                child: pw.ClipRRect(
                                  horizontalRadius: 6,
                                  verticalRadius: 6,
                                  child: pw.Image(img, fit: pw.BoxFit.cover),
                                ),
                              ),
                              pw.SizedBox(width: 14),
                              // Specs
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Container(
                                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: pw.BoxDecoration(
                                        color: PdfColors.amber100,
                                        borderRadius: pw.BorderRadius.circular(4),
                                        border: pw.Border.all(color: PdfColors.amber700, width: 0.5),
                                      ),
                                      child: pw.Text(
                                        sec.sectionType,
                                        style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.amber900),
                                      ),
                                    ),
                                    pw.SizedBox(height: 6),
                                    pw.Text(
                                      sec.title,
                                      style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blueGrey900),
                                    ),
                                    pw.SizedBox(height: 6),
                                    pw.Text(
                                      sec.description,
                                      style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey800, lineSpacing: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('مصنع ستارز هومز للأثاث والمصنوعات الخشبية', style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey600)),
                    pw.Text('صفحة ملحق الصور', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return doc;
  }

  static pw.Widget _buildInfoItem(
    pw.Font fontBold,
    pw.Font fontRegular, {
    required String label,
    required String value,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey800),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          value,
          style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.blueGrey900),
        ),
      ],
    );
  }
}
