import 'package:uuid/uuid.dart';

class PurchaseModel {
  final String id;
  final String itemName;
  final String category;
  final double? quantity;
  final double? unitPrice;
  final double totalAmount;
  final DateTime transactionDate;
  final String? notes;
  final String sourceType; // direct, worker_advance, worker_payroll, contractor_payment
  final String? sourceId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isReversed;
  final String syncStatus;

  PurchaseModel({
    String? id,
    required this.itemName,
    required this.category,
    this.quantity,
    this.unitPrice,
    required this.totalAmount,
    required this.transactionDate,
    this.notes,
    this.sourceType = 'direct',
    this.sourceId,
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isReversed = false,
    this.syncStatus = 'pending',
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_name': itemName,
      'category': category,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'transaction_date': transactionDate.toIso8601String().split('T')[0],
      'notes': notes,
      'source_type': sourceType,
      'source_id': sourceId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_reversed': isReversed ? 1 : 0,
      'sync_status': syncStatus,
    };
  }

  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    return PurchaseModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      itemName: map['item_name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'مصروفات عامة',
      quantity: map['quantity'] != null ? double.tryParse(map['quantity'].toString()) : null,
      unitPrice: map['unit_price'] != null ? double.tryParse(map['unit_price'].toString()) : null,
      totalAmount: double.tryParse(map['total_amount']?.toString() ?? '0') ?? 0.0,
      transactionDate: map['transaction_date'] != null
          ? DateTime.tryParse(map['transaction_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: map['notes']?.toString(),
      sourceType: map['source_type']?.toString() ?? 'direct',
      sourceId: map['source_id']?.toString(),
      createdBy: map['created_by']?.toString() ?? 'المدير',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
      isReversed: map['is_reversed'] == 1 || map['is_reversed'] == true,
      syncStatus: map['sync_status']?.toString() ?? 'synced',
    );
  }

  PurchaseModel copyWith({
    String? itemName,
    String? category,
    double? quantity,
    double? unitPrice,
    double? totalAmount,
    DateTime? transactionDate,
    String? notes,
    String? sourceType,
    String? sourceId,
    String? createdBy,
    bool? isReversed,
    String? syncStatus,
  }) {
    return PurchaseModel(
      id: id,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      notes: notes ?? this.notes,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isReversed: isReversed ?? this.isReversed,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
