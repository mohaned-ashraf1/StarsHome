import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../models/worker_model.dart';
import '../../providers/workers_provider.dart';

class AddWorkerDialog extends StatefulWidget {
  final WorkerModel? workerToEdit;
  const AddWorkerDialog({super.key, this.workerToEdit});

  @override
  State<AddWorkerDialog> createState() => _AddWorkerDialogState();
}

class _AddWorkerDialogState extends State<AddWorkerDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _wageController = TextEditingController();
  final TextEditingController _overtimeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Time stored internally as 24h for calculations, displayed as 12h
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    if (widget.workerToEdit != null) {
      final w = widget.workerToEdit!;
      _nameController.text = w.fullName;
      _wageController.text = w.dailyWage % 1 == 0 ? w.dailyWage.toInt().toString() : w.dailyWage.toString();
      _overtimeController.text = w.overtimeHourlyRate % 1 == 0 ? w.overtimeHourlyRate.toInt().toString() : w.overtimeHourlyRate.toString();
      _phoneController.text = w.phone ?? '';
      _notesController.text = w.notes ?? '';

      try {
        final startParts = w.standardStartTime.split(':');
        _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      } catch (_) {}
      try {
        final endParts = w.standardEndTime.split(':');
        _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
      } catch (_) {}
    }
  }

  /// Convert TimeOfDay → "HH:mm" 24h string for DB storage
  String _toDb(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Convert TimeOfDay → "hh:mm ص/م" for display
  String _toDisplay(TimeOfDay t) {
    return DateHelper.formatTimeStringTo12Hour(_toDb(t));
  }

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
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
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wageController.dispose();
    _overtimeController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workers = Provider.of<WorkersProvider>(context, listen: false);

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
                    Text(
                      widget.workerToEdit != null ? 'تعديل بيانات العامل' : 'إضافة عامل جديد للمصنع',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.surfaceBorder),
                const SizedBox(height: 12),

                // Full Name
                const Text('اسم العامل بالكامل *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'مثال: عادل محمد، إبراهيم حسن...',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.accentGold),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'يرجى كتابة اسم العامل' : null,
                ),
                const SizedBox(height: 14),

                // Daily Wage & Overtime Rate
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('أجر اليومية (ج.م) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _wageController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(hintText: 'مثال: 300'),
                            validator: (val) {
                              final d = double.tryParse(val ?? '');
                              if (d == null || d <= 0) return 'قيمة غير صحيحة';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('أجر ساعة الإضافي (ج.م) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _overtimeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(hintText: 'مثال: 45'),
                            validator: (val) {
                              final d = double.tryParse(val ?? '');
                              if (d == null || d < 0) return 'قيمة غير صحيحة';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Working Hours - 12h TimePicker
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('وقت الحضور الرسمي', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          _buildTimePicker(
                            label: _toDisplay(_startTime),
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
                          const Text('وقت الانصراف الرسمي', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          _buildTimePicker(
                            label: _toDisplay(_endTime),
                            icon: Icons.logout_rounded,
                            color: AppColors.warningAmber,
                            onTap: () => _pickTime(context, false),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Phone
                const Text('رقم الهاتف (اختياري)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '01xxxxxxxxx',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.accentGold),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'ملاحظات (المهنة، ورشة النجارة، التخصص)...',
                  ),
                ),
                const SizedBox(height: 22),

                // Buttons
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
                          if (_formKey.currentState!.validate()) {
                            final wage = double.parse(_wageController.text);
                            final overtime = double.parse(_overtimeController.text);

                            if (widget.workerToEdit != null) {
                              final updated = widget.workerToEdit!.copyWith(
                                fullName: _nameController.text.trim(),
                                dailyWage: wage,
                                overtimeHourlyRate: overtime,
                                standardStartTime: _toDb(_startTime),
                                standardEndTime: _toDb(_endTime),
                                phone: _phoneController.text.trim(),
                                notes: _notesController.text.trim(),
                              );
                              await workers.updateWorker(updated);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم تعديل بيانات العامل بنجاح')),
                                );
                              }
                            } else {
                              await workers.addWorker(
                                fullName: _nameController.text,
                                dailyWage: wage,
                                overtimeHourlyRate: overtime,
                                standardStartTime: _toDb(_startTime),
                                standardEndTime: _toDb(_endTime),
                                phone: _phoneController.text,
                                notes: _notesController.text,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تمت إضافة العامل بنجاح')),
                                );
                              }
                            }
                          }
                        },
                        child: Text(
                          widget.workerToEdit != null ? 'حفظ التعديلات' : 'حفظ العامل',
                          style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
                        ),
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
