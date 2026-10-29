import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/sync_service.dart';
import '../views/sync/sync_status_screen.dart';

/// Compact sync status indicator for app bars and headers.
/// Tapping opens the full SyncStatusScreen.
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: SyncService.instance.statusNotifier,
      builder: (context, status, child) {
        return ValueListenableBuilder<int>(
          valueListenable: SyncService.instance.pendingCountNotifier,
          builder: (context, pending, child) {
            return IconButton(
              tooltip: _label(status, pending),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SyncStatusScreen()),
              ),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(_icon(status), color: _color(status), size: 22),
                  if (pending > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.warningAmber,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            pending > 9 ? '9+' : '$pending',
                            style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _icon(SyncStatus s) {
    switch (s) {
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.synced:
        return Icons.cloud_done_outlined;
      case SyncStatus.pendingChanges:
        return Icons.cloud_upload_outlined;
      case SyncStatus.online:
        return Icons.cloud_outlined;
      case SyncStatus.offline:
        return Icons.cloud_off_outlined;
    }
  }

  Color _color(SyncStatus s) {
    switch (s) {
      case SyncStatus.syncing:
        return AppColors.accentGold;
      case SyncStatus.synced:
        return AppColors.incomeGreen;
      case SyncStatus.pendingChanges:
        return AppColors.warningAmber;
      case SyncStatus.online:
        return AppColors.textMuted;
      case SyncStatus.offline:
        return AppColors.textMuted;
    }
  }

  String _label(SyncStatus s, int pending) {
    switch (s) {
      case SyncStatus.syncing:
        return 'جاري المزامنة...';
      case SyncStatus.synced:
        return 'تمت المزامنة';
      case SyncStatus.pendingChanges:
        return '$pending عملية في الانتظار';
      case SyncStatus.online:
        return 'متصل';
      case SyncStatus.offline:
        return 'غير متصل (بيانات محلية)';
    }
  }
}
