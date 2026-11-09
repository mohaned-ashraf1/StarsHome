import 'package:uuid/uuid.dart';

class OrderPaymentModel {
  final String id;
  final String orderId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? notes;
  final String? linkedIncomeId;
  final String createdBy;
  final DateTime createdAt;

  OrderPaymentModel({
    String? id,
    required this.orderId,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod = 'نقدي',
    this.notes,
    this.linkedIncomeId,
    required this.createdBy,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'payment_method': paymentMethod,
      'notes': notes,
      'linked_income_id': linkedIncomeId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OrderPaymentModel.fromMap(Map<String, dynamic> map) {
    return OrderPaymentModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      orderId: map['order_id']?.toString() ?? '',
      amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
      paymentDate: map['payment_date'] != null
          ? DateTime.tryParse(map['payment_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      paymentMethod: map['payment_method']?.toString() ?? 'نقدي',
      notes: map['notes']?.toString(),
      linkedIncomeId: map['linked_income_id']?.toString(),
      createdBy: map['created_by']?.toString() ?? 'المدير',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  OrderPaymentModel copyWith({
    String? orderId,
    double? amount,
    DateTime? paymentDate,
    String? paymentMethod,
    String? notes,
    String? linkedIncomeId,
    String? createdBy,
  }) {
    return OrderPaymentModel(
      id: id,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      linkedIncomeId: linkedIncomeId ?? this.linkedIncomeId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
    );
  }
}
