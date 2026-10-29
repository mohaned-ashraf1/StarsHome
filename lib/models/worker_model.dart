import 'package:uuid/uuid.dart';

class WorkerModel {
  final String id;
  final String fullName;
  final double dailyWage;
  final String standardStartTime;
  final String standardEndTime;
  final double overtimeHourlyRate;
  final String? phone;
  final String status; // active, inactive
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkerModel({
    String? id,
    required this.fullName,
    required this.dailyWage,
    this.standardStartTime = '08:00',
    this.standardEndTime = '19:00',
    required this.overtimeHourlyRate,
    this.phone,
    this.status = 'active',
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isActive => status == 'active';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'daily_wage': dailyWage,
      'standard_start_time': standardStartTime,
      'standard_end_time': standardEndTime,
      'overtime_hourly_rate': overtimeHourlyRate,
      'phone': phone,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WorkerModel.fromMap(Map<String, dynamic> map) {
    return WorkerModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      fullName: map['full_name']?.toString() ?? '',
      dailyWage: double.tryParse(map['daily_wage']?.toString() ?? '0') ?? 0.0,
      standardStartTime: map['standard_start_time']?.toString() ?? '08:00',
      standardEndTime: map['standard_end_time']?.toString() ?? '19:00',
      overtimeHourlyRate: double.tryParse(map['overtime_hourly_rate']?.toString() ?? '0') ?? 0.0,
      phone: map['phone']?.toString(),
      status: map['status']?.toString() ?? 'active',
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  WorkerModel copyWith({
    String? fullName,
    double? dailyWage,
    String? standardStartTime,
    String? standardEndTime,
    double? overtimeHourlyRate,
    String? phone,
    String? status,
    String? notes,
  }) {
    return WorkerModel(
      id: id,
      fullName: fullName ?? this.fullName,
      dailyWage: dailyWage ?? this.dailyWage,
      standardStartTime: standardStartTime ?? this.standardStartTime,
      standardEndTime: standardEndTime ?? this.standardEndTime,
      overtimeHourlyRate: overtimeHourlyRate ?? this.overtimeHourlyRate,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
