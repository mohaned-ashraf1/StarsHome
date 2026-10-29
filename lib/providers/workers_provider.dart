import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/services/db_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/date_helper.dart';
import '../models/worker_model.dart';
import '../models/attendance_model.dart';
import '../models/worker_financial_item_model.dart';
import '../models/payroll_settlement_model.dart';
import '../models/purchase_model.dart';

class WorkerPayrollSummary {
  final WorkerModel worker;
  final int daysAttended;
  final double dailyWagesEarned;
  final double overtimeHours;
  final double overtimeEarnings;
  final double bonusesTotal;
  final double advancesTotal;
  final double deductionsTotal;
  final double grossEarnings;
  final double netAmountDue;
  final double amountAlreadyPaid;
  final double remainingDue;
  final bool isSettled;

  WorkerPayrollSummary({
    required this.worker,
    required this.daysAttended,
    required this.dailyWagesEarned,
    required this.overtimeHours,
    required this.overtimeEarnings,
    required this.bonusesTotal,
    required this.advancesTotal,
    required this.deductionsTotal,
    required this.grossEarnings,
    required this.netAmountDue,
    required this.amountAlreadyPaid,
    required this.remainingDue,
    required this.isSettled,
  });
}

class WorkersProvider with ChangeNotifier {
  List<WorkerModel> _workers = [];
  List<AttendanceModel> _attendanceRecords = [];
  List<WorkerFinancialItemModel> _financialItems = [];
  List<PayrollSettlementModel> _payrollSettlements = [];

  DateTime _selectedAttendanceDate = DateTime.now();
  PeriodFilterType _selectedWeekPeriod = PeriodFilterType.currentWeek;
  DateTime? _customWeekStart;
  DateTime? _customWeekEnd;
  bool _isLoading = false;
  String? _lastError;

  List<WorkerModel> get workers => _workers;
  List<WorkerModel> get activeWorkers => _workers.where((w) => w.isActive).toList();
  List<AttendanceModel> get attendanceRecords => _attendanceRecords;
  List<WorkerFinancialItemModel> get financialItems => _financialItems;
  List<PayrollSettlementModel> get payrollSettlements => _payrollSettlements;

