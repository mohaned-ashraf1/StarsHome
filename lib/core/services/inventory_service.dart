import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/inventory_item_model.dart';
import '../../models/inventory_movement_model.dart';
import '../../models/inventory_reservation_model.dart';
import 'db_service.dart';
import 'sync_service.dart';

class InventoryService {
  static final InventoryService instance = InventoryService._internal();
  InventoryService._internal();

  Future<List<InventoryItemModel>> getAllItems() async {
    try {
      final db = await DBService.instance.database;
      final result = await db.query('inventory_items', orderBy: 'category ASC, material_name ASC');
      return result.map((m) => InventoryItemModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error getting inventory items: $e');
      return [];
    }
  }

  Future<InventoryItemModel?> getItemById(String id) async {
    try {
      final db = await DBService.instance.database;
      final result = await db.query('inventory_items', where: 'id = ?', whereArgs: [id]);
      if (result.isNotEmpty) {
        return InventoryItemModel.fromMap(result.first);
      }
    } catch (e) {
      debugPrint('Error getting inventory item by id: $e');
    }
    return null;
  }

  Future<InventoryItemModel?> getItemByName(String name) async {
    try {
      final db = await DBService.instance.database;
      final result = await db.query('inventory_items', where: 'material_name = ?', whereArgs: [name.trim()]);
      if (result.isNotEmpty) {
        return InventoryItemModel.fromMap(result.first);
      }
    } catch (e) {
      debugPrint('Error getting inventory item by name: $e');
    }
    return null;
  }

  Future<void> saveItem(InventoryItemModel item) async {
    final db = await DBService.instance.database;
    await db.insert('inventory_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await SyncService.instance.queueOperation(
      tableName: 'inventory_items',
      operation: 'insert',
      recordId: item.id,
      payload: item.toMap(),
    );
  }

  Future<void> deleteItem(String id) async {
    final db = await DBService.instance.database;
    await db.delete('inventory_items', where: 'id = ?', whereArgs: [id]);
    await SyncService.instance.queueOperation(
      tableName: 'inventory_items',
      operation: 'delete',
      recordId: id,
      payload: {'id': id},
    );
  }

  // Stock Movement Transaction
  Future<void> recordMovement({
    required String inventoryItemId,
    required String movementType, // receipt, issue, adjustment, return
    required double quantity,
    String? referenceType,
    String? referenceId,
    String? reasonNotes,
    required String createdBy,
  }) async {
    final db = await DBService.instance.database;
    final item = await getItemById(inventoryItemId);
    if (item == null) return;

    double newCurrentStock = item.currentStock;
    double newReservedStock = item.reservedStock;

    if (movementType == 'receipt') {
      newCurrentStock += quantity;
    } else if (movementType == 'issue') {
      newCurrentStock = (newCurrentStock - quantity) < 0 ? 0.0 : (newCurrentStock - quantity);
      // If issued for an order that had reservation, reduce reserved stock as well
      if (referenceType == 'manufacturing_order' && newReservedStock > 0) {
        newReservedStock = (newReservedStock - quantity) < 0 ? 0.0 : (newReservedStock - quantity);
      }
    } else if (movementType == 'adjustment') {
      newCurrentStock = quantity;
    } else if (movementType == 'return') {
      newCurrentStock += quantity;
    }

    final movement = InventoryMovementModel(
      inventoryItemId: inventoryItemId,
      movementType: movementType,
      quantity: quantity,
      referenceType: referenceType,
      referenceId: referenceId,
      reasonNotes: reasonNotes,
      createdBy: createdBy,
    );

    await db.transaction((txn) async {
      await txn.insert('inventory_movements', movement.toMap());
      await txn.update(
        'inventory_items',
        {
          'current_stock': newCurrentStock,
          'reserved_stock': newReservedStock,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [inventoryItemId],
      );
    });

    await SyncService.instance.queueOperation(
      tableName: 'inventory_movements',
      operation: 'insert',
      recordId: movement.id,
      payload: movement.toMap(),
    );

    await SyncService.instance.queueOperation(
      tableName: 'inventory_items',
      operation: 'update',
      recordId: inventoryItemId,
      payload: {
        'id': inventoryItemId,
        'current_stock': newCurrentStock,
        'reserved_stock': newReservedStock,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // Reserve stock for a manufacturing order
  Future<bool> reserveStockForOrder({
    required String manufacturingOrderId,
    required String inventoryItemId,
    required double quantityToReserve,
  }) async {
    final item = await getItemById(inventoryItemId);
    if (item == null) return false;

    // Available to promise = currentStock - reservedStock
    final available = item.availableStock;
    final qty = quantityToReserve > available ? available : quantityToReserve;
    if (qty <= 0) return false;

    final db = await DBService.instance.database;
    final reservation = InventoryReservationModel(
      manufacturingOrderId: manufacturingOrderId,
      inventoryItemId: inventoryItemId,
      reservedQuantity: qty,
      status: 'active',
    );

    final newReserved = item.reservedStock + qty;

    await db.transaction((txn) async {
      await txn.insert('inventory_reservations', reservation.toMap());
      await txn.update(
        'inventory_items',
        {
          'reserved_stock': newReserved,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [inventoryItemId],
      );
    });

    await SyncService.instance.queueOperation(
      tableName: 'inventory_reservations',
      operation: 'insert',
      recordId: reservation.id,
      payload: reservation.toMap(),
    );

    return true;
  }

  // Release all active reservations for an order
  Future<void> releaseReservationsForOrder(String manufacturingOrderId) async {
    final db = await DBService.instance.database;
    final reservations = await db.query(
      'inventory_reservations',
      where: 'manufacturing_order_id = ? AND status = ?',
      whereArgs: [manufacturingOrderId, 'active'],
    );

    for (var r in reservations) {
      final itemId = r['inventory_item_id'].toString();
      final qty = (r['reserved_quantity'] as num).toDouble();
      final item = await getItemById(itemId);
      if (item != null) {
        final newReserved = (item.reservedStock - qty) < 0 ? 0.0 : (item.reservedStock - qty);
        await db.update(
          'inventory_items',
          {'reserved_stock': newReserved, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [itemId],
        );
      }
      await db.update(
        'inventory_reservations',
        {'status': 'released'},
        where: 'id = ?',
        whereArgs: [r['id']],
      );
    }
  }

  Future<List<InventoryMovementModel>> getMovementsForItem(String inventoryItemId) async {
    try {
      final db = await DBService.instance.database;
      final result = await db.query(
        'inventory_movements',
        where: 'inventory_item_id = ?',
        whereArgs: [inventoryItemId],
        orderBy: 'created_at DESC',
      );
      return result.map((m) => InventoryMovementModel.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<InventoryMovementModel>> getAllMovements({int limit = 100}) async {
    try {
      final db = await DBService.instance.database;
      final result = await db.query(
        'inventory_movements',
        orderBy: 'created_at DESC',
        limit: limit,
      );
      return result.map((m) => InventoryMovementModel.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }
}
