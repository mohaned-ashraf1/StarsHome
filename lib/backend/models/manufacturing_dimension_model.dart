import 'package:uuid/uuid.dart';

class ManufacturingDimensionModel {
  final String id;
  final String manufacturingOrderId;
  final double? height;
  final double? width;
  final double? depth;
  final String unit; // سم, م, مم
  final String? additionalNotes;
  final DateTime createdAt;

  ManufacturingDimensionModel({
    String? id,
    required this.manufacturingOrderId,
    this.height,
    this.width,
    this.depth,
    this.unit = 'سم',
    this.additionalNotes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get formattedDisplay {
    final parts = <String>[];
    if (height != null && height! > 0) parts.add('الارتفاع: $height $unit');
    if (width != null && width! > 0) parts.add('العرض: $width $unit');
    if (depth != null && depth! > 0) parts.add('العمق: $depth $unit');
    return parts.join(' × ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'manufacturing_order_id': manufacturingOrderId,
      'height': height,
      'width': width,
      'depth': depth,
      'unit': unit,
      'additional_notes': additionalNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ManufacturingDimensionModel.fromMap(Map<String, dynamic> map) {
    return ManufacturingDimensionModel(
      id: map['id']?.toString(),
      manufacturingOrderId: map['manufacturing_order_id']?.toString() ?? '',
      height: (map['height'] as num?)?.toDouble(),
      width: (map['width'] as num?)?.toDouble(),
      depth: (map['depth'] as num?)?.toDouble(),
      unit: map['unit']?.toString() ?? 'سم',
      additionalNotes: map['additional_notes']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
    );
  }
}
