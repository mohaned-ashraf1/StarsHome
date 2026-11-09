import 'package:uuid/uuid.dart';

class ContractorModel {
  final String id;
  final String name;
  final String serviceType; // الدهان, التنجيد, القشرة, etc.
  final String? phone;
  final String? notes;
  final String status; // active, inactive
  final DateTime createdAt;
  final DateTime updatedAt;

  ContractorModel({
    String? id,
    required this.name,
    required this.serviceType,
    this.phone,
    this.notes,
    this.status = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isActive => status == 'active';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'service_type': serviceType,
      'phone': phone,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ContractorModel.fromMap(Map<String, dynamic> map) {
    return ContractorModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      name: map['name']?.toString() ?? '',
      serviceType: map['service_type']?.toString() ?? 'ورشة خارجية',
      phone: map['phone']?.toString(),
      notes: map['notes']?.toString(),
      status: map['status']?.toString() ?? 'active',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  ContractorModel copyWith({
    String? name,
    String? serviceType,
    String? phone,
    String? notes,
    String? status,
  }) {
    return ContractorModel(
      id: id,
      name: name ?? this.name,
      serviceType: serviceType ?? this.serviceType,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
