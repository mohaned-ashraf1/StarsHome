import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/db_service.dart';
import '../../core/services/sync_service.dart';

/// Full sync status screen showing:
/// - Current sync status
/// - Pending operations (queued, not yet uploaded)
/// - Failed operations (exceeded retry limit)
/// - Completed operations (recent)
/// - Manual retry and force sync controls
class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  List<Map<String, dynamic>> _pendingItems = [];
  List<Map<String, dynamic>> _failedItems = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadQueueItems();
  }

  Future<void> _loadQueueItems() async {
    setState(() => _isLoading = true);
    try {
      final db = await DBService.instance.database;
      final pending = await db.query(
        'sync_queue',
        where: "status = 'pending'",
        orderBy: 'created_at ASC',
        limit: 100,
      );
      final failed = await db.query(
        'sync_queue',
        where: "status = 'failed'",
        orderBy: 'created_at DESC',
        limit: 50,
      );
      setState(() {
        _pendingItems = pending;
        _failedItems = failed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _retryFailed() async {
    try {
      final db = await DBService.instance.database;
      // Reset failed items to pending for retry
      await db.rawUpdate(
        "UPDATE sync_queue SET status = 'pending', retry_count = 0, last_error = NULL "
        "WHERE status = 'failed'",
      );
      await _loadQueueItems();
      await SyncService.instance.checkPendingQueueCount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة تعيين العمليات الفاشلة للإعادة المحاولة'),
            backgroundColor: AppColors.incomeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _retryItem(String id) async {
    try {
      final db = await DBService.instance.database;
      await db.rawUpdate(
        "UPDATE sync_queue SET status = 'pending', retry_count = 0, last_error = NULL WHERE id = ?",
        [id],
      );
      await _loadQueueItems();
    } catch (e) {
      debugPrint('Retry item error: $e');
    }
  }

  Future<void> _discardItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('تجاهل العملية؟'),
        content: const Text(
          'سيتم حذف هذه العملية من قائمة الانتظار. '
          'لن تُرسَل إلى السيرفر. تأكد أن البيانات محفوظة محلياً قبل التجاهل.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تجاهل',
                  style: TextStyle(color: AppColors.expenseRed))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final db = await DBService.instance.database;
      await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
      await _loadQueueItems();
      await SyncService.instance.checkPendingQueueCount();
    } catch (e) {
      debugPrint('Discard item error: $e');
    }
  }

  Future<void> _forceSyncNow() async {
    setState(() => _isSyncing = true);
    final success = await SyncService.instance.syncNow();
    await _loadQueueItems();
    setState(() => _isSyncing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'تمت المزامنة بنجاح'
              : 'تعذرت المزامنة — يرجى التحقق من الاتصال'),
          backgroundColor: success ? AppColors.incomeGreen : AppColors.expenseRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('حالة المزامنة'),
        backgroundColor: AppColors.primaryNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _loadQueueItems,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : RefreshIndicator(
              onRefresh: _loadQueueItems,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildSyncButton(),
                  const SizedBox(height: 24),
                  if (_pendingItems.isNotEmpty) ...[
                    _buildSectionHeader(
                        'في الانتظار (${_pendingItems.length})',
                        Icons.cloud_upload_outlined,
                        AppColors.warningAmber),
                    const SizedBox(height: 8),
                    ..._pendingItems.map(_buildPendingTile),
                    const SizedBox(height: 24),
                  ],
                  if (_failedItems.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildSectionHeader(
                              'فاشلة (${_failedItems.length})',
                              Icons.error_outline,
                              AppColors.expenseRed),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.replay, size: 16,
                              color: AppColors.accentGold),
                          label: const Text('إعادة الكل',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.accentGold)),
                          onPressed: _retryFailed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._failedItems.map(_buildFailedTile),
                  ],
                  if (_pendingItems.isEmpty && _failedItems.isEmpty)
                    _buildEmptyState(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: SyncService.instance.statusNotifier,
      builder: (context, status, child) {
        final (icon, color, label, desc) = _statusInfo(status);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(desc,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSyncButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryNavy,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _isSyncing ? null : _forceSyncNow,
      icon: _isSyncing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primaryNavy))
          : const Icon(Icons.sync),
      label: Text(_isSyncing ? 'جاري المزامنة...' : 'مزامنة الآن',
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildPendingTile(Map<String, dynamic> item) {
    return _buildQueueTile(
      item: item,
      color: AppColors.warningAmber,
      icon: Icons.upload_outlined,
      showRetry: false,
    );
  }

  Widget _buildFailedTile(Map<String, dynamic> item) {
    return _buildQueueTile(
      item: item,
      color: AppColors.expenseRed,
      icon: Icons.error_outline,
      showRetry: true,
    );
  }

  Widget _buildQueueTile({
    required Map<String, dynamic> item,
    required Color color,
    required IconData icon,
    required bool showRetry,
  }) {
    final table = item['table_name'] as String? ?? '';
    final op = item['operation'] as String? ?? '';
    final retries = item['retry_count'] as int? ?? 0;
    final lastError = item['last_error'] as String?;
    final id = item['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(_tableLabel(table),
                  style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _opColor(op).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_opLabel(op),
                    style: TextStyle(
                        color: _opColor(op),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              if (showRetry) ...[
                IconButton(
                  icon: const Icon(Icons.replay,
                      size: 18, color: AppColors.accentGold),
                  tooltip: 'إعادة المحاولة',
                  onPressed: () => _retryItem(id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.expenseRed),
                  tooltip: 'تجاهل',
                  onPressed: () => _discardItem(id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          if (retries > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('محاولات: $retries',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
            ),
          if (lastError != null && lastError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'خطأ: ${lastError.length > 80 ? '${lastError.substring(0, 80)}...' : lastError}',
                style: const TextStyle(
                    color: AppColors.expenseRed, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.cloud_done_outlined,
                size: 56, color: AppColors.incomeGreen),
            const SizedBox(height: 12),
            const Text('لا توجد عمليات معلّقة',
                style: TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              SyncService.instance.isConfigured
                  ? 'جميع البيانات مزامنة مع السيرفر'
                  : 'الجهاز يعمل بشكل محلي (لا يوجد إعداد Supabase)',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String, String) _statusInfo(SyncStatus s) {
    switch (s) {
      case SyncStatus.syncing:
        return (Icons.sync, AppColors.accentGold, 'جاري المزامنة',
            'يتم رفع وتنزيل البيانات...');
      case SyncStatus.synced:
        return (Icons.cloud_done_outlined, AppColors.incomeGreen,
            'مزامنة كاملة', 'جميع البيانات متطابقة مع السيرفر');
      case SyncStatus.pendingChanges:
        return (Icons.cloud_upload_outlined, AppColors.warningAmber,
            'تغييرات في الانتظار',
            'هناك بيانات لم تُرسَل إلى السيرفر بعد');
      case SyncStatus.online:
        return (Icons.cloud_outlined, AppColors.textMuted, 'متصل',
            'جاهز للمزامنة');
      case SyncStatus.offline:
        return (Icons.cloud_off_outlined, AppColors.textMuted, 'غير متصل',
            'البيانات تُحفَظ محلياً وستُزامَن لاحقاً');
    }
  }

  String _tableLabel(String t) {
    const labels = {
      'purchases': 'مشتريات',
      'incomes': 'إيرادات',
      'workers': 'عمال',
      'worker_attendance': 'حضور',
      'worker_financial_items': 'بنود مالية',
      'worker_payroll_settlements': 'تسويات رواتب',
      'contractors': 'مقاولون',
      'contractor_payments': 'دفعات مقاولين',
      'debts_advances': 'ديون وسلف',
      'debt_advance_payments': 'سداد ديون',
      'customer_orders': 'طلبات عملاء',
      'order_payments': 'دفعات طلبات',
      'inventory_items': 'مخزون',
      'inventory_movements': 'حركة مخزون',
      'manufacturing_orders': 'أوامر تصنيع',
      'material_shortages': 'نقص مواد',
    };
    return labels[t] ?? t;
  }

  String _opLabel(String op) {
    switch (op) {
      case 'insert':
        return 'إضافة';
      case 'update':
        return 'تعديل';
      case 'delete':
        return 'حذف';
      default:
        return op;
    }
  }

  Color _opColor(String op) {
    switch (op) {
      case 'insert':
        return AppColors.incomeGreen;
      case 'update':
        return AppColors.accentGold;
      case 'delete':
        return AppColors.expenseRed;
      default:
        return AppColors.textMuted;
    }
  }
}
