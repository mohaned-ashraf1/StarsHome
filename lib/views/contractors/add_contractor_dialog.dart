import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/contractor_model.dart';
import '../../providers/contractors_provider.dart';

class AddContractorDialog extends StatefulWidget {
  final ContractorModel? contractorToEdit;
  const AddContractorDialog({super.key, this.contractorToEdit});

  @override
  State<AddContractorDialog> createState() => _AddContractorDialogState();
}

class _AddContractorDialogState extends State<AddContractorDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController(text: 'الدهان');
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _suggestedServices = ['الدهان', 'التنجيد', 'القشرة', 'الزجاج والمرايات', 'خرط وخراطة CNC', 'تجليد ولحام'];

  @override
  void initState() {
    super.initState();
    if (widget.contractorToEdit != null) {
      final c = widget.contractorToEdit!;
      _nameController.text = c.name;
      _serviceController.text = c.serviceType;
      _phoneController.text = c.phone ?? '';
      _notesController.text = c.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serviceController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contractors = Provider.of<ContractorsProvider>(context, listen: false);

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
                    Text(
                      widget.contractorToEdit != null ? 'تعديل بيانات الورشة' : 'إضافة ورشة / جهة اشتراك جديدة',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.infoBlue),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.surfaceBorder),
                const SizedBox(height: 12),

                // Name
                const Text('اسم الورشة أو الفني الخارجي *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'مثال: ورشة الدهان الحديث (المعلم رجب)...',
                    prefixIcon: Icon(Icons.handshake_outlined, color: AppColors.infoBlue),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'يرجى كتابة اسم الورشة' : null,
                ),
                const SizedBox(height: 14),

                // Service Type
                const Text('نوع الخدمة / الاشتراك *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _serviceController,
                  decoration: const InputDecoration(
                    hintText: 'مثال: الدهان، التنجيد، القشرة...',
                    prefixIcon: Icon(Icons.build_outlined, color: AppColors.infoBlue),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'يرجى تحديد نوع الخدمة' : null,
                ),
                const SizedBox(height: 8),

                // Quick Service chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _suggestedServices.map((svc) {
                    return ActionChip(
                      label: Text(svc, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.primaryNavy,
                      side: const BorderSide(color: AppColors.surfaceBorder),
                      onPressed: () {
                        setState(() => _serviceController.text = svc);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Phone
                const Text('رقم الهاتف (اختياري)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '01xxxxxxxxx',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.infoBlue),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'ملاحظات وتفاصيل التعامل، شروط التسليم...',
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
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.infoBlue),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (widget.contractorToEdit != null) {
                              final updated = widget.contractorToEdit!.copyWith(
                                name: _nameController.text.trim(),
                                serviceType: _serviceController.text.trim(),
                                phone: _phoneController.text.trim(),
                                notes: _notesController.text.trim(),
                              );
                              await contractors.updateContractor(updated);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم تعديل بيانات الورشة بنجاح')),
                                );
                              }
                            } else {
                              await contractors.addContractor(
                                name: _nameController.text,
                                serviceType: _serviceController.text,
                                phone: _phoneController.text,
                                notes: _notesController.text,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تمت إضافة الورشة بنجاح')),
                                );
                              }
                            }
                          }
                        },
                        child: Text(
                          widget.contractorToEdit != null ? 'حفظ التعديلات' : 'حفظ الورشة',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
