import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stars_home/backend/services/audit_service.dart';
import 'package:stars_home/frontend/constants/app_colors.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  bool _isLoading = true;
  List<AuditLogEntry> _logs = [];
  String _selectedModule = 'all';
  String _selectedRole = 'all';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final results = await AuditService.instance.getLogs(
      module: _selectedModule == 'all' ? null : _selectedModule,
      userRole: _selectedRole == 'all' ? null : _selectedRole,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _logs = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportCsv() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد سجلات لتصديرها.')),
      );
      return;
    }

    try {
      final csv = AuditService.instance.exportToCsv(_logs);
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/STARS_HOMES_ACTIVITY_LOG_$now.csv');
      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ سجل العمليات بنجاح: ${file.path}'),
            backgroundColor: AppColors.incomeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تصدير الملف: $e'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    }
  }

  Color _getModuleColor(String module) {
    switch (module) {
      case 'orders':
        return AppColors.accentGold;
      case 'workers':
        return Colors.purpleAccent;
      case 'accounts':
        return AppColors.incomeGreen;
      case 'inventory':
        return Colors.orangeAccent;
      case 'backup':
        return Colors.blueAccent;
      case 'auth':
        return AppColors.expenseRed;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('سجل العمليات والرقابة'),
        backgroundColor: AppColors.primaryNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'تصدير كملف CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث السجل',
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Header
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surfaceDark,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'بحث في السجلات (اسم المستخدم، نوع الإجراء، أو التفاصيل)...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: AppColors.accentGold, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              _loadLogs();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _loadLogs(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedModule,
                        dropdownColor: AppColors.surfaceDark,
                        style: const TextStyle(color: AppColors.accentGold, fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'القسم',
                          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          filled: true,
                          fillColor: AppColors.backgroundDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('كافة الأقسام')),
                          DropdownMenuItem(value: 'orders', child: Text('العملاء والطلبات')),
                          DropdownMenuItem(value: 'workers', child: Text('شؤون العمال')),
                          DropdownMenuItem(value: 'accounts', child: Text('المالية والحسابات')),
                          DropdownMenuItem(value: 'inventory', child: Text('المخزن والخامات')),
                          DropdownMenuItem(value: 'backup', child: Text('النسخ الاحتياطي')),
                          DropdownMenuItem(value: 'auth', child: Text('تسجيل الدخول والأمان')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedModule = val);
                            _loadLogs();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        dropdownColor: AppColors.surfaceDark,
                        style: const TextStyle(color: AppColors.accentGold, fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'الدور',
                          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          filled: true,
                          fillColor: AppColors.backgroundDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('الكل')),
                          DropdownMenuItem(value: 'owner', child: Text('مالك المصنع')),
                          DropdownMenuItem(value: 'manager', child: Text('مدير المصنع')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRole = val);
                            _loadLogs();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
                : _logs.isEmpty
                    ? const Center(
                        child: Text('لا توجد سجلات مطابقة لخيارات البحث.',
                            style: TextStyle(color: AppColors.textMuted)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: _logs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final log = _logs[i];
                          final modColor = _getModuleColor(log.module);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: modColor.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: modColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(log.moduleArabic,
                                          style: TextStyle(
                                              color: modColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        log.actionArabic,
                                        style: const TextStyle(
                                            color: AppColors.textWhite,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      log.createdAt.toString().substring(11, 16),
                                      style: const TextStyle(
                                          color: AppColors.accentGold, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline,
                                        size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${log.userName} (${log.userRole == "owner" ? "مالك المصنع" : "مدير المصنع"})',
                                      style: const TextStyle(
                                          color: AppColors.textMuted, fontSize: 11),
                                    ),
                                    const Spacer(),
                                    Text(
                                      log.createdAt.toString().substring(0, 10),
                                      style: const TextStyle(
                                          color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                                if (log.details != null && log.details!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundDark,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      log.details!,
                                      style: const TextStyle(
                                          color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

