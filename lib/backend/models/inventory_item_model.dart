import 'package:uuid/uuid.dart';

class InventoryItemModel {
  final String id;
  final String materialName;
  final String category;
  final String unit; // لوح, متر, قطعة, كجم, لفة, طقم
  final double currentStock; // On-hand stock
  final double reservedStock; // Reserved for active manufacturing orders
  final double minimumStockLevel;
  final double unitCost;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItemModel({
    String? id,
    required this.materialName,
    required this.category,
    this.unit = 'لوح',
    this.currentStock = 0.0,
    this.reservedStock = 0.0,
    this.minimumStockLevel = 0.0,
    this.unitCost = 0.0,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Available to Promise = On-hand - Reserved
  double get availableStock => (currentStock - reservedStock) < 0 ? 0.0 : (currentStock - reservedStock);

  // Shortage for a required amount = max(required - available, 0)
  double calculateShortage(double requiredQty) {
    final shortage = requiredQty - availableStock;
    return shortage > 0 ? shortage : 0.0;
  }

  bool get isLowStock => currentStock <= minimumStockLevel && minimumStockLevel > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'material_name': materialName,
      'category': category,
      'unit': unit,
      'current_stock': currentStock,
      'reserved_stock': reservedStock,
      'minimum_stock_level': minimumStockLevel,
      'unit_cost': unitCost,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InventoryItemModel.fromMap(Map<String, dynamic> map) {
    return InventoryItemModel(
      id: map['id']?.toString(),
      materialName: map['material_name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'أخشاب ومواد خام',
      unit: map['unit']?.toString() ?? 'لوح',
      currentStock: (map['current_stock'] as num?)?.toDouble() ?? 0.0,
      reservedStock: (map['reserved_stock'] as num?)?.toDouble() ?? 0.0,
      minimumStockLevel: (map['minimum_stock_level'] as num?)?.toDouble() ?? 0.0,
      unitCost: (map['unit_cost'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'].toString()) : DateTime.now(),
    );
  }

  InventoryItemModel copyWith({
    String? materialName,
    String? category,
    String? unit,
    double? currentStock,
    double? reservedStock,
    double? minimumStockLevel,
    double? unitCost,
    String? notes,
    DateTime? updatedAt,
  }) {
    return InventoryItemModel(
      id: id,
      materialName: materialName ?? this.materialName,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      reservedStock: reservedStock ?? this.reservedStock,
      minimumStockLevel: minimumStockLevel ?? this.minimumStockLevel,
      unitCost: unitCost ?? this.unitCost,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
