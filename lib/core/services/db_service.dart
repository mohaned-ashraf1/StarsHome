import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// ignore: unnecessary_import
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Database version history:
///  v1 — initial schema (purchases, incomes, workers, attendance, payroll,
///         contractors, payments, sync_queue)
///  v2 — customer_orders, order_payments
///  v3 — debts_advances, debt_advance_payments
///  v4 — inventory_items, inventory_movements, manufacturing_orders,
///         manufacturing_order_dimensions, manufacturing_order_materials,
///         manufacturing_checklist, inventory_reservations, material_shortages
///  v5 — add sections_data to manufacturing_orders;
///         add thickness_grade, color_code, linked_piece to manufacturing_order_materials
///  v6 — add last_error column to sync_queue (for retry tracking)
///  v7 — add supplier_name, minimum_limit alias (min_stock_level renamed), updated_at
///         to inventory_items; category column in material_shortages
const int _kDbVersion = 7;

class DBService {
  static final DBService instance = DBService._internal();
  DBService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final bool isAndroidOrIOS = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (!isAndroidOrIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = 'stars_homes_factory.db';
    } else if (isAndroidOrIOS) {
      final dbFolder = await getDatabasesPath();
      path = p.join(dbFolder, 'stars_homes_factory.db');
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      path = p.join(docsDir.path, 'stars_homes_factory.db');
    }

    final db = await openDatabase(
      path,
      version: _kDbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );

