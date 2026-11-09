import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stars_home/backend/models/customer_order_model.dart';
import 'package:stars_home/backend/utils/date_helper.dart';
import 'package:stars_home/frontend/constants/app_colors.dart';

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
    List<OrderSectionItem>? sections,
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
  final _paymentNotesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _deliveryDate;
  String _status = 'in_progress';
  String _paymentMethod = 'نقدي';
  final bool _recordAsIncome = true;

  // Order Sections with Photos
  List<OrderSectionItem> _sections = [];

  final List<String> _sectionCategories = [
    'غرفة نوم رئيسية',
    'غرفة أطفال',
    'دولاب / دريسينج',
    'صالون / أنتريه',
    'ركنة',
    'سفرة وبوفيه',
    'مطبخ',
    'وحدة تلفزيون / ديكور',
    'أخرى (مخصص)',
  ];

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
      _totalAmountController.text = o.totalAmount > 0 ? o.totalAmount.toStringAsFixed(0) : '';
      _notesController.text = o.notes ?? '';
      _startDate = o.startDate;
      _deliveryDate = o.deliveryDate;
      _status = o.status;
      _sections = List.from(o.sections);
    } else {
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
    _paymentNotesController.dispose();
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

  void _syncDescriptionFromSections() {
    if (_sections.isEmpty) return;
    final buffer = StringBuffer();
    for (final s in _sections) {
      buffer.writeln('• ${s.title}: ${s.description}');
    }
    _descController.text = buffer.toString().trim();
  }

  Future<void> _showAddEditSectionDialog({OrderSectionItem? existing, int? index}) async {
    String selectedCategory = existing?.sectionType ?? _sectionCategories.first;
    final titleController = TextEditingController(text: existing?.title ?? selectedCategory);
    final descController = TextEditingController(text: existing?.description ?? '');
    String? localImagePath = existing?.imagePath;
    String? imageBase64 = existing?.imageBase64;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> pickPhoto(ImageSource source) async {
            try {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: source,
                maxWidth: 900,
                maxHeight: 900,
                imageQuality: 75,
              );
              if (picked != null) {
                final bytes = await picked.readAsBytes();
                setDialogState(() {
                  localImagePath = picked.path;
                  imageBase64 = base64Encode(bytes);
                });
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('تعذر اختيار الصورة: $e')),
                );
              }
            }
          }

          Widget buildImagePreview() {
            if (imageBase64 != null && imageBase64!.isNotEmpty) {
              try {
                final bytes = base64Decode(imageBase64!);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(bytes, height: 140, width: double.infinity, fit: BoxFit.cover),
                );
              } catch (_) {}
            }
            if (localImagePath != null && localImagePath!.isNotEmpty && !kIsWeb) {
              final f = File(localImagePath!);
              if (f.existsSync()) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(f, height: 140, width: double.infinity, fit: BoxFit.cover),
                );
              }
            }
            return Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceBorder, style: BorderStyle.solid),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.accentGold, size: 36),
                    SizedBox(height: 6),
                    Text(
                      'لم يتم إضافة صورة لهذا القسم',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          return AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.surfaceBorder),
            ),
            title: Row(
              children: [
                const Icon(Icons.style_rounded, color: AppColors.accentGold, size: 22),
                const SizedBox(width: 8),
                Text(
                  existing != null ? 'تعديل قسم بالطلب' : 'إضافة قسم / غرفة جديدة',
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category Selection
                    const Text('نوع التقسيم:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceDark,
                          items: _sectionCategories.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c, style: const TextStyle(color: AppColors.textWhite, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedCategory = val;
                                if (titleController.text.trim().isEmpty || _sectionCategories.contains(titleController.text.trim())) {
                                  titleController.text = val;
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section Title
                    TextFormField(
                      controller: titleController,
                      style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'اسم / عنوان القسم *',
                        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                    ),
                    const SizedBox(height: 12),

                    // Section Description
                    TextFormField(
                      controller: descController,
                      maxLines: 3,
                      style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'المواصفات والخامات والمقاسات *',
                        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        hintText: 'مثال: سرير 160 سم خشب زان + 2 كومود + تسريحة، دهان أستر، قماش هامر كابوتونيه',
                        hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5), fontSize: 11),
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
                    ),
                    const SizedBox(height: 14),

                    // Photo Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'صورة التصميم / الموديل (تطبع بالـ PDF):',
                          style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        if (imageBase64 != null)
                          TextButton.icon(
                            icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 16),
                            label: const Text('حذف الصورة', style: TextStyle(color: AppColors.expenseRed, fontSize: 11)),
                            onPressed: () {
                              setDialogState(() {
                                localImagePath = null;
                                imageBase64 = null;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    buildImagePreview(),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textWhite,
                              side: const BorderSide(color: AppColors.surfaceBorder),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.infoBlue),
                            label: const Text('من المعرض', style: TextStyle(fontSize: 12)),
                            onPressed: () => pickPhoto(ImageSource.gallery),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textWhite,
                              side: const BorderSide(color: AppColors.surfaceBorder),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.accentGold),
                            label: const Text('التقاط بالكاميرا', style: TextStyle(fontSize: 12)),
                            onPressed: () => pickPhoto(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.backgroundDark,
                ),
                onPressed: () {
                  final t = titleController.text.trim();
                  final d = descController.text.trim();
                  if (t.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال اسم أو عنوان القسم')),
                    );
                    return;
                  }
                  final newSec = OrderSectionItem(
                    id: existing?.id,
                    sectionType: selectedCategory,
                    title: t,
                    description: d.isNotEmpty ? d : 'حسب المواصفات المحددة',
                    imagePath: localImagePath,
                    imageBase64: imageBase64,
                  );

                  setState(() {
                    if (existing != null && index != null && index < _sections.length) {
                      _sections[index] = newSec;
                    } else {
                      _sections.add(newSec);
                    }
                    _syncDescriptionFromSections();
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('حفظ القسم', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.4), fontSize: 12),
      prefixIcon: Icon(icon, color: AppColors.accentGold, size: 20),
      filled: true,
      fillColor: AppColors.backgroundDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingOrder != null;

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceBorder, width: 1.2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
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
                          'تسجيل تفاصيل الاتفاق، التقسيمات بالصور، ومواعيد التسليم',
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
              const SizedBox(height: 12),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              const SizedBox(height: 12),

              // Form Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Customer Name (Full Width)
                      TextFormField(
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
                      const SizedBox(height: 10),

                      // 2. Phone Number (Full Width - Solves clipping issue on all screens!)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 14),
                        decoration: _inputDecoration(
                          'رقم هاتف العميل (واتساب)',
                          Icons.phone_outlined,
                          hintText: 'مثال: 01012345678',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Sections & Models Area (التقسيم بالصور)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.category_rounded, color: AppColors.accentGold, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'التقسيم والموديلات المطلوبة:',
                                      style: TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentGold,
                                    foregroundColor: AppColors.backgroundDark,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('إضافة قسم بالصورة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  onPressed: () => _showAddEditSectionDialog(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Quick Category Choice Pills
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final cat in _sectionCategories)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: ActionChip(
                                        backgroundColor: AppColors.surfaceDark,
                                        side: const BorderSide(color: AppColors.surfaceBorder),
                                        label: Text(cat, style: const TextStyle(color: AppColors.textWhite, fontSize: 11)),
                                        avatar: const Icon(Icons.add_circle_outline, color: AppColors.accentGold, size: 14),
                                        onPressed: () {
                                          _showAddEditSectionDialog(
                                            existing: OrderSectionItem(
                                              sectionType: cat,
                                              title: cat,
                                              description: '',
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            if (_sections.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceDark.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.surfaceBorder.withOpacity(0.5)),
                                ),
                                child: const Center(
                                  child: Text(
                                    'اضغط على زر (إضافة قسم) أو اختر تصنيفاً سريعاً (غرفة نوم، دولاب، دريسنج...) لإضافة تفاصيل وصور الموديلات لتضمينها وطباعتها بالـ PDF تلقائياً.',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _sections.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 8),
                                itemBuilder: (ctx, i) {
                                  final s = _sections[i];
                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceDark,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        // Image thumbnail
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            width: 54,
                                            height: 54,
                                            color: AppColors.backgroundDark,
                                            child: s.imageBase64 != null
                                                ? Image.memory(base64Decode(s.imageBase64!), fit: BoxFit.cover)
                                                : (s.imagePath != null && !kIsWeb && File(s.imagePath!).existsSync())
                                                    ? Image.file(File(s.imagePath!), fit: BoxFit.cover)
                                                    : const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 24),
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // Title & Specs
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.accentGold.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      s.sectionType,
                                                      style: const TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      s.title,
                                                      style: const TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                s.description,
                                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Actions
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: AppColors.infoBlue, size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showAddEditSectionDialog(existing: s, index: i),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              _sections.removeAt(i);
                                              _syncDescriptionFromSections();
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 4. Order Description
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'بيان وتفاصيل الطلب الشاملة *',
                          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          hintText: 'يتم ملء هذا الحقل تلقائياً من الأقسام بالأعلى، أو يمكنك تعديله وكتابة تفاصيل إضافية.',
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
                          if ((val == null || val.trim().isEmpty) && _sections.isEmpty) {
                            return 'يرجى كتابة تفاصيل الطلب أو إضافة قسم واحد على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // 5. Total Price Agreed
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

                      // 6. Dates: Start Date & Delivery Date
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
                                        Text(
                                          DateHelper.formatDisplay(_startDate),
                                          style: const TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
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

                      // 7. Order Status
                      DropdownButtonFormField<String>(
                        value: _status,
                        dropdownColor: AppColors.surfaceDark,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                        decoration: _inputDecoration('حالة تنفيذ الطلب', Icons.timeline_rounded),
                        items: const [
                          DropdownMenuItem(value: 'in_progress', child: Text('قيد التنفيذ بالمصنع')),
                          DropdownMenuItem(value: 'ready', child: Text('جاهز للتسليم')),
                          DropdownMenuItem(value: 'delivered', child: Text('تم التسليم للعميل')),
                          DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // 8. Initial Payment (Only for new orders)
                      if (!isEditing) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.incomeGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.incomeGreen.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.payments_outlined, color: AppColors.incomeGreen, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'عربون / دفعة أولى الآن (اختياري)',
                                    style: TextStyle(
                                      color: AppColors.incomeGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                      decoration: _inputDecoration('مبلغ العربون (ج.م)', Icons.attach_money_rounded),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      value: _paymentMethod,
                                      dropdownColor: AppColors.surfaceDark,
                                      style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                                      decoration: _inputDecoration('طريقة الدفع', Icons.payment_outlined),
                                      items: _paymentMethods.map((m) {
                                        return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 11)));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _paymentMethod = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // 9. Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                        decoration: _inputDecoration('ملاحظات خاصة بالعميل أو الاتفاق', Icons.note_alt_outlined),
                      ),
                      const SizedBox(height: 20),

                      // Submit Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentGold,
                                foregroundColor: AppColors.backgroundDark,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.check_circle_outline_rounded),
                              label: Text(
                                isEditing ? 'حفظ التعديلات' : 'حفظ وإنشاء الطلب',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  double? initialPayment;
                                  if (_initialPaymentController.text.trim().isNotEmpty) {
                                    initialPayment = double.tryParse(_initialPaymentController.text.trim());
                                  }

                                  String desc = _descController.text.trim();
                                  if (desc.isEmpty && _sections.isNotEmpty) {
                                    final buf = StringBuffer();
                                    for (final s in _sections) {
                                      buf.writeln('• ${s.title}: ${s.description}');
                                    }
                                    desc = buf.toString().trim();
                                  }

                                  widget.onSave(
                                    customerName: _nameController.text.trim(),
                                    phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
                                    orderDescription: desc,
                                    startDate: _startDate,
                                    deliveryDate: _deliveryDate,
                                    totalAmount: double.parse(_totalAmountController.text.trim()),
                                    status: _status,
                                    notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
                                    sections: _sections,
                                    initialPayment: initialPayment,
                                    paymentMethod: _paymentMethod,
                                    paymentNotes: _paymentNotesController.text.trim().isNotEmpty ? _paymentNotesController.text.trim() : null,
                                    recordAsIncome: _recordAsIncome,
                                  );

                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textMuted,
                                side: const BorderSide(color: AppColors.surfaceBorder),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('إلغاء'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
