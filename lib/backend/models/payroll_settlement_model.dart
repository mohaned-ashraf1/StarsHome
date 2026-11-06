import 'package:uuid/uuid.dart';

class PayrollSettlementModel {
  final String id;
  final String workerId;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final int daysAttended;
  final double dailyWagesTotal;
  final double overtimeHoursTotal;
  final double overtimePayTotal;
  final double bonusesTotal;
  final double advancesTotal;
  final double deductionsTotal;
  final double grossEarnings;
  final double netDue;
  final double amountPaid;
  final double remainingBalance;
  final DateTime? paymentDate;
  final String paymentMethod;
  final String? notes;
  final bool isSettled;
  final String? linkedExpenseId;
  final String createdBy;
  final DateTime createdAt;

  PayrollSettlementModel({
    String? id,
    required this.workerId,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.daysAttended,
    required this.dailyWagesTotal,
    required this.overtimeHoursTotal,
    required this.overtimePayTotal,
    required this.bonusesTotal,
    required this.advancesTotal,
    required this.deductionsTotal,
    required this.grossEarnings,
    required this.netDue,
    this.amountPaid = 0.0,
    required this.remainingBalance,
    this.paymentDate,
    this.paymentMethod = 'cash',
    this.notes,
    this.isSettled = false,
    this.linkedExpenseId,
    required this.createdBy,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'week_start_date': weekStartDate.toIso8601String().split('T')[0],
      'week_end_date': weekEndDate.toIso8601String().split('T')[0],
      'days_attended': daysAttended,
      'daily_wages_total': dailyWagesTotal,
      'overtime_hours_total': overtimeHoursTotal,
      'overtime_pay_total': overtimePayTotal,
      'bonuses_total': bonusesTotal,
      'advances_total': advancesTotal,
      'deductions_total': deductionsTotal,
      'gross_earnings': grossEarnings,
      'net_due': netDue,
      'amount_paid': amountPaid,
      'remaining_balance': remainingBalance,
      'payment_date': paymentDate?.toIso8601String().split('T')[0],
      'payment_method': paymentMethod,
      'notes': notes,
      'is_settled': isSettled ? 1 : 0,
      'linked_expense_id': linkedExpenseId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PayrollSettlementModel.fromMap(Map<String, dynamic> map) {
    return PayrollSettlementModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      workerId: map['worker_id']?.toString() ?? '',
      weekStartDate: map['week_start_date'] != null
          ? DateTime.tryParse(map['week_start_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      weekEndDate: map['week_end_date'] != null
          ? DateTime.tryParse(map['week_end_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      daysAttended: int.tryParse(map['days_attended']?.toString() ?? '0') ?? 0,
      dailyWagesTotal: double.tryParse(map['daily_wages_total']?.toString() ?? '0') ?? 0.0,
      overtimeHoursTotal: double.tryParse(map['overtime_hours_total']?.toString() ?? '0') ?? 0.0,
      overtimePayTotal: double.tryParse(map['overtime_pay_total']?.toString() ?? '0') ?? 0.0,
      bonusesTotal: double.tryParse(map['bonuses_total']?.toString() ?? '0') ?? 0.0,
      advancesTotal: double.tryParse(map['advances_total']?.toString() ?? '0') ?? 0.0,
      deductionsTotal: double.tryParse(map['deductions_total']?.toString() ?? '0') ?? 0.0,
      grossEarnings: double.tryParse(map['gross_earnings']?.toString() ?? '0') ?? 0.0,
      netDue: double.tryParse(map['net_due']?.toString() ?? '0') ?? 0.0,
      amountPaid: double.tryParse(map['amount_paid']?.toString() ?? '0') ?? 0.0,
      remainingBalance: double.tryParse(map['remaining_balance']?.toString() ?? '0') ?? 0.0,
      paymentDate: map['payment_date'] != null ? DateTime.tryParse(map['payment_date'].toString()) : null,
      paymentMethod: map['payment_method']?.toString() ?? 'cash',
      notes: map['notes']?.toString(),
      isSettled: map['is_settled'] == 1 || map['is_settled'] == true,
      linkedExpenseId: map['linked_expense_id']?.toString(),
      createdBy: map['created_by']?.toString() ?? 'المدير',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }
}
