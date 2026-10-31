import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/furniture_templates.dart';
import '../../models/manufacturing_order_model.dart';
import '../../models/manufacturing_material_model.dart';
import '../../models/furniture_section_model.dart';
import '../../providers/manufacturing_provider.dart';
import '../../providers/workers_provider.dart';
import '../../providers/contractors_provider.dart';
import '../../providers/customers_provider.dart';
import '../../providers/auth_provider.dart';
import 'edit_furniture_component_dialog.dart';

class CreateManufacturingOrderScreen extends StatefulWidget {
  final String? initialCustomerOrderId;
  final String? initialCustomerName;
  final String? initialProductName;

  const CreateManufacturingOrderScreen({
    super.key,
    this.initialCustomerOrderId,
    this.initialCustomerName,
    this.initialProductName,
  });

  @override
  State<CreateManufacturingOrderScreen> createState() => _CreateManufacturingOrderScreenState();
}

class _MaterialRowData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController unitController = TextEditingController(text: 'لوح');
  final TextEditingController thicknessController = TextEditingController();
  final TextEditingController specsController = TextEditingController();
  final TextEditingController colorCodeController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String? linkedPiece;

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    unitController.dispose();
    thicknessController.dispose();
    specsController.dispose();
    colorCodeController.dispose();
    notesController.dispose();
  }
}

