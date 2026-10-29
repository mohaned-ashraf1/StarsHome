import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/services/db_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/date_helper.dart';
import '../models/purchase_model.dart';
import '../models/income_model.dart';
import '../models/debt_advance_model.dart';
import '../models/debt_advance_payment_model.dart';

class AccountsProvider with ChangeNotifier {
  List<PurchaseModel> _purchases = [];
  List<IncomeModel> _incomes = [];
  List<DebtAdvanceModel> _debtsAdvances = [];
  Map<String, List<DebtAdvancePaymentModel>> _debtPayments = {};
  List<String> _categories = [];
  List<Map<String, dynamic>> _itemSuggestions = [];

  // ── True financial totals — computed directly from DB via SQL SUM ──
  // These are NEVER derived from the in-memory paginated list.
  // They are the authoritative totals for dashboard and reports.
  double _dbTotalPurchasesAllTime = 0.0;
  double _dbTotalIncomesAllTime = 0.0;
  double _dbTotalDebtOutstanding = 0.0;
  double _dbTotalAdvanceOutstanding = 0.0;

  PeriodFilterType _selectedPeriod = PeriodFilterType.currentMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'الكل';
  String _debtTypeFilter = 'all'; // 'all', 'advance', 'debt_receivable', 'debt_payable'
  String _debtStatusFilter = 'all'; // 'all', 'active', 'settled'
  bool _isLoading = false;
  String? _lastError;

  List<PurchaseModel> get purchases => _purchases;
  List<IncomeModel> get incomes => _incomes;
  List<DebtAdvanceModel> get debtsAdvances => _debtsAdvances;
  Map<String, List<DebtAdvancePaymentModel>> get debtPayments => _debtPayments;
  List<String> get categories => _categories;
  List<Map<String, dynamic>> get itemSuggestions => _itemSuggestions;
  PeriodFilterType get selectedPeriod => _selectedPeriod;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;
  String get searchQuery => _searchQuery;
  String get selectedCategoryFilter => _selectedCategoryFilter;
  String get debtTypeFilter => _debtTypeFilter;
  String get debtStatusFilter => _debtStatusFilter;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  // ── DB-accurate totals (not affected by pagination) ──
  double get dbTotalPurchasesAllTime => _dbTotalPurchasesAllTime;
  double get dbTotalIncomesAllTime => _dbTotalIncomesAllTime;
  double get dbTotalDebtOutstanding => _dbTotalDebtOutstanding;
  double get dbTotalAdvanceOutstanding => _dbTotalAdvanceOutstanding;

  AccountsProvider() {
    loadAll();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    await Future.wait([
      _loadCategories(),
      _loadItemSuggestions(),
      _loadPurchases(),
      _loadIncomes(),
      _loadDebtsAdvances(),
      _refreshDbTotals(), // Always compute accurate totals from DB
    ]);

    _isLoading = false;
    notifyListeners();
  }

