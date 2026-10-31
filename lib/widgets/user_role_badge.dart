import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Reusable badge widget indicating whether an entry was recorded
/// by the Factory Owner (المالك) or the Factory Manager (المدير).
class UserRoleBadge extends StatelessWidget {
  final String? createdBy;
  final bool compact;

  const UserRoleBadge({
    super.key,
    required this.createdBy,
    this.compact = false,
  });

  /// Determines if the record creator is the Owner
  bool get isOwner {
    if (createdBy == null || createdBy!.isEmpty) return false;
    final lower = createdBy!.toLowerCase();
    return lower.contains('مالك') ||
        lower.contains('owner') ||
        lower.contains('himoonegm');
  }

  @override
  Widget build(BuildContext context) {
    final owner = isOwner;
    final roleTitle = owner ? 'المالك' : 'المدير';
    final roleColor = owner ? AppColors.accentGold : const Color(0xFF38BDF8); // Gold for Owner, Sky/Cyan for Manager
    final roleBgColor = roleColor.withOpacity(0.12);
    final roleBorderColor = roleColor.withOpacity(0.35);
    final icon = owner ? Icons.workspace_premium_outlined : Icons.badge_outlined;

    // Display string: e.g. "المالك (حسام)" or "المدير (مهند)" or "المالك" / "المدير"
    String displayText = roleTitle;
    final raw = createdBy?.trim() ?? '';
    if (!compact && raw.isNotEmpty) {
      if (raw.contains('(') && raw.contains(')')) {
        displayText = raw;
      } else if (raw != 'المالك' &&
          raw != 'المدير' &&
          raw != 'مالك المصنع' &&
          raw != 'مدير المصنع' &&
          raw != 'owner' &&
          raw != 'manager') {
        displayText = '$roleTitle ($raw)';
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: roleBgColor,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(color: roleBorderColor, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: compact ? 11 : 13, color: roleColor),
          const SizedBox(width: 4),
          Text(
            compact ? roleTitle : displayText,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.bold,
              color: roleColor,
            ),
          ),
        ],
      ),
    );
  }
}

