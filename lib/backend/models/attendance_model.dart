import 'package:uuid/uuid.dart';

class AttendanceModel {
  final String id;
  final String workerId;
  final DateTime attendanceDate;
  final String status; // present, absent, leave
  final String? arrivalTime;
  final String? departureTime;
  final int totalDurationMinutes;
  final int overtimeDurationMinutes;
  final double overtimePay;
  final double dailyWageApplied;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceModel({
    String? id,
    required this.workerId,
    required this.attendanceDate,
    required this.status,
    this.arrivalTime,
    this.departureTime,
    this.totalDurationMinutes = 0,
    this.overtimeDurationMinutes = 0,
    this.overtimePay = 0.0,
    required this.dailyWageApplied,
    this.notes,
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get overtimeHours => double.parse((overtimeDurationMinutes / 60.0).toStringAsFixed(2));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'attendance_date': attendanceDate.toIso8601String().split('T')[0],
      'status': status,
      'arrival_time': arrivalTime,
      'departure_time': departureTime,
      'total_duration_minutes': totalDurationMinutes,
      'overtime_duration_minutes': overtimeDurationMinutes,
      'overtime_pay': overtimePay,
      'daily_wage_applied': dailyWageApplied,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      workerId: map['worker_id']?.toString() ?? '',
      attendanceDate: map['attendance_date'] != null
          ? DateTime.tryParse(map['attendance_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: map['status']?.toString() ?? 'present',
      arrivalTime: map['arrival_time']?.toString(),
      departureTime: map['departure_time']?.toString(),
      totalDurationMinutes: int.tryParse(map['total_duration_minutes']?.toString() ?? '0') ?? 0,
      overtimeDurationMinutes: int.tryParse(map['overtime_duration_minutes']?.toString() ?? '0') ?? 0,
      overtimePay: double.tryParse(map['overtime_pay']?.toString() ?? '0') ?? 0.0,
      dailyWageApplied: double.tryParse(map['daily_wage_applied']?.toString() ?? '0') ?? 0.0,
      notes: map['notes']?.toString(),
      createdBy: map['created_by']?.toString() ?? 'المدير',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }
}
