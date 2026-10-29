import 'package:uuid/uuid.dart';

class MaterialShortageModel {
  final String id;
  final String materialName;
  final double? quantity;
  final String unit;
  final String? specifications;
  final String? notes;
  final String? manufacturingOrderId;
  final String? manufacturingOrderNumber;
  final String status; // 'shortage' (ناقص), 'in_progress' (جارٍ المتابعة), 'resolved' (تم الحل), 'reopened' (أعيد فتحه)
  final String recordedBy;
  final DateTime recordedAt;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime updatedAt;

  MaterialShortageModel({
    String? id,
    required this.materialName,
    this.quantity,
    this.unit = 'لوح',
    this.specifications,
    this.notes,
    this.manufacturingOrderId,
    this.manufacturingOrderNumber,
    this.status = 'shortage',
    required this.recordedBy,
    DateTime? recordedAt,
    this.resolvedBy,
    this.resolvedAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        recordedAt = recordedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isResolved => status == 'resolved';
  bool get isActive => status == 'shortage' || status == 'in_progress' || status == 'reopened';

  String get statusArabic {
    switch (status) {
      case 'shortage':
        return 'ناقص';
      case 'in_progress':
        return 'جارٍ المتابعة';
      case 'resolved':
        return 'تم الحل';
      case 'reopened':
        return 'أعيد فتحه';
      default:
        return status;
    }
  }

  String get quantityDisplay {
    if (quantity == null || quantity == 0) {
      return 'الكمية غير محددة';
    }
    // Format double cleanly (e.g. 3 or 3.5)
    final qStr = quantity! % 1 == 0 ? quantity!.toInt().toString() : quantity!.toString();
    return '$qStr $unit';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'material_name': materialName,
      'quantity': quantity,
      'unit': unit,
      'specifications': specifications,
      'notes': notes,
      'manufacturing_order_id': manufacturingOrderId,
      'manufacturing_order_number': manufacturingOrderNumber,
      'status': status,
      'recorded_by': recordedBy,
      'recorded_at': recordedAt.toIso8601String(),
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MaterialShortageModel.fromMap(Map<String, dynamic> map) {
    return MaterialShortageModel(
      id: map['id']?.toString(),
      materialName: map['material_name']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit']?.toString() ?? 'لوح',
      specifications: map['specifications']?.toString(),
      notes: map['notes']?.toString(),
      manufacturingOrderId: map['manufacturing_order_id']?.toString(),
      manufacturingOrderNumber: map['manufacturing_order_number']?.toString(),
      status: map['status']?.toString() ?? 'shortage',
      recordedBy: map['recorded_by']?.toString() ?? 'غير محدد',
      recordedAt: map['recorded_at'] != null ? DateTime.parse(map['recorded_at'].toString()) : DateTime.now(),
      resolvedBy: map['resolved_by']?.toString(),
      resolvedAt: map['resolved_at'] != null ? DateTime.parse(map['resolved_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'].toString()) : DateTime.now(),
    );
  }

  MaterialShortageModel copyWith({
    String? materialName,
    double? quantity,
    String? unit,
    String? specifications,
    String? notes,
    String? manufacturingOrderId,
    String? manufacturingOrderNumber,
    String? status,
    String? recordedBy,
    DateTime? recordedAt,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? updatedAt,
  }) {
    return MaterialShortageModel(
      id: id,
      materialName: materialName ?? this.materialName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      specifications: specifications ?? this.specifications,
      notes: notes ?? this.notes,
      manufacturingOrderId: manufacturingOrderId ?? this.manufacturingOrderId,
      manufacturingOrderNumber: manufacturingOrderNumber ?? this.manufacturingOrderNumber,
      status: status ?? this.status,
      recordedBy: recordedBy ?? this.recordedBy,
      recordedAt: recordedAt ?? this.recordedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
