import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/furniture_templates.dart';
import '../../models/material_shortage_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/manufacturing_provider.dart';
import '../../providers/shortages_provider.dart';

class AddEditShortageDialog extends StatefulWidget {
  final MaterialShortageModel? shortageToEdit;
  final String? initialMaterialName;
  final String? initialOrderId;
  final String? initialOrderNumber;

  const AddEditShortageDialog({
    super.key,
    this.shortageToEdit,
    this.initialMaterialName,
    this.initialOrderId,
    this.initialOrderNumber,
  });

  @override
  State<AddEditShortageDialog> createState() => _AddEditShortageDialogState();
}

class _AddEditShortageDialogState extends State<AddEditShortageDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _qtyController;
  late TextEditingController _specsController;
  late TextEditingController _notesController;
  String _unit = 'لوح';
  String? _selectedOrderId;
  String? _selectedOrderNumber;
  String _status = 'shortage';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.shortageToEdit;
    _nameController = TextEditingController(
      text: edit?.materialName ?? widget.initialMaterialName ?? '',
    );
    _qtyController = TextEditingController(
      text: edit?.quantity != null && edit!.quantity! > 0
          ? (edit.quantity! % 1 == 0 ? edit.quantity!.toInt().toString() : edit.quantity!.toString())
          : '',
    );
    _specsController = TextEditingController(text: edit?.specifications ?? '');
    _notesController = TextEditingController(text: edit?.notes ?? '');
    _unit = edit?.unit ?? 'لوح';
    _selectedOrderId = edit?.manufacturingOrderId ?? widget.initialOrderId;
    _selectedOrderNumber = edit?.manufacturingOrderNumber ?? widget.initialOrderNumber;
    _status = edit?.status ?? 'shortage';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _specsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<ShortagesProvider>(context, listen: false);

    final qty = double.tryParse(_qtyController.text.trim());

    try {
      if (widget.shortageToEdit == null) {
        final shortage = MaterialShortageModel(
          materialName: _nameController.text.trim(),
          quantity: qty,
          unit: _unit,
          specifications: _specsController.text.trim().isNotEmpty ? _specsController.text.trim() : null,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          manufacturingOrderId: _selectedOrderId,
          manufacturingOrderNumber: _selectedOrderNumber,
          status: _status,
          recordedBy: auth.currentUser?.fullName ?? 'المدير',
        );
        await provider.addShortage(shortage);
      } else {
        final updated = widget.shortageToEdit!.copyWith(
          materialName: _nameController.text.trim(),
          quantity: qty,
          unit: _unit,
          specifications: _specsController.text.trim().isNotEmpty ? _specsController.text.trim() : null,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          manufacturingOrderId: _selectedOrderId,
          manufacturingOrderNumber: _selectedOrderNumber,
          status: _status,
        );
        await provider.updateShortage(updated);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.shortageToEdit == null
                ? 'تم تسجيل النقص بنجاح'
                : 'تم تحديث بيانات النقص بنجاح'),
            backgroundColor: AppColors.incomeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء حفظ النقص: $e'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mProvider = Provider.of<ManufacturingProvider>(context, listen: false);
    final isEditing = widget.shortageToEdit != null;

    return Dialog(
      backgroundColor: AppColors.cardNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 550,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.expenseRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.report_problem_rounded, color: AppColors.expenseRed, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEditing ? 'تعديل نقص مسجل' : 'تسجيل خامة ناقصة جديدة',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: [
                    // Material Name with Autocomplete
                    const Text('اسم الخامة الناقصة *', style: TextStyle(color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: _nameController.text),
                      optionsBuilder: (TextEditingValue val) {
                        if (val.text.isEmpty) return const Iterable<String>.empty();
                        return FurnitureTemplates.commonRawMaterials.where(
                          (mat) => mat.toLowerCase().contains(val.text.toLowerCase()),
                        );
                      },
                      onSelected: (selection) {
                        _nameController.text = selection;
                      },
                      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
                        // Keep our controller in sync
                        fieldController.addListener(() {
                          _nameController.text = fieldController.text;
                        });
                        return TextFormField(
                          controller: fieldController,
                          focusNode: focusNode,
                          style: const TextStyle(color: AppColors.textWhite),
                          decoration: InputDecoration(
                            hintText: 'مثال: أبلكاش كوري، مفصلات باكم، قماش تنجيد...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            filled: true,
                            fillColor: AppColors.surfaceDark,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.category_outlined, color: AppColors.accentGold, size: 20),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى كتابة اسم الخامة' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantity (Optional) & Unit
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('الكمية المطلوبة', style: TextStyle(color: AppColors.textWhite, fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Text('(اختيارية)', style: TextStyle(color: AppColors.textMuted.withOpacity(0.8), fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _qtyController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: AppColors.textWhite),
                                decoration: InputDecoration(
                                  hintText: 'اتركها فارغة إذا لم تُحدد بعد',
                                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  filled: true,
                                  fillColor: AppColors.surfaceDark,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  prefixIcon: const Icon(Icons.numbers_rounded, color: AppColors.textMuted, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('وحدة القياس', style: TextStyle(color: AppColors.textWhite, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _unit,
                                dropdownColor: AppColors.surfaceDark,
                                style: const TextStyle(color: AppColors.textWhite),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceDark,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: FurnitureTemplates.standardUnits.map((u) {
                                  return DropdownMenuItem(value: u, child: Text(u));
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _unit = v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Specifications (Thickness, Grade, Color)
                    const Text('المواصفات والسمك واللون', style: TextStyle(color: AppColors.textWhite, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _specsController,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: InputDecoration(
                        hintText: 'مثال: 18 مم، درجة أولى، كود القماش K-402، زاوية 110...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.tune_rounded, color: AppColors.textMuted, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Linked Manufacturing Order (Optional)
                    Row(
                      children: [
                        const Text('ربط بأمر تصنيع', style: TextStyle(color: AppColors.textWhite, fontSize: 13)),
                        const SizedBox(width: 4),
                        Text('(اختياري)', style: TextStyle(color: AppColors.textMuted.withOpacity(0.8), fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      value: _selectedOrderId,
                      dropdownColor: AppColors.surfaceDark,
                      isExpanded: true,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.assignment_outlined, color: AppColors.textMuted, size: 20),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('بدون ربط بأمر تصنيع (احتياج عام للورشة)', style: TextStyle(color: AppColors.textMuted)),
                        ),
                        ...mProvider.orders
                            .where((o) => o.status != 'completed' && o.status != 'cancelled')
                            .map((order) {
                          return DropdownMenuItem<String?>(
                            value: order.id,
                            child: Text(
                              '${order.orderNumber} - ${order.displayTitle} (${order.customerName ?? "بدون عميل"})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedOrderId = val;
                          if (val != null) {
                            final match = mProvider.orders.firstWhere((o) => o.id == val);
                            _selectedOrderNumber = match.orderNumber;
                          } else {
                            _selectedOrderNumber = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Status (if editing)
                    if (isEditing) ...[
                      const Text('حالة النقص', style: TextStyle(color: AppColors.textWhite, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _status,
                        dropdownColor: AppColors.surfaceDark,
                        style: const TextStyle(color: AppColors.textWhite),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'shortage', child: Text('ناقص (مطلوب)')),
                          DropdownMenuItem(value: 'in_progress', child: Text('جارٍ المتابعة والتوفير')),
                          DropdownMenuItem(value: 'resolved', child: Text('تم الحل وتوفير الخامة')),
                          DropdownMenuItem(value: 'reopened', child: Text('أعيد فتحه')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Notes
                    const Text('ملاحظات إضافية', style: TextStyle(color: AppColors.textWhite, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: InputDecoration(
                        hintText: 'أي تفاصيل أخرى بخصوص المورد أو مكان الشراء...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.surfaceBorder),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: AppColors.primaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
                            )
                          : Text(
                              isEditing ? 'حفظ التعديلات' : 'تسجيل النقص',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
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
}
