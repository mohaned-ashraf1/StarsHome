import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_colors.dart';
import 'order_payment_model.dart';

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
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
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
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CustomerOrderModel.fromMap(Map<String, dynamic> map) {
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
      notes: map['notes']?.toString(),
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
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
