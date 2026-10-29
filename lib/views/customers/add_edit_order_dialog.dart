import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../models/customer_order_model.dart';

class AddEditOrderDialog extends StatefulWidget {
  final CustomerOrderModel? existingOrder;
  final Function({
    required String customerName,
    String? phone,
    required String orderDescription,
    required DateTime startDate,
    DateTime? deliveryDate,
    required double totalAmount,
    required String status,
    String? notes,
    double? initialPayment,
    String paymentMethod,
    String? paymentNotes,
    bool recordAsIncome,
  }) onSave;

  const AddEditOrderDialog({
    super.key,
    this.existingOrder,
    required this.onSave,
  });

  @override
  State<AddEditOrderDialog> createState() => _AddEditOrderDialogState();
}

class _AddEditOrderDialogState extends State<AddEditOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _initialPaymentController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _deliveryDate;
  String _status = 'in_progress';
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
    if (widget.existingOrder != null) {
      final o = widget.existingOrder!;
      _nameController.text = o.customerName;
      _phoneController.text = o.phone ?? '';
      _descController.text = o.orderDescription;
      _totalAmountController.text = o.totalAmount.toStringAsFixed(0);
      _notesController.text = o.notes ?? '';
      _startDate = o.startDate;
      _deliveryDate = o.deliveryDate;
      _status = o.status;
    } else {
      // Default delivery date to 3 weeks later
      _deliveryDate = DateTime.now().add(const Duration(days: 21));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    _totalAmountController.dispose();
    _initialPaymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => _datePickerTheme(child!),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? _startDate.add(const Duration(days: 14)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => _datePickerTheme(child!),
    );
    if (picked != null) {
      setState(() => _deliveryDate = picked);
    }
  }

  Widget _datePickerTheme(Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentGold,
          onPrimary: AppColors.backgroundDark,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textWhite,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingOrder != null;

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceBorder, width: 1.2),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.accentGold, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'تعديل بيانات طلب العميل' : 'إضافة عميل وطلب جديد',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                        ),
                        const Text(
                          'تسجيل تفاصيل الاتفاق، مواعيد التسليم، والدفعات',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
              const SizedBox(height: 14),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              const SizedBox(height: 14),

              // Form Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Customer Name & Phone Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: AppColors.textWhite, fontSize: 14),
                              decoration: _inputDecoration('اسم العميل *', Icons.person_outline),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'يرجى إدخال اسم العميل';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: AppColors.textWhite, fontSize: 14),
                              decoration: _inputDecoration('رقم الهاتف', Icons.phone_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Order Description (الطلب اللي العميل طالبه)
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'الطلب اللي العميل طالبه بالتفصيل والمواصفات *',
                          labelStyle: const TextStyle(color: AppColors.textMuted),
                          hintText: 'مثال: غرفة نوم رئيسية خشب زان دهان أستر + دولاب 3 ضلفة سحاب + 2 كومود وتسريحة',
                          hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5), fontSize: 11),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 35),
                            child: Icon(Icons.inventory_2_outlined, color: AppColors.accentGold),
                          ),
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
                            return 'يرجى كتابة تفاصيل الطلب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Total Price Agreed
                      TextFormField(
                        controller: _totalAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                        decoration: _inputDecoration('إجمالي المبلغ المتفق عليه (ج.م) *', Icons.monetization_on_outlined),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'يرجى إدخال إجمالي المبلغ';
                          }
                          final num = double.tryParse(val.trim());
                          if (num == null || num <= 0) {
                            return 'يرجى إدخال مبلغ صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Dates: Start Date & Delivery Date
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickStartDate,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.surfaceBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('تاريخ بدء الطلب', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.date_range, color: AppColors.accentGold, size: 16),
                                        const SizedBox(width: 6),
                                        Text(DateHelper.formatDisplay(_startDate), style: const TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: _pickDeliveryDate,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.surfaceBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('تاريخ التسليم المتفق عليه', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.local_shipping_outlined, color: AppColors.infoBlue, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          _deliveryDate != null ? DateHelper.formatDisplay(_deliveryDate!) : 'غير محدد',
                                          style: const TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Status Dropdown
                      DropdownButtonFormField<String>(
                        value: _status,
                        dropdownColor: AppColors.surfaceDark,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                        decoration: _inputDecoration('حالة تنفيذ الطلب', Icons.timeline_rounded),
                        items: const [
                          DropdownMenuItem(value: 'in_progress', child: Text('قيد التنفيذ بالمصنع')),
                          DropdownMenuItem(value: 'ready', child: Text('جاهز للتسليم')),
                          DropdownMenuItem(value: 'delivered', child: Text('تم التسليم والانتهاء')),
                          DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // INITIAL PAYMENT SECTION (Only shown when adding new order)
                      if (!isEditing) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.incomeGreen.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.payments_rounded, color: AppColors.incomeGreen, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'عربون / دفعة أولى الآن (اختياري)',
                                    style: TextStyle(color: AppColors.incomeGreen, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _initialPaymentController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: AppColors.textWhite, fontSize: 14),
                                      decoration: _inputDecoration('مبلغ العربون / الدفعة الأولى', Icons.attach_money),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      value: _paymentMethod,
                                      dropdownColor: AppColors.surfaceDark,
                                      style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                                      decoration: _inputDecoration('طريقة الدفع', Icons.payment),
                                      items: _paymentMethods.map((m) {
                                        return DropdownMenuItem<String>(value: m, child: Text(m));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _paymentMethod = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AppColors.incomeGreen, size: 16),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'يتم تسجيل العربون تلقائياً في حسابات "الداخل" وخزينة المصنع فوراً',
                                      style: TextStyle(color: AppColors.incomeGreen, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Additional Notes
                      TextFormField(
                        controller: _notesController,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                        decoration: _inputDecoration('ملاحظات إضافية (ألوان، ملحقات، شروط خاصة)', Icons.edit_note_rounded),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              const SizedBox(height: 16),

              // Action Buttons
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
                      label: Text(
                        isEditing ? 'حفظ التعديلات' : 'حفظ وإنشاء الطلب',
                        style: const TextStyle(color: AppColors.backgroundDark, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final total = double.parse(_totalAmountController.text.trim());
                          final initialPayText = _initialPaymentController.text.trim();
                          final initialPay = initialPayText.isNotEmpty ? double.tryParse(initialPayText) : null;

                          widget.onSave(
                            customerName: _nameController.text.trim(),
                            phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
                            orderDescription: _descController.text.trim(),
                            startDate: _startDate,
                            deliveryDate: _deliveryDate,
                            totalAmount: total,
                            status: _status,
                            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
                            initialPayment: initialPay,
                            paymentMethod: _paymentMethod,
                            paymentNotes: 'عربون / دفعة أولى',
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
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.accentGold, size: 20),
      filled: true,
      fillColor: AppColors.backgroundDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accentGold, width: 1.5),
      ),
    );
  }
}
