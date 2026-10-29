import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/manufacturing_order_model.dart';
import '../utils/date_helper.dart';

class ManufacturingPdfService {
  static Future<Uint8List> generateManufacturingOrderPdf(ManufacturingOrderModel order) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        margin: const pw.EdgeInsets.all(26),
        header: (pw.Context ctx) {
          return pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.amber800, width: 2.0)),
            ),
            padding: const pw.EdgeInsets.only(bottom: 8),
            margin: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'STARS HOMES',
                      style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.blueGrey900),
                    ),
                    pw.Text(
                      'مصنع ستارز هومز للأثاث والمصنوعات الخشبية',
                      style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.amber900),
                    ),
                    pw.Text(
                      'بطاقة تشغيل ورشة • أمر تصنيع معتمد',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
                if (logoImage != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.amber800),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'STARS HOMES',
                      style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.amber800),
                    ),
                  ),
              ],
            ),
          );
        },
        footer: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('STARS HOMES FACTORY • إدارة الإنتاج والتشغيل', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('صفحة ${ctx.pageNumber} من ${ctx.pagesCount}', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey800)),
              ],
            ),
          );
        },
        build: (pw.Context ctx) {
          return [
            // ORDER BADGE & TIMELINE
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('أمر تصنيع رقم: ${order.orderNumber}', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blueGrey900)),
                  pw.Text('تاريخ البدء: ${DateHelper.formatYMD(order.manufacturingDate)}', style: const pw.TextStyle(fontSize: 10)),
                  if (order.expectedCompletionDate != null)
                    pw.Text(
                      'موعد التسليم المتوقع: ${DateHelper.formatYMD(order.expectedCompletionDate!)}',
                      style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.red800),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // SECTION 1: CUSTOMER & WORKER
            _buildSectionTitle('أولاً: بيانات العميل والمسؤول', fontBold),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(children: [
                          pw.TextSpan(text: 'العميل: ', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                          pw.TextSpan(
                            text: order.customerName != null && order.customerName!.isNotEmpty ? order.customerName! : 'عميل غير مسجل بالاسم',
                            style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blueGrey900),
                          ),
                        ]),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'بيان الطلب: ${order.displayTitle}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(children: [
                          pw.TextSpan(text: 'الصنايعي / الورشة: ', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                          pw.TextSpan(
                            text: order.assignedWorkerName ?? "ورشة المصنع العامة",
                            style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blueGrey800),
                          ),
                        ]),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'إجمالي القطع: ${order.totalPiecesCount} قطعة',
                        style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.amber900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // SECTION 2: FURNITURE SECTIONS & COMPONENTS
            _buildSectionTitle('ثانياً: أقسام الأثاث والمكونات والمقاسات المطلوبة', fontBold),
            if (order.sections.isNotEmpty) ...[
              ...order.sections.map((section) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'قسم: ${section.sectionName}',
                              style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blueGrey900),
                            ),
                            pw.Text(
                              'عدد القطع: ${section.totalPiecesCount}',
                              style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.amber900),
                            ),
                          ],
                        ),
                      ),
                      // Components Table
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                        children: [
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(color: PdfColors.grey50),
                            children: [
                              _buildTableCell('القطعة', font: fontBold, isHeader: true, width: 110),
                              _buildTableCell('العدد', font: fontBold, isHeader: true, width: 35),
                              _buildTableCell('المقاسات والأبعاد', font: fontBold, isHeader: true, width: 140),
                              _buildTableCell('الخامات والمواصفات والتشطيب', font: fontBold, isHeader: true),
                            ],
                          ),
                          ...section.components.map((comp) {
                            return pw.TableRow(
                              children: [
                                _buildTableCell(comp.name, font: fontBold),
                                _buildTableCell('${comp.quantity}', font: fontBold),
                                _buildTableCell(comp.dimensionsSummary),
                                _buildTableCell(
                                  comp.specsSummary.isNotEmpty
                                      ? comp.specsSummary
                                      : (comp.notes ?? '---'),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              // Fallback for single product
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('المنتج: ${order.productName}', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                    pw.Text('المقاسات: ${order.dimensions?.formattedDisplay ?? "حسب المعاينة"}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
            pw.SizedBox(height: 12),

            // SECTION 3: RAW MATERIALS TABLE
            _buildSectionTitle('ثالثاً: الخامات المطلوبة للتصنيع وقائمة الفحص [ ✓ ]', fontBold),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('استلام', font: fontBold, isHeader: true, width: 40),
                    _buildTableCell('الخامة المطلوبة', font: fontBold, isHeader: true, width: 140),
                    _buildTableCell('الكمية', font: fontBold, isHeader: true, width: 70),
                    _buildTableCell('السمك / المواصفات', font: fontBold, isHeader: true, width: 100),
                    _buildTableCell('اللون / الملاحظات والتوجيه', font: fontBold, isHeader: true),
                  ],
                ),
                if (order.materials.isEmpty)
                  pw.TableRow(
                    children: [
                      _buildTableCell(''),
                      _buildTableCell('لم يتم تسجيل خامات مطلوبة'),
                      _buildTableCell(''),
                      _buildTableCell(''),
                      _buildTableCell(''),
                    ],
                  ),
                ...order.materials.map((mat) {
                  return pw.TableRow(
                    children: [
                      // Pen Checkbox
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.symmetric(vertical: 5),
                        child: pw.Container(
                          width: 12,
                          height: 12,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.black, width: 1),
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      _buildTableCell(mat.materialName, font: fontBold),
                      _buildTableCell(mat.quantityDisplay, font: fontBold),
                      _buildTableCell(mat.thicknessGrade ?? mat.specifications ?? '---'),
                      _buildTableCell(mat.colorCode ?? mat.notes ?? '---'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),

            // SECTION 4: INSTRUCTIONS & GENERAL NOTES
            _buildSectionTitle('رابعاً: تعليمات وملاحظات الورشة والتشغيل', fontBold),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
                color: PdfColors.grey50,
              ),
              child: pw.Text(
                order.notes != null && order.notes!.isNotEmpty
                    ? order.notes!
                    : '1. يرجى مطابقة المقاسات قبل القص والتجميع.\n2. استخدام غراء ألماني ومسامير مخفية.\n3. الفحص النهائي قبل تسليم أمر التصنيع للإدارة.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
              ),
            ),
            pw.SizedBox(height: 14),

            // SIGNATURES FOOTER
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 1)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('مسؤول تجهيز الخامات: ...........................', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Text('التاريخ: _____ / _____ / 2026', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('توقيع الصنايعي المستلم: ...........................', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Text('الاسم: ${order.assignedWorkerName ?? "..........................."}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('اعتماد إدارة المصنع: ...........................', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Text('STARS HOMES FACTORY', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildSectionTitle(String title, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(
        title,
        style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blueGrey800),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.Font? font,
    bool isHeader = false,
    double? width,
  }) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 9 : 8.5,
          color: isHeader ? PdfColors.black : PdfColors.grey900,
        ),
      ),
    );
  }

  static Future<void> printManufacturingOrder(BuildContext context, ManufacturingOrderModel order) async {
    final pdfBytes = await generateManufacturingOrderPdf(order);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'امر_تصنيع_${order.orderNumber.replaceAll('#', '')}.pdf',
    );
  }
}
