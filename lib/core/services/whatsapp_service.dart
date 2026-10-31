import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/customer_order_model.dart';
import '../../models/order_payment_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/customer_receipt_helper.dart';
import '../utils/date_helper.dart';

/// ========================================================
/// STARS HOMES - WhatsApp Service
/// خدمة ربط التطبيق بواتساب ومشاركة تفاصيل الطلبات والفواتير
/// ========================================================
class WhatsAppService {
  static final WhatsAppService instance = WhatsAppService._internal();
  WhatsAppService._internal();

  /// Formats raw phone number to international WhatsApp format (e.g. Egypt +20)
  static String formatPhoneNumber(String rawPhone) {
    String cleaned = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    } else if (cleaned.startsWith('00')) {
      cleaned = cleaned.substring(2);
    }

    // Egyptian phone formatting: 010..., 011..., 012..., 015...
    if (cleaned.startsWith('01') && cleaned.length == 11) {
      cleaned = '2$cleaned';
    } else if (cleaned.startsWith('1') && cleaned.length == 10) {
      cleaned = '20$cleaned';
    }

    return cleaned;
  }

  /// Builds a friendly and professional order registration confirmation message
  static String buildOrderMessage({
    required CustomerOrderModel order,
    List<OrderPaymentModel> payments = const [],
    double? initialPayment,
  }) {
    final totalPaid = payments.isNotEmpty
        ? order.calculateTotalPaid(payments)
        : (initialPayment ?? 0.0);
    final remaining = (order.totalAmount - totalPaid).clamp(0.0, double.infinity);

    final deliveryStr = order.deliveryDate != null
        ? DateHelper.formatYMD(order.deliveryDate!)
        : 'سيتم تحديده بالتنسيق معكم';

    final orderCode = order.id.length >= 6 ? order.id.substring(0, 6).toUpperCase() : order.id;

    final notesSection = order.notes != null && order.notes!.trim().isNotEmpty
        ? '📝 *ملاحظات:* ${order.notes}\n'
        : '';

    return '''مرحباً أستاذ/ة ${order.customerName} 🌟
نشكرك على ثقتك في *مصنع ستارز هومز للأثاث والمصنوعات الخشبية* 🛋️🪵

تم تسجيل طلبك لدينا بنجاح، وتفاصيل الطلبية كالتالي:
━━━━━━━━━━━━━━━━━━
📋 *كود الطلب:* #$orderCode
🏷️ *تفاصيل الطلبية:* ${order.orderDescription}
💰 *إجمالي قيمة الطلب:* ${CurrencyFormatter.format(order.totalAmount)}
💵 *المبلغ المسدد / العربون:* ${CurrencyFormatter.format(totalPaid)}
⏳ *المبلغ المتبقي:* ${CurrencyFormatter.format(remaining)}
📅 *تاريخ التسليم المتوقع:* $deliveryStr
$notesSection━━━━━━━━━━━━━━━━━━
📄 مرفق لحضرتك نسخة PDF تفصيلية من الفاتورة والطلبية.

نسعد دائماً بخدمتكم وتلبية رغباتكم بأعلى معايير الجودة والدقة ✨
📞 لأي استفسار يسعدنا تواصلك معنا دائماً.''';
  }

  /// Builds a delivery reminder message to notify the customer about upcoming delivery
  static String buildDeliveryReminderMessage({
    required CustomerOrderModel order,
    required int daysRemaining,
    List<OrderPaymentModel> payments = const [],
  }) {
    final totalPaid = payments.isNotEmpty
        ? order.calculateTotalPaid(payments)
        : 0.0;
    final remaining = (order.totalAmount - totalPaid).clamp(0.0, double.infinity);
    final deliveryStr = order.deliveryDate != null
        ? DateHelper.formatYMD(order.deliveryDate!)
        : 'خلال الأيام القادمة';
    final orderCode = order.id.length >= 6 ? order.id.substring(0, 6).toUpperCase() : order.id;

    final countdownStr = daysRemaining < 0
        ? 'تجاوز موعد التسليم المحدد ($deliveryStr) ونعمل على إنهاء التسليم فوراً'
        : daysRemaining == 0
            ? 'اليوم بإذن الله ($deliveryStr)'
            : daysRemaining == 1
                ? 'غداً بإذن الله ($deliveryStr)'
                : 'خلال $daysRemaining أيام (الموافق $deliveryStr)';

    return '''تذكير بموعد التسليم 🌟
مرحباً أستاذ/ة ${order.customerName}، تحية طيبة من *مصنع ستارز هومز للأثاث والمصنوعات الخشبية* 🛋️✨

نود تذكيركم باقتراب موعد تسليم طلبيتكم:
━━━━━━━━━━━━━━━━━━
📋 *كود الطلب:* #$orderCode
🏷️ *تفاصيل الطلبية:* ${order.orderDescription}
📅 *موعد التسليم المتوقع:* $countdownStr
💰 *إجمالي الحساب:* ${CurrencyFormatter.format(order.totalAmount)}
💵 *المسدد:* ${CurrencyFormatter.format(totalPaid)}
⏳ *المتبقي عند الاستلام:* ${CurrencyFormatter.format(remaining)}
━━━━━━━━━━━━━━━━━━
نحن في المراحل النهائية لتجهيز طلبكم بأعلى درجات الجودة والإتقان.
يرجى تأكيد موعد الاستلام والتنسيق معنا 🚚
📞 للتواصل والاستفسار: يسعدنا دائماً خدمتكم!''';
  }

  /// Opens WhatsApp chat directly with a pre-filled message
  static Future<bool> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = formatPhoneNumber(phone);
    if (cleanPhone.isEmpty) return false;

    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for native whatsapp scheme
        final nativeUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedMessage');
        if (await canLaunchUrl(nativeUri)) {
          return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('[WhatsAppService] launchUrl error: $e');
    }
    return false;
  }

  /// Generates the order receipt PDF and opens the share dialog (WhatsApp share)
  static Future<void> shareOrderPdf({
    required CustomerOrderModel order,
    required List<OrderPaymentModel> payments,
  }) async {
    try {
      final pdfBytes = await CustomerReceiptHelper.generateReceiptPdfBytes(
        order: order,
        payments: payments,
      );

      final filename = 'فاتورة_طلب_${order.customerName}_${DateHelper.formatYMD(DateTime.now())}.pdf';

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
        subject: 'فاتورة طلبية - مصنع ستارز هومز للأثاث',
      );
    } catch (e) {
      debugPrint('[WhatsAppService] shareOrderPdf error: $e');
    }
  }

  /// Sends full WhatsApp notification (opens chat with message and allows sharing PDF)
  static Future<void> sendOrderViaWhatsApp({
    required BuildContext context,
    required CustomerOrderModel order,
    List<OrderPaymentModel> payments = const [],
    double? initialPayment,
  }) async {
    if (order.phone == null || order.phone!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد رقم هاتف مسجل لهذا العميل'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final message = buildOrderMessage(
      order: order,
      payments: payments,
      initialPayment: initialPayment,
    );

    // 1. Open WhatsApp with message
    final opened = await openWhatsApp(phone: order.phone!, message: message);

    // 2. Offer to share PDF
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(opened
              ? 'تم فتح محادثة واتساب! يمكنك مشاركة ملف الفاتورة PDF الآن.'
              : 'تعذر فتح واتساب مباشرة. يمكنك مشاركة الفاتورة PDF:'),
          backgroundColor: const Color(0xFF1E3A2B),
          action: SnackBarAction(
            label: 'مشاركة PDF 📄',
            textColor: Colors.amber,
            onPressed: () {
              shareOrderPdf(order: order, payments: payments);
            },
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  /// Sends a 1-week or upcoming delivery reminder to the customer via WhatsApp
  static Future<void> sendDeliveryReminderViaWhatsApp({
    required BuildContext context,
    required CustomerOrderModel order,
    required int daysRemaining,
    List<OrderPaymentModel> payments = const [],
  }) async {
    if (order.phone == null || order.phone!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد رقم هاتف مسجل لهذا العميل'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final message = buildDeliveryReminderMessage(
      order: order,
      daysRemaining: daysRemaining,
      payments: payments,
    );

    final opened = await openWhatsApp(phone: order.phone!, message: message);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(opened
              ? 'تم فتح واتساب لإرسال رسالة تذكير موعد التسليم للعميل!'
              : 'تعذر فتح واتساب مباشرة. يرجى التأكد من تثبيت واتساب على الجهاز.'),
          backgroundColor: const Color(0xFF1E3A2B),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

