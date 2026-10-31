import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../models/income_model.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';

class AddIncomeDialog extends StatefulWidget {
  final IncomeModel? incomeToEdit;
  const AddIncomeDialog({super.key, this.incomeToEdit});

  @override
  State<AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends State<AddIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.incomeToEdit != null) {
      final inc = widget.incomeToEdit!;
      _sourceController.text = inc.sourceName;
      _amountController.text = inc.amount % 1 == 0 ? inc.amount.toInt().toString() : inc.amount.toString();
      _notesController.text = inc.notes ?? '';
      _selectedDate = inc.transactionDate;
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = Provider.of<AccountsProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
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
                      widget.incomeToEdit != null ? 'تعديل بيانات الإيراد' : 'تسجيل داخل / مقبوضات نقدية',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.incomeGreen),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.surfaceBorder),
                const SizedBox(height: 12),

                // Source Name
                const Text('مصدر أو بيان الإيراد *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _sourceController,
                  decoration: const InputDecoration(
                    hintText: 'مثال: دفعة عميل أ/ أحمد (غرفة نوم)، عربون صالون...',
                    prefixIcon: Icon(Icons.account_balance_outlined, color: AppColors.incomeGreen, size: 20),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'يرجى كتابة بيان الإيراد' : null,
                ),
                const SizedBox(height: 14),

                // Amount
                const Text('المبلغ المحصل (ج.م) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.incomeGreen)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.incomeGreen),
                  decoration: const InputDecoration(
                    hintText: 'المبلغ بالجنية المصري',
                    prefixIcon: Icon(Icons.payments_outlined, color: AppColors.incomeGreen),
                  ),
                  validator: (val) {
                    final d = double.tryParse(val ?? '');
                    if (d == null || d <= 0) return 'يرجى كتابة مبلغ صحيح أكبر من صفر';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Date Picker
                const Text('تاريخ الاستلام', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.incomeGreen,
                            onPrimary: AppColors.primaryNavy,
                            surface: AppColors.surfaceDark,
                          ),
                        ),
                        child: child!,
                      ),
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
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.incomeGreen),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'ملاحظات إضافية (اختياري)...',
                  ),
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
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.incomeGreen),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final amount = double.parse(_amountController.text);
                            if (widget.incomeToEdit != null) {
                              final updated = widget.incomeToEdit!.copyWith(
                                sourceName: _sourceController.text.trim(),
                                amount: amount,
                                transactionDate: _selectedDate,
                                notes: _notesController.text.trim(),
                              );
                              await accounts.updateIncome(updated);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم تعديل بيانات الإيراد بنجاح')),
                                );
                              }
                            } else {
                              await accounts.addIncome(
                                sourceName: _sourceController.text,
                                amount: amount,
                                transactionDate: _selectedDate,
                                notes: _notesController.text,
                                createdBy: auth.currentUser?.signature ?? (auth.isOwner ? 'المالك' : 'المدير'),
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم تسجيل الإيراد بنجاح')),
                                );
                              }
                            }
                          }
                        },
                        child: Text(
                          widget.incomeToEdit != null ? 'حفظ التعديلات' : 'حفظ الإيراد',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
}