  DateTime get selectedAttendanceDate => _selectedAttendanceDate;
  PeriodFilterType get selectedWeekPeriod => _selectedWeekPeriod;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  WorkersProvider() {
    loadAll();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadWorkers(),
      _loadAttendance(),
      _loadFinancialItems(),
      _loadPayrollSettlements(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadWorkers() async {
    try {
      final db = await DBService.instance.database;
      final rows = await db.query('workers', orderBy: 'full_name ASC');
      _workers = rows.map((r) => WorkerModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[WorkersProvider] loadWorkers error: $e');
      _lastError = 'فشل تحميل بيانات العمال';
    }
  }

  // Loads ALL attendance records — no limit.
  // Payroll calculations (calculatePayrollForPeriod) filter by period in-memory
  // and MUST have access to all records for all workers. A limit would corrupt payroll.
  Future<void> _loadAttendance() async {
    try {
      final db = await DBService.instance.database;
      final rows = await db.query(
        'worker_attendance',
        orderBy: 'attendance_date DESC',
      );
      _attendanceRecords = rows.map((r) => AttendanceModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[WorkersProvider] loadAttendance error: $e');
    }
  }

  // Loads ALL financial items — no limit.
  // Payroll calculations filter by worker and period — all records are needed.
  Future<void> _loadFinancialItems() async {
    try {
      final db = await DBService.instance.database;
      final rows = await db.query(
        'worker_financial_items',
        orderBy: 'transaction_date DESC',
      );
      _financialItems = rows.map((r) => WorkerFinancialItemModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[WorkersProvider] loadFinancialItems error: $e');
    }
  }

  Future<void> _loadPayrollSettlements() async {
    try {
      final db = await DBService.instance.database;
      final rows = await db.query(
        'worker_payroll_settlements',
        orderBy: 'week_start_date DESC',
        limit: 200,
      );
      _payrollSettlements = rows.map((r) => PayrollSettlementModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[WorkersProvider] loadPayrollSettlements error: $e');
    }
  }

  void setSelectedAttendanceDate(DateTime date) {
    _selectedAttendanceDate = date;
    notifyListeners();
  }

  void setPayrollWeek(PeriodFilterType period, {DateTime? start, DateTime? end}) {
    _selectedWeekPeriod = period;
    _customWeekStart = start;
    _customWeekEnd = end;
    notifyListeners();
  }

  // Attendance for the selected date
  List<AttendanceModel> get attendanceForSelectedDate {
    final ymd = DateHelper.formatYMD(_selectedAttendanceDate);
    return _attendanceRecords.where((a) => DateHelper.formatYMD(a.attendanceDate) == ymd).toList();
  }

  // Add Worker
  Future<void> addWorker({
    required String fullName,
    required double dailyWage,
    String standardStartTime = '08:00',
    String standardEndTime = '19:00',
    required double overtimeHourlyRate,
    String? phone,
    String? notes,
  }) async {
    final worker = WorkerModel(
      fullName: fullName.trim(),
      dailyWage: dailyWage,
      standardStartTime: standardStartTime,
      standardEndTime: standardEndTime,
      overtimeHourlyRate: overtimeHourlyRate,
      phone: phone?.trim(),
      notes: notes?.trim(),
    );

    final db = await DBService.instance.database;
    await db.insert('workers', worker.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    await SyncService.instance.queueOperation(
      tableName: 'workers',
      operation: 'insert',
      recordId: worker.id,
      payload: worker.toMap(),
    );

    await _loadWorkers();
    notifyListeners();
  }

  Future<void> updateWorker(WorkerModel updatedWorker) async {
    final db = await DBService.instance.database;
    final map = updatedWorker.toMap();
    await db.update('workers', map, where: 'id = ?', whereArgs: [updatedWorker.id]);

    await SyncService.instance.queueOperation(
      tableName: 'workers',
      operation: 'update',
      recordId: updatedWorker.id,
      payload: map,
    );

    await _loadWorkers();
    notifyListeners();
  }

  Future<void> deleteWorker(String workerId) async {
    final db = await DBService.instance.database;
    await db.delete('worker_attendance', where: 'worker_id = ?', whereArgs: [workerId]);
    await db.delete('worker_financial_items', where: 'worker_id = ?', whereArgs: [workerId]);
    await db.delete('worker_payroll_settlements', where: 'worker_id = ?', whereArgs: [workerId]);
    await db.delete('workers', where: 'id = ?', whereArgs: [workerId]);

    await SyncService.instance.queueOperation(
      tableName: 'workers',
      operation: 'delete',
      recordId: workerId,
      payload: {'id': workerId},
    );

    await _loadWorkers();
    await _loadAttendance();
    await _loadFinancialItems();
    notifyListeners();
  }

  Future<void> deleteFinancialItem(String itemId) async {
    final db = await DBService.instance.database;
    await db.delete('worker_financial_items', where: 'id = ?', whereArgs: [itemId]);

    await SyncService.instance.queueOperation(
      tableName: 'worker_financial_items',
      operation: 'delete',
      recordId: itemId,
      payload: {'id': itemId},
    );

    await _loadFinancialItems();
    notifyListeners();
  }

  // Record or Update Attendance with automatic overtime calculation
  Future<void> recordAttendance({
    required String workerId,
    required DateTime date,
    required String status, // 'present', 'absent', 'leave'
    String? arrivalTime,
    String? departureTime,
    String? notes,
    required String createdBy,
  }) async {
    final worker = _workers.firstWhere((w) => w.id == workerId, orElse: () => WorkerModel(fullName: '', dailyWage: 0, overtimeHourlyRate: 0));

    double overtimeHours = 0.0;
    double overtimePay = 0.0;
    double dailyWageApplied = 0.0;
    int totalMinutes = 0;
    int overtimeMinutes = 0;

    if (status == 'present') {
      dailyWageApplied = worker.dailyWage;

      if (departureTime != null && departureTime.isNotEmpty) {
        overtimeHours = DateHelper.calculateOvertimeHours(
          standardEndTimeStr: worker.standardEndTime,
          actualDepartureTimeStr: departureTime,
        );
        overtimeMinutes = (overtimeHours * 60).round();
        overtimePay = double.parse((overtimeHours * worker.overtimeHourlyRate).toStringAsFixed(2));

        if (arrivalTime != null && arrivalTime.isNotEmpty) {
          try {
            final arrP = arrivalTime.split(':');
            final depP = departureTime.split(':');
            final arrM = int.parse(arrP[0]) * 60 + int.parse(arrP[1]);
            final depM = int.parse(depP[0]) * 60 + int.parse(depP[1]);
            totalMinutes = depM - arrM;
            if (totalMinutes < 0) totalMinutes += 1440;
          } catch (_) {}
        }
      }
    }

    final attendance = AttendanceModel(
      workerId: workerId,
      attendanceDate: date,
      status: status,
      arrivalTime: arrivalTime,
      departureTime: departureTime,
      totalDurationMinutes: totalMinutes,
      overtimeDurationMinutes: overtimeMinutes,
      overtimePay: overtimePay,
      dailyWageApplied: dailyWageApplied,
      notes: notes,
      createdBy: createdBy,
    );

    final db = await DBService.instance.database;
    await db.insert('worker_attendance', attendance.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    await SyncService.instance.queueOperation(
      tableName: 'worker_attendance',
      operation: 'insert',
      recordId: attendance.id,
      payload: attendance.toMap(),
    );

    await _loadAttendance();
    notifyListeners();
  }

  // Add Bonus, Advance, or Deduction
  Future<void> addFinancialItem({
    required String workerId,
    required String type, // 'advance', 'bonus', 'deduction'
    required double amount,
    required DateTime transactionDate,
    String? reasonNotes,
    required String createdBy,
  }) async {
    final worker = _workers.firstWhere((w) => w.id == workerId);
    String? linkedExpenseId;

    final db = await DBService.instance.database;

    // IF TYPE IS ADVANCE (سلفة): It must appear as a factory expense in Accounts!
    if (type == 'advance') {
      linkedExpenseId = const Uuid().v4();
      final purchase = PurchaseModel(
        id: linkedExpenseId,
        itemName: 'سلفة عامل: ${worker.fullName}',
        category: 'مصاريف عمال وضيافة',
        totalAmount: amount,
        transactionDate: transactionDate,
        notes: reasonNotes != null ? 'سلفة للعمال: $reasonNotes' : 'سلفة للعامل ${worker.fullName}',
        sourceType: 'worker_advance',
        sourceId: workerId,
        createdBy: createdBy,
      );

      await db.insert('purchases', purchase.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await SyncService.instance.queueOperation(
        tableName: 'purchases',
        operation: 'insert',
        recordId: purchase.id,
        payload: purchase.toMap(),
      );
    }

    final item = WorkerFinancialItemModel(
      workerId: workerId,
      type: type,
      amount: amount,
      transactionDate: transactionDate,
      reasonNotes: reasonNotes,
      linkedExpenseId: linkedExpenseId,
      createdBy: createdBy,
    );

    await db.insert('worker_financial_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await SyncService.instance.queueOperation(
      tableName: 'worker_financial_items',
      operation: 'insert',
      recordId: item.id,
      payload: item.toMap(),
    );

    await _loadFinancialItems();
    notifyListeners();
  }

  // Calculate Weekly Payroll Summaries for all workers
  List<WorkerPayrollSummary> calculatePayrollForPeriod() {
    final range = DateHelper.getDateRangeForPeriod(
      _selectedWeekPeriod,
      customStart: _customWeekStart,
      customEnd: _customWeekEnd,
    );

    List<WorkerPayrollSummary> summaries = [];

    for (var worker in _workers) {
      // 1. Attendance within period
      final workerAtt = _attendanceRecords.where((a) => a.workerId == worker.id && range.contains(a.attendanceDate)).toList();

      final presentDays = workerAtt.where((a) => a.status == 'present').length;
      final dailyWages = workerAtt.where((a) => a.status == 'present').fold(0.0, (s, a) => s + a.dailyWageApplied);
      final overtimeHours = workerAtt.fold(0.0, (s, a) => s + a.overtimeHours);
      final overtimePay = workerAtt.fold(0.0, (s, a) => s + a.overtimePay);

      // 2. Financial Items within period
      final workerItems = _financialItems.where((i) => i.workerId == worker.id && range.contains(i.transactionDate)).toList();

      final bonuses = workerItems.where((i) => i.type == 'bonus').fold(0.0, (s, i) => s + i.amount);
      final advances = workerItems.where((i) => i.type == 'advance').fold(0.0, (s, i) => s + i.amount);
      final deductions = workerItems.where((i) => i.type == 'deduction').fold(0.0, (s, i) => s + i.amount);

      // 3. Existing settlements for this worker & period
      final existingSettlement = _payrollSettlements.where((p) {
        return p.workerId == worker.id && DateHelper.formatYMD(p.weekStartDate) == DateHelper.formatYMD(range.start);
      }).firstOrNull;

      final amountPaid = existingSettlement?.amountPaid ?? 0.0;
      final isSettled = existingSettlement?.isSettled ?? false;

      // Formulas:
      // Gross Earnings = Earned Daily Wages + Earned Overtime + Bonuses
      final gross = dailyWages + overtimePay + bonuses;

      // Net Amount Due = Gross Earnings - Advances - Deductions - Previous Payments
      final netDue = gross - advances - deductions;
      final remaining = netDue - amountPaid;

      summaries.add(WorkerPayrollSummary(
        worker: worker,
        daysAttended: presentDays,
        dailyWagesEarned: dailyWages,
        overtimeHours: overtimeHours,
        overtimeEarnings: overtimePay,
        bonusesTotal: bonuses,
        advancesTotal: advances,
        deductionsTotal: deductions,
        grossEarnings: gross,
        netAmountDue: netDue,
        amountAlreadyPaid: amountPaid,
        remainingDue: remaining > 0 ? remaining : 0.0,
        isSettled: isSettled,
      ));
    }

    return summaries;
  }

  // Settle Payroll Payment
  Future<void> settleWorkerPayroll({
    required String workerId,
    required double amountToPay,
    required DateTime paymentDate,
    String paymentMethod = 'cash',
    String? notes,
    required String createdBy,
  }) async {
    final range = DateHelper.getDateRangeForPeriod(
      _selectedWeekPeriod,
      customStart: _customWeekStart,
      customEnd: _customWeekEnd,
    );

    final summaries = calculatePayrollForPeriod();
    final summary = summaries.firstWhere((s) => s.worker.id == workerId);

    final db = await DBService.instance.database;

    // Create linked Expense in Accounts for the wage payment
    final linkedExpenseId = const Uuid().v4();
    final purchase = PurchaseModel(
      id: linkedExpenseId,
      itemName: 'صرف أجور عمال: ${summary.worker.fullName}',
      category: 'مصاريف عمال وضيافة',
      totalAmount: amountToPay,
      transactionDate: paymentDate,
      notes: 'صرف مستحقات أسبوعية للفترة من ${DateHelper.formatYMD(range.start)} إلى ${DateHelper.formatYMD(range.end)}. $notes',
      sourceType: 'worker_payroll',
      sourceId: workerId,
      createdBy: createdBy,
    );

    await db.insert('purchases', purchase.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await SyncService.instance.queueOperation(
      tableName: 'purchases',
      operation: 'insert',
      recordId: purchase.id,
      payload: purchase.toMap(),
    );

    final totalPaid = summary.amountAlreadyPaid + amountToPay;
    final remaining = summary.netAmountDue - totalPaid;
    final isFullySettled = remaining <= 0;

    final settlement = PayrollSettlementModel(
      workerId: workerId,
      weekStartDate: range.start,
      weekEndDate: range.end,
      daysAttended: summary.daysAttended,
      dailyWagesTotal: summary.dailyWagesEarned,
      overtimeHoursTotal: summary.overtimeHours,
      overtimePayTotal: summary.overtimeEarnings,
      bonusesTotal: summary.bonusesTotal,
      advancesTotal: summary.advancesTotal,
      deductionsTotal: summary.deductionsTotal,
      grossEarnings: summary.grossEarnings,
      netDue: summary.netAmountDue,
      amountPaid: totalPaid,
      remainingBalance: remaining > 0 ? remaining : 0.0,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      notes: notes,
      isSettled: isFullySettled,
      linkedExpenseId: linkedExpenseId,
      createdBy: createdBy,
    );

    await db.insert('worker_payroll_settlements', settlement.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await SyncService.instance.queueOperation(
      tableName: 'worker_payroll_settlements',
      operation: 'insert',
      recordId: settlement.id,
      payload: settlement.toMap(),
    );

    await _loadPayrollSettlements();
    notifyListeners();
  }

  // Get total worker accounts summary across all workers
  Map<String, double> getWorkersAggregatedFinancials() {
    final summaries = calculatePayrollForPeriod();
    double totalGross = 0;
    double totalOvertime = 0;
    double totalBonuses = 0;
    double totalAdvances = 0;
    double totalDeductions = 0;
    double totalPaid = 0;
    double totalRemaining = 0;

    for (var s in summaries) {
      totalGross += s.grossEarnings;
      totalOvertime += s.overtimeEarnings;
      totalBonuses += s.bonusesTotal;
      totalAdvances += s.advancesTotal;
      totalDeductions += s.deductionsTotal;
      totalPaid += s.amountAlreadyPaid;
      totalRemaining += s.remainingDue;
    }

    return {
      'gross': totalGross,
      'overtime': totalOvertime,
      'bonuses': totalBonuses,
      'advances': totalAdvances,
      'deductions': totalDeductions,
      'paid': totalPaid,
      'remaining': totalRemaining,
    };
  }
}
