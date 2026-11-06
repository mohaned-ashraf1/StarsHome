import 'package:uuid/uuid.dart';

class ManufacturingMaterialModel {
  final String id;
  final String manufacturingOrderId;
  final String? inventoryItemId;
  final String materialName;
  final double requiredQuantity;
  final String unit;
  final String? specifications;
  final String? thicknessGrade; // e.g. 18مم, 6مم, درجة أولى
  final String? colorCode; // e.g. أبيض دوكو، رمادي 402، خشب أرو
  final String? linkedPiece; // Linked furniture piece or section name
  final String? notes;
  final DateTime createdAt;

  ManufacturingMaterialModel({
    String? id,
    required this.manufacturingOrderId,
    this.inventoryItemId,
    required this.materialName,
    required this.requiredQuantity,
    required this.unit,
    this.specifications,
    this.thicknessGrade,
    this.colorCode,
    this.linkedPiece,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get quantityDisplay {
    final qStr = requiredQuantity % 1 == 0
        ? requiredQuantity.toInt().toString()
        : requiredQuantity.toString();
    return '$qStr $unit';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'manufacturing_order_id': manufacturingOrderId,
      'inventory_item_id': inventoryItemId,
      'material_name': materialName,
      'required_quantity': requiredQuantity,
      'unit': unit,
      'specifications': specifications,
      'thickness_grade': thicknessGrade,
      'color_code': colorCode,
      'linked_piece': linkedPiece,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ManufacturingMaterialModel.fromMap(Map<String, dynamic> map) {
    return ManufacturingMaterialModel(
      id: map['id']?.toString(),
      manufacturingOrderId: map['manufacturing_order_id']?.toString() ?? '',
      inventoryItemId: map['inventory_item_id']?.toString(),
      materialName: map['material_name']?.toString() ?? '',
      requiredQuantity: (map['required_quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? 'لوح',
      specifications: map['specifications']?.toString(),
      thicknessGrade: map['thickness_grade']?.toString(),
      colorCode: map['color_code']?.toString(),
      linkedPiece: map['linked_piece']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
    );
  }

  ManufacturingMaterialModel copyWith({
    String? materialName,
    double? requiredQuantity,
    String? unit,
    String? specifications,
    String? thicknessGrade,
    String? colorCode,
    String? linkedPiece,
    String? notes,
  }) {
    return ManufacturingMaterialModel(
      id: id,
      manufacturingOrderId: manufacturingOrderId,
      inventoryItemId: inventoryItemId,
      materialName: materialName ?? this.materialName,
      requiredQuantity: requiredQuantity ?? this.requiredQuantity,
      unit: unit ?? this.unit,
      specifications: specifications ?? this.specifications,
      thicknessGrade: thicknessGrade ?? this.thicknessGrade,
      colorCode: colorCode ?? this.colorCode,
      linkedPiece: linkedPiece ?? this.linkedPiece,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
