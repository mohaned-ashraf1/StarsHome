import 'package:uuid/uuid.dart';

class ManufacturingChecklistItemModel {
  final String id;
  final String manufacturingOrderId;
  final String materialName;
  final double requiredQuantity;
  final String unit;
  final String status; // required (مطلوب), ordered (تم الطلب), received (تم الاستلام), prepared (تم التجهيز)
  final bool isPrepared;
  final String? notes;
  final DateTime updatedAt;

  ManufacturingChecklistItemModel({
    String? id,
    required this.manufacturingOrderId,
    required this.materialName,
    required this.requiredQuantity,
    required this.unit,
    this.status = 'required',
    this.isPrepared = false,
    this.notes,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now();

  String get statusArabic {
    switch (status) {
      case 'required':
        return 'مطلوب';
      case 'ordered':
        return 'تم الطلب';
      case 'received':
        return 'تم الاستلام';
      case 'prepared':
        return 'تم التجهيز';
      default:
        return status;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'manufacturing_order_id': manufacturingOrderId,
      'material_name': materialName,
      'required_quantity': requiredQuantity,
      'unit': unit,
      'status': status,
      'is_prepared': isPrepared ? 1 : 0,
      'notes': notes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ManufacturingChecklistItemModel.fromMap(Map<String, dynamic> map) {
    return ManufacturingChecklistItemModel(
      id: map['id']?.toString(),
      manufacturingOrderId: map['manufacturing_order_id']?.toString() ?? '',
      materialName: map['material_name']?.toString() ?? '',
      requiredQuantity: (map['required_quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? 'لوح',
      status: map['status']?.toString() ?? 'required',
      isPrepared: map['is_prepared'] == 1 || map['is_prepared'] == true,
      notes: map['notes']?.toString(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'].toString()) : DateTime.now(),
    );
  }

  ManufacturingChecklistItemModel copyWith({
    String? status,
    bool? isPrepared,
    String? notes,
  }) {
    return ManufacturingChecklistItemModel(
      id: id,
      manufacturingOrderId: manufacturingOrderId,
      materialName: materialName,
      requiredQuantity: requiredQuantity,
      unit: unit,
      status: status ?? this.status,
      isPrepared: isPrepared ?? this.isPrepared,
      notes: notes ?? this.notes,
      updatedAt: DateTime.now(),
    );
  }
}
