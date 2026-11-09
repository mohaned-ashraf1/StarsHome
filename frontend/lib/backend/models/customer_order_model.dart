import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:stars_home/frontend/constants/app_colors.dart';
import 'order_payment_model.dart';

/// Represents a distinct furniture section or room inside a customer order
/// (e.g. غرفة نوم رئيسية, غرفة أطفال, دولاب / دريسينج, صالون, مطبخ...)
class OrderSectionItem {
  final String id;
  final String sectionType; // e.g. 'غرفة نوم رئيسية', 'غرفة أطفال', 'دولاب / دريسينج', 'صالون', 'مطبخ', 'أخرى'
  final String title;       // Section name / title
  final String description; // Specs & details
  final String? imagePath;  // Local file path
  final String? imageBase64;// Base64 string for sync & PDF printing

  OrderSectionItem({
    String? id,
    required this.sectionType,
    required this.title,
    required this.description,
    this.imagePath,
    this.imageBase64,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'section_type': sectionType,
    'title': title,
    'description': description,
    'image_path': imagePath,
    'image_base64': imageBase64,
  };

  factory OrderSectionItem.fromMap(Map<String, dynamic> map) => OrderSectionItem(
    id: map['id']?.toString(),
    sectionType: map['section_type']?.toString() ?? 'قسم مخصص',
    title: map['title']?.toString() ?? '',
    description: map['description']?.toString() ?? '',
    imagePath: map['image_path']?.toString(),
    imageBase64: map['image_base64']?.toString(),
  );

  OrderSectionItem copyWith({
    String? sectionType,
    String? title,
    String? description,
    String? imagePath,
    String? imageBase64,
  }) => OrderSectionItem(
    id: id,
    sectionType: sectionType ?? this.sectionType,
    title: title ?? this.title,
    description: description ?? this.description,
    imagePath: imagePath ?? this.imagePath,
    imageBase64: imageBase64 ?? this.imageBase64,
  );
}

class CustomerOrderModel {
  final String id;
  final String customerName;
  final String? phone;
  final String orderDescription;
  final DateTime startDate;
  final DateTime? deliveryDate;
  final double totalAmount;
  final String status; // 'in_progress', 'ready', 'delivered', 'cancelled'
  final String? notes;
  final List<OrderSectionItem> sections;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerOrderModel({
    String? id,
    required this.customerName,
    this.phone,
    required this.orderDescription,
    required this.startDate,
    this.deliveryDate,
    required this.totalAmount,
    this.status = 'in_progress',
    this.notes,
    List<OrderSectionItem>? sections,
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        sections = sections ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double calculateTotalPaid(List<OrderPaymentModel> payments) {
    return payments
        .where((p) => p.orderId == id)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double calculateRemainingBalance(List<OrderPaymentModel> payments) {
    final paid = calculateTotalPaid(payments);
    final remaining = totalAmount - paid;
    return remaining < 0 ? 0.0 : remaining;
  }

  bool isFullyPaid(List<OrderPaymentModel> payments) {
    return calculateRemainingBalance(payments) <= 0.01 && totalAmount > 0;
  }

  double paymentProgress(List<OrderPaymentModel> payments) {
    if (totalAmount <= 0) return 1.0;
    final progress = calculateTotalPaid(payments) / totalAmount;
    return progress.clamp(0.0, 1.0);
  }

  String get statusArabicName {
    switch (status) {
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'ready':
        return 'جاهز للتسليم';
      case 'delivered':
        return 'تم التسليم والانتهاء';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'قيد التنفيذ';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'in_progress':
        return AppColors.accentGold;
      case 'ready':
        return AppColors.infoBlue;
      case 'delivered':
        return AppColors.incomeGreen;
      case 'cancelled':
        return AppColors.expenseRed;
      default:
        return AppColors.accentGold;
    }
  }

  /// Days remaining until delivery date (negative if overdue).
  /// Returns null if no delivery date is set.
  int? get daysUntilDelivery {
    if (deliveryDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(deliveryDate!.year, deliveryDate!.month, deliveryDate!.day);
    return target.difference(today).inDays;
  }

  /// Whether this order is due within 7 days (and not yet delivered or cancelled).
  bool get isDueWithinOneWeek {
    if (status == 'delivered' || status == 'cancelled') return false;
    final days = daysUntilDelivery;
    if (days == null) return false;
    return days >= 0 && days <= 7;
  }

  /// Whether this order is overdue (past delivery date and not delivered/cancelled).
  bool get isOverdue {
    if (status == 'delivered' || status == 'cancelled') return false;
    final days = daysUntilDelivery;
    if (days == null) return false;
    return days < 0;
  }

  /// User-facing warning badge text
  String? get deliveryWarningText {
    if (status == 'delivered' || status == 'cancelled') return null;
    final days = daysUntilDelivery;
    if (days == null) return null;
    if (days < 0) {
      return 'تأخر التسليم بـ ${-days} يوم!';
    } else if (days == 0) {
      return 'موعد التسليم اليوم!';
    } else if (days == 1) {
      return 'موعد التسليم غداً!';
    } else if (days <= 7) {
      return 'متبقي $days أيام على موعد التسليم';
    }
    return null;
  }

  static String encodeNotesWithSections(String? userNotes, List<OrderSectionItem> sections) {
    if (sections.isEmpty) return userNotes ?? '';
    final sectionsJson = jsonEncode(sections.map((s) => s.toMap()).toList());
    final cleanNotes = userNotes?.trim() ?? '';
    if (cleanNotes.isEmpty) {
      return '---SECTIONS_START---\n$sectionsJson\n---SECTIONS_END---';
    }
    return '$cleanNotes\n---SECTIONS_START---\n$sectionsJson\n---SECTIONS_END---';
  }

  static ({String? userNotes, List<OrderSectionItem> sections}) decodeNotesWithSections(String? raw) {
    if (raw == null || raw.isEmpty) {
      return (userNotes: null, sections: <OrderSectionItem>[]);
    }
    const startTag = '---SECTIONS_START---';
    const endTag = '---SECTIONS_END---';
    final startIndex = raw.indexOf(startTag);
    final endIndex = raw.indexOf(endTag);

    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      final userNotes = raw.substring(0, startIndex).trim();
      final jsonStr = raw.substring(startIndex + startTag.length, endIndex).trim();
      try {
        final decoded = jsonDecode(jsonStr) as List;
        final list = decoded
            .map((item) => OrderSectionItem.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
        return (userNotes: userNotes.isEmpty ? null : userNotes, sections: list);
      } catch (e) {
        return (userNotes: raw, sections: <OrderSectionItem>[]);
      }
    }
    return (userNotes: raw, sections: <OrderSectionItem>[]);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'phone': phone,
      'order_description': orderDescription,
      'start_date': startDate.toIso8601String().split('T')[0],
      'delivery_date': deliveryDate?.toIso8601String().split('T')[0],
      'total_amount': totalAmount,
      'status': status,
      'notes': encodeNotesWithSections(notes, sections),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CustomerOrderModel.fromMap(Map<String, dynamic> map) {
    final parsed = decodeNotesWithSections(map['notes']?.toString());
    return CustomerOrderModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      customerName: map['customer_name']?.toString() ?? '',
      phone: map['phone']?.toString(),
      orderDescription: map['order_description']?.toString() ?? '',
      startDate: map['start_date'] != null
          ? DateTime.tryParse(map['start_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      deliveryDate: map['delivery_date'] != null
          ? DateTime.tryParse(map['delivery_date'].toString())
          : null,
      totalAmount: double.tryParse(map['total_amount']?.toString() ?? '0') ?? 0.0,
      status: map['status']?.toString() ?? 'in_progress',
      notes: parsed.userNotes,
      sections: parsed.sections,
      createdBy: map['created_by']?.toString() ?? 'المدير',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  CustomerOrderModel copyWith({
    String? customerName,
    String? phone,
    String? orderDescription,
    DateTime? startDate,
    DateTime? deliveryDate,
    double? totalAmount,
    String? status,
    String? notes,
    List<OrderSectionItem>? sections,
    String? createdBy,
  }) {
    return CustomerOrderModel(
      id: id,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      orderDescription: orderDescription ?? this.orderDescription,
      startDate: startDate ?? this.startDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      sections: sections ?? this.sections,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
