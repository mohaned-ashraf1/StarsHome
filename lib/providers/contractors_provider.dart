import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/services/db_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/date_helper.dart';
import '../models/contractor_model.dart';
import '../models/contractor_payment_model.dart';
import '../models/purchase_model.dart';

class ContractorsProvider with ChangeNotifier {
  List<ContractorModel> _contractors = [];
  List<ContractorPaymentModel> _payments = [];

  PeriodFilterType _selectedPeriod = PeriodFilterType.currentMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _searchQuery = '';
  String? _selectedContractorId;
  bool _isLoading = false;

  List<ContractorModel> get contractors => _contractors;
  List<ContractorModel> get activeContractors => _contractors.where((c) => c.isActive).toList();
  List<ContractorPaymentModel> get payments => _payments;

  PeriodFilterType get selectedPeriod => _selectedPeriod;
  String get searchQuery => _searchQuery;
  String? get selectedContractorId => _selectedContractorId;
  bool get isLoading => _isLoading;

  ContractorsProvider() {
    loadAll();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadContractors(),
      _loadPayments(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadContractors() async {
    try {
      final db = await DBService.instance.database;
      // NOTE: Do NOT delete records based on ID prefix — 'cont_' records
      // may be legitimate production data. Demo data cleanup was removed
      // as part of Issue 9 security remediation.
      final rows = await db.query('contractors', orderBy: 'name ASC');
      _contractors = rows.map((r) => ContractorModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[ContractorsProvider] loadContractors error: $e');
    }
  }

  Future<void> _loadPayments() async {
    try {
      final db = await DBService.instance.database;
      final rows = await db.query('contractor_payments', orderBy: 'payment_date DESC, created_at DESC');
      _payments = rows.map((r) => ContractorPaymentModel.fromMap(r)).toList();
    } catch (_) {}
  }

  void setPeriod(PeriodFilterType period, {DateTime? start, DateTime? end}) {
    _selectedPeriod = period;
    _customStartDate = start;
    _customEndDate = end;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setSelectedContractor(String? contractorId) {
    _selectedContractorId = contractorId;
    notifyListeners();
  }

  // Filtered Payments based on Period, Search & Selected Contractor
  List<ContractorPaymentModel> get filteredPayments {
    final range = DateHelper.getDateRangeForPeriod(
      _selectedPeriod,
      customStart: _customStartDate,
      customEnd: _customEndDate,
    );

    return _payments.where((p) {
      if (!range.contains(p.paymentDate)) return false;

      if (_selectedContractorId != null && _selectedContractorId!.isNotEmpty && p.contractorId != _selectedContractorId) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final contractor = _contractors.firstWhere((c) => c.id == p.contractorId, orElse: () => ContractorModel(name: '', serviceType: ''));
        final matchContractor = contractor.name.toLowerCase().contains(query);
        final matchService = contractor.serviceType.toLowerCase().contains(query);
        final matchDesc = p.description.toLowerCase().contains(query);
        final matchOrder = (p.relatedOrder ?? '').toLowerCase().contains(query);

        if (!matchContractor && !matchService && !matchDesc && !matchOrder) return false;
      }

      return true;
    }).toList();
  }

  double get filteredPaymentsTotalAmount {
    return filteredPayments.fold(0.0, (sum, p) => sum + p.amount);
  }

  int get filteredPaymentsCount => filteredPayments.length;

  // Add new Contractor / Service Provider
  Future<void> addContractor({
    required String name,
    required String serviceType,
    String? phone,
    String? notes,
  }) async {
    final contractor = ContractorModel(
      name: name.trim(),
      serviceType: serviceType.trim(),
      phone: phone?.trim(),
      notes: notes?.trim(),
    );

    final db = await DBService.instance.database;
    await db.insert('contractors', contractor.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    await SyncService.instance.queueOperation(
      tableName: 'contractors',
      operation: 'insert',
      recordId: contractor.id,
      payload: contractor.toMap(),
    );

    await _loadContractors();
    notifyListeners();
  }

  Future<void> updateContractor(ContractorModel updatedContractor) async {
    final db = await DBService.instance.database;
    final map = updatedContractor.toMap();
    await db.update('contractors', map, where: 'id = ?', whereArgs: [updatedContractor.id]);

    await SyncService.instance.queueOperation(
      tableName: 'contractors',
      operation: 'update',
      recordId: updatedContractor.id,
      payload: map,
    );

    await _loadContractors();
    notifyListeners();
  }

  Future<void> deleteContractor(String contractorId) async {
    final db = await DBService.instance.database;
    final payments = _payments.where((p) => p.contractorId == contractorId).toList();
    for (var p in payments) {
      if (p.linkedExpenseId != null) {
        await db.delete('purchases', where: 'id = ?', whereArgs: [p.linkedExpenseId]);
        await SyncService.instance.queueOperation(
          tableName: 'purchases',
          operation: 'delete',
          recordId: p.linkedExpenseId!,
          payload: {'id': p.linkedExpenseId},
        );
      }
    }
    await db.delete('contractor_payments', where: 'contractor_id = ?', whereArgs: [contractorId]);
    await db.delete('contractors', where: 'id = ?', whereArgs: [contractorId]);

    await SyncService.instance.queueOperation(
      tableName: 'contractors',
      operation: 'delete',
      recordId: contractorId,
      payload: {'id': contractorId},
    );

    await _loadContractors();
    await _loadPayments();
    notifyListeners();
  }

  Future<void> deletePayment(String paymentId) async {
    final db = await DBService.instance.database;
    final payment = _payments.firstWhere((p) => p.id == paymentId);
    if (payment.linkedExpenseId != null) {
      await db.delete('purchases', where: 'id = ?', whereArgs: [payment.linkedExpenseId]);
      await SyncService.instance.queueOperation(
        tableName: 'purchases',
        operation: 'delete',
        recordId: payment.linkedExpenseId!,
        payload: {'id': payment.linkedExpenseId},
      );
    }
    await db.delete('contractor_payments', where: 'id = ?', whereArgs: [paymentId]);
    await SyncService.instance.queueOperation(
      tableName: 'contractor_payments',
      operation: 'delete',
      recordId: paymentId,
      payload: {'id': paymentId},
    );

    await _loadPayments();
    notifyListeners();
  }

  // Record Payment to Contractor with AUTOMATIC ACCOUNTING INTEGRATION
  Future<void> recordPayment({
    required String contractorId,
    required String description,
    required double amount,
    required DateTime paymentDate,
    String? relatedOrder,
    String? notes,
    required String createdBy,
  }) async {
    final contractor = _contractors.firstWhere((c) => c.id == contractorId);
    final db = await DBService.instance.database;

    // 1. Create linked expense in Accounts (purchases table)
    final linkedExpenseId = const Uuid().v4();
    final expense = PurchaseModel(
      id: linkedExpenseId,
      itemName: 'حساب ورشة / اشتراك: ${contractor.name} (${contractor.serviceType})',
      category: 'ورش واشتراكات خارجية',
      totalAmount: amount,
      transactionDate: paymentDate,
      notes: 'تفاصيل الدفعة: $description. ${relatedOrder != null ? 'أوردر: $relatedOrder. ' : ''}${notes ?? ''}',
      sourceType: 'contractor_payment',
      sourceId: contractorId,
      createdBy: createdBy,
    );

    await db.insert('purchases', expense.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await SyncService.instance.queueOperation(
      tableName: 'purchases',
      operation: 'insert',
      recordId: expense.id,
      payload: expense.toMap(),
    );

    // 2. Create Contractor Payment record
    final payment = ContractorPaymentModel(
      contractorId: contractorId,
      description: description.trim(),
      amount: amount,
      paymentDate: paymentDate,
      relatedOrder: relatedOrder?.trim(),
      notes: notes?.trim(),
      linkedExpenseId: linkedExpenseId,
      createdBy: createdBy,
    );

    await db.insert('contractor_payments', payment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await SyncService.instance.queueOperation(
      tableName: 'contractor_payments',
      operation: 'insert',
      recordId: payment.id,
      payload: payment.toMap(),
    );

    await _loadPayments();
    notifyListeners();
  }

  double getTotalPaidToContractor(String contractorId, {PeriodFilterType? period}) {
    final range = DateHelper.getDateRangeForPeriod(period ?? _selectedPeriod);
    return _payments
        .where((p) => p.contractorId == contractorId && range.contains(p.paymentDate))
        .fold(0.0, (s, p) => s + p.amount);
  }
}
