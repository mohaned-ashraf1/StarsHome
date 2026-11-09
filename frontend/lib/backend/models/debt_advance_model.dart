class DebtAdvanceModel {
  final String id;
  final String personName;
  final String? phone;
  final String type; // 'advance' (سلفة), 'debt_receivable' (مديونية لنا), 'debt_payable' (مديونية علينا)
  final double amount;
  final double paidAmount;
  final DateTime transactionDate;
  final DateTime? dueDate;
  final String status; // 'active', 'settled'
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DebtAdvanceModel({
    required this.id,
    required this.personName,
    this.phone,
    required this.type,
    required this.amount,
    this.paidAmount = 0.0,
    required this.transactionDate,
    this.dueDate,
    this.status = 'active',
    this.notes,
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get remainingAmount => (amount - paidAmount) > 0 ? (amount - paidAmount) : 0.0;
  bool get isSettled => remainingAmount <= 0.001 || status == 'settled';

  String get typeLabel {
    switch (type) {
      case 'advance':
        return 'سلفة نقدية';
      case 'debt_receivable':
        return 'مديونية لنا (طرف الغير)';
      case 'debt_payable':
        return 'مديونية علينا (التزام)';
      default:
        return 'سلفة / مديونية';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_name': personName,
      'phone': phone,
      'type': type,
      'amount': amount,
      'paid_amount': paidAmount,
      'transaction_date': transactionDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'status': isSettled ? 'settled' : status,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DebtAdvanceModel.fromMap(Map<String, dynamic> map) {
    return DebtAdvanceModel(
      id: map['id']?.toString() ?? '',
      personName: map['person_name']?.toString() ?? '',
      phone: map['phone']?.toString(),
      type: map['type']?.toString() ?? 'advance',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: DateTime.tryParse(map['transaction_date']?.toString() ?? '') ?? DateTime.now(),
      dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date'].toString()) : null,
      status: map['status']?.toString() ?? 'active',
      notes: map['notes']?.toString(),
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  DebtAdvanceModel copyWith({
    String? personName,
    String? phone,
    String? type,
    double? amount,
    double? paidAmount,
    DateTime? transactionDate,
    DateTime? dueDate,
    String? status,
    String? notes,
    DateTime? updatedAt,
  }) {
    return DebtAdvanceModel(
      id: id,
      personName: personName ?? this.personName,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
