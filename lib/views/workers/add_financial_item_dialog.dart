import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../providers/workers_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';

class AddFinancialItemDialog extends StatefulWidget {
  final String? initialWorkerId;
  const AddFinancialItemDialog({super.key, this.initialWorkerId});

  @override
  State<AddFinancialItemDialog> createState() => _AddFinancialItemDialogState();
}

class _AddFinancialItemDialogState extends State<AddFinancialItemDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedWorkerId;
  String _selectedType = 'advance'; // advance, bonus, deduction
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final workers = Provider.of<WorkersProvider>(context, listen: false);
    _selectedWorkerId = widget.initialWorkerId ?? (workers.activeWorkers.isNotEmpty ? workers.activeWorkers.first.id : null);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workers = Provider.of<WorkersProvider>(context);
    final accounts = Provider.of<AccountsProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    Color themeColor;
    String typeLabel;
    if (_selectedType == 'advance') {
      themeColor = AppColors.warningAmber;
      typeLabel = 'سلفة على الراتب (تخصم من كشف الأسبوع وتظهر كمصروف)';
    } else if (_selectedType == 'bonus') {
      themeColor = AppColors.incomeGreen;
      typeLabel = 'مكافأة تشجيعية (تضاف إلى كشف أجر الأسبوع)';
    } else {
      themeColor = AppColors.expenseRed;
      typeLabel = 'خصم جزائي / إتلاف (يخصم من كشف أجر الأسبوع)';
    }

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
                      'تسجيل حركة مالية لعامل',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.surfaceBorder),
                const SizedBox(height: 12),

                // Type selector
                Row(
                  children: [
                    _buildTypeOption('advance', 'سلفة', AppColors.warningAmber),
                    const SizedBox(width: 8),
                    _buildTypeOption('bonus', 'مكافأة', AppColors.incomeGreen),
                    const SizedBox(width: 8),
                    _buildTypeOption('deduction', 'خصم', AppColors.expenseRed),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  typeLabel,
                  style: TextStyle(fontSize: 11, color: themeColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

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
                          child: Text(w.fullName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedWorkerId = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Amount
                Text('المبلغ (ج.م) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: themeColor)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeColor),
                  decoration: InputDecoration(
                    hintText: 'المبلغ بالجنية المصري',
                    prefixIcon: Icon(Icons.attach_money, color: themeColor),
                  ),
                  validator: (val) {
                    final d = double.tryParse(val ?? '');
                    if (d == null || d <= 0) return 'يرجى كتابة مبلغ صحيح أكبر من صفر';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Date Picker
                const Text('تاريخ العملية', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                        Icon(Icons.calendar_today, size: 18, color: themeColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Reason / Notes
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'السبب أو التفاصيل (مثال: سلفة لمصاريف شخصية، مكافأة إنجاز صالون، خصم تأخير)...',
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
                        style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && _selectedWorkerId != null) {
                            final amount = double.parse(_amountController.text);

                            await workers.addFinancialItem(
                              workerId: _selectedWorkerId!,
                              type: _selectedType,
                              amount: amount,
                              transactionDate: _selectedDate,
                              reasonNotes: _reasonController.text,
                              createdBy: auth.currentUser?.signature ?? (auth.isOwner ? 'المالك' : 'المدير'),
                            );

                            // Reload accounts if advance was added
                            if (_selectedType == 'advance') {
                              await accounts.loadAll();
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم تسجيل المعاملة بنجاح وتحديث حسابات العامل والمصنع')),
                              );
                            }
                          }
                        },
                        child: const Text('حفظ المعاملة', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
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

  Widget _buildTypeOption(String typeKey, String label, Color color) {
    final isSelected = _selectedType == typeKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = typeKey),
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
}
