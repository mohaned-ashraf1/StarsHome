import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../models/worker_model.dart';
import '../../providers/workers_provider.dart';
import '../../providers/auth_provider.dart';

/// Convert TimeOfDay → "HH:mm" 24h string for DB/calculations
String _tod24(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class RecordAttendanceDialog extends StatefulWidget {
  const RecordAttendanceDialog({super.key});

  @override
  State<RecordAttendanceDialog> createState() => _RecordAttendanceDialogState();
}

class _RecordAttendanceDialogState extends State<RecordAttendanceDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedWorkerId;
  String _selectedStatus = 'present'; // present, absent, leave
  late DateTime _selectedDate;

  // Time stored as TimeOfDay internally, displayed in 12h, saved to DB as 24h
  TimeOfDay _arrivalTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _departureTime = const TimeOfDay(hour: 19, minute: 0);
  final TextEditingController _notesController = TextEditingController();

  double _previewOvertimeHours = 0.0;
  double _previewOvertimePay = 0.0;

  Future<void> _pickTime(BuildContext context, bool isArrival) async {
    final initial = isArrival ? _arrivalTime : _departureTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isArrival) {
          _arrivalTime = picked;
        } else {
          _departureTime = picked;
        }
      });
      _updateOvertimePreview();
    }
  }

  @override
  void initState() {
    super.initState();
    final workers = Provider.of<WorkersProvider>(context, listen: false);
    _selectedDate = workers.selectedAttendanceDate;
    if (workers.activeWorkers.isNotEmpty) {
      _selectedWorkerId = workers.activeWorkers.first.id;
      _updateOvertimePreview();
    }
    // No listener needed - _pickTime calls _updateOvertimePreview directly
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateOvertimePreview() {
    if (_selectedStatus != 'present' || _selectedWorkerId == null) {
      setState(() {
        _previewOvertimeHours = 0.0;
        _previewOvertimePay = 0.0;
      });
      return;
    }

    final workers = Provider.of<WorkersProvider>(context, listen: false);
    final worker = workers.workers.firstWhere((w) => w.id == _selectedWorkerId, orElse: () => WorkerModel(fullName: '', dailyWage: 0, overtimeHourlyRate: 0));

    final hours = DateHelper.calculateOvertimeHours(
      standardEndTimeStr: worker.standardEndTime,
      actualDepartureTimeStr: _tod24(_departureTime),
    );
    final pay = hours * worker.overtimeHourlyRate;

    setState(() {
      _previewOvertimeHours = hours;
      _previewOvertimePay = pay;
    });
  }

  @override
  Widget build(BuildContext context) {
    final workers = Provider.of<WorkersProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (workers.activeWorkers.isEmpty) {
      return AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('تنبيه'),
        content: const Text('لا يوجد عمال نشطين. يرجى إضافة عمال أولاً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      );
    }

    final selectedWorker = workers.workers.firstWhere((w) => w.id == _selectedWorkerId, orElse: () => workers.activeWorkers.first);

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تسجيل حضور وانصراف عامل',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.surfaceBorder),
                const SizedBox(height: 12),

                // Select Worker
                const Text('اختر العامل *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedWorkerId,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceDark,
                      items: workers.activeWorkers.map((w) {
                        return DropdownMenuItem(
                          value: w.id,
                          child: Text('${w.fullName} (اليومية: ${CurrencyFormatter.format(w.dailyWage)})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedWorkerId = val);
                          _updateOvertimePreview();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Date Picker
                const Text('تاريخ اليوم', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateHelper.formatDisplay(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.accentGold),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Status
                const Text('حالة الحضور *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildStatusChip('present', 'حاضر', AppColors.incomeGreen),
                    const SizedBox(width: 8),
                    _buildStatusChip('absent', 'غائب', AppColors.expenseRed),
                    const SizedBox(width: 8),
                    _buildStatusChip('leave', 'إجازة', AppColors.warningAmber),
                  ],
                ),
                const SizedBox(height: 16),

                if (_selectedStatus == 'present') ...[
                  // Times - 12h pickers
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('وقت الحضور الفعلي', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            const SizedBox(height: 6),
                            _buildTimePicker(
                              label: DateHelper.formatTimeStringTo12Hour(_tod24(_arrivalTime)),
                              icon: Icons.login_rounded,
                              color: AppColors.incomeGreen,
                              onTap: () => _pickTime(context, true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('وقت الانصراف الفعلي', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            const SizedBox(height: 6),
                            _buildTimePicker(
                              label: DateHelper.formatTimeStringTo12Hour(_tod24(_departureTime)),
                              icon: Icons.logout_rounded,
                              color: AppColors.warningAmber,
                              onTap: () => _pickTime(context, false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Realtime Overtime Calculation Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.infoBlue.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الانصراف الرسمي للعامل: ${DateHelper.formatTimeStringTo12Hour(selectedWorker.standardEndTime)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ساعات الإضافي المحسوبة: $_previewOvertimeHours ساعة',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.infoBlue),
                            ),
                          ],
                        ),
                        Text(
                          'مستحق الإضافي: ${CurrencyFormatter.format(_previewOvertimePay)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(hintText: 'ملاحظات الحضور / التأخير...'),
                ),
                const SizedBox(height: 22),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && _selectedWorkerId != null) {
                            await workers.recordAttendance(
                              workerId: _selectedWorkerId!,
                              date: _selectedDate,
                              status: _selectedStatus,
                              arrivalTime: _selectedStatus == 'present' ? _tod24(_arrivalTime) : null,
                              departureTime: _selectedStatus == 'present' ? _tod24(_departureTime) : null,
                              notes: _notesController.text,
                              createdBy: auth.currentUser?.fullName ?? 'المدير',
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم تسجيل الحضور واحتساب الإضافي بنجاح')),
                              );
                            }
                          }
                        },
                        child: const Text('تأكيد وحفظ', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String statusKey, String label, Color color) {
    final isSelected = _selectedStatus == statusKey;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatus = statusKey;
          });
          _updateOvertimePreview();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : AppColors.surfaceBorder, width: isSelected ? 1.5 : 1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryNavy,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
            Icon(icon, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}
