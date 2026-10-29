import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/customer_order_model.dart';
import '../../models/order_payment_model.dart';

class AddPaymentDialog extends StatefulWidget {
  final CustomerOrderModel order;
  final List<OrderPaymentModel> currentPayments;
  final Function({
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? notes,
    required bool recordAsIncome,
  }) onSave;

  const AddPaymentDialog({
    super.key,
    required this.order,
    required this.currentPayments,
    required this.onSave,
  });

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'نقدي';
  final bool _recordAsIncome = true;

  final List<String> _paymentMethods = [
    'نقدي',
    'إنستاباي (InstaPay)',
    'فودافون كاش',
    'تحويل بنكي',
    'شيك',
  ];

  @override
  void initState() {
    super.initState();
    final remaining = widget.order.calculateRemainingBalance(widget.currentPayments);
    if (remaining > 0) {
      _amountController.text = remaining.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentGold,
              onPrimary: AppColors.backgroundDark,
              surface: AppColors.surfaceDark,
              onSurface: AppColors.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPaid = widget.order.calculateTotalPaid(widget.currentPayments);
    final remaining = widget.order.calculateRemainingBalance(widget.currentPayments);

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceBorder, width: 1.2),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.incomeGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.payments_rounded, color: AppColors.incomeGreen, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تسجيل دفعة جديدة للعميل',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                          ),
                          Text(
                            widget.order.customerName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.accentGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Order Financial Overview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniInfo('إجمالي الاتفاق', CurrencyFormatter.format(widget.order.totalAmount), AppColors.textWhite),
                      Container(width: 1, height: 32, color: AppColors.surfaceBorder),
                      _buildMiniInfo('المسدد حتى الآن', CurrencyFormatter.format(totalPaid), AppColors.incomeGreen),
                      Container(width: 1, height: 32, color: AppColors.surfaceBorder),
                      _buildMiniInfo('المتبقي المستحق', CurrencyFormatter.format(remaining), AppColors.expenseRed),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'مبلغ الدفعة المسددة (ج.م) *',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppColors.accentGold),
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.accentGold, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'يرجى إدخال مبلغ الدفعة';
                    }
                    final num = double.tryParse(val.trim());
                    if (num == null || num <= 0) {
                      return 'يرجى إدخال مبلغ صحيح أكبر من صفر';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Payment Date
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: AppColors.accentGold, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'تاريخ الدفعة: ${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Payment Method
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'طريقة السداد',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.accentGold),
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                  ),
                  items: _paymentMethods.map((m) {
                    return DropdownMenuItem<String>(
                      value: m,
                      child: Text(m),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMethod = val);
                  },
                ),
                const SizedBox(height: 14),

                // Payment Notes
                TextFormField(
                  controller: _notesController,
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'بيان وملاحظات الدفعة (مثال: دفعة ثانية بعد النجارة)',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.accentGold),
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Permanent Automatic Income Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.incomeGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.incomeGreen.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.incomeGreen, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تسجيل فوري في الحسابات (الداخل)',
                              style: TextStyle(color: AppColors.incomeGreen, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'سيتم إدراج هذه الدفعة تلقائياً في خانة "الداخل" وتحديث إجمالي الخزينة',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.surfaceBorder),
                          ),
                        ),
                        child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, color: AppColors.backgroundDark),
                        label: const Text('تأكيد وحفظ الدفعة', style: TextStyle(color: AppColors.backgroundDark, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final amount = double.parse(_amountController.text.trim());
                            widget.onSave(
                              amount: amount,
                              paymentDate: _selectedDate,
                              paymentMethod: _paymentMethod,
                              notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
                              recordAsIncome: _recordAsIncome,
                            );
                            Navigator.pop(context);
                          }
                        },
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

  Widget _buildMiniInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
