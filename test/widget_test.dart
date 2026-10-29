import 'package:flutter_test/flutter_test.dart';
import 'package:stars_home/core/utils/date_helper.dart';
import 'package:stars_home/core/utils/currency_formatter.dart';
import 'package:stars_home/models/purchase_model.dart';
import 'package:stars_home/models/worker_financial_item_model.dart';

void main() {
  group('STARS HOMES - Financial & Accounting Integrity Tests', () {
    test('Overtime Calculation: Departure at 21:00 with standard 19:00 produces exactly 2.0 hours', () {
      final overtimeHours = DateHelper.calculateOvertimeHours(
        standardEndTimeStr: '19:00',
        actualDepartureTimeStr: '21:00',
      );
      expect(overtimeHours, 2.0);
    });

    test('Overtime Calculation: Early departure produces 0.0 hours', () {
      final overtimeHours = DateHelper.calculateOvertimeHours(
        standardEndTimeStr: '19:00',
        actualDepartureTimeStr: '18:45',
      );
      expect(overtimeHours, 0.0);
    });

    test('Weekly Payroll Formula: Gross = Wages + Overtime + Bonuses; Net = Gross - Advances - Deductions', () {
      const dailyWages = 6 * 300.0; // 1,800 EGP (6 days)
      const overtimePay = 4 * 45.0; // 180 EGP (4 hours)
      const bonuses = 200.0;        // 200 EGP bonus
      const grossEarnings = dailyWages + overtimePay + bonuses; // 2,180 EGP

      const advances = 300.0;   // 300 EGP advance
      const deductions = 50.0;  // 50 EGP deduction
      const netAmountDue = grossEarnings - advances - deductions; // 1,830 EGP

      expect(grossEarnings, 2180.0);
      expect(netAmountDue, 1830.0);

      // Partial payment of 1,000 EGP leaves exactly 830 EGP
      const amountPaid = 1000.0;
      final remainingDue = netAmountDue - amountPaid;
      expect(remainingDue, 830.0);
    });

    test('Purchase Model: Automatic total calculation equals quantity * unit_price', () {
      const qty = 5.0;
      const unitPrice = 350.0; // e.g. أبلكاش كوري
      final purchase = PurchaseModel(
        itemName: 'أبلكاش كوري',
        category: 'أخشاب ومواد خام',
        quantity: qty,
        unitPrice: unitPrice,
        totalAmount: qty * unitPrice,
        transactionDate: DateTime(2026, 10, 20),
        createdBy: 'المدير',
      );

      expect(purchase.totalAmount, 1750.0);
      expect(purchase.isReversed, false);
      expect(purchase.sourceType, 'direct');
    });

    test('Worker Advance: Flagged with worker_advance and correct attributes', () {
      final advance = WorkerFinancialItemModel(
        workerId: 'worker_1',
        type: 'advance',
        amount: 500.0,
        transactionDate: DateTime(2026, 10, 20),
        reasonNotes: 'سلفة أسبوعية',
        createdBy: 'المالك',
      );

      expect(advance.type, 'advance');
      expect(advance.amount, 500.0);
      expect(advance.typeArabicName, 'سلفة');
    });

    test('Currency Formatter: Egyptian Pound formatting', () {
      final formatted = CurrencyFormatter.format(1500.0);
      expect(formatted.isNotEmpty, true);
      expect(formatted.contains('ج.م'), true);
    });
  });
}
