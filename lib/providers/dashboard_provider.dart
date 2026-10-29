import 'package:flutter/material.dart';
import '../core/utils/date_helper.dart';
import 'accounts_provider.dart';
import 'workers_provider.dart';
import 'contractors_provider.dart';

class DashboardProvider with ChangeNotifier {
  PeriodFilterType _selectedPeriod = PeriodFilterType.currentMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  PeriodFilterType get selectedPeriod => _selectedPeriod;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;

  void setPeriod(PeriodFilterType period, {DateTime? start, DateTime? end}) {
    _selectedPeriod = period;
    _customStartDate = start;
    _customEndDate = end;
    notifyListeners();
  }

  // 1. Total Income
  double calculateTotalIncome(AccountsProvider accounts) {
    final range = DateHelper.getDateRangeForPeriod(_selectedPeriod, customStart: _customStartDate, customEnd: _customEndDate);
    return accounts.incomes
        .where((inc) => !inc.isReversed && range.contains(inc.transactionDate))
        .fold(0.0, (s, inc) => s + inc.amount);
  }

  // 2. Total Actual Expenses (Cash Outflows without double counting)
  double calculateTotalExpenses(AccountsProvider accounts) {
    final range = DateHelper.getDateRangeForPeriod(_selectedPeriod, customStart: _customStartDate, customEnd: _customEndDate);
    return accounts.purchases
        .where((p) => !p.isReversed && range.contains(p.transactionDate))
        .fold(0.0, (s, p) => s + p.totalAmount);
  }

  // 3. Worker Accounts Summary
  Map<String, double> calculateWorkerSummary(WorkersProvider workers) {
    return workers.getWorkersAggregatedFinancials();
  }

  // 4. Net Cash Flow = Actual Inflows - Actual Outflows
  double calculateNetCashFlow(AccountsProvider accounts) {
    final income = calculateTotalIncome(accounts);
    final expenses = calculateTotalExpenses(accounts);
    return income - expenses;
  }

  // 5. Category Breakdown for Expenses Chart
  Map<String, double> getCategoryBreakdown(AccountsProvider accounts) {
    final range = DateHelper.getDateRangeForPeriod(_selectedPeriod, customStart: _customStartDate, customEnd: _customEndDate);
    final filtered = accounts.purchases.where((p) => !p.isReversed && range.contains(p.transactionDate));

    Map<String, double> map = {};
    for (var p in filtered) {
      map[p.category] = (map[p.category] ?? 0.0) + p.totalAmount;
    }
    return map;
  }

  // 6. Contractor Payments Breakdown for Chart
  Map<String, double> getContractorBreakdown(ContractorsProvider contractors) {
    final range = DateHelper.getDateRangeForPeriod(_selectedPeriod, customStart: _customStartDate, customEnd: _customEndDate);
    final filtered = contractors.payments.where((p) => range.contains(p.paymentDate));

    Map<String, double> map = {};
    for (var p in filtered) {
      final cont = contractors.contractors.firstWhere((c) => c.id == p.contractorId, orElse: () => contractors.contractors.first);
      map[cont.name] = (map[cont.name] ?? 0.0) + p.amount;
    }
    return map;
  }
}
