import 'package:uuid/uuid.dart';

class InventoryMovementModel {
  final String id;
  final String inventoryItemId;
  final String movementType; // receipt (وارد), issue (صرف), adjustment (تسوية), reservation, reservation_release, return (مرتجع)
  final double quantity;
  final String? referenceType; // purchase, manufacturing_order, manual_adjustment, return
  final String? referenceId;
  final String? reasonNotes;
  final String createdBy;
  final DateTime createdAt;

  InventoryMovementModel({
    String? id,
    required this.inventoryItemId,
    required this.movementType,
    required this.quantity,
    this.referenceType,
    this.referenceId,
    this.reasonNotes,
    required this.createdBy,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get movementTypeArabic {
    switch (movementType) {
      case 'receipt':
        return 'إيداع / وارد';
      case 'issue':
        return 'صرف للتشغيل';
      case 'adjustment':
        return 'تسوية جرد';
      case 'reservation':
        return 'حجز لأمر تصنيع';
      case 'reservation_release':
        return 'إلغاء حجز';
      case 'return':
        return 'مرتجع للمخزن';
      default:
        return movementType;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inventory_item_id': inventoryItemId,
      'movement_type': movementType,
      'quantity': quantity,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'reason_notes': reasonNotes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InventoryMovementModel.fromMap(Map<String, dynamic> map) {
    return InventoryMovementModel(
      id: map['id']?.toString(),
      inventoryItemId: map['inventory_item_id']?.toString() ?? '',
      movementType: map['movement_type']?.toString() ?? 'receipt',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      referenceType: map['reference_type']?.toString(),
      referenceId: map['reference_id']?.toString(),
      reasonNotes: map['reason_notes']?.toString(),
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
    );
  }
}
