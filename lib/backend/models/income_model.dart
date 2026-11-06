import 'package:uuid/uuid.dart';

class IncomeModel {
  final String id;
  final String sourceName;
  final double amount;
  final DateTime transactionDate;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isReversed;
  final String syncStatus;

  IncomeModel({
    String? id,
    required this.sourceName,
    required this.amount,
    required this.transactionDate,
    this.notes,
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
      'source_name': sourceName,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String().split('T')[0],
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_reversed': isReversed ? 1 : 0,
      'sync_status': syncStatus,
    };
  }

  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      sourceName: map['source_name']?.toString() ?? '',
      amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
      transactionDate: map['transaction_date'] != null
          ? DateTime.tryParse(map['transaction_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: map['notes']?.toString(),
      createdBy: map['created_by']?.toString() ?? 'المدير',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
      isReversed: map['is_reversed'] == 1 || map['is_reversed'] == true,
      syncStatus: map['sync_status']?.toString() ?? 'synced',
    );
  }

  IncomeModel copyWith({
    String? sourceName,
    double? amount,
    DateTime? transactionDate,
    String? notes,
    String? createdBy,
    bool? isReversed,
    String? syncStatus,
  }) {
    return IncomeModel(
      id: id,
      sourceName: sourceName ?? this.sourceName,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isReversed: isReversed ?? this.isReversed,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