  /// Computes authoritative financial totals directly from SQLite via SQL SUM.
  /// This must always query the FULL table — no pagination, no in-memory filter.
  /// Called after every mutation and on full loadAll().
  Future<void> _refreshDbTotals() async {
    try {
      final db = await DBService.instance.database;

      final purchaseResult = await db.rawQuery(
        "SELECT COALESCE(SUM(total_amount), 0.0) AS total FROM purchases WHERE is_reversed = 0",
      );
      _dbTotalPurchasesAllTime =
          (purchaseResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final incomeResult = await db.rawQuery(
        "SELECT COALESCE(SUM(amount), 0.0) AS total FROM incomes WHERE is_reversed = 0",
      );
      _dbTotalIncomesAllTime =
          (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final debtResult = await db.rawQuery(
        "SELECT COALESCE(SUM(amount - paid_amount), 0.0) AS total "
        "FROM debts_advances WHERE status = 'active' AND type = 'debt_payable'",
      );
      _dbTotalDebtOutstanding =
          (debtResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final advanceResult = await db.rawQuery(
        "SELECT COALESCE(SUM(amount - paid_amount), 0.0) AS total "
        "FROM debts_advances WHERE status = 'active' AND type = 'advance'",
      );
      _dbTotalAdvanceOutstanding =
          (advanceResult.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('[AccountsProvider] _refreshDbTotals error: $e');
    }
  }

  /// Returns the accurate total purchases for a given date range — queries DB directly.
  /// Use this for reports and dashboard, NOT filteredPurchasesTotalAmount.
  Future<double> getTotalPurchasesForRange(DateTime start, DateTime end) async {
    try {
      final db = await DBService.instance.database;
      final result = await db.rawQuery(
        "SELECT COALESCE(SUM(total_amount), 0.0) AS total FROM purchases "
        "WHERE is_reversed = 0 AND transaction_date >= ? AND transaction_date <= ?",
        [DateHelper.formatYMD(start), DateHelper.formatYMD(end)],
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('[AccountsProvider] getTotalPurchasesForRange error: $e');
      return 0.0;
    }
  }

  /// Returns the accurate total incomes for a given date range — queries DB directly.
  Future<double> getTotalIncomesForRange(DateTime start, DateTime end) async {
    try {
      final db = await DBService.instance.database;
      final result = await db.rawQuery(
        "SELECT COALESCE(SUM(amount), 0.0) AS total FROM incomes "
        "WHERE is_reversed = 0 AND transaction_date >= ? AND transaction_date <= ?",
        [DateHelper.formatYMD(start), DateHelper.formatYMD(end)],
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('[AccountsProvider] getTotalIncomesForRange error: $e');
      return 0.0;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final db = await DBService.instance.database;
      final rows = await db.query('categories', orderBy: 'name ASC');
      _categories = rows.map((r) => r['name'].toString()).toList();
      if (!_categories.contains('مصروفات عامة')) {
        _categories.add('مصروفات عامة');
      }
    } catch (e) {
      debugPrint('[AccountsProvider] loadCategories error: $e');
    }
  }

  Future<void> _loadItemSuggestions() async {
    try {
      final db = await DBService.instance.database;
      _itemSuggestions = await db.query(
        'item_suggestions',
        orderBy: 'times_used DESC, last_used_at DESC',
        limit: 50,
      );
    } catch (e) {
      debugPrint('[AccountsProvider] loadItemSuggestions error: $e');
    }
  }

  // Loads ALL purchases into memory (no limit).
  // SQLite is a local on-device DB — full load is appropriate for ≤50k rows.
  // Financial totals are separately computed via SQL SUM in _refreshDbTotals().
  Future<void> _loadPurchases() async {
    try {
      final db = await DBService.instance.database;
      final rows = await db.query(
        'purchases',
        where: 'is_reversed = 0',
        orderBy: 'transaction_date DESC, created_at DESC',
      );
      _purchases = rows.map((r) => PurchaseModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[AccountsProvider] loadPurchases error: $e');
      _lastError = 'فشل تحميل المشتريات';
    }
  }

  Future<void> _loadIncomes() async {
    try {
      final db = await DBService.instance.database;
      final rows = await db.query(
        'incomes',
        where: 'is_reversed = 0',
        orderBy: 'transaction_date DESC, created_at DESC',
      );
      _incomes = rows.map((r) => IncomeModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[AccountsProvider] loadIncomes error: $e');
      _lastError = 'فشل تحميل الإيرادات';
    }
  }

  Future<void> _loadDebtsAdvances() async {
    try {
      final db = await DBService.instance.database;
      final rows = await db.query(
        'debts_advances',
        orderBy: 'transaction_date DESC, created_at DESC',
      );
      _debtsAdvances = rows.map((r) => DebtAdvanceModel.fromMap(r)).toList();

      final paymentRows = await db.query(
        'debt_advance_payments',
        orderBy: 'payment_date ASC, created_at ASC',
      );
      final payments = paymentRows
          .map((r) => DebtAdvancePaymentModel.fromMap(r))
          .toList();
      _debtPayments = {};
      for (final p in payments) {
        _debtPayments.putIfAbsent(p.debtAdvanceId, () => []).add(p);
      }
    } catch (e) {
      debugPrint('[AccountsProvider] loadDebtsAdvances error: $e');
      _lastError = 'فشل تحميل السلف والديون';
    }
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

  void setCategoryFilter(String category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  // Filtered Purchases based on Period, Search & Category
  List<PurchaseModel> get filteredPurchases {
    final range = DateHelper.getDateRangeForPeriod(
      _selectedPeriod,
      customStart: _customStartDate,
      customEnd: _customEndDate,
    );

    return _purchases.where((p) {
      if (!range.contains(p.transactionDate)) return false;

      if (_selectedCategoryFilter != 'الكل' && p.category != _selectedCategoryFilter) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchItem = p.itemName.toLowerCase().contains(query);
        final matchCategory = p.category.toLowerCase().contains(query);
        final matchNotes = (p.notes ?? '').toLowerCase().contains(query);
        if (!matchItem && !matchCategory && !matchNotes) return false;
      }

      return true;
    }).toList();
  }

  // Filtered Incomes
  List<IncomeModel> get filteredIncomes {
    final range = DateHelper.getDateRangeForPeriod(
      _selectedPeriod,
      customStart: _customStartDate,
      customEnd: _customEndDate,
    );

    return _incomes.where((inc) {
      if (!range.contains(inc.transactionDate)) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchSource = inc.sourceName.toLowerCase().contains(query);
        final matchNotes = (inc.notes ?? '').toLowerCase().contains(query);
        if (!matchSource && !matchNotes) return false;
      }

      return true;
    }).toList();
  }

  // Reporting Totals for filtered purchases
  double get filteredPurchasesTotalAmount {
    return filteredPurchases.fold(0.0, (sum, p) => sum + p.totalAmount);
  }

  double get filteredPurchasesTotalQuantity {
    return filteredPurchases.fold(0.0, (sum, p) => sum + (p.quantity ?? 0.0));
  }

  int get filteredPurchasesTransactionCount => filteredPurchases.length;

  // Reporting Totals for filtered incomes
  double get filteredIncomesTotalAmount {
    return filteredIncomes.fold(0.0, (sum, inc) => sum + inc.amount);
  }

  int get filteredIncomesTransactionCount => filteredIncomes.length;

  // Add Purchase / Expense
  Future<void> addPurchase({
    required String itemName,
    required String category,
    double? quantity,
    double? unitPrice,
    required double totalAmount,
    required DateTime transactionDate,
    String? notes,
    String sourceType = 'direct',
    String? sourceId,
    required String createdBy,
  }) async {
    final purchase = PurchaseModel(
      itemName: itemName.trim(),
      category: category.trim(),
      quantity: quantity,
      unitPrice: unitPrice,
      totalAmount: totalAmount,
      transactionDate: transactionDate,
      notes: notes?.trim(),
      sourceType: sourceType,
      sourceId: sourceId,
      createdBy: createdBy,
    );

    final db = await DBService.instance.database;

    // 1. Insert Purchase
    await db.insert('purchases', purchase.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    // 2. Add or update category if new
    if (!_categories.contains(category.trim())) {
      _categories.add(category.trim());
      await db.insert(
        'categories',
        {
          'id': const Uuid().v4(),
          'name': category.trim(),
          'type': 'expense',
          'is_reusable': 1,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // 3. Save or update Item Suggestion for Autocomplete
    await db.rawInsert('''
      INSERT INTO item_suggestions (id, item_name, default_category, last_unit_price, times_used, last_used_at)
      VALUES (?, ?, ?, ?, 1, ?)
      ON CONFLICT(item_name) DO UPDATE SET
        default_category = excluded.default_category,
        last_unit_price = excluded.last_unit_price,
        times_used = times_used + 1,
        last_used_at = excluded.last_used_at
    ''', [
      const Uuid().v4(),
      itemName.trim(),
      category.trim(),
      unitPrice ?? 0.0,
      DateTime.now().toIso8601String(),
    ]);

    // 4. Queue for Sync
    await SyncService.instance.queueOperation(
      tableName: 'purchases',
      operation: 'insert',
      recordId: purchase.id,
      payload: purchase.toMap(),
    );

    await _loadPurchases();
    await _loadItemSuggestions();
    await _refreshDbTotals();
    notifyListeners();
  }

  // Update Purchase
  Future<void> updatePurchase(PurchaseModel purchase) async {
    final db = await DBService.instance.database;
    final map = purchase.toMap();
    await db.update('purchases', map, where: 'id = ?', whereArgs: [purchase.id]);

    await SyncService.instance.queueOperation(
      tableName: 'purchases',
      operation: 'update',
      recordId: purchase.id,
      payload: map,
    );

    await _loadPurchases();
    await _refreshDbTotals();
    notifyListeners();
  }

  // Delete Purchase Permanently
  Future<void> deletePurchasePermanently(String id) async {
    final db = await DBService.instance.database;
    try {
      await db.delete('purchase_items', where: 'purchase_id = ?', whereArgs: [id]);
    } catch (_) {}
    await db.delete('purchases', where: 'id = ?', whereArgs: [id]);

    await SyncService.instance.queueOperation(
      tableName: 'purchases',
      operation: 'delete',
      recordId: id,
      payload: {'id': id},
    );

    await _loadPurchases();
    await _refreshDbTotals();
    notifyListeners();
  }

  // Add Income
  Future<String> addIncome({
    required String sourceName,
    required double amount,
    required DateTime transactionDate,
    String? notes,
    required String createdBy,
    String? id,
  }) async {
    final income = IncomeModel(
      id: id,
      sourceName: sourceName.trim(),
      amount: amount,
      transactionDate: transactionDate,
      notes: notes?.trim(),
      createdBy: createdBy,
    );

    final db = await DBService.instance.database;
    await db.insert('incomes', income.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    await SyncService.instance.queueOperation(
      tableName: 'incomes',
      operation: 'insert',
      recordId: income.id,
      payload: income.toMap(),
    );

    await _loadIncomes();
    await _refreshDbTotals();
    notifyListeners();
    return income.id;
  }

  // Delete Income
  Future<void> deleteIncome(String id) async {
    final db = await DBService.instance.database;
    await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
    await SyncService.instance.queueOperation(
      tableName: 'incomes',
      operation: 'delete',
      recordId: id,
      payload: {'id': id},
    );
    await _loadIncomes();
    await _refreshDbTotals();
    notifyListeners();
  }

  // Update Income
  Future<void> updateIncome(IncomeModel income) async {
    final db = await DBService.instance.database;
    final map = income.toMap();
    await db.update('incomes', map, where: 'id = ?', whereArgs: [income.id]);

    await SyncService.instance.queueOperation(
      tableName: 'incomes',
      operation: 'update',
      recordId: income.id,
      payload: map,
    );

    await _loadIncomes();
    await _refreshDbTotals();
    notifyListeners();
  }

  // Soft Reverse Transaction
  Future<void> reversePurchase(String id, String reversedBy) async {
    final db = await DBService.instance.database;
    await db.update(
      'purchases',
      {
        'is_reversed': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await SyncService.instance.queueOperation(
      tableName: 'purchases',
      operation: 'update',
      recordId: id,
      payload: {'is_reversed': 1, 'updated_at': DateTime.now().toIso8601String()},
    );

    await _loadPurchases();
    await _refreshDbTotals();
    notifyListeners();
  }

  Future<void> reverseIncome(String id, String reversedBy) async {
    final db = await DBService.instance.database;
    await db.update(
      'incomes',
      {
        'is_reversed': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await SyncService.instance.queueOperation(
      tableName: 'incomes',
      operation: 'update',
      recordId: id,
      payload: {'is_reversed': 1, 'updated_at': DateTime.now().toIso8601String()},
    );

    await _loadIncomes();
    await _refreshDbTotals();
    notifyListeners();
  }

  // ================= DEBTS & ADVANCES =================
  void setDebtTypeFilter(String filter) {
    _debtTypeFilter = filter;
    notifyListeners();
  }

  void setDebtStatusFilter(String filter) {
    _debtStatusFilter = filter;
    notifyListeners();
  }

  List<DebtAdvanceModel> get filteredDebtsAdvances {
    final range = DateHelper.getDateRangeForPeriod(
      _selectedPeriod,
      customStart: _customStartDate,
      customEnd: _customEndDate,
    );

    return _debtsAdvances.where((d) {
      // Period filter
      if (!range.contains(d.transactionDate)) return false;

      // Type filter
      if (_debtTypeFilter != 'all' && d.type != _debtTypeFilter) return false;

      // Status filter
      if (_debtStatusFilter == 'active' && d.isSettled) return false;
      if (_debtStatusFilter == 'settled' && !d.isSettled) return false;

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchPerson = d.personName.toLowerCase().contains(query);
        final matchPhone = (d.phone ?? '').contains(query);
        final matchNotes = (d.notes ?? '').toLowerCase().contains(query);
        if (!matchPerson && !matchPhone && !matchNotes) return false;
      }

      return true;
    }).toList();
  }

  double get filteredDebtsAdvancesTotalAmount =>
      filteredDebtsAdvances.fold(0.0, (sum, d) => sum + d.amount);

  double get filteredDebtsAdvancesTotalRemaining =>
      filteredDebtsAdvances.fold(0.0, (sum, d) => sum + d.remainingAmount);

  double get filteredDebtsAdvancesTotalPaid =>
      filteredDebtsAdvances.fold(0.0, (sum, d) => sum + d.paidAmount);

  int get filteredDebtsAdvancesCount => filteredDebtsAdvances.length;

  List<DebtAdvancePaymentModel> getPaymentsForDebt(String debtId) {
    return _debtPayments[debtId] ?? [];
  }

  // Add Debt / Advance
  Future<DebtAdvanceModel> addDebtAdvance({
    required String personName,
    String? phone,
    required String type,
    required double amount,
    required DateTime transactionDate,
    DateTime? dueDate,
    String? notes,
    required String createdBy,
  }) async {
    final id = const Uuid().v4();
    final model = DebtAdvanceModel(
      id: id,
      personName: personName.trim(),
      phone: phone?.trim(),
      type: type,
      amount: amount,
      paidAmount: 0.0,
      transactionDate: transactionDate,
      dueDate: dueDate,
      status: 'active',
      notes: notes?.trim(),
      createdBy: createdBy,
    );

    final db = await DBService.instance.database;
    await db.insert('debts_advances', model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    await SyncService.instance.queueOperation(
      tableName: 'debts_advances',
      operation: 'insert',
      recordId: model.id,
      payload: model.toMap(),
    );

    await _loadDebtsAdvances();
    notifyListeners();
    return model;
  }

  // Record a payment / repayment on an advance or debt
  Future<void> recordDebtRepayment({
    required String debtAdvanceId,
    required double amount,
    required DateTime paymentDate,
    String? notes,
    required String createdBy,
  }) async {
    final db = await DBService.instance.database;
    final paymentId = const Uuid().v4();

    final payment = DebtAdvancePaymentModel(
      id: paymentId,
      debtAdvanceId: debtAdvanceId,
      amount: amount,
      paymentDate: paymentDate,
      notes: notes?.trim(),
      createdBy: createdBy,
    );

    await db.insert('debt_advance_payments', payment.toMap());

    // Update parent debt_advance record
    final debt = _debtsAdvances.firstWhere((d) => d.id == debtAdvanceId);
    final newPaid = debt.paidAmount + amount;
    final newStatus = (debt.amount - newPaid) <= 0.001 ? 'settled' : 'active';

    await db.update(
      'debts_advances',
      {
        'paid_amount': newPaid,
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [debtAdvanceId],
    );

    await SyncService.instance.queueOperation(
      tableName: 'debt_advance_payments',
      operation: 'insert',
      recordId: payment.id,
      payload: payment.toMap(),
    );

    await SyncService.instance.queueOperation(
      tableName: 'debts_advances',
      operation: 'update',
      recordId: debtAdvanceId,
      payload: {
        'paid_amount': newPaid,
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );

    await _loadDebtsAdvances();
    notifyListeners();
  }

  // Delete Debt / Advance
  Future<void> deleteDebtAdvance(String id) async {
    final db = await DBService.instance.database;
    await db.delete('debt_advance_payments', where: 'debt_advance_id = ?', whereArgs: [id]);
    await db.delete('debts_advances', where: 'id = ?', whereArgs: [id]);

    await SyncService.instance.queueOperation(
      tableName: 'debts_advances',
      operation: 'delete',
      recordId: id,
      payload: {'id': id},
    );

    await _loadDebtsAdvances();
    notifyListeners();
  }
}
