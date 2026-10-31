import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/services/db_service.dart';
import '../core/services/sync_service.dart';
import '../models/customer_order_model.dart';
import '../models/order_payment_model.dart';
import '../models/income_model.dart';
import 'accounts_provider.dart';

class CustomersProvider with ChangeNotifier {
  List<CustomerOrderModel> _orders = [];
  List<OrderPaymentModel> _payments = [];

  String _searchQuery = '';
  String _statusFilter = 'الكل';
  bool _isLoading = false;

  List<CustomerOrderModel> get orders => _orders;
  List<OrderPaymentModel> get payments => _payments;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  bool get isLoading => _isLoading;

  CustomersProvider() {
    loadAll();
  }

  Future<void> loadAll({AccountsProvider? accountsProvider}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DBService.instance.database;

      final orderRows = await db.query(
        'customer_orders',
        orderBy: 'created_at DESC',
      );
      _orders = orderRows.map((r) => CustomerOrderModel.fromMap(r)).toList();

      final paymentRows = await db.query(
        'order_payments',
        orderBy: 'payment_date DESC, created_at DESC',
      );
      _payments = paymentRows.map((r) => OrderPaymentModel.fromMap(r)).toList();

      // Ensure every payment has a linked income record in 'incomes'
      bool needsReload = false;
      for (var p in _payments) {
        if (p.linkedIncomeId == null || p.linkedIncomeId!.isEmpty) {
          final matching = _orders.where((o) => o.id == p.orderId).toList();
          final custName = matching.isNotEmpty ? matching.first.customerName : 'عميل';
          final orderDesc = matching.isNotEmpty ? matching.first.orderDescription : 'طلب';

          final newIncomeId = await _createIncomeEntry(
            db: db,
            customerName: custName,
            orderId: p.orderId,
            orderDescription: orderDesc,
            amount: p.amount,
            paymentDate: p.paymentDate,
            paymentMethod: p.paymentMethod,
            notes: p.notes,
            createdBy: p.createdBy,
            accountsProvider: accountsProvider,
          );

          await db.update(
            'order_payments',
            {'linked_income_id': newIncomeId},
            where: 'id = ?',
            whereArgs: [p.id],
          );
          needsReload = true;
        }
      }

      if (needsReload) {
        final reloaded = await db.query(
          'order_payments',
          orderBy: 'payment_date DESC, created_at DESC',
        );
        _payments = reloaded.map((r) => OrderPaymentModel.fromMap(r)).toList();
      }
    } catch (e) {
      debugPrint('Error loading customer orders: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Orders that have delivery date within 7 days from today (or overdue) and not yet delivered/cancelled
  List<CustomerOrderModel> get ordersDueSoon {
    return _orders.where((o) => o.isDueWithinOneWeek || o.isOverdue).toList();
  }

  List<CustomerOrderModel> get filteredOrders {
    return _orders.where((order) {
      // Status filter
      if (_statusFilter != 'الكل') {
        if (_statusFilter == 'due_soon') {
          if (!order.isDueWithinOneWeek && !order.isOverdue) return false;
        } else if (order.status != _statusFilter) {
          return false;
        }
      }

      // Search filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchName = order.customerName.toLowerCase().contains(q);
        final matchPhone = (order.phone ?? '').toLowerCase().contains(q);
        final matchDesc = order.orderDescription.toLowerCase().contains(q);
        if (!matchName && !matchPhone && !matchDesc) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<OrderPaymentModel> getPaymentsForOrder(String orderId) {
    return _payments.where((p) => p.orderId == orderId).toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  double getTotalPaidForOrder(String orderId) {
    return _payments
        .where((p) => p.orderId == orderId)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double getRemainingForOrder(CustomerOrderModel order) {
    final paid = getTotalPaidForOrder(order.id);
    final remaining = order.totalAmount - paid;
    return remaining < 0 ? 0.0 : remaining;
  }

  // Dashboard & Metrics
  double get totalOrdersValue =>
      _orders.fold(0.0, (sum, o) => sum + o.totalAmount);

  double get totalCollected =>
      _payments.fold(0.0, (sum, p) => sum + p.amount);

  double get totalRemainingBalance {
    double total = 0.0;
    for (var order in _orders) {
      if (order.status != 'cancelled') {
        total += getRemainingForOrder(order);
      }
    }
    return total;
  }

  int get activeOrdersCount =>
      _orders.where((o) => o.status == 'in_progress').length;

  int get readyOrdersCount =>
      _orders.where((o) => o.status == 'ready').length;

  int get deliveredOrdersCount =>
      _orders.where((o) => o.status == 'delivered').length;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  // Helper to record income directly into database and trigger AccountsProvider reload
  Future<String> _createIncomeEntry({
    required Database db,
    required String customerName,
    required String orderId,
    required String orderDescription,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? notes,
    required String createdBy,
    AccountsProvider? accountsProvider,
  }) async {
    final incomeId = const Uuid().v4();
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId;

    final income = IncomeModel(
      id: incomeId,
      sourceName: 'دفعة عميل: $customerName',
      amount: amount,
      transactionDate: paymentDate,
      notes: 'طلب #$shortId ($orderDescription) - طريقة السداد: $paymentMethod${notes != null && notes.isNotEmpty ? ' - $notes' : ''}',
      createdBy: createdBy,
    );

    await db.insert(
      'incomes',
      income.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await SyncService.instance.queueOperation(
      tableName: 'incomes',
      operation: 'insert',
      recordId: income.id,
      payload: income.toMap(),
    );

    if (accountsProvider != null) {
      await accountsProvider.loadAll();
    }

    return incomeId;
  }

  // Helper to delete income entry from database
  Future<void> _deleteIncomeEntry({
    required Database db,
    required String incomeId,
    AccountsProvider? accountsProvider,
  }) async {
    await db.delete('incomes', where: 'id = ?', whereArgs: [incomeId]);

    await SyncService.instance.queueOperation(
      tableName: 'incomes',
      operation: 'delete',
      recordId: incomeId,
      payload: {'id': incomeId},
    );

    if (accountsProvider != null) {
      await accountsProvider.loadAll();
    }
  }

  // Add new order with optional initial deposit payment
  Future<bool> addOrder(
    CustomerOrderModel order, {
    double? initialPayment,
    String paymentMethod = 'نقدي',
    String? paymentNotes,
    bool recordAsIncome = true,
    AccountsProvider? accountsProvider,
  }) async {
    try {
      final db = await DBService.instance.database;

      await db.insert(
        'customer_orders',
        order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await SyncService.instance.queueOperation(
        tableName: 'customer_orders',
        operation: 'insert',
        recordId: order.id,
        payload: order.toMap(),
      );

      // Add initial payment if provided
      if (initialPayment != null && initialPayment > 0) {
        String? linkedIncomeId;

        // Record directly into factory incomes
        if (recordAsIncome) {
          linkedIncomeId = await _createIncomeEntry(
            db: db,
            customerName: order.customerName,
            orderId: order.id,
            orderDescription: order.orderDescription,
            amount: initialPayment,
            paymentDate: order.startDate,
            paymentMethod: paymentMethod,
            notes: paymentNotes ?? 'عربون / دفعة أولى',
            createdBy: order.createdBy,
            accountsProvider: accountsProvider,
          );
        }

        final payment = OrderPaymentModel(
          id: const Uuid().v4(),
          orderId: order.id,
          amount: initialPayment,
          paymentDate: order.startDate,
          paymentMethod: paymentMethod,
          notes: paymentNotes ?? 'عربون / دفعة أولى',
          linkedIncomeId: linkedIncomeId,
          createdBy: order.createdBy,
        );

        await db.insert(
          'order_payments',
          payment.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await SyncService.instance.queueOperation(
          tableName: 'order_payments',
          operation: 'insert',
          recordId: payment.id,
          payload: payment.toMap(),
        );

        _payments.insert(0, payment);
      }

      _orders.insert(0, order);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding customer order: $e');
      return false;
    }
  }

  Future<bool> updateOrder(CustomerOrderModel order) async {
    try {
      final db = await DBService.instance.database;
      final map = order.toMap();

      await db.update(
        'customer_orders',
        map,
        where: 'id = ?',
        whereArgs: [order.id],
      );

      await SyncService.instance.queueOperation(
        tableName: 'customer_orders',
        operation: 'update',
        recordId: order.id,
        payload: map,
      );

      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = order;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating customer order: $e');
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    final order = _orders.firstWhere((o) => o.id == orderId);
    final updated = order.copyWith(status: newStatus);
    return await updateOrder(updated);
  }

  Future<bool> deleteOrder(String orderId, {AccountsProvider? accountsProvider}) async {
    try {
      final db = await DBService.instance.database;

      // Delete payments and their linked incomes
      final orderPayments = getPaymentsForOrder(orderId);
      for (var p in orderPayments) {
        if (p.linkedIncomeId != null && p.linkedIncomeId!.isNotEmpty) {
          await _deleteIncomeEntry(
            db: db,
            incomeId: p.linkedIncomeId!,
            accountsProvider: accountsProvider,
          );
        }
        await db.delete('order_payments', where: 'id = ?', whereArgs: [p.id]);
        await SyncService.instance.queueOperation(
          tableName: 'order_payments',
          operation: 'delete',
          recordId: p.id,
          payload: {'id': p.id},
        );
      }

      // Delete order
      await db.delete('customer_orders', where: 'id = ?', whereArgs: [orderId]);
      await SyncService.instance.queueOperation(
        tableName: 'customer_orders',
        operation: 'delete',
        recordId: orderId,
        payload: {'id': orderId},
      );

      _payments.removeWhere((p) => p.orderId == orderId);
      _orders.removeWhere((o) => o.id == orderId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting customer order: $e');
      return false;
    }
  }

  // Add installment payment
  Future<bool> addPayment(
    OrderPaymentModel payment, {
    required CustomerOrderModel order,
    bool recordAsIncome = true,
    AccountsProvider? accountsProvider,
  }) async {
    try {
      final db = await DBService.instance.database;
      String? linkedIncomeId;

      if (recordAsIncome) {
        linkedIncomeId = await _createIncomeEntry(
          db: db,
          customerName: order.customerName,
          orderId: order.id,
          orderDescription: order.orderDescription,
          amount: payment.amount,
          paymentDate: payment.paymentDate,
          paymentMethod: payment.paymentMethod,
          notes: payment.notes,
          createdBy: payment.createdBy,
          accountsProvider: accountsProvider,
        );
      }

      final finalPayment = payment.copyWith(linkedIncomeId: linkedIncomeId);

      await db.insert(
        'order_payments',
        finalPayment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await SyncService.instance.queueOperation(
        tableName: 'order_payments',
        operation: 'insert',
        recordId: finalPayment.id,
        payload: finalPayment.toMap(),
      );

      _payments.insert(0, finalPayment);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding order payment: $e');
      return false;
    }
  }

  // Delete payment
  Future<bool> deletePayment(
    String paymentId, {
    AccountsProvider? accountsProvider,
  }) async {
    try {
      final db = await DBService.instance.database;

      final p = _payments.firstWhere((item) => item.id == paymentId);
      if (p.linkedIncomeId != null && p.linkedIncomeId!.isNotEmpty) {
        await _deleteIncomeEntry(
          db: db,
          incomeId: p.linkedIncomeId!,
          accountsProvider: accountsProvider,
        );
      }

      await db.delete('order_payments', where: 'id = ?', whereArgs: [paymentId]);

      await SyncService.instance.queueOperation(
        tableName: 'order_payments',
        operation: 'delete',
        recordId: paymentId,
        payload: {'id': paymentId},
      );

      _payments.removeWhere((item) => item.id == paymentId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting payment: $e');
      return false;
    }
  }
}
