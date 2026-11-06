import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'manufacturing_dimension_model.dart';
import 'manufacturing_material_model.dart';
import 'manufacturing_checklist_item_model.dart';
import 'furniture_section_model.dart';

class ManufacturingOrderModel {
  final String id;
  final String orderNumber; // e.g. #000101
  final String? customerOrderId;
  final String? customerName;
  final String productName; // e.g. 'غرفة نوم رئيسية + انتريه'
  final String productCategory;
  final int quantity;
  final DateTime manufacturingDate;
  final DateTime? expectedCompletionDate;
  final String? assignedWorkerId;
  final String? assignedWorkerName;
  final String status; // new, awaiting_materials, ready_to_build, in_progress, completed, cancelled
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Multi-section furniture architecture
  final List<FurnitureSectionModel> sections;

  // Associated loaded items (for backwards compatibility & checklists)
  final ManufacturingDimensionModel? dimensions;
  final List<ManufacturingMaterialModel> materials;
  final List<ManufacturingChecklistItemModel> checklist;

  ManufacturingOrderModel({
    String? id,
    required this.orderNumber,
    this.customerOrderId,
    this.customerName,
    required this.productName,
    this.productCategory = 'أثاث خشبي',
    this.quantity = 1,
    DateTime? manufacturingDate,
    this.expectedCompletionDate,
    this.assignedWorkerId,
    this.assignedWorkerName,
    this.status = 'new',
    this.notes,
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.sections = const [],
    this.dimensions,
    this.materials = const [],
    this.checklist = const [],
  })  : id = id ?? const Uuid().v4(),
        manufacturingDate = manufacturingDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get totalPiecesCount {
    if (sections.isNotEmpty) {
      final sum = sections.fold(0, (prev, s) => prev + s.totalPiecesCount);
      return sum > 0 ? sum : quantity;
    }
    return quantity;
  }

  String get displayTitle {
    if (sections.isNotEmpty) {
      final names = sections.map((s) => s.sectionName).where((n) => n.isNotEmpty).toList();
      if (names.isNotEmpty) {
        return names.join(' • ');
      }
    }
    return productName.isNotEmpty ? productName : 'أمر تصنيع بدون اسم';
  }

  String get statusArabic {
    switch (status) {
      case 'new':
        return 'جديد';
      case 'awaiting_materials':
        return 'في انتظار الخامات';
      case 'ready_to_build':
        return 'جاهز للتصنيع';
      case 'in_progress':
        return 'قيد التصنيع';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_order_id': customerOrderId,
      'customer_name': customerName,
      'product_name': productName,
      'product_category': productCategory,
      'quantity': quantity,
      'manufacturing_date': manufacturingDate.toIso8601String().split('T').first,
      'expected_completion_date': expectedCompletionDate?.toIso8601String().split('T').first,
      'assigned_worker_id': assignedWorkerId,
      'assigned_worker_name': assignedWorkerName,
      'status': status,
      'notes': notes,
      'sections_data': sections.isNotEmpty ? jsonEncode(sections.map((s) => s.toMap()).toList()) : null,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ManufacturingOrderModel.fromMap(Map<String, dynamic> map, {
    ManufacturingDimensionModel? dimensions,
    List<ManufacturingMaterialModel> materials = const [],
    List<ManufacturingChecklistItemModel> checklist = const [],
    List<FurnitureSectionModel>? sections,
  }) {
    List<FurnitureSectionModel> parsedSections = sections ?? [];
    if (parsedSections.isEmpty && map['sections_data'] != null && map['sections_data'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['sections_data'].toString()) as List;
        parsedSections = decoded
            .map((s) => FurnitureSectionModel.fromMap(Map<String, dynamic>.from(s as Map)))
            .toList();
      } catch (_) {}
    }

    return ManufacturingOrderModel(
      id: map['id']?.toString(),
      orderNumber: map['order_number']?.toString() ?? '',
      customerOrderId: map['customer_order_id']?.toString(),
      customerName: map['customer_name']?.toString(),
      productName: map['product_name']?.toString() ?? '',
      productCategory: map['product_category']?.toString() ?? 'أثاث خشبي',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      manufacturingDate: map['manufacturing_date'] != null
          ? DateTime.parse(map['manufacturing_date'].toString())
          : DateTime.now(),
      expectedCompletionDate: map['expected_completion_date'] != null
          ? DateTime.parse(map['expected_completion_date'].toString())
          : null,
      assignedWorkerId: map['assigned_worker_id']?.toString(),
      assignedWorkerName: map['assigned_worker_name']?.toString(),
      status: map['status']?.toString() ?? 'new',
      notes: map['notes']?.toString(),
      sections: parsedSections,
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'].toString()) : DateTime.now(),
      dimensions: dimensions,
      materials: materials,
      checklist: checklist,
    );
  }

  ManufacturingOrderModel copyWith({
    String? status,
    String? assignedWorkerId,
    String? assignedWorkerName,
    DateTime? expectedCompletionDate,
    String? notes,
    List<FurnitureSectionModel>? sections,
    ManufacturingDimensionModel? dimensions,
    List<ManufacturingMaterialModel>? materials,
    List<ManufacturingChecklistItemModel>? checklist,
  }) {
    return ManufacturingOrderModel(
      id: id,
      orderNumber: orderNumber,
      customerOrderId: customerOrderId,
      customerName: customerName,
      productName: productName,
      productCategory: productCategory,
      quantity: quantity,
      manufacturingDate: manufacturingDate,
      expectedCompletionDate: expectedCompletionDate ?? this.expectedCompletionDate,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      assignedWorkerName: assignedWorkerName ?? this.assignedWorkerName,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      sections: sections ?? this.sections,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      dimensions: dimensions ?? this.dimensions,
      materials: materials ?? this.materials,
      checklist: checklist ?? this.checklist,
    );
  }
}
