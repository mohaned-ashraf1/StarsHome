import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../models/purchase_model.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';

class AddPurchaseDialog extends StatefulWidget {
  final PurchaseModel? purchaseToEdit;
  const AddPurchaseDialog({super.key, this.purchaseToEdit});

  @override
  State<AddPurchaseDialog> createState() => _AddPurchaseDialogState();
}

class _AddPurchaseDialogState extends State<AddPurchaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'أخشاب ومواد خام';
  bool _isCustomCategory = false;
  bool _isAutoCalculating = true;

  @override
  void initState() {
    super.initState();
    if (widget.purchaseToEdit != null) {
      final p = widget.purchaseToEdit!;
      _itemController.text = p.itemName;
      _selectedCategory = p.category;
      if (p.quantity != null && p.quantity! > 0) {
        _quantityController.text = p.quantity! % 1 == 0 ? p.quantity!.toInt().toString() : p.quantity!.toString();
      }
      if (p.unitPrice != null && p.unitPrice! > 0) {
        _unitPriceController.text = p.unitPrice! % 1 == 0 ? p.unitPrice!.toInt().toString() : p.unitPrice!.toString();
      }
      _totalAmountController.text = p.totalAmount % 1 == 0 ? p.totalAmount.toInt().toString() : p.totalAmount.toString();
      _notesController.text = p.notes ?? '';
      _selectedDate = p.transactionDate;
    }
    _quantityController.addListener(_recalculateTotal);
    _unitPriceController.addListener(_recalculateTotal);
  }

  @override
  void dispose() {
    _itemController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _totalAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculateTotal() {
    if (!_isAutoCalculating) return;
    final qty = double.tryParse(_quantityController.text) ?? 0.0;
    final price = double.tryParse(_unitPriceController.text) ?? 0.0;
    if (qty > 0 && price > 0) {
      final total = qty * price;
      _totalAmountController.text = total.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = Provider.of<AccountsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // Merge categories
    final availableCategories = accounts.categories.toSet().toList();
    if (!availableCategories.contains(_selectedCategory) && availableCategories.isNotEmpty) {
      _selectedCategory = availableCategories.first;
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.purchaseToEdit != null ? 'تعديل بيانات المصروف' : 'تسجيل مشتروات / مصروف جديد',
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

                // Item Name with Autocomplete
                const Text('اسم البند أو المصروف *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _itemController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return accounts.itemSuggestions.map((s) => s['item_name'].toString());
                    }
                    return accounts.itemSuggestions
                        .where((s) => s['item_name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()))
                        .map((s) => s['item_name'].toString());
                  },
                  onSelected: (String selection) {
                    _itemController.text = selection;
                    final match = accounts.itemSuggestions.firstWhere((s) => s['item_name'] == selection, orElse: () => {});
                    if (match.isNotEmpty) {
                      if (match['default_category'] != null) {
                        setState(() {
                          _selectedCategory = match['default_category'];
                          _isCustomCategory = false;
                        });
                      }
                      final lastPrice = double.tryParse(match['last_unit_price']?.toString() ?? '0') ?? 0;
                      if (lastPrice > 0) {
                        _unitPriceController.text = lastPrice.toStringAsFixed(2);
                      }
                    }
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    controller.addListener(() {
                      _itemController.text = controller.text;
                    });
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'مثال: خشب زان، أبلكاش، بنزين...',
                        prefixIcon: Icon(Icons.inventory_2_outlined, color: AppColors.accentGold, size: 20),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'يرجى كتابة اسم البند' : null,
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Category Selection
                const Text('التصنيف *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _isCustomCategory
                          ? TextFormField(
                              controller: _categoryController,
                              decoration: const InputDecoration(hintText: 'اكتب تصنيفاً جديداً...'),
                              validator: (val) => val == null || val.trim().isEmpty ? 'يرجى كتابة التصنيف' : null,
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavy,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.surfaceBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: availableCategories.contains(_selectedCategory) ? _selectedCategory : null,
                                  isExpanded: true,
                                  dropdownColor: AppColors.surfaceDark,
                                  items: availableCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCategory = val);
                                  },
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(_isCustomCategory ? Icons.list : Icons.add_circle_outline, color: AppColors.accentGold),
                      tooltip: _isCustomCategory ? 'اختيار من القائمة' : 'إضافة تصنيف جديد',
                      onPressed: () {
                        setState(() {
                          _isCustomCategory = !_isCustomCategory;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Quantity and Unit Price
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الكمية (اختياري)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(hintText: 'مثال: 5'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('سعر الوحدة (ج.م)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _unitPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(hintText: 'مثال: 250'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Total Amount
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('المبلغ الإجمالي (ج.م) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _totalAmountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.expenseRed),
                            decoration: const InputDecoration(
                              hintText: 'المبلغ الإجمالي',
                              prefixIcon: Icon(Icons.attach_money, color: AppColors.accentGold),
                            ),
                            onChanged: (val) {
                              _isAutoCalculating = false;
                            },
                            validator: (val) {
                              final d = double.tryParse(val ?? '');
                              if (d == null || d <= 0) return 'يرجى كتابة مبلغ صحيح أكبر من صفر';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Date Picker
                const Text('تاريخ المعاملة', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                            primary: AppColors.accentGold,
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
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.accentGold),
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
                const SizedBox(height: 12),

                const SizedBox(height: 10),

                // Action Buttons
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
                            final category = _isCustomCategory ? _categoryController.text.trim() : _selectedCategory;
                            final qty = double.tryParse(_quantityController.text);
                            final unitPrice = double.tryParse(_unitPriceController.text);
                            final total = double.parse(_totalAmountController.text);

                            if (widget.purchaseToEdit != null) {
                              final updated = widget.purchaseToEdit!.copyWith(
                                itemName: _itemController.text.trim(),
                                category: category,
                                quantity: qty,
                                unitPrice: unitPrice,
                                totalAmount: total,
                                transactionDate: _selectedDate,
                                notes: _notesController.text.trim(),
                              );
                              await accounts.updatePurchase(updated);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم تعديل بيانات المصروف بنجاح')),
                                );
                              }
                            } else {
                              await accounts.addPurchase(
                                itemName: _itemController.text,
                                category: category,
                                quantity: qty,
                                unitPrice: unitPrice,
                                totalAmount: total,
                                transactionDate: _selectedDate,
                                notes: _notesController.text,
                                createdBy: auth.currentUser?.signature ?? (auth.isOwner ? 'المالك' : 'المدير'),
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم تسجيل المعاملة بنجاح')),
                                );
                              }
                            }
                          }
                        },
                        child: Text(
                          widget.purchaseToEdit != null ? 'حفظ التعديلات' : 'حفظ المعاملة',
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
}
