import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/debt_advance_receipt_helper.dart';
import '../../models/debt_advance_model.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';

class RecordDebtPaymentDialog extends StatefulWidget {
  final DebtAdvanceModel debtAdvance;
  const RecordDebtPaymentDialog({super.key, required this.debtAdvance});

  @override
  State<RecordDebtPaymentDialog> createState() => _RecordDebtPaymentDialogState();
}

class _RecordDebtPaymentDialogState extends State<RecordDebtPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  bool _printUpdatedReceipt = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Default to the full remaining amount
    if (widget.debtAdvance.remainingAmount > 0) {
      _amountController.text = widget.debtAdvance.remainingAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = Provider.of<AccountsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final remaining = widget.debtAdvance.remainingAmount;

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
                    Row(
                      children: const [
                        Icon(Icons.payment_rounded, color: AppColors.incomeGreen, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'تسجيل سداد / دفعة نقدية',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.incomeGreen),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.surfaceBorder),
                const SizedBox(height: 12),

                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.debtAdvance.personName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textWhite),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.debtAdvance.typeLabel,
                              style: const TextStyle(fontSize: 11, color: AppColors.accentGold, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('المبلغ الأصلي: ${CurrencyFormatter.format(widget.debtAdvance.amount)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text('المسدد: ${CurrencyFormatter.format(widget.debtAdvance.paidAmount)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.incomeGreen)),
                        ],
                      ),
                      const Divider(color: AppColors.surfaceBorder, height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المتبقي المطلوب سداده:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
                          Text(
                            CurrencyFormatter.format(remaining),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.expenseRed),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Amount
                const Text('المبلغ المسدد الآن (ج.م) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.incomeGreen),
                    suffixIcon: TextButton(
                      child: const Text('سداد كامل المتبقي', style: TextStyle(color: AppColors.accentGold, fontSize: 11)),
                      onPressed: () {
                        _amountController.text = remaining.toStringAsFixed(2);
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'يرجى إدخال المبلغ';
                    final amt = double.tryParse(val.trim());
                    if (amt == null || amt <= 0) return 'مبلغ غير صحيح';
                    if (amt > (remaining + 0.01)) return 'المبلغ أكبر من المتبقي المستحق (${CurrencyFormatter.format(remaining)})';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Date
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.surfaceBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.accentGold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('تاريخ الدفعة', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              Text(DateHelper.formatDisplay(_paymentDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                const Text('ملاحظات وسجل الدفعة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'دفعة سداد نقدي أو حوالة...',
                  ),
                ),
                const SizedBox(height: 14),

                // Print updated receipt Checkbox
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                  ),
                  child: CheckboxListTile(
                    value: _printUpdatedReceipt,
                    activeColor: AppColors.accentGold,
                    checkColor: AppColors.primaryNavy,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'طباعة إيصال محدث بعد السداد',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                    ),
                    subtitle: const Text(
                      'يتضمن كل الدفعات السابقة والرصيد المتبقي الجديد',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                    onChanged: (val) => setState(() => _printUpdatedReceipt = val ?? true),
                  ),
                ),
                const SizedBox(height: 18),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.incomeGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: Text(
                        _printUpdatedReceipt ? 'تسجيل وطباعة الإيصال' : 'تأكيد السداد',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _isSaving = true);

                              final navigator = Navigator.of(context);
                              final amount = double.parse(_amountController.text.trim());
                              final createdBy = auth.currentUser?.signature ?? (auth.isOwner ? 'المالك' : 'المدير');

                              await accounts.recordDebtRepayment(
                                debtAdvanceId: widget.debtAdvance.id,
                                amount: amount,
                                paymentDate: _paymentDate,
                                notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
                                createdBy: createdBy,
                              );

                              navigator.pop();

                              if (_printUpdatedReceipt) {
                                final updatedItem = accounts.debtsAdvances.firstWhere(
                                  (d) => d.id == widget.debtAdvance.id,
                                  orElse: () => widget.debtAdvance,
                                );
                                final payments = accounts.getPaymentsForDebt(widget.debtAdvance.id);
                                await DebtAdvanceReceiptHelper.printReceipt(
                                  item: updatedItem,
                                  payments: payments,
                                );
                              }
                            },
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
