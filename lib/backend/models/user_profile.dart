class UserProfile {
  final String id;
  final String fullName;
  final String role; // 'owner' or 'manager'
  final String? phone;
  final bool isActive;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
    this.isActive = true,
  });

  bool get isOwner => role == 'owner';
  bool get isManager => role == 'manager';

  String get roleArabicName => isOwner ? 'مالك المصنع' : 'مدير المصنع';

  /// Returns a clean signature string to store in `created_by`
  /// e.g. "المالك (حسام)" or "المدير (مهند)" or simply "المالك" / "المدير"
  String get signature {
    final roleName = isOwner ? 'المالك' : 'المدير';
    final trimmedName = fullName.trim();
    if (trimmedName.isNotEmpty &&
        trimmedName != 'مالك المصنع' &&
        trimmedName != 'مدير المصنع' &&
        trimmedName != 'المالك' &&
        trimmedName != 'المدير') {
      return '$roleName ($trimmedName)';
    }
    return roleName;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      role: map['role']?.toString() ?? 'manager',
      phone: map['phone']?.toString(),
      isActive: map['is_active'] == 1 || map['is_active'] == true,
    );
  }
}
