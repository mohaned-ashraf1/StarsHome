import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/debt_advance_receipt_helper.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';

class AddDebtAdvanceDialog extends StatefulWidget {
  const AddDebtAdvanceDialog({super.key});

  @override
  State<AddDebtAdvanceDialog> createState() => _AddDebtAdvanceDialogState();
}

class _AddDebtAdvanceDialogState extends State<AddDebtAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedType = 'advance'; // 'advance', 'debt_receivable', 'debt_payable'
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDueDate;
  bool _printReceiptAfterSave = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _personController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = Provider.of<AccountsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    Color themeColor;
    String typeDescription;
    if (_selectedType == 'advance') {
      themeColor = AppColors.warningAmber;
      typeDescription = 'سلفة نقدية منصرفة من الخزينة لشخص أو عامل أو شريك مع إيصال استلام رسمي';
    } else if (_selectedType == 'debt_receivable') {
      themeColor = AppColors.infoBlue;
      typeDescription = 'مديونية مستحقة للمصنع على شخص / ورشة / عميل خارجي';
    } else {
      themeColor = AppColors.expenseRed;
      typeDescription = 'مديونية أو التزام مالي على المصنع لصالح طرف خارجي';
    }

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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: themeColor, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'تسجيل سلفة / مديونية جديدة',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor),
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

                // Type Selector Tabs
                Row(
                  children: [
                    _buildTypeOption('advance', 'سلفة نقدية', AppColors.warningAmber),
                    const SizedBox(width: 8),
                    _buildTypeOption('debt_receivable', 'مديونية لنا', AppColors.infoBlue),
                    const SizedBox(width: 8),
                    _buildTypeOption('debt_payable', 'مديونية علينا', AppColors.expenseRed),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  typeDescription,
                  style: TextStyle(fontSize: 11, color: themeColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                // Beneficiary Name
                const Text('اسم الشخص / المستفيد *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _personController,
                  decoration: const InputDecoration(
                    hintText: 'أدخل اسم الشخص أو الجهة المستفيدة...',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.accentGold),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'يرجى إدخال اسم المستفيد';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Phone & Amount in Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phone
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('رقم الهاتف (اختياري)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: '01xxxxxxxxx',
                              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.accentGold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Amount
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('المبلغ (ج.م) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              prefixIcon: Icon(Icons.attach_money_rounded, color: AppColors.accentGold),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'المبلغ مطلوب';
                              final amt = double.tryParse(val.trim());
                              if (amt == null || amt <= 0) return 'مبلغ غير صحيح';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Transaction Date & Due Date
                Row(
                  children: [
                    // Date
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
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
                                    const Text('تاريخ السلفة', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                    Text(DateHelper.formatDisplay(_selectedDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Due Date
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) setState(() => _selectedDueDate = picked);
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
                              const Icon(Icons.event_available_rounded, size: 18, color: AppColors.infoBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('تاريخ الاستحقاق', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                    Text(
                                      _selectedDueDate != null ? DateHelper.formatDisplay(_selectedDueDate!) : 'غير محدد',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedDueDate != null ? AppColors.textWhite : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedDueDate != null)
                                GestureDetector(
                                  onTap: () => setState(() => _selectedDueDate = null),
                                  child: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Notes / Description
                const Text('البيان والسبب وملاحظات السند', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'سبب السلفة أو تفاصيل الاتفاق وشروط السداد...',
                  ),
                ),
                const SizedBox(height: 14),

                // Print Receipt Checkbox
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                  ),
                  child: CheckboxListTile(
                    value: _printReceiptAfterSave,
                    activeColor: AppColors.accentGold,
                    checkColor: AppColors.primaryNavy,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'طباعة إيصال استلام السلفة فوراً بعد الحفظ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                    ),
                    subtitle: const Text(
                      'يفتح نافذة PDF لطباعة أو حفظ الإيصال مع التوقيعات الرسمية',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                    onChanged: (val) => setState(() => _printReceiptAfterSave = val ?? true),
                  ),
                ),
                const SizedBox(height: 18),

                // Action Buttons
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
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: Text(
                        _printReceiptAfterSave ? 'حفظ وطباعة الإيصال' : 'حفظ السند',
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

                              final createdItem = await accounts.addDebtAdvance(
                                personName: _personController.text.trim(),
                                phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
                                type: _selectedType,
                                amount: amount,
                                transactionDate: _selectedDate,
                                dueDate: _selectedDueDate,
                                notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
                                createdBy: createdBy,
                              );

                              navigator.pop();

                              if (_printReceiptAfterSave) {
                                await DebtAdvanceReceiptHelper.printReceipt(
                                  item: createdItem,
                                  payments: const [],
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

  Widget _buildTypeOption(String type, String label, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppColors.surfaceBorder.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.surfaceBorder,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