    return db;
  }

  // ──────────────────────────────────────────────────
  // Fresh install (onCreate)
  // ──────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await _createV1Tables(db);
    await _createV2Tables(db);
    await _createV3Tables(db);
    await _createV4Tables(db);
    await _applyV5Columns(db);
    await _applyV6Columns(db);
    await _applyV7Columns(db);
    await _seedDefaults(db);
  }

  // ──────────────────────────────────────────────────
  // Upgrade path (onUpgrade) — ordered, safe migrations
  // ──────────────────────────────────────────────────

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('[DBService] Upgrading from v$oldVersion to v$newVersion');

    // Each migration is idempotent: CREATE TABLE IF NOT EXISTS / ALTER IF NOT EXISTS
    if (oldVersion < 2) await _createV2Tables(db);
    if (oldVersion < 3) await _createV3Tables(db);
    if (oldVersion < 4) await _createV4Tables(db);
    if (oldVersion < 5) await _applyV5Columns(db);
    if (oldVersion < 6) await _applyV6Columns(db);
    if (oldVersion < 7) await _applyV7Columns(db);
  }

  // ──────────────────────────────────────────────────
  // Schema versions
  // ──────────────────────────────────────────────────

  Future<void> _createV1Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL DEFAULT 'expense',
        is_reusable INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS item_suggestions (
        id TEXT PRIMARY KEY,
        item_name TEXT UNIQUE NOT NULL,
        default_category TEXT,
        last_unit_price REAL DEFAULT 0,
        times_used INTEGER DEFAULT 1,
        last_used_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        id TEXT PRIMARY KEY,
        item_name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity REAL,
        unit_price REAL,
        total_amount REAL NOT NULL,
        transaction_date TEXT NOT NULL,
        notes TEXT,
        source_type TEXT DEFAULT 'direct',
        source_id TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_reversed INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS incomes (
        id TEXT PRIMARY KEY,
        source_name TEXT NOT NULL,
        amount REAL NOT NULL,
        transaction_date TEXT NOT NULL,
        notes TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_reversed INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS workers (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        daily_wage REAL NOT NULL DEFAULT 0,
        standard_start_time TEXT NOT NULL DEFAULT '08:00',
        standard_end_time TEXT NOT NULL DEFAULT '19:00',
        overtime_hourly_rate REAL NOT NULL DEFAULT 0,
        phone TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        notes TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS worker_attendance (
        id TEXT PRIMARY KEY,
        worker_id TEXT NOT NULL,
        attendance_date TEXT NOT NULL,
        status TEXT NOT NULL,
        arrival_time TEXT,
        departure_time TEXT,
        total_duration_minutes INTEGER DEFAULT 0,
        overtime_duration_minutes INTEGER DEFAULT 0,
        overtime_pay REAL DEFAULT 0,
        daily_wage_applied REAL NOT NULL DEFAULT 0,
        notes TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(worker_id, attendance_date)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS worker_financial_items (
        id TEXT PRIMARY KEY,
        worker_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        transaction_date TEXT NOT NULL,
        reason_notes TEXT,
        is_settled_in_payroll INTEGER DEFAULT 0,
        payroll_settlement_id TEXT,
        linked_expense_id TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS worker_payroll_settlements (
        id TEXT PRIMARY KEY,
        worker_id TEXT NOT NULL,
        week_start_date TEXT NOT NULL,
        week_end_date TEXT NOT NULL,
        days_attended INTEGER DEFAULT 0,
        daily_wages_total REAL DEFAULT 0,
        overtime_hours_total REAL DEFAULT 0,
        overtime_pay_total REAL DEFAULT 0,
        bonuses_total REAL DEFAULT 0,
        advances_total REAL DEFAULT 0,
        deductions_total REAL DEFAULT 0,
        gross_earnings REAL NOT NULL DEFAULT 0,
        net_due REAL NOT NULL DEFAULT 0,
        amount_paid REAL NOT NULL DEFAULT 0,
        remaining_balance REAL NOT NULL DEFAULT 0,
        payment_date TEXT,
        payment_method TEXT DEFAULT 'cash',
        notes TEXT,
        is_settled INTEGER DEFAULT 0,
        linked_expense_id TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS contractors (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        service_type TEXT NOT NULL,
        phone TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS contractor_payments (
        id TEXT PRIMARY KEY,
        contractor_id TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        related_order TEXT,
        notes TEXT,
        linked_expense_id TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        record_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        last_error TEXT
      )
    ''');

    // Indexes for performance
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchases_date ON purchases (transaction_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_incomes_date ON incomes (transaction_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_worker_attendance_worker ON worker_attendance (worker_id, attendance_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue (status, created_at)',
    );
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer_orders (
        id TEXT PRIMARY KEY,
        customer_name TEXT NOT NULL,
        phone TEXT,
        order_description TEXT NOT NULL,
        start_date TEXT NOT NULL,
        delivery_date TEXT,
        total_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'in_progress',
        notes TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS order_payments (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT DEFAULT 'نقدي',
        notes TEXT,
        linked_income_id TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_order_payments_order ON order_payments (order_id)',
    );
  }

  Future<void> _createV3Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts_advances (
        id TEXT PRIMARY KEY,
        person_name TEXT NOT NULL,
        phone TEXT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        paid_amount REAL NOT NULL DEFAULT 0,
        transaction_date TEXT NOT NULL,
        due_date TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        notes TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS debt_advance_payments (
        id TEXT PRIMARY KEY,
        debt_advance_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON debt_advance_payments (debt_advance_id)',
    );
  }

  Future<void> _createV4Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_items (
        id TEXT PRIMARY KEY,
        material_name TEXT UNIQUE NOT NULL,
        category TEXT NOT NULL,
        unit TEXT NOT NULL DEFAULT 'لوح',
        current_stock REAL NOT NULL DEFAULT 0,
        reserved_stock REAL NOT NULL DEFAULT 0,
        minimum_stock_level REAL NOT NULL DEFAULT 0,
        unit_cost REAL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_movements (
        id TEXT PRIMARY KEY,
        inventory_item_id TEXT NOT NULL,
        movement_type TEXT NOT NULL,
        quantity REAL NOT NULL,
        reference_type TEXT,
        reference_id TEXT,
        reason_notes TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS manufacturing_orders (
        id TEXT PRIMARY KEY,
        order_number TEXT UNIQUE NOT NULL,
        customer_order_id TEXT,
        customer_name TEXT,
        product_name TEXT NOT NULL,
        product_category TEXT NOT NULL DEFAULT 'أثاث خشبي',
        quantity INTEGER NOT NULL DEFAULT 1,
        manufacturing_date TEXT NOT NULL,
        expected_completion_date TEXT,
        assigned_worker_id TEXT,
        assigned_worker_name TEXT,
        status TEXT NOT NULL DEFAULT 'new',
        notes TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS manufacturing_order_dimensions (
        id TEXT PRIMARY KEY,
        manufacturing_order_id TEXT NOT NULL,
        height REAL,
        width REAL,
        depth REAL,
        unit TEXT NOT NULL DEFAULT 'سم',
        additional_notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS manufacturing_order_materials (
        id TEXT PRIMARY KEY,
        manufacturing_order_id TEXT NOT NULL,
        inventory_item_id TEXT,
        material_name TEXT NOT NULL,
        required_quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        specifications TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS manufacturing_checklist (
        id TEXT PRIMARY KEY,
        manufacturing_order_id TEXT NOT NULL,
        material_name TEXT NOT NULL,
        required_quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'required',
        is_prepared INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_reservations (
        id TEXT PRIMARY KEY,
        manufacturing_order_id TEXT NOT NULL,
        inventory_item_id TEXT NOT NULL,
        reserved_quantity REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS material_shortages (
        id TEXT PRIMARY KEY,
        material_name TEXT NOT NULL,
        quantity REAL,
        unit TEXT DEFAULT 'لوح',
        specifications TEXT,
        notes TEXT,
        manufacturing_order_id TEXT,
        manufacturing_order_number TEXT,
        status TEXT NOT NULL DEFAULT 'shortage',
        recorded_by TEXT NOT NULL,
        recorded_at TEXT NOT NULL,
        resolved_by TEXT,
        resolved_at TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_mfg_materials_order ON manufacturing_order_materials (manufacturing_order_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_mfg_checklist_order ON manufacturing_checklist (manufacturing_order_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_shortages_status ON material_shortages (status)',
    );
  }

  // V5: Extra columns for manufacturing tables
  Future<void> _applyV5Columns(Database db) async {
    await _safeAlter(db, 'ALTER TABLE manufacturing_orders ADD COLUMN sections_data TEXT');
    await _safeAlter(db, 'ALTER TABLE manufacturing_order_materials ADD COLUMN thickness_grade TEXT');
    await _safeAlter(db, 'ALTER TABLE manufacturing_order_materials ADD COLUMN color_code TEXT');
    await _safeAlter(db, 'ALTER TABLE manufacturing_order_materials ADD COLUMN linked_piece TEXT');
  }

  // V6: last_error column in sync_queue for retry diagnostics
  Future<void> _applyV6Columns(Database db) async {
    await _safeAlter(db, 'ALTER TABLE sync_queue ADD COLUMN last_error TEXT');
  }

  // V7: align inventory_items with PostgreSQL schema + category in material_shortages
  Future<void> _applyV7Columns(Database db) async {
    await _safeAlter(db, 'ALTER TABLE inventory_items ADD COLUMN supplier_name TEXT');
    await _safeAlter(db, 'ALTER TABLE inventory_items ADD COLUMN minimum_limit REAL DEFAULT 0');
    await _safeAlter(db, 'ALTER TABLE material_shortages ADD COLUMN category TEXT');
    await _safeAlter(db, 'ALTER TABLE material_shortages ADD COLUMN urgency TEXT DEFAULT \'normal\'');
    await _safeAlter(db, 'ALTER TABLE material_shortages ADD COLUMN related_order_number TEXT');
    await _safeAlter(db, 'ALTER TABLE material_shortages ADD COLUMN quantity_needed REAL');
  }

  /// Executes an ALTER TABLE statement, silently ignoring "duplicate column" errors.
  Future<void> _safeAlter(Database db, String sql) async {
    try {
      await db.execute(sql);
    } catch (e) {
      // SQLite throws when the column already exists — this is expected on re-run
      final msg = e.toString().toLowerCase();
      if (!msg.contains('duplicate column') && !msg.contains('already exists')) {
        debugPrint('[DBService] Migration warning: $sql → $e');
      }
    }
  }

  // ──────────────────────────────────────────────────
  // Seed defaults (fresh install only)
  // ──────────────────────────────────────────────────

  Future<void> _seedDefaults(Database db) async {
    final batch = db.batch();

    final categories = [
      {'id': 'cat_1', 'name': 'أخشاب ومواد خام', 'type': 'expense'},
      {'id': 'cat_2', 'name': 'إكسسوارات ومعدات', 'type': 'expense'},
      {'id': 'cat_3', 'name': 'أقمشة وجلود', 'type': 'expense'},
      {'id': 'cat_4', 'name': 'وقود وصيانة سيارات', 'type': 'expense'},
      {'id': 'cat_5', 'name': 'نقل وتروسيكل', 'type': 'expense'},
      {'id': 'cat_6', 'name': 'مصاريف عمال وضيافة', 'type': 'expense'},
      {'id': 'cat_7', 'name': 'ورش واشتراكات خارجية', 'type': 'expense'},
      {'id': 'cat_8', 'name': 'فواتير ومرافق مصنع', 'type': 'expense'},
      {'id': 'cat_9', 'name': 'مصروفات نثرية أخرى', 'type': 'expense'},
    ];

    for (final cat in categories) {
      batch.insert(
        'categories',
        {...cat, 'is_reusable': 1, 'created_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final suggestions = [
      {'item_name': 'خشب زان', 'default_category': 'أخشاب ومواد خام', 'last_unit_price': 14500.0, 'times_used': 10},
      {'item_name': 'خشب عادي (سويد)', 'default_category': 'أخشاب ومواد خام', 'last_unit_price': 9200.0, 'times_used': 8},
      {'item_name': 'أبلكاش كوري', 'default_category': 'أخشاب ومواد خام', 'last_unit_price': 350.0, 'times_used': 15},
      {'item_name': 'أبلكاش سيه', 'default_category': 'أخشاب ومواد خام', 'last_unit_price': 290.0, 'times_used': 12},
      {'item_name': 'كونتر اندونيسي', 'default_category': 'أخشاب ومواد خام', 'last_unit_price': 850.0, 'times_used': 6},
      {'item_name': 'ألواح MDF مستورد', 'default_category': 'أخشاب ومواد خام', 'last_unit_price': 720.0, 'times_used': 9},
      {'item_name': 'إكسسوارات ومقابض', 'default_category': 'إكسسوارات ومعدات', 'last_unit_price': 0.0, 'times_used': 5},
      {'item_name': 'مفصلات هيدروليك', 'default_category': 'إكسسوارات ومعدات', 'last_unit_price': 45.0, 'times_used': 8},
      {'item_name': 'مسامير وغراء ألماني', 'default_category': 'إكسسوارات ومعدات', 'last_unit_price': 0.0, 'times_used': 7},
      {'item_name': 'عدة وأدوات ورشة', 'default_category': 'إكسسوارات ومعدات', 'last_unit_price': 0.0, 'times_used': 4},
      {'item_name': 'جلد تركي فاخر', 'default_category': 'أقمشة وجلود', 'last_unit_price': 220.0, 'times_used': 6},
      {'item_name': 'قماش قطيفة تنجيد', 'default_category': 'أقمشة وجلود', 'last_unit_price': 180.0, 'times_used': 10},
      {'item_name': 'بنزين سيارة المصنع', 'default_category': 'وقود وصيانة سيارات', 'last_unit_price': 0.0, 'times_used': 20},
      {'item_name': 'صيانة وغيار زيت السيارة', 'default_category': 'وقود وصيانة سيارات', 'last_unit_price': 0.0, 'times_used': 4},
      {'item_name': 'نقل وتروسيكل مشاوير', 'default_category': 'نقل وتروسيكل', 'last_unit_price': 0.0, 'times_used': 14},
      {'item_name': 'وجبات ومشروبات العمال', 'default_category': 'مصاريف عمال وضيافة', 'last_unit_price': 0.0, 'times_used': 25},
    ];

    int idx = 1;
    for (final sug in suggestions) {
      batch.insert(
        'item_suggestions',
        {'id': 'sug_${idx++}', ...sug, 'last_used_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }
}
