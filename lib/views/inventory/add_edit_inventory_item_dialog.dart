import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';

class AddEditInventoryItemDialog extends StatefulWidget {
  final InventoryItemModel? itemToEdit;

  const AddEditInventoryItemDialog({super.key, this.itemToEdit});

  @override
  State<AddEditInventoryItemDialog> createState() => _AddEditInventoryItemDialogState();
}

class _AddEditInventoryItemDialogState extends State<AddEditInventoryItemDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _unitController = TextEditingController(text: 'لوح');
  final TextEditingController _currentStockController = TextEditingController(text: '0');
  final TextEditingController _minStockController = TextEditingController(text: '0');
  final TextEditingController _unitCostController = TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = 'أخشاب ومواد خام';
  final List<String> _categories = [
    'أخشاب ومواد خام',
    'إكسسوارات ومعدات',
    'أقمشة وجلود',
    'دهانات ومواد عازلة',
    'زجاج ومرايات',
    'خامات أخرى',
  ];

  final List<String> _units = ['لوح', 'متر', 'متر مكعب', 'قطعة', 'كجم', 'لفة', 'طقم'];

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      final it = widget.itemToEdit!;
      _nameController.text = it.materialName;
      _selectedCategory = it.category;
      _unitController.text = it.unit;
      _currentStockController.text = it.currentStock.toString();
      _minStockController.text = it.minimumStockLevel.toString();
      _unitCostController.text = it.unitCost.toString();
      _notesController.text = it.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    _unitCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Text(
        isEditing ? 'تعديل صنف خام' : 'إضافة صنف خام جديد للمخزن',
        style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: const InputDecoration(
                  labelText: 'اسم الخامة / الصنف * (مثال: أبلكاش كوري 3 مم)',
                  isDense: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل اسم الخامة' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _categories.contains(_selectedCategory) ? _selectedCategory : _categories.first,
                dropdownColor: AppColors.surfaceDark,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: const InputDecoration(labelText: 'التصنيف', isDense: true),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _units.contains(_unitController.text) ? _unitController.text : _units.first,
                      dropdownColor: AppColors.surfaceDark,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: const InputDecoration(labelText: 'الوحدة', isDense: true),
                      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _unitController.text = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _currentStockController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: const InputDecoration(
                        labelText: 'الرصيد الفعلي حالياً *',
                        isDense: true,
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n < 0) ? 'أدخل رصيد صحيح' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: const InputDecoration(
                        labelText: 'حد الأمان الأدنى (حد الطلب)',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _unitCostController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: const InputDecoration(
                        labelText: 'تكلفة الوحدة التقريبية (ج.م)',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: const InputDecoration(
                  labelText: 'ملاحظات / مكان التخزين بالورشة',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
          child: Text(
            isEditing ? 'حفظ التعديلات' : 'إضافة الصنف',
            style: const TextStyle(color: AppColors.backgroundDark, fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final invProvider = Provider.of<InventoryProvider>(context, listen: false);
            final currentStock = double.tryParse(_currentStockController.text) ?? 0.0;
            final minStock = double.tryParse(_minStockController.text) ?? 0.0;
            final unitCost = double.tryParse(_unitCostController.text) ?? 0.0;

            final item = InventoryItemModel(
              id: widget.itemToEdit?.id,
              materialName: _nameController.text.trim(),
              category: _selectedCategory,
              unit: _unitController.text.trim(),
              currentStock: currentStock,
              reservedStock: widget.itemToEdit?.reservedStock ?? 0.0,
              minimumStockLevel: minStock,
              unitCost: unitCost,
              notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
            );

            await invProvider.saveItem(item);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
