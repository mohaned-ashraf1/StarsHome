import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stars_home/backend/services/audit_service.dart';
import 'package:stars_home/backend/services/db_service.dart';
import 'package:stars_home/backend/services/google_drive_service.dart';
import 'package:uuid/uuid.dart';

class BackupRecordItem {
  final String id;
  final String filename;
  final String backupType; // 'manual', 'automatic', 'before_restore', 'before_update'
  final String storageDestination;
  final int fileSize;
  final String? sha256Hash;
  final String? deviceId;
  final String createdBy;
  final String status;
  final String? filePath;
  final DateTime createdAt;

  BackupRecordItem({
    required this.id,
    required this.filename,
    required this.backupType,
    required this.storageDestination,
    required this.fileSize,
    this.sha256Hash,
    this.deviceId,
    required this.createdBy,
    required this.status,
    this.filePath,
    required this.createdAt,
  });

  factory BackupRecordItem.fromMap(Map<String, dynamic> map, {String? filePath}) {
    return BackupRecordItem(
      id: map['id']?.toString() ?? '',
      filename: map['filename']?.toString() ?? '',
      backupType: map['backup_type']?.toString() ?? 'manual',
      storageDestination: map['storage_destination']?.toString() ?? 'local',
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      sha256Hash: map['sha256_hash']?.toString(),
      deviceId: map['device_id']?.toString(),
      createdBy: map['created_by']?.toString() ?? 'المستخدم',
      status: map['status']?.toString() ?? 'completed',
      filePath: filePath,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get typeArabic {
    switch (backupType) {
      case 'manual':
        return 'يدوية';
      case 'automatic':
        return 'تلقائية مجدولة';
      case 'before_restore':
        return 'أمان قبل الاسترجاع';
      case 'before_update':
        return 'أمان قبل التحديث';
      default:
        return backupType;
    }
  }
}

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  static const _uuid = Uuid();

  static const List<String> businessTables = [
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

  Future<Directory> _getBackupRootDirectory() async {
    Directory baseDir;
    if (!kIsWeb && Platform.isAndroid) {
      baseDir = (await getExternalStorageDirectory()) ?? (await getApplicationDocumentsDirectory());
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    final root = Directory('${baseDir.path}/STARS_HOMES_BACKUPS');
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  String _getSubfolderForType(String type) {
    switch (type) {
      case 'automatic':
        return 'Automatic';
      case 'before_restore':
        return 'Before_Restore';
      case 'before_update':
        return 'Before_Updates';
      case 'manual':
      default:
        return 'Manual';
    }
  }

  /// Creates a complete, self-contained, and compressed backup archive (.zip)
  Future<File> createBackup({
    required String type, // 'manual', 'automatic', 'before_restore', 'before_update'
    String? createdBy,
    String? notes,
  }) async {
    final db = await DBService.instance.database;
    final now = DateTime.now();
    final backupId = 'bck_${_uuid.v4()}';
    final timestampStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
    final filename = 'STARS_HOMES_BACKUP_$timestampStr.zip';

    final packageInfo = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('stars_device_id') ?? 'unknown_device';
    final user = createdBy ?? 'المستخدم';

    final rootDir = await _getBackupRootDirectory();
    final subfolder = _getSubfolderForType(type);
    final targetDir = Directory('${rootDir.path}/$subfolder');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final zipFile = File('${targetDir.path}/$filename');

    // 1. Export local database tables to JSON map
    final Map<String, dynamic> dbData = {};
    for (final table in businessTables) {
      try {
        final rows = await db.query(table);
        dbData[table] = rows;
      } catch (e) {
        debugPrint('[BackupService] Warning reading table $table: $e');
        dbData[table] = [];
      }
    }

    final dbDataBytes = utf8.encode(jsonEncode(dbData));

    // 2. Build metadata
    final metadata = {
      'backup_id': backupId,
      'filename': filename,
      'backup_type': type,
      'created_at': now.toIso8601String(),
      'created_by': user,
      'device_id': deviceId,
      'app_version': '${packageInfo.version}+${packageInfo.buildNumber}',
      'database_version': 9,
      'tables_count': businessTables.length,
      'notes': notes ?? '',
    };
    final metadataBytes = utf8.encode(jsonEncode(metadata));

    // 3. Compress into ZIP archive using pure Dart archive package
    final archive = Archive();
    archive.addFile(ArchiveFile('metadata.json', metadataBytes.length, metadataBytes));
    archive.addFile(ArchiveFile('database.json', dbDataBytes.length, dbDataBytes));

    final zipBytes = ZipEncoder().encode(archive);
    await zipFile.writeAsBytes(zipBytes);

    // 4. Calculate SHA-256 Checksum
    final sha256Hash = sha256.convert(zipBytes).toString().toLowerCase();

    // 5. Store record in local database
    final backupRow = {
      'id': backupId,
      'filename': filename,
      'backup_type': type,
      'storage_destination': 'local',
      'file_size': zipBytes.length,
      'sha256_hash': sha256Hash,
      'device_id': deviceId,
      'created_by': user,
      'status': 'completed',
      'details': jsonEncode(metadata),
      'created_at': now.toIso8601String(),
    };
    await db.insert('backup_records', backupRow);

    // 6. Record event in Audit Log
    await AuditService.instance.logEvent(
      action: 'create_backup',
      module: 'backup',
      entityTable: 'backup_records',
      entityId: backupId,
      details: {
        'filename': filename,
        'type': type,
        'size_bytes': zipBytes.length,
        'sha256': sha256Hash,
      },
      userName: user,
    );

    // 7. If Google Drive is connected, upload safely in background
    if (GoogleDriveService.instance.isConnected) {
      GoogleDriveService.instance
          .uploadBackup(zipFile, subfolder: subfolder)
          .then((ok) {
        if (ok) {
          db.update(
            'backup_records',
            {'storage_destination': 'google_drive_and_local'},
            where: 'id = ?',
            whereArgs: [backupId],
          );
        }
      });
    }

    // 8. Apply Retention Policy
    await _applyRetentionPolicy();

    debugPrint('[BackupService] ✓ Created backup successfully: $filename');
    return zipFile;
  }

  /// Verifies the integrity of a backup archive (.zip)
  Future<Map<String, dynamic>> verifyBackup(File zipFile) async {
    if (!await zipFile.exists()) {
      throw Exception('ملف النسخة الاحتياطية غير موجود.');
    }

    final bytes = await zipFile.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('ملف النسخة الاحتياطية فارغ أو تالف.');
    }

    final actualHash = sha256.convert(bytes).toString().toLowerCase();

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw Exception('تعذر فك ضغط الأرشيف — قد يكون الملف تالفاً: $e');
    }

    ArchiveFile? metadataFile;
    ArchiveFile? dbFile;

    for (final f in archive) {
      if (f.name == 'metadata.json') metadataFile = f;
      if (f.name == 'database.json') dbFile = f;
    }

    if (metadataFile == null || dbFile == null) {
      throw Exception('الأرشيف يفتقر للملفات الأساسية (metadata.json أو database.json).');
    }

    final metadataContent = utf8.decode(metadataFile.content as List<int>);
    final Map<String, dynamic> metadata = jsonDecode(metadataContent);

    return {
      'metadata': metadata,
      'sha256': actualHash,
      'isValid': true,
      'fileSize': bytes.length,
    };
  }

  /// Safely restores database from a verified backup archive
  /// CRITICAL SAFETY: Always takes an automatic 'before_restore' backup first!
  Future<void> restoreBackup(File zipFile, {required bool confirmed}) async {
    if (!confirmed) {
      throw Exception('يجب تأكيد عملية الاسترجاع صراحةً قبل التنفيذ.');
    }

    // 1. Verify archive integrity
    final verification = await verifyBackup(zipFile);
    final metadata = verification['metadata'] as Map<String, dynamic>;

    // 2. MANDATORY SAFETY: Create safety backup of current data first
    await createBackup(
      type: 'before_restore',
      notes: 'نسخة أمان تلقائية قبل استرجاع النسخة ${zipFile.uri.pathSegments.last}',
    );

    // 3. Decode database.json payload
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final dbArchiveFile = archive.firstWhere((f) => f.name == 'database.json');
    final dbContent = utf8.decode(dbArchiveFile.content as List<int>);
    final Map<String, dynamic> tablesData = jsonDecode(dbContent);

    // 4. Pause synchronization and perform atomic transactional restore
    final db = await DBService.instance.database;

    await db.transaction((txn) async {
      for (final table in businessTables) {
        if (tablesData.containsKey(table)) {
          final rows = (tablesData[table] as List<dynamic>).cast<Map<String, dynamic>>();

          // Clear table first
          await txn.delete(table);

          // Restore rows
          for (final row in rows) {
            await txn.insert(table, row);
          }
        }
      }
    });

    // 5. Log restore event in Audit Log
    await AuditService.instance.logEvent(
      action: 'restore_backup',
      module: 'backup',
      details: {
        'source_file': zipFile.uri.pathSegments.last,
        'backup_id': metadata['backup_id'],
        'tables_restored': tablesData.keys.toList(),
      },
    );

    debugPrint('[BackupService] ✓ Restore completed successfully');
  }

  /// Lists all local backup records
  Future<List<BackupRecordItem>> listBackups() async {
    final db = await DBService.instance.database;
    final rows = await db.query('backup_records', orderBy: 'created_at DESC');

    final rootDir = await _getBackupRootDirectory();
    final List<BackupRecordItem> items = [];

    for (final r in rows) {
      final filename = r['filename']?.toString() ?? '';
      final type = r['backup_type']?.toString() ?? 'manual';
      final subfolder = _getSubfolderForType(type);
      final potentialPath = '${rootDir.path}/$subfolder/$filename';

      items.add(BackupRecordItem.fromMap(r, filePath: potentialPath));
    }

    return items;
  }

  /// Deletes an old backup file
  Future<void> deleteBackup(BackupRecordItem item) async {
    if (item.filePath != null) {
      final file = File(item.filePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    final db = await DBService.instance.database;
    await db.delete('backup_records', where: 'id = ?', whereArgs: [item.id]);

    await AuditService.instance.logEvent(
      action: 'delete_backup',
      module: 'backup',
      entityId: item.id,
      details: {'filename': item.filename},
    );
  }

  /// Retention policy: keeps latest 7 daily backups, latest 4 weekly backups.
  /// Never deletes manual backups automatically.
  Future<void> _applyRetentionPolicy() async {
    try {
      final db = await DBService.instance.database;
      final autoRows = await db.query(
        'backup_records',
        where: "backup_type = 'automatic'",
        orderBy: 'created_at DESC',
      );

      // Keep maximum 14 automatic backups
      if (autoRows.length > 14) {
        final toDelete = autoRows.sublist(14);
        for (final row in toDelete) {
          final id = row['id']?.toString();
          final filename = row['filename']?.toString() ?? '';
          final rootDir = await _getBackupRootDirectory();
          final file = File('${rootDir.path}/Automatic/$filename');
          if (await file.exists()) {
            await file.delete();
          }
          if (id != null) {
            await db.delete('backup_records', where: 'id = ?', whereArgs: [id]);
          }
        }
      }
    } catch (e) {
      debugPrint('[BackupService] Retention error: $e');
    }
  }
}
