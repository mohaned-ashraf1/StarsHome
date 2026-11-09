import 'package:uuid/uuid.dart';

class ContractorPaymentModel {
  final String id;
  final String contractorId;
  final String description;
  final double amount;
  final DateTime paymentDate;
  final String? relatedOrder;
  final String? notes;
  final String? linkedExpenseId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContractorPaymentModel({
    String? id,
    required this.contractorId,
    required this.description,
    required this.amount,
    required this.paymentDate,
    this.relatedOrder,
    this.notes,
    this.linkedExpenseId,
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contractor_id': contractorId,
      'description': description,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'related_order': relatedOrder,
      'notes': notes,
      'linked_expense_id': linkedExpenseId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ContractorPaymentModel.fromMap(Map<String, dynamic> map) {
    return ContractorPaymentModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      contractorId: map['contractor_id']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
      paymentDate: map['payment_date'] != null
          ? DateTime.tryParse(map['payment_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      relatedOrder: map['related_order']?.toString(),
      notes: map['notes']?.toString(),
      linkedExpenseId: map['linked_expense_id']?.toString(),
      createdBy: map['created_by']?.toString() ?? 'المدير',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }
}