class _CreateManufacturingOrderScreenState extends State<CreateManufacturingOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  String _orderNumber = '#000101';
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _workerNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _manufacturingDate = DateTime.now();
  DateTime? _expectedCompletionDate = DateTime.now().add(const Duration(days: 14));
  String? _selectedWorkerId;
  String? _selectedCustomerOrderId;
  bool _isSaving = false;

  // Multi-section architecture
  final List<FurnitureSectionModel> _sections = [];

  // Materials rows
  final List<_MaterialRowData> _materialRows = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomerName != null) {
      _customerNameController.text = widget.initialCustomerName!;
    }
    _selectedCustomerOrderId = widget.initialCustomerOrderId;

    // Load next order number & seed default section
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final mProvider = Provider.of<ManufacturingProvider>(context, listen: false);
      final nextNum = await mProvider.getNextOrderNumber();
      if (mounted) {
        setState(() {
          _orderNumber = nextNum;
        });
      }

      // Leave sections and material rows completely empty so user starts clean without sample data
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _workerNameController.dispose();
    _notesController.dispose();
    for (var r in _materialRows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addSection(String sectionType) {
    final defaultComponents = FurnitureTemplates.generateDefaultComponents(sectionType);
    final sectionName = sectionType;

    setState(() {
      _sections.add(
        FurnitureSectionModel(
          sectionType: sectionType,
          sectionName: sectionName,
          components: defaultComponents,
        ),
      );
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sections.removeAt(index);
    });
  }

  void _addComponentToSection(int sectionIndex) {
    final section = _sections[sectionIndex];
    final newComp = FurnitureComponentModel(
      name: 'قطعة إضافية جديدة',
      category: section.sectionType,
      quantity: 1,
    );

    setState(() {
      _sections[sectionIndex] = section.copyWith(
        components: [...section.components, newComp],
      );
    });
  }

  Future<void> _editComponent(int sectionIndex, int compIndex) async {
    final section = _sections[sectionIndex];
    final comp = section.components[compIndex];

    final updated = await showDialog<FurnitureComponentModel>(
      context: context,
      builder: (_) => EditFurnitureComponentDialog(
        component: comp,
        sectionType: section.sectionType,
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        final newComps = List<FurnitureComponentModel>.from(section.components);
        newComps[compIndex] = updated;
        _sections[sectionIndex] = section.copyWith(components: newComps);
      });
    }
  }

  void _removeComponent(int sectionIndex, int compIndex) {
    final section = _sections[sectionIndex];
    setState(() {
      final newComps = List<FurnitureComponentModel>.from(section.components);
      newComps.removeAt(compIndex);
      _sections[sectionIndex] = section.copyWith(components: newComps);
    });
  }

  void _addMaterialRow({String? defaultName, String? defaultQty, String? defaultUnit}) {
    final row = _MaterialRowData();
    if (defaultName != null) row.nameController.text = defaultName;
    if (defaultQty != null) row.qtyController.text = defaultQty;
    if (defaultUnit != null) row.unitController.text = defaultUnit;

    setState(() {
      _materialRows.add(row);
    });
  }

  void _removeMaterialRow(int index) {
    if (_materialRows.length > 1) {
      setState(() {
        _materialRows[index].dispose();
        _materialRows.removeAt(index);
      });
    }
  }

  void _showAddSectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: AppColors.accentGold),
                  SizedBox(width: 8),
                  Text(
                    'اختر نوع قسم الأثاث لإضافته للأمر',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'يمكنك إضافة أكثر من قسم داخل نفس أمر التصنيع للعميل، وسيتم توليد المكونات الافتراضية تلقائيًا.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: FurnitureTemplates.availableSectionTypes.length,
                  itemBuilder: (context, idx) {
                    final item = FurnitureTemplates.availableSectionTypes[idx];
                    return Card(
                      color: AppColors.surfaceDark,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.surfaceBorder),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.weekend_rounded, color: AppColors.accentGold),
                        title: Text(
                          item['label']!,
                          style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.add_rounded, color: AppColors.incomeGreen),
                        onTap: () {
                          Navigator.pop(ctx);
                          _addSection(item['type']!);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة قسم أثاث واحد على الأقل داخل أمر التصنيع'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final mProvider = Provider.of<ManufacturingProvider>(context, listen: false);

    try {
      // Build order title from section names
      final productSummary = _sections.map((s) => s.sectionName).join(' + ');
      final totalQuantity = _sections.fold(0, (sum, s) => sum + s.totalPiecesCount);

      final order = ManufacturingOrderModel(
        orderNumber: _orderNumber,
        customerOrderId: _selectedCustomerOrderId,
        customerName: _customerNameController.text.trim().isNotEmpty ? _customerNameController.text.trim() : null,
        productName: productSummary.isNotEmpty ? productSummary : 'أمر تصنيع أثاث',
        productCategory: _sections.first.sectionType,
        quantity: totalQuantity > 0 ? totalQuantity : 1,
        manufacturingDate: _manufacturingDate,
        expectedCompletionDate: _expectedCompletionDate,
        assignedWorkerId: _selectedWorkerId,
        assignedWorkerName: _workerNameController.text.trim().isNotEmpty ? _workerNameController.text.trim() : null,
        status: 'new',
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        sections: _sections,
        createdBy: auth.currentUser?.signature ?? (auth.isOwner ? 'المالك' : 'المدير'),
      );

      // Build materials list manually entered
      final List<ManufacturingMaterialModel> materials = [];
      for (var row in _materialRows) {
        final name = row.nameController.text.trim();
        final qty = double.tryParse(row.qtyController.text.trim()) ?? 0.0;
        final unit = row.unitController.text.trim();
        final thickness = row.thicknessController.text.trim();
        final specs = row.specsController.text.trim();
        final color = row.colorCodeController.text.trim();
        final notes = row.notesController.text.trim();

        if (name.isNotEmpty && qty > 0) {
          materials.add(
            ManufacturingMaterialModel(
              manufacturingOrderId: order.id,
              materialName: name,
              requiredQuantity: qty,
              unit: unit.isNotEmpty ? unit : 'لوح',
              thicknessGrade: thickness.isNotEmpty ? thickness : null,
              specifications: specs.isNotEmpty ? specs : null,
              colorCode: color.isNotEmpty ? color : null,
              linkedPiece: row.linkedPiece,
              notes: notes.isNotEmpty ? notes : null,
            ),
          );
        }
      }

      // Save order without deducting inventory
      await mProvider.createOrder(
        order: order,
        materials: materials,
        autoReserveStock: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء أمر التصنيع $_orderNumber بنجاح بحفظ ${_sections.length} أقسام و${materials.length} خامات'),
            backgroundColor: AppColors.incomeGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء حفظ أمر التصنيع: $e'),
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
    final workersProvider = Provider.of<WorkersProvider>(context);
    final contractorsProvider = Provider.of<ContractorsProvider>(context);
    final customersProvider = Provider.of<CustomersProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.post_add_rounded, color: AppColors.accentGold, size: 22),
            const SizedBox(width: 8),
            Text(
              'إنشاء أمر تصنيع جديد ($_orderNumber)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // 1. GENERAL INFO SECTION
            _buildCardContainer(
              title: 'البيانات الأساسية لأمر التصنيع والعميل',
              icon: Icons.person_pin_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Order Number
                      Expanded(
                        child: _buildReadOnlyField(
                          label: 'رقم أمر التصنيع',
                          value: _orderNumber,
                          icon: Icons.tag_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Manufacturing Date
                      Expanded(
                        child: _buildDatePicker(
                          label: 'تاريخ بدء التصنيع',
                          selectedDate: _manufacturingDate,
                          onDateSelected: (d) => setState(() => _manufacturingDate = d),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Expected Completion Date
                      Expanded(
                        child: _buildDatePicker(
                          label: 'موعد التسليم المتوقع',
                          selectedDate: _expectedCompletionDate,
                          onDateSelected: (d) => setState(() => _expectedCompletionDate = d),
                          isHighlight: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      // Customer Field
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('اسم العميل *', style: TextStyle(color: AppColors.textWhite, fontSize: 12)),
                            const SizedBox(height: 4),
                            Autocomplete<String>(
                              initialValue: TextEditingValue(text: _customerNameController.text),
                              optionsBuilder: (TextEditingValue val) {
                                if (val.text.isEmpty) return const Iterable<String>.empty();
                                return customersProvider.orders
                                    .map((o) => o.customerName)
                                    .toSet()
                                    .where((name) => name.toLowerCase().contains(val.text.toLowerCase()));
                              },
                              onSelected: (selection) {
                                _customerNameController.text = selection;
                                final match = customersProvider.orders.cast<dynamic>().firstWhere(
                                      (o) => o.customerName == selection,
                                      orElse: () => null,
                                    );
                                if (match != null) {
                                  _selectedCustomerOrderId = match.id;
                                }
                              },
                              fieldViewBuilder: (ctx, fieldController, focusNode, onFieldSubmitted) {
                                fieldController.addListener(() {
                                  _customerNameController.text = fieldController.text;
                                });
                                return TextFormField(
                                  controller: fieldController,
                                  focusNode: focusNode,
                                  style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'اكتب اسم العميل أو اختر من القائمة',
                                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    filled: true,
                                    fillColor: AppColors.surfaceDark,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.accentGold, size: 20),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم العميل مطلوب' : null,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Assigned Worker / Workshop
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الصنايعي أو الورشة المسؤولة', style: TextStyle(color: AppColors.textWhite, fontSize: 12)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _selectedWorkerId,
                              dropdownColor: AppColors.surfaceDark,
                              isExpanded: true,
                              style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'اختر صنايعي أو ورشة خارجية',
                                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                filled: true,
                                fillColor: AppColors.surfaceDark,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                prefixIcon: const Icon(Icons.engineering_rounded, color: AppColors.accentGold, size: 20),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('لم يحدد بعد / ورشة عامة', style: TextStyle(color: AppColors.textMuted)),
                                ),
                                ...workersProvider.workers.map((w) {
                                  return DropdownMenuItem<String>(
                                    value: w.id,
                                    child: Text('${w.fullName} (عامل مصنع)'),
                                  );
                                }),
                                ...contractorsProvider.contractors.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c.id,
                                    child: Text('${c.name} (${c.serviceType})'),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedWorkerId = val;
                                  if (val != null) {
                                    final w = workersProvider.workers.cast<dynamic>().firstWhere(
                                          (x) => x.id == val,
                                          orElse: () => null,
                                        );
                                    if (w != null) {
                                      _workerNameController.text = w.fullName;
                                    } else {
                                      final c = contractorsProvider.contractors.cast<dynamic>().firstWhere(
                                            (x) => x.id == val,
                                            orElse: () => null,
                                          );
                                      if (c != null) _workerNameController.text = c.name;
                                    }
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // General Notes
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ملاحظات عامة وتوجيهات للطلب', style: TextStyle(color: AppColors.textWhite, fontSize: 12)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'تعليمات الشحن، متطلبات التركيب، طريقة التغليف...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. FURNITURE SECTIONS & PRODUCTS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.weekend_rounded, color: AppColors.accentGold, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'الأقسام والمنتجات المطلوبة للتصنيع',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة قسم أثاث (+)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: _showAddSectionDialog,
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_sections.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardNavy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.weekend_outlined, color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 10),
                      const Text(
                        'لم يتم إضافة أي قسم أثاث حتى الآن',
                        style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: AppColors.primaryNavy),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة أول قسم (غرفة نوم / مطبخ / انتريه...)'),
                        onPressed: _showAddSectionDialog,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._sections.asMap().entries.map((entry) {
                final sIdx = entry.key;
                final section = entry.value;
                return _buildSectionCard(sIdx, section);
              }),

            const SizedBox(height: 24),

            // 3. REQUIRED RAW MATERIALS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.layers_rounded, color: AppColors.accentGold, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'الخامات المطلوبة للتصنيع (إدخال يدوي حر)',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة سطر خامة (+)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => _addMaterialRow(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'سجّل جميع الخامات والكميات المطلوبة لأمر التصنيع يدويًا دون أي ارتباط بأرصدة مخزون أو خصومات تلقائية.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 10),

            _buildMaterialsTable(),

            const SizedBox(height: 24),

            // 4. SUMMARY & ACTION BUTTON
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardNavy,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accentGold.withOpacity(0.5), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ملخص محتويات أمر التصنيع',
                        style: TextStyle(color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_sections.length} أقسام أثاث  •  ${_sections.fold(0, (s, sec) => s + sec.totalPiecesCount)} قطعة مطلوبة  •  ${_materialRows.where((r) => r.nameController.text.isNotEmpty).length} بنود خامات مسجلة',
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: AppColors.primaryNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 3,
                    ),
                    icon: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy))
                        : const Icon(Icons.check_circle_rounded, size: 22),
                    label: Text(
                      _isSaving ? 'جاري الحفظ...' : 'حفظ ومراجعة أمر التصنيع',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: _isSaving ? null : _submitOrder,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(int sIdx, FurnitureSectionModel section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        collapsedIconColor: AppColors.accentGold,
        iconColor: AppColors.accentGold,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.meeting_room_outlined, color: AppColors.accentGold, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.sectionName,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${section.components.length} مكونات • إجمالي ${section.totalPiecesCount} قطعة',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 20),
              tooltip: 'حذف هذا القسم بالكامل',
              onPressed: () => _removeSection(sIdx),
            ),
          ],
        ),
        children: [
          const Divider(color: AppColors.surfaceBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Components list inside section
                ...section.components.asMap().entries.map((cEntry) {
                  final cIdx = cEntry.key;
                  final comp = cEntry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        // Quantity Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
                          ),
                          child: Text(
                            '${comp.quantity}x',
                            style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comp.name,
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                comp.dimensionsSummary,
                                style: const TextStyle(color: AppColors.accentGold, fontSize: 11),
                              ),
                              if (comp.specsSummary.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  comp.specsSummary,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Action buttons
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: AppColors.accentGold, size: 22),
                          tooltip: 'تعديل المقاسات والخامات الخاصة بالقطعة',
                          onPressed: () => _editComponent(sIdx, cIdx),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                          tooltip: 'حذف القطعة',
                          onPressed: () => _removeComponent(sIdx, cIdx),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.accentGold),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: Text('إضافة قطعة أخرى لقسم ${section.sectionName} (+)'),
                    onPressed: () => _addComponentToSection(sIdx),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('اسم الخامة *', style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                Expanded(flex: 1, child: Text('الكمية', style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                Expanded(flex: 1, child: Text('الوحدة', style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('السمك/المواصفات', style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('اللون/ملاحظات', style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold))),
                SizedBox(width: 36, child: Text('حذف', style: TextStyle(color: AppColors.textMuted, fontSize: 11), textAlign: TextAlign.center)),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),

          // Table Rows or Empty State
          if (_materialRows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      'لم يتم إضافة خامات مطلوبة بعد لهذا الطلب.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceDark,
                        foregroundColor: AppColors.accentGold,
                        side: const BorderSide(color: AppColors.surfaceBorder),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة سطر خامة (+)'),
                      onPressed: () => _addMaterialRow(),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _materialRows.length,
              separatorBuilder: (_, _) => const Divider(color: AppColors.surfaceBorder, height: 1),
            itemBuilder: (ctx, idx) {
              final row = _materialRows[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    // Material Name with Autocomplete
                    Expanded(
                      flex: 3,
                      child: Autocomplete<String>(
                        initialValue: TextEditingValue(text: row.nameController.text),
                        optionsBuilder: (val) {
                          if (val.text.isEmpty) return const Iterable<String>.empty();
                          return FurnitureTemplates.commonRawMaterials.where(
                            (m) => m.toLowerCase().contains(val.text.toLowerCase()),
                          );
                        },
                        onSelected: (sel) => row.nameController.text = sel,
                        fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
                          fieldController.addListener(() {
                            row.nameController.text = fieldController.text;
                          });
                          return TextFormField(
                            controller: fieldController,
                            focusNode: focusNode,
                            style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'اسم الخامة',
                              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              filled: true,
                              fillColor: AppColors.surfaceDark,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quantity
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: row.qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'الكمية',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Unit
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: FurnitureTemplates.standardUnits.contains(row.unitController.text)
                            ? row.unitController.text
                            : 'لوح',
                        dropdownColor: AppColors.surfaceDark,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        items: FurnitureTemplates.standardUnits.map((u) {
                          return DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 11)));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) row.unitController.text = v;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Thickness / Specs
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: row.specsController,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'سمك / مواصفات',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Color / Notes
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: row.notesController,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'كود اللون / ملاحظات',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),

                    // Delete Row
                    SizedBox(
                      width: 36,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 18),
                        onPressed: () => _removeMaterialRow(idx),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Add row footer button
          Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.accentGold),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة سطر خامة آخر (+)'),
              onPressed: () => _addMaterialRow(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textWhite, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accentGold, size: 18),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textWhite, fontSize: 12)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) onDateSelected(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isHighlight ? AppColors.accentGold : AppColors.surfaceBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null ? DateHelper.formatYMD(selectedDate) : 'اختر تاريخ',
                  style: TextStyle(
                    color: isHighlight ? AppColors.accentGold : AppColors.textWhite,
                    fontSize: 12,
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: isHighlight ? AppColors.accentGold : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
