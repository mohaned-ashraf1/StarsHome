import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../providers/contractors_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';

class RecordContractorPaymentDialog extends StatefulWidget {
  final String? initialContractorId;

  const RecordContractorPaymentDialog({super.key, this.initialContractorId});

  @override
  State<RecordContractorPaymentDialog> createState() => _RecordContractorPaymentDialogState();
}

class _RecordContractorPaymentDialogState extends State<RecordContractorPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedContractorId;
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final contractors = Provider.of<ContractorsProvider>(context, listen: false);
    _selectedContractorId = widget.initialContractorId ?? (contractors.activeContractors.isNotEmpty ? contractors.activeContractors.first.id : null);
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _orderController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contractors = Provider.of<ContractorsProvider>(context);
    final accounts = Provider.of<AccountsProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (contractors.activeContractors.isEmpty) {
      return AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('تنبيه'),
        content: const Text('لا توجد ورش مسجلة. يرجى إضافة ورشة أولاً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      );
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
                    const Text(
                      'تسجيل دفعة نقدية لورشة اشتراك',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.infoBlue),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.surfaceBorder),
                const SizedBox(height: 12),

                // Select Contractor
                const Text('اختر الورشة / الفني الخارجي *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                      value: _selectedContractorId,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceDark,
                      items: contractors.activeContractors.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} (${c.serviceType})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedContractorId = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Description
                const Text('بيان الدفعة أو الأعمال المنفذة *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    hintText: 'مثال: دهان غرفة نوم دوكو، تنجيد أنتريه صالون...',
                    prefixIcon: Icon(Icons.description_outlined, color: AppColors.infoBlue),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'يرجى كتابة بيان الدفعة' : null,
                ),
                const SizedBox(height: 14),

                // Amount
                const Text('المبلغ المدفوع (ج.م) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.infoBlue)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.infoBlue),
                  decoration: const InputDecoration(
                    hintText: 'المبلغ بالجنية المصري',
                    prefixIcon: Icon(Icons.payments_outlined, color: AppColors.infoBlue),
                  ),
                  validator: (val) {
                    final d = double.tryParse(val ?? '');
                    if (d == null || d <= 0) return 'يرجى كتابة مبلغ صحيح أكبر من صفر';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Related Order / Product
                const Text('الأوردر أو المنتج المرتبط (اختياري)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _orderController,
                  decoration: const InputDecoration(
                    hintText: 'مثال: أوردر أ/ محمود، صالون كلاسيك رقم 12...',
                    prefixIcon: Icon(Icons.weekend_outlined, color: AppColors.accentGold),
                  ),
                ),
                const SizedBox(height: 14),

                // Date Picker
                const Text('تاريخ الدفع الفعلي', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.infoBlue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(hintText: 'ملاحظات إضافية، شيك أو إيصال استلام...'),
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
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.infoBlue),
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && _selectedContractorId != null) {
                            final amount = double.parse(_amountController.text);

                            await contractors.recordPayment(
                              contractorId: _selectedContractorId!,
                              description: _descController.text,
                              amount: amount,
                              paymentDate: _selectedDate,
                              relatedOrder: _orderController.text,
                              notes: _notesController.text,
                              createdBy: auth.currentUser?.fullName ?? 'المدير',
                            );

                            // Sync accounts state
                            await accounts.loadAll();

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم تسجيل دفعة الورشة وإدراجها بالمصروفات تلقائياً')),
                              );
                            }
                          }
                        },
                        child: const Text('تأكيد وحفظ الدفعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
