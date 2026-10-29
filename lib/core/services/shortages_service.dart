import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/material_shortage_model.dart';
import 'db_service.dart';
import 'sync_service.dart';

class ShortagesService {
  static final ShortagesService instance = ShortagesService._internal();
  ShortagesService._internal();

  Future<List<MaterialShortageModel>> getAllShortages() async {
    try {
      final db = await DBService.instance.database;
      // Immediately purge any previous sample shortages
      await db.delete('material_shortages', where: "id IN ('sht_1', 'sht_2', 'sht_3')");
      final rows = await db.query(
        'material_shortages',
        orderBy: 'recorded_at DESC',
      );
      return rows.map((r) => MaterialShortageModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('Error getting all shortages: $e');
      return [];
    }
  }

  Future<List<MaterialShortageModel>> getActiveShortages() async {
    try {
      final db = await DBService.instance.database;
      final rows = await db.query(
        'material_shortages',
        where: "status != 'resolved'",
        orderBy: 'recorded_at DESC',
      );
      return rows.map((r) => MaterialShortageModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('Error getting active shortages: $e');
      return [];
    }
  }

  Future<List<MaterialShortageModel>> getResolvedShortages() async {
    try {
      final db = await DBService.instance.database;
      final rows = await db.query(
        'material_shortages',
        where: "status = 'resolved'",
        orderBy: 'resolved_at DESC, updated_at DESC',
      );
      return rows.map((r) => MaterialShortageModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('Error getting resolved shortages: $e');
      return [];
    }
  }

  Future<MaterialShortageModel?> getShortageById(String id) async {
    try {
      final db = await DBService.instance.database;
      final rows = await db.query(
        'material_shortages',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isNotEmpty) {
        return MaterialShortageModel.fromMap(rows.first);
      }
    } catch (e) {
      debugPrint('Error getting shortage by id: $e');
    }
    return null;
  }

  Future<void> addShortage(MaterialShortageModel shortage) async {
    final db = await DBService.instance.database;
    await db.insert(
      'material_shortages',
      shortage.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await SyncService.instance.queueOperation(
      tableName: 'material_shortages',
      operation: 'insert',
      recordId: shortage.id,
      payload: shortage.toMap(),
    );
  }

  Future<void> updateShortage(MaterialShortageModel shortage) async {
    final db = await DBService.instance.database;
    final updated = shortage.copyWith(updatedAt: DateTime.now());
    await db.update(
      'material_shortages',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [shortage.id],
    );

    await SyncService.instance.queueOperation(
      tableName: 'material_shortages',
      operation: 'update',
      recordId: shortage.id,
      payload: updated.toMap(),
    );
  }

  Future<void> resolveShortage({
    required String shortageId,
    required String resolvedBy,
  }) async {
    final db = await DBService.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'material_shortages',
      {
        'status': 'resolved',
        'resolved_by': resolvedBy,
        'resolved_at': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [shortageId],
    );

    await SyncService.instance.queueOperation(
      tableName: 'material_shortages',
      operation: 'update',
      recordId: shortageId,
      payload: {
        'id': shortageId,
        'status': 'resolved',
        'resolved_by': resolvedBy,
        'resolved_at': now,
        'updated_at': now,
      },
    );
  }

  Future<void> reopenShortage({
    required String shortageId,
  }) async {
    final db = await DBService.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'material_shortages',
      {
        'status': 'reopened',
        'resolved_by': null,
        'resolved_at': null,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [shortageId],
    );

    await SyncService.instance.queueOperation(
      tableName: 'material_shortages',
      operation: 'update',
      recordId: shortageId,
      payload: {
        'id': shortageId,
        'status': 'reopened',
        'resolved_by': null,
        'resolved_at': null,
        'updated_at': now,
      },
    );
  }

  Future<void> deleteShortage(String id) async {
    final db = await DBService.instance.database;
    await db.delete(
      'material_shortages',
      where: 'id = ?',
      whereArgs: [id],
    );

    await SyncService.instance.queueOperation(
      tableName: 'material_shortages',
      operation: 'delete',
      recordId: id,
      payload: {'id': id},
    );
  }
}
