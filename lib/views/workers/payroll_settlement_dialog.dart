import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../providers/workers_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/worker_payroll_receipt_helper.dart';

class PayrollSettlementDialog extends StatefulWidget {
  final WorkerPayrollSummary summary;

  const PayrollSettlementDialog({super.key, required this.summary});

  @override
  State<PayrollSettlementDialog> createState() => _PayrollSettlementDialogState();
}

class _PayrollSettlementDialogState extends State<PayrollSettlementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'كاش (نقدي)';

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.summary.remainingDue.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workers = Provider.of<WorkersProvider>(context, listen: false);
    final accounts = Provider.of<AccountsProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final s = widget.summary;

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 520,
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
                      'صرف وتصفية مستحقات: ${s.worker.fullName}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.surfaceBorder),
                const SizedBox(height: 10),

                // Financial Breakdown Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      _buildRow('أيام الحضور الفعلية', '${s.daysAttended} يوم'),
                      _buildRow('أجر اليوميات المستحق', CurrencyFormatter.format(s.dailyWagesEarned)),
                      _buildRow('ساعات وأجر الإضافي', '${s.overtimeHours} ساعة (${CurrencyFormatter.format(s.overtimeEarnings)})'),
                      _buildRow('إجمالي المكافآت (+)', CurrencyFormatter.format(s.bonusesTotal), color: AppColors.incomeGreen),
                      _buildRow('إجمالي السلف المخصومة (-)', CurrencyFormatter.format(s.advancesTotal), color: AppColors.warningAmber),
                      _buildRow('إجمالي الخصومات (-)', CurrencyFormatter.format(s.deductionsTotal), color: AppColors.expenseRed),
                      const Divider(color: AppColors.surfaceBorder, height: 16),
                      _buildRow('صافي المستحق للأسبوع', CurrencyFormatter.format(s.netAmountDue), isBold: true, color: AppColors.accentGold),
                      if (s.amountAlreadyPaid > 0)
                        _buildRow('المبالغ المصروفة سابقاً', CurrencyFormatter.format(s.amountAlreadyPaid), color: AppColors.textMuted),
                      _buildRow('المبلغ المتبقي للصرف', CurrencyFormatter.format(s.remainingDue), isBold: true, color: AppColors.expenseRed),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Amount to Pay (Supports Full and Partial Payments)
                const Text('المبلغ المراد صرفه الآن (ج.م) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.incomeGreen),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.payments_outlined, color: AppColors.incomeGreen),
                    hintText: 'المبلغ المدفوع',
                  ),
                  validator: (val) {
                    final d = double.tryParse(val ?? '');
                    if (d == null || d <= 0) return 'يرجى كتابة مبلغ صحيح أكبر من صفر';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Payment Method
                const Text('طريقة الصرف', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _paymentMethod,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceDark,
                      items: const [
                        DropdownMenuItem(value: 'كاش (نقدي)', child: Text('كاش (نقدي)')),
                        DropdownMenuItem(value: 'فودافون كاش / إنستاباي', child: Text('فودافون كاش / إنستاباي')),
                        DropdownMenuItem(value: 'تحويل بنكي / شيك', child: Text('تحويل بنكي / شيك')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentMethod = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Payment Date
                const Text('تاريخ الصرف الفعلي', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setState(() => _paymentDate = picked);
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
                        Text(DateHelper.formatDisplay(_paymentDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.accentGold),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'ملاحظات الصرف (صرف كامل، دفعة جزئية، ترحيل الباقي)...',
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.print_outlined, size: 15, color: AppColors.accentGold),
                        label: const Text('إيصال العامل', style: TextStyle(color: AppColors.accentGold, fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accentGold),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                        ),
                        onPressed: () async {
                          final range = DateHelper.getDateRangeForPeriod(workers.selectedWeekPeriod);
                          await WorkerPayrollReceiptHelper.printSingleWorkerReceipt(
                            context: context,
                            summary: s,
                            weekStart: range.start,
                            weekEnd: range.end,
                            attendanceList: workers.attendanceRecords,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final amount = double.parse(_amountController.text);

                            await workers.settleWorkerPayroll(
                              workerId: s.worker.id,
                              amountToPay: amount,
                              paymentDate: _paymentDate,
                              paymentMethod: _paymentMethod,
                              notes: _notesController.text,
                              createdBy: auth.currentUser?.signature ?? (auth.isOwner ? 'المالك' : 'المدير'),
                            );

                            await accounts.loadAll();

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم تسجيل الصرف وإدراجه في المصروفات بنجاح')),
                              );
                            }
                          }
                        },
                        child: const Text('تأكيد الصرف', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
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

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isBold ? AppColors.textWhite : AppColors.textMuted, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? AppColors.textWhite)),
        ],
      ),
    );
  }
}
