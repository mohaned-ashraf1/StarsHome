import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stars_home/backend/services/db_service.dart';
import 'package:uuid/uuid.dart';

class AuditLogEntry {
  final String id;
  final String userName;
  final String userRole;
  final String? deviceId;
  final String action;
  final String module;
  final String? entityTable;
  final String? entityId;
  final String? details;
  final DateTime createdAt;

  AuditLogEntry({
    required this.id,
    required this.userName,
    required this.userRole,
    this.deviceId,
    required this.action,
    required this.module,
    this.entityTable,
    this.entityId,
    this.details,
    required this.createdAt,
  });

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map['id']?.toString() ?? '',
      userName: map['user_name']?.toString() ?? 'غير معروف',
      userRole: map['user_role']?.toString() ?? 'manager',
      deviceId: map['device_id']?.toString(),
      action: map['action']?.toString() ?? '',
      module: map['module']?.toString() ?? 'عام',
      entityTable: map['entity_table']?.toString(),
      entityId: map['entity_id']?.toString(),
      details: map['details']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_name': userName,
      'user_role': userRole,
      'device_id': deviceId,
      'action': action,
      'module': module,
      'entity_table': entityTable,
      'entity_id': entityId,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get actionArabic {
    switch (action) {
      case 'login':
        return 'تسجيل دخول';
      case 'logout':
        return 'تسجيل خروج';
      case 'create_order':
        return 'إنشاء طلب جديد';
      case 'update_order':
        return 'تعديل بيانات طلب';
      case 'delete_order':
        return 'حذف طلب';
      case 'add_payment':
        return 'تسجيل دفعة عميل';
      case 'create_worker':
        return 'إضافة عامل جديد';
      case 'update_worker':
        return 'تعديل بيانات عامل';
      case 'delete_worker':
        return 'حذف عامل';
      case 'record_attendance':
        return 'تسجيل حضور وانصراف';
      case 'add_financial_item':
        return 'تسجيل سلفة / مكافأة / خصم';
      case 'settle_payroll':
        return 'تقفيل راتب عامل';
      case 'create_purchase':
        return 'تسجيل مشتريات / مصروف';
      case 'delete_purchase':
        return 'حذف مصروف';
      case 'create_income':
        return 'تسجيل إيراد';
      case 'create_inventory_item':
        return 'إضافة خامة جديدة للمخزن';
      case 'update_inventory_stock':
        return 'تسجيل حركة مخزن';
      case 'create_backup':
        return 'إنشاء نسخة احتياطية';
      case 'restore_backup':
        return 'استرجاع نسخة احتياطية';
      case 'delete_backup':
        return 'حذف نسخة احتياطية';
      case 'app_update':
        return 'تحديث إصدار التطبيق';
      case 'reset_data':
        return 'تصفير بيانات الهاتف';
      default:
        return action;
    }
  }

  String get moduleArabic {
    switch (module) {
      case 'orders':
        return 'العملاء والطلبات';
      case 'workers':
        return 'شؤون العمال';
      case 'accounts':
        return 'المالية والحسابات';
      case 'inventory':
        return 'المخزن والخامات';
      case 'manufacturing':
        return 'أوامر التصنيع';
      case 'backup':
        return 'النسخ الاحتياطي';
      case 'auth':
        return 'الأمان وتسجيل الدخول';
      case 'settings':
        return 'إعدادات النظام';
      default:
        return module;
    }
  }
}

class AuditService {
  static final AuditService instance = AuditService._internal();
  AuditService._internal();

  static const _uuid = Uuid();
  String? _currentUserName;
  String? _currentUserRole;
  String? _deviceId;

  void setCurrentUser({required String name, required String role}) {
    _currentUserName = name;
    _currentUserRole = role;
  }

  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('stars_device_id');
    if (_deviceId == null) {
      _deviceId = 'dev_${_uuid.v4().substring(0, 8)}';
      await prefs.setString('stars_device_id', _deviceId!);
    }
    return _deviceId!;
  }

  /// Logs a business or system event
  Future<void> logEvent({
    required String action,
    required String module,
    String? entityTable,
    String? entityId,
    Map<String, dynamic>? details,
    String? userName,
    String? userRole,
  }) async {
    try {
      final db = await DBService.instance.database;
      final devId = await _getDeviceId();
      final now = DateTime.now();
      final logId = 'log_${_uuid.v4()}';

      final finalUser = userName ?? _currentUserName ?? 'المستخدم';
      final finalRole = userRole ?? _currentUserRole ?? 'manager';
      final detailsJson = details != null ? jsonEncode(details) : null;

      final row = {
        'id': logId,
        'user_name': finalUser,
        'user_role': finalRole,
        'device_id': devId,
        'action': action,
        'module': module,
        'entity_table': entityTable,
        'entity_id': entityId,
        'details': detailsJson,
        'created_at': now.toIso8601String(),
      };

      await db.insert('audit_logs', row);

      // Add to sync_queue so logs sync to Supabase cloud
      await db.insert('sync_queue', {
        'id': 'sq_${_uuid.v4()}',
        'table_name': 'audit_logs',
        'record_id': logId,
        'operation': 'insert',
        'payload': jsonEncode(row),
        'created_at': now.toIso8601String(),
        'retry_count': 0,
        'status': 'pending',
      });

      debugPrint('[AuditService] Logged: $action in $module by $finalUser');
    } catch (e) {
      debugPrint('[AuditService] Failed to record log: $e');
    }
  }

  /// Fetches logs with optional search, module, user, and date filters
  Future<List<AuditLogEntry>> getLogs({
    String? module,
    String? search,
    String? userRole,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await DBService.instance.database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (module != null && module.isNotEmpty && module != 'all') {
      whereClauses.add('module = ?');
      whereArgs.add(module);
    }

    if (userRole != null && userRole.isNotEmpty && userRole != 'all') {
      whereClauses.add('user_role = ?');
      whereArgs.add(userRole);
    }

    if (fromDate != null) {
      whereClauses.add('created_at >= ?');
      whereArgs.add(fromDate.toIso8601String());
    }

    if (toDate != null) {
      whereClauses.add('created_at <= ?');
      whereArgs.add(toDate.toIso8601String());
    }

    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('(user_name LIKE ? OR action LIKE ? OR details LIKE ?)');
      final term = '%${search.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final rows = await db.query(
      'audit_logs',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map((r) => AuditLogEntry.fromMap(r)).toList();
  }

  /// Generates CSV content from a list of log entries
  String exportToCsv(List<AuditLogEntry> logs) {
    final buffer = StringBuffer();
    buffer.writeln('المعرف,التاريخ والوقت,المستخدم,الدور,القسم,الإجراء,الجهاز,التفاصيل');

    for (final l in logs) {
      final safeDetails = (l.details ?? '').replaceAll('"', '""').replaceAll('\n', ' ');
      buffer.writeln(
        '"${l.id}","${l.createdAt.toIso8601String()}","${l.userName}","${l.userRole == 'owner' ? 'المالك' : 'المدير'}","${l.moduleArabic}","${l.actionArabic}","${l.deviceId ?? ''}","$safeDetails"',
      );
    }

    return buffer.toString();
  }
}
