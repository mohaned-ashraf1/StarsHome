class DebtAdvancePaymentModel {
  final String id;
  final String debtAdvanceId;
  final double amount;
  final DateTime paymentDate;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;

  DebtAdvancePaymentModel({
    required this.id,
    required this.debtAdvanceId,
    required this.amount,
    required this.paymentDate,
    this.notes,
    required this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debt_advance_id': debtAdvanceId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DebtAdvancePaymentModel.fromMap(Map<String, dynamic> map) {
    return DebtAdvancePaymentModel(
      id: map['id']?.toString() ?? '',
      debtAdvanceId: map['debt_advance_id']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: DateTime.tryParse(map['payment_date']?.toString() ?? '') ?? DateTime.now(),
      notes: map['notes']?.toString(),
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
