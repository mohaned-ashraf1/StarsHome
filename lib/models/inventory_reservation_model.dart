import 'package:uuid/uuid.dart';

class InventoryReservationModel {
  final String id;
  final String manufacturingOrderId;
  final String inventoryItemId;
  final double reservedQuantity;
  final String status; // active, released, consumed
  final DateTime createdAt;

  InventoryReservationModel({
    String? id,
    required this.manufacturingOrderId,
    required this.inventoryItemId,
    required this.reservedQuantity,
    this.status = 'active',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'manufacturing_order_id': manufacturingOrderId,
      'inventory_item_id': inventoryItemId,
      'reserved_quantity': reservedQuantity,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InventoryReservationModel.fromMap(Map<String, dynamic> map) {
    return InventoryReservationModel(
      id: map['id']?.toString(),
      manufacturingOrderId: map['manufacturing_order_id']?.toString() ?? '',
      inventoryItemId: map['inventory_item_id']?.toString() ?? '',
      reservedQuantity: (map['reserved_quantity'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? 'active',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
    );
  }
}
