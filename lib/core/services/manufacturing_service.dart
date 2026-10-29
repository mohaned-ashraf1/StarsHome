import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/manufacturing_order_model.dart';
import '../../models/manufacturing_dimension_model.dart';
import '../../models/manufacturing_material_model.dart';
import '../../models/manufacturing_checklist_item_model.dart';
import 'db_service.dart';
import 'sync_service.dart';

class ManufacturingService {
  static final ManufacturingService instance = ManufacturingService._internal();
  ManufacturingService._internal();

  Future<String> generateNextOrderNumber() async {
    try {
      final db = await DBService.instance.database;
      final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM manufacturing_orders');
      final count = Sqflite.firstIntValue(result) ?? 0;
      final nextNum = count + 101;
      return '#${nextNum.toString().padLeft(6, '0')}';
    } catch (_) {
      return '#000101';
    }
  }

  Future<List<ManufacturingOrderModel>> getAllOrders() async {
    try {
      final db = await DBService.instance.database;
      final ordersRows = await db.query('manufacturing_orders', orderBy: 'manufacturing_date DESC, created_at DESC');

      final List<ManufacturingOrderModel> orders = [];
      for (var row in ordersRows) {
        final orderId = row['id'].toString();

        // Dimensions
        final dimRows = await db.query('manufacturing_order_dimensions', where: 'manufacturing_order_id = ?', whereArgs: [orderId]);
        final dimensions = dimRows.isNotEmpty ? ManufacturingDimensionModel.fromMap(dimRows.first) : null;

        // Materials
        final matRows = await db.query('manufacturing_order_materials', where: 'manufacturing_order_id = ?', whereArgs: [orderId]);
        final materials = matRows.map((m) => ManufacturingMaterialModel.fromMap(m)).toList();

        // Checklist
        final checkRows = await db.query('manufacturing_checklist', where: 'manufacturing_order_id = ?', whereArgs: [orderId]);
        final checklist = checkRows.map((c) => ManufacturingChecklistItemModel.fromMap(c)).toList();

        orders.add(ManufacturingOrderModel.fromMap(
          row,
          dimensions: dimensions,
          materials: materials,
          checklist: checklist,
        ));
      }
      return orders;
    } catch (e) {
      debugPrint('Error getting manufacturing orders: $e');
      return [];
    }
  }

  Future<ManufacturingOrderModel?> getOrderById(String orderId) async {
    try {
      final db = await DBService.instance.database;
      final rows = await db.query('manufacturing_orders', where: 'id = ?', whereArgs: [orderId]);
      if (rows.isEmpty) return null;

      final dimRows = await db.query('manufacturing_order_dimensions', where: 'manufacturing_order_id = ?', whereArgs: [orderId]);
      final dimensions = dimRows.isNotEmpty ? ManufacturingDimensionModel.fromMap(dimRows.first) : null;

      final matRows = await db.query('manufacturing_order_materials', where: 'manufacturing_order_id = ?', whereArgs: [orderId]);
      final materials = matRows.map((m) => ManufacturingMaterialModel.fromMap(m)).toList();

      final checkRows = await db.query('manufacturing_checklist', where: 'manufacturing_order_id = ?', whereArgs: [orderId]);
      final checklist = checkRows.map((c) => ManufacturingChecklistItemModel.fromMap(c)).toList();

      return ManufacturingOrderModel.fromMap(
        rows.first,
        dimensions: dimensions,
        materials: materials,
        checklist: checklist,
      );
    } catch (e) {
      debugPrint('Error getting order by id: $e');
      return null;
    }
  }

  Future<ManufacturingOrderModel> createOrder({
    required ManufacturingOrderModel order,
    ManufacturingDimensionModel? dimensions,
    required List<ManufacturingMaterialModel> materials,
    bool autoReserveStock = true,
  }) async {
    final db = await DBService.instance.database;

    await db.transaction((txn) async {
      // 1. Insert order
      await txn.insert('manufacturing_orders', order.toMap());

      // 2. Insert dimensions if provided
      if (dimensions != null) {
        await txn.insert('manufacturing_order_dimensions', dimensions.toMap());
      }

      // 3. Insert materials & checklist items
      for (var mat in materials) {
        await txn.insert('manufacturing_order_materials', mat.toMap());

        final checklistItem = ManufacturingChecklistItemModel(
          manufacturingOrderId: order.id,
          materialName: mat.materialName,
          requiredQuantity: mat.requiredQuantity,
          unit: mat.unit,
          status: 'required',
          isPrepared: false,
        );
        await txn.insert('manufacturing_checklist', checklistItem.toMap());
      }
    });

    // Sync queue operations
    await SyncService.instance.queueOperation(
      tableName: 'manufacturing_orders',
      operation: 'insert',
      recordId: order.id,
      payload: order.toMap(),
    );

    if (dimensions != null) {
      await SyncService.instance.queueOperation(
        tableName: 'manufacturing_order_dimensions',
        operation: 'insert',
        recordId: dimensions.id,
        payload: dimensions.toMap(),
      );
    }

    for (var mat in materials) {
      await SyncService.instance.queueOperation(
        tableName: 'manufacturing_order_materials',
        operation: 'insert',
        recordId: mat.id,
        payload: mat.toMap(),
      );
    }

    // Auto-reserve stock is completely removed as per ERP specifications
    // Order creation never depends on or alters inventory balances.

    return (await getOrderById(order.id))!;
  }

  Future<void> updateChecklistItem({
    required String checklistId,
    required String newStatus, // required, ordered, received, prepared
    required bool isPrepared,
  }) async {
    final db = await DBService.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'manufacturing_checklist',
      {
        'status': newStatus,
        'is_prepared': isPrepared ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [checklistId],
    );

    await SyncService.instance.queueOperation(
      tableName: 'manufacturing_checklist',
      operation: 'update',
      recordId: checklistId,
      payload: {
        'id': checklistId,
        'status': newStatus,
        'is_prepared': isPrepared,
        'updated_at': now,
      },
    );
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    final db = await DBService.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'manufacturing_orders',
      {
        'status': newStatus,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );

    // Order status updated
    await SyncService.instance.queueOperation(
      tableName: 'manufacturing_orders',
      operation: 'update',
      recordId: orderId,
      payload: {
        'id': orderId,
        'status': newStatus,
        'updated_at': now,
      },
    );
  }

  // Workshop material preparation: Marks checklist as ready and sets order to in_progress
  Future<void> issueMaterialsToWorkshop({
    required String orderId,
    required String createdBy,
  }) async {
    final order = await getOrderById(orderId);
    if (order == null) return;

    // Mark all checklist items as prepared
    for (var chk in order.checklist) {
      await updateChecklistItem(
        checklistId: chk.id,
        newStatus: 'prepared',
        isPrepared: true,
      );
    }

    // Update order status to in_progress
    await updateOrderStatus(orderId: order.id, newStatus: 'in_progress');
  }

  Future<void> deleteOrder(String orderId) async {
    final db = await DBService.instance.database;
    await db.delete('manufacturing_orders', where: 'id = ?', whereArgs: [orderId]);

    await SyncService.instance.queueOperation(
      tableName: 'manufacturing_orders',
      operation: 'delete',
      recordId: orderId,
      payload: {'id': orderId},
    );
  }
}
