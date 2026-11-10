import 'package:flutter_test/flutter_test.dart';
import 'package:stars_home/backend/constants/database_dictionary.dart';

void main() {
  group('STARS HOMES ERP — Arabic Database Dictionary Tests', () {
    test('Scenario 1: All 24 live public tables are registered in DatabaseDictionary', () {
      final requiredPublicTables = [
        'profiles',
        'categories',
        'item_suggestions',
        'purchases',
        'incomes',
        'workers',
        'worker_attendance',
        'worker_financial_items',
        'worker_payroll_settlements',
        'contractors',
        'contractor_payments',
        'customer_orders',
        'order_payments',
        'debts_advances',
        'debt_advance_payments',
        'inventory_items',
        'inventory_movements',
        'inventory_reservations',
        'material_shortages',
        'manufacturing_orders',
        'manufacturing_order_dimensions',
        'manufacturing_order_materials',
        'manufacturing_checklist',
        'audit_logs',
      ];

      for (final table in requiredPublicTables) {
        final meta = DatabaseDictionary.getTable(table);
        expect(meta, isNotNull, reason: 'Table $table should be registered');
        expect(meta!.name, equals(table));
        expect(meta.arabicName.isNotEmpty, isTrue);
        expect(meta.columns.isNotEmpty, isTrue);
      }
    });

    test('Scenario 2: Every registered table has valid Arabic metadata and module', () {
      final allTables = DatabaseDictionary.getAllTables();
      expect(allTables.length, greaterThanOrEqualTo(24));

      for (final table in allTables) {
        expect(table.name.trim().isNotEmpty, isTrue);
        expect(table.arabicName.trim().isNotEmpty, isTrue);
        expect(table.description.trim().isNotEmpty, isTrue);
        expect(table.module.trim().isNotEmpty, isTrue);
      }
    });

    test('Scenario 3: Every column has valid Arabic name, data type, and description', () {
      final allTables = DatabaseDictionary.getAllTables();

      for (final table in allTables) {
        for (final col in table.columns) {
          expect(col.name.trim().isNotEmpty, isTrue);
          expect(col.arabicName.trim().isNotEmpty, isTrue);
          expect(col.type.trim().isNotEmpty, isTrue);
          expect(col.description.trim().isNotEmpty, isTrue);
        }
      }
    });

    test('Scenario 4: DatabaseDictionary.getTableLabel returns Arabic and falls back', () {
      expect(DatabaseDictionary.getTableLabel('customer_orders'), equals('طلبيات وعقود العملاء'));
      expect(DatabaseDictionary.getTableLabel('purchases'), equals('المشتريات ومصروفات المصنع'));
      expect(DatabaseDictionary.getTableLabel('workers'), equals('ملفات عمال وفنيي المصنع'));
      expect(DatabaseDictionary.getTableLabel('inventory_items'), equals('أصناف وخامات المخزون'));
      expect(DatabaseDictionary.getTableLabel('non_existent_table'), equals('non_existent_table'));
    });

    test('Scenario 5: DatabaseDictionary.getColumnLabel returns Arabic and falls back', () {
      expect(DatabaseDictionary.getColumnLabel('customer_orders', 'customer_name'), equals('اسم العميل بالكامل'));
      expect(DatabaseDictionary.getColumnLabel('purchases', 'total_amount'), equals('إجمالي المبلغ'));
      expect(DatabaseDictionary.getColumnLabel('workers', 'daily_wage'), equals('قيمة اليومية الأساسية'));
      expect(DatabaseDictionary.getColumnLabel('purchases', 'non_existent_col'), equals('non_existent_col'));
    });

    test('Scenario 6: DatabaseDictionary.search matches by Arabic, English, or column name', () {
      final searchByArabic = DatabaseDictionary.search('عملاء');
      expect(searchByArabic.any((t) => t.name == 'customer_orders'), isTrue);

      final searchByEnglish = DatabaseDictionary.search('inventory');
      expect(searchByEnglish.any((t) => t.name.startsWith('inventory')), isTrue);

      final searchByColumn = DatabaseDictionary.search('daily_wage');
      expect(searchByColumn.any((t) => t.name == 'workers'), isTrue);
    });

    test('Scenario 7: Schema filtering isolates public vs auth vs storage vs realtime', () {
      final publicTables = DatabaseDictionary.getAllTables(schema: 'public');
      final authTables = DatabaseDictionary.getAllTables(schema: 'auth');
      final storageTables = DatabaseDictionary.getAllTables(schema: 'storage');
      final realtimeTables = DatabaseDictionary.getAllTables(schema: 'realtime');

      expect(publicTables.length, greaterThanOrEqualTo(24));
      expect(publicTables.every((t) => t.schema == 'public'), isTrue);

      expect(authTables.isNotEmpty, isTrue);
      expect(authTables.every((t) => t.schema == 'auth'), isTrue);

      expect(storageTables.isNotEmpty, isTrue);
      expect(storageTables.every((t) => t.schema == 'storage'), isTrue);

      expect(realtimeTables.isNotEmpty, isTrue);
      expect(realtimeTables.every((t) => t.schema == 'realtime'), isTrue);
    });
  });
}
