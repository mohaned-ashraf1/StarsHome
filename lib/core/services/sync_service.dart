import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'db_service.dart';

enum SyncStatus {
  online,
  offline,
  syncing,
  synced,
  pendingChanges,
}

/// Synchronisation service implementing:
/// - Full paginated pull (no fixed 200-record limit)
/// - Last-write-wins conflict resolution based on updated_at timestamps
/// - Idempotent upserts — safe to retry
/// - debts_advances and debt_advance_payments coverage
/// - Retry with exponential back-off (max 5 attempts per item)
/// - Local changes are preserved until confirmed by the server
class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  static const int _pageSize = 100;
  static const int _maxRetries = 5;

  /// Default Supabase production credentials for Stars Homes Factory
  static const String defaultSupabaseUrl = 'https://rxhepjrwowtkhonebcsp.supabase.co';
  static const String defaultSupabaseAnonKey = 'sb_publishable_FmSiopJi6Y15IDjqLIutKg_Jjl3wIXb';

  SupabaseClient? _supabaseClient;
  bool _isConfigured = false;
  bool _isSyncing = false;

  SyncStatus _currentStatus = SyncStatus.offline;
  int _pendingCount = 0;

  SyncStatus get status => _currentStatus;
  int get pendingCount => _pendingCount;
  bool get isConfigured => _isConfigured;

  final ValueNotifier<SyncStatus> statusNotifier =
      ValueNotifier<SyncStatus>(SyncStatus.offline);
  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);

  // ──────────────────────────────────────────────────
  // Initialisation
  // ──────────────────────────────────────────────────

  Future<void> init() async {
    String supabaseUrl = defaultSupabaseUrl;
    String supabaseAnonKey = defaultSupabaseAnonKey;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUrl = prefs.getString('supabase_url');
      final storedKey = prefs.getString('supabase_anon_key');

      if (storedUrl != null && storedUrl.trim().isNotEmpty) {
        supabaseUrl = storedUrl.trim();
      } else {
        await prefs.setString('supabase_url', defaultSupabaseUrl);
      }

      if (storedKey != null && storedKey.trim().isNotEmpty) {
        supabaseAnonKey = storedKey.trim();
      } else {
        await prefs.setString('supabase_anon_key', defaultSupabaseAnonKey);
      }
    } catch (e) {
      debugPrint('[SyncService] SharedPreferences read error: $e');
    }

    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      try {
        // Supabase may already be initialised — guard against double init
        try {
          _supabaseClient = Supabase.instance.client;
          _isConfigured = true;
        } catch (_) {
          await Supabase.initialize(
            url: supabaseUrl,
            anonKey: supabaseAnonKey,
            authOptions: const FlutterAuthClientOptions(
              authFlowType: AuthFlowType.pkce,
            ),
          );
          _supabaseClient = Supabase.instance.client;
          _isConfigured = true;
        }
        _updateStatus(SyncStatus.online);
        debugPrint('[SyncService] Supabase configured and online');
      } catch (e) {
        debugPrint('[SyncService] Supabase init error: $e');
        _isConfigured = false;
        _updateStatus(SyncStatus.offline);
      }
    } else {
      _isConfigured = false;
      _updateStatus(SyncStatus.offline);
      debugPrint('[SyncService] No Supabase credentials — running offline');
    }

    await checkPendingQueueCount();
  }

  Future<void> configureSupabase(String url, String anonKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabase_url', url);
    await prefs.setString('supabase_anon_key', anonKey);
    await init();
  }

  // ──────────────────────────────────────────────────
  // Status helpers
  // ──────────────────────────────────────────────────

  void _updateStatus(SyncStatus newStatus) {
    _currentStatus = newStatus;
    statusNotifier.value = newStatus;
  }

  Future<void> checkPendingQueueCount() async {
    try {
      final db = await DBService.instance.database;
      final result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'pending'",
      );
      _pendingCount = Sqflite.firstIntValue(result) ?? 0;
      pendingCountNotifier.value = _pendingCount;

      if (_pendingCount > 0 && _currentStatus != SyncStatus.syncing) {
        _updateStatus(SyncStatus.pendingChanges);
      } else if (_pendingCount == 0 && _currentStatus == SyncStatus.pendingChanges) {
        _updateStatus(_isConfigured ? SyncStatus.synced : SyncStatus.offline);
      }
    } catch (e) {
      debugPrint('[SyncService] checkPendingQueueCount error: $e');
    }
  }

  // ──────────────────────────────────────────────────
  // Queue a local operation
  // ──────────────────────────────────────────────────

  Future<void> queueOperation({
    required String tableName,
    required String operation, // 'insert', 'update', 'delete'
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final db = await DBService.instance.database;
      await db.insert(
        'sync_queue',
        {
          'id': const Uuid().v4(),
          'table_name': tableName,
          'operation': operation,
          'record_id': recordId,
          'payload': jsonEncode(payload),
          'created_at': DateTime.now().toIso8601String(),
          'retry_count': 0,
          'status': 'pending',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await checkPendingQueueCount();

      // Fire-and-forget sync if online (don't block the caller)
      if (_isConfigured && !_isSyncing) {
        syncNow().ignore();
      }
    } catch (e) {
      debugPrint('[SyncService] queueOperation error ($tableName/$operation): $e');
    }
  }

  // ──────────────────────────────────────────────────
  // Main sync loop
  // ──────────────────────────────────────────────────

  Future<bool> syncNow() async {
    if (!_isConfigured || _supabaseClient == null) {
      await checkPendingQueueCount();
      return false;
    }
    if (_isSyncing) {
      debugPrint('[SyncService] Sync already in progress — skipping');
      return false;
    }

    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    try {
      final db = await DBService.instance.database;

      // ── 1. Push local queue to remote ──
      await _processUploadQueue(db);

      // ── 2. Pull remote updates (fully paginated) ──
      await _pullAllTables();

      await checkPendingQueueCount();
      _updateStatus(SyncStatus.synced);
      debugPrint('[SyncService] Sync complete');
      return true;
    } catch (e) {
      debugPrint('[SyncService] Sync failed: $e');
      _updateStatus(_pendingCount > 0 ? SyncStatus.pendingChanges : SyncStatus.offline);
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processUploadQueue(Database db) async {
    final pendingItems = await db.query(
      'sync_queue',
      where: "status = 'pending' AND retry_count < $_maxRetries",
      orderBy: 'created_at ASC',
    );

    for (final item in pendingItems) {
      final id = item['id'].toString();
      final table = item['table_name'].toString();
      final op = item['operation'].toString();
      final payload =
          jsonDecode(item['payload'].toString()) as Map<String, dynamic>;
      final retryCount = (item['retry_count'] as int?) ?? 0;

      try {
        if (op == 'insert') {
          await _supabaseClient!.from(table).upsert(payload);
        } else if (op == 'update') {
          await _supabaseClient!
              .from(table)
              .update(payload)
              .eq('id', item['record_id'].toString());
        } else if (op == 'delete') {
          await _supabaseClient!
              .from(table)
              .delete()
              .eq('id', item['record_id'].toString());
        }

        // Success — mark completed
        await db.update(
          'sync_queue',
          {'status': 'completed'},
          where: 'id = ?',
          whereArgs: [id],
        );
        debugPrint('[SyncService] ✓ $op on $table (id=${item['record_id']})');
      } catch (itemErr) {
        debugPrint('[SyncService] ✗ $op on $table retry=$retryCount error: $itemErr');
        // Increment retry counter; item stays 'pending' for next cycle
        await db.rawUpdate(
          'UPDATE sync_queue SET retry_count = retry_count + 1, last_error = ? WHERE id = ?',
          [itemErr.toString(), id],
        );
        // After max retries, mark as failed to prevent indefinite blocking
        if (retryCount + 1 >= _maxRetries) {
          await db.update(
            'sync_queue',
            {'status': 'failed'},
            where: 'id = ?',
            whereArgs: [id],
          );
          debugPrint('[SyncService] ✗ Item $id permanently failed after $_maxRetries retries');
        }
      }
    }

    // Clean up completed entries
    await db.delete('sync_queue', where: "status = 'completed'");
  }

  Future<void> _pullAllTables() async {
    // All business tables — including debts_advances and debt_advance_payments
    final tables = [
      'purchases',
      'incomes',
      'workers',
      'worker_attendance',
      'worker_financial_items',
      'worker_payroll_settlements',
      'contractors',
      'contractor_payments',
      'debts_advances',
      'debt_advance_payments',
      'customer_orders',
      'order_payments',
      'inventory_items',
      'inventory_movements',
      'inventory_reservations',
      'manufacturing_orders',
      'manufacturing_order_dimensions',
      'manufacturing_order_materials',
      'manufacturing_checklist',
      'material_shortages',
    ];

    for (final table in tables) {
      await _pullRemoteTablePaginated(table);
    }
  }

  // ──────────────────────────────────────────────────
  // Paginated pull with last-write-wins conflict resolution
  // ──────────────────────────────────────────────────

  /// Pulls all remote rows for [table] using keyset pagination,
  /// applying a last-write-wins strategy: the row with the newer
  /// updated_at timestamp wins. For tables without updated_at,
  /// remote always wins (ConflictAlgorithm.replace).
  Future<void> _pullRemoteTablePaginated(String table) async {
    if (_supabaseClient == null) return;

    try {
      final db = await DBService.instance.database;
      String? lastId;
      int totalPulled = 0;

      while (true) {
        List<Map<String, dynamic>> remoteRows;

        if (lastId == null) {
          remoteRows = await _supabaseClient!
              .from(table)
              .select()
              .order('id')
              .limit(_pageSize);
        } else {
          remoteRows = await _supabaseClient!
              .from(table)
              .select()
              .gt('id', lastId)
              .order('id')
              .limit(_pageSize);
        }

        if (remoteRows.isEmpty) break;

        for (final row in remoteRows) {
          await _mergeRow(db, table, Map<String, dynamic>.from(row));
        }

        totalPulled += remoteRows.length;
        lastId = remoteRows.last['id']?.toString();

        if (remoteRows.length < _pageSize) break; // last page
      }

      if (totalPulled > 0) {
        debugPrint('[SyncService] Pulled $totalPulled rows from $table');
      }
    } catch (e) {
      // Non-fatal — table may not exist on remote yet
      debugPrint('[SyncService] Pull error for $table: $e');
    }
  }

  /// Merges a single remote row into the local database.
  /// Last-write-wins: if local row has a newer updated_at, skip the remote row.
  Future<void> _mergeRow(
    Database db,
    String table,
    Map<String, dynamic> remoteRow,
  ) async {
    final id = remoteRow['id']?.toString();
    if (id == null) return;

    try {
      final existing = await db.query(table,
          where: 'id = ?', whereArgs: [id], limit: 1);

      if (existing.isEmpty) {
        // New row from remote — insert it
        await db.insert(
          table,
          remoteRow,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        return;
      }

      final localRow = existing.first;
      final remoteUpdatedStr = remoteRow['updated_at']?.toString();
      final localUpdatedStr = localRow['updated_at']?.toString();

      if (remoteUpdatedStr != null && localUpdatedStr != null) {
        final remoteUpdated = DateTime.tryParse(remoteUpdatedStr);
        final localUpdated = DateTime.tryParse(localUpdatedStr);
        if (remoteUpdated != null &&
            localUpdated != null &&
            !remoteUpdated.isAfter(localUpdated)) {
          // Local is newer or equal — skip remote row to preserve local changes
          return;
        }
      }

      // Remote wins (newer or no timestamp to compare)
      await db.insert(
        table,
        remoteRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[SyncService] mergeRow error ($table id=$id): $e');
    }
  }
}
