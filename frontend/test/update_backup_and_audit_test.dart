import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars_home/backend/services/audit_service.dart';
import 'package:stars_home/backend/services/backup_service.dart';
import 'package:stars_home/backend/services/update_service.dart';

void main() {
  group('STARS HOMES ERP — Auto Update Service Tests', () {
    test('Scenario 1: Newer semantic version is correctly detected', () {
      expect(
        UpdateService.isNewerVersion(
          currentVer: '1.0.12',
          currentBuild: 13,
          latestVer: '1.0.13',
          latestBuild: 14,
        ),
        isTrue,
      );

      expect(
        UpdateService.isNewerVersion(
          currentVer: '1.0.12',
          currentBuild: 13,
          latestVer: '1.1.0',
          latestBuild: 1,
        ),
        isTrue,
      );

      expect(
        UpdateService.isNewerVersion(
          currentVer: '1.0.12',
          currentBuild: 13,
          latestVer: '2.0.0',
          latestBuild: 1,
        ),
        isTrue,
      );
    });

    test('Scenario 2: Same version with higher build number is detected as newer', () {
      expect(
        UpdateService.isNewerVersion(
          currentVer: '1.0.12',
          currentBuild: 13,
          latestVer: '1.0.12',
          latestBuild: 14,
        ),
        isTrue,
      );
    });

    test('Scenario 3: Same or older version is rejected (no update)', () {
      expect(
        UpdateService.isNewerVersion(
          currentVer: '1.0.12',
          currentBuild: 13,
          latestVer: '1.0.12',
          latestBuild: 13,
        ),
        isFalse,
      );

      expect(
        UpdateService.isNewerVersion(
          currentVer: '1.0.12',
          currentBuild: 13,
          latestVer: '1.0.11',
          latestBuild: 20,
        ),
        isFalse,
      );
    });
  });

  group('STARS HOMES ERP — Activity / Audit Log Tests', () {
    test('Scenario 4: AuditLogEntry serializes and deserializes correctly', () {
      final now = DateTime.now();
      final entry = AuditLogEntry(
        id: 'log_test_1',
        userName: 'المهندس مهند',
        userRole: 'owner',
        deviceId: 'dev_win11_main',
        action: 'create_order',
        module: 'orders',
        entityTable: 'customer_orders',
        entityId: 'ord_123',
        details: jsonEncode({'order_number': 'ORD-2026-001'}),
        createdAt: now,
      );

      final map = entry.toMap();
      final deserialized = AuditLogEntry.fromMap(map);

      expect(deserialized.id, equals('log_test_1'));
      expect(deserialized.userName, equals('المهندس مهند'));
      expect(deserialized.userRole, equals('owner'));
      expect(deserialized.actionArabic, equals('إنشاء طلب جديد'));
      expect(deserialized.moduleArabic, equals('العملاء والطلبات'));
    });

    test('Scenario 5: Audit log CSV export generates valid RFC-compliant headers and lines', () {
      final logs = [
        AuditLogEntry(
          id: 'log_1',
          userName: 'إبراهيم',
          userRole: 'manager',
          deviceId: 'dev_phone_1',
          action: 'login',
          module: 'auth',
          details: 'تم تسجيل الدخول بنجاح',
          createdAt: DateTime(2026, 11, 10, 10, 30),
        ),
      ];

      final csv = AuditService.instance.exportToCsv(logs);
      expect(csv, contains('المعرف,التاريخ والوقت,المستخدم,الدور,القسم,الإجراء,الجهاز,التفاصيل'));
      expect(csv, contains('إبراهيم'));
      expect(csv, contains('المدير'));
      expect(csv, contains('تسجيل دخول'));
    });
  });

  group('STARS HOMES ERP — Backup & SHA-256 Integrity Tests', () {
    test('Scenario 6: BackupRecordItem formatting and labels', () {
      final item = BackupRecordItem(
        id: 'bck_123',
        filename: 'STARS_HOMES_BACKUP_2026-11-10.zip',
        backupType: 'before_restore',
        storageDestination: 'local',
        fileSize: 1048576,
        createdBy: 'المالك',
        status: 'completed',
        createdAt: DateTime.now(),
      );

      expect(item.typeArabic, equals('أمان قبل الاسترجاع'));
    });

    test('Scenario 7: In-memory Zip packaging and SHA-256 verification', () {
      final sampleDatabase = {
        'workers': [
          {'id': 'w_1', 'name': 'علي النجار', 'daily_rate': 400.0},
        ],
        'customer_orders': [
          {'id': 'ord_1', 'customer_name': 'محمد أحمد', 'total_amount': 50000.0},
        ],
      };

      final dbJsonBytes = utf8.encode(jsonEncode(sampleDatabase));
      final metaJsonBytes = utf8.encode(jsonEncode({
        'backup_id': 'bck_test_77',
        'app_version': '1.0.12+13',
        'tables_count': 2,
      }));

      final archive = Archive();
      archive.addFile(ArchiveFile('metadata.json', metaJsonBytes.length, metaJsonBytes));
      archive.addFile(ArchiveFile('database.json', dbJsonBytes.length, dbJsonBytes));

      final zipBytes = ZipEncoder().encode(archive);
      expect(zipBytes, isNotNull);

      // Verify SHA-256 hash
      final computedHash = sha256.convert(zipBytes).toString().toLowerCase();
      expect(computedHash.length, equals(64));

      // Decode and verify payload
      final decodedArchive = ZipDecoder().decodeBytes(zipBytes);
      ArchiveFile? decodedMeta;
      ArchiveFile? decodedDb;

      for (final f in decodedArchive) {
        if (f.name == 'metadata.json') decodedMeta = f;
        if (f.name == 'database.json') decodedDb = f;
      }

      expect(decodedMeta, isNotNull);
      expect(decodedDb, isNotNull);

      final restoredDb = jsonDecode(utf8.decode(decodedDb!.content as List<int>)) as Map<String, dynamic>;
      expect(restoredDb['workers'], isNotEmpty);
      expect(restoredDb['workers'][0]['name'], equals('علي النجار'));
      expect(restoredDb['customer_orders'][0]['total_amount'], equals(50000.0));
    });

    test('Scenario 8: Checksum tampering detection', () {
      final sampleData = utf8.encode('Original STARS HOMES Backup Data');
      final validHash = sha256.convert(sampleData).toString().toLowerCase();

      final tamperedData = utf8.encode('Tampered Data');
      final tamperedHash = sha256.convert(tamperedData).toString().toLowerCase();

      expect(validHash, isNot(equals(tamperedHash)));
    });
  });
}
