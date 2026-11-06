import 'package:uuid/uuid.dart';

class WorkerFinancialItemModel {
  final String id;
  final String workerId;
  final String type; // advance (سلفة), bonus (مكافأة), deduction (خصم)
  final double amount;
  final DateTime transactionDate;
  final String? reasonNotes;
  final bool isSettledInPayroll;
  final String? payrollSettlementId;
  final String? linkedExpenseId;
  final String createdBy;
  final DateTime createdAt;

  WorkerFinancialItemModel({
    String? id,
    required this.workerId,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.reasonNotes,
    this.isSettledInPayroll = false,
    this.payrollSettlementId,
    this.linkedExpenseId,
    required this.createdBy,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get typeArabicName {
    switch (type) {
      case 'advance':
        return 'سلفة';
      case 'bonus':
        return 'مكافأة';
      case 'deduction':
        return 'خصم';
      default:
        return type;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'type': type,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String().split('T')[0],
      'reason_notes': reasonNotes,
      'is_settled_in_payroll': isSettledInPayroll ? 1 : 0,
      'payroll_settlement_id': payrollSettlementId,
      'linked_expense_id': linkedExpenseId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WorkerFinancialItemModel.fromMap(Map<String, dynamic> map) {
    return WorkerFinancialItemModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      workerId: map['worker_id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'advance',
      amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
      transactionDate: map['transaction_date'] != null
          ? DateTime.tryParse(map['transaction_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reasonNotes: map['reason_notes']?.toString(),
      isSettledInPayroll: map['is_settled_in_payroll'] == 1 || map['is_settled_in_payroll'] == true,
      payrollSettlementId: map['payroll_settlement_id']?.toString(),
      linkedExpenseId: map['linked_expense_id']?.toString(),
      createdBy: map['created_by']?.toString() ?? 'المدير',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }
}
