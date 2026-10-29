import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/furniture_section_model.dart';

class EditFurnitureComponentDialog extends StatefulWidget {
  final FurnitureComponentModel component;
  final String sectionType;

  const EditFurnitureComponentDialog({
    super.key,
    required this.component,
    required this.sectionType,
  });

  @override
  State<EditFurnitureComponentDialog> createState() => _EditFurnitureComponentDialogState();
}

class _EditFurnitureComponentDialogState extends State<EditFurnitureComponentDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _qtyController;
  late TextEditingController _notesController;

  // Dimensions controllers
  late TextEditingController _heightController;
  late TextEditingController _widthController;
  late TextEditingController _depthController;
  late TextEditingController _lengthController;
  late TextEditingController _headboardController;
  late TextEditingController _seatHeightController;
  String _dimensionUnit = 'سم';

  // Common Specs Controllers
  late TextEditingController _woodTypeController;
  late TextEditingController _thicknessController;
  late TextEditingController _finishController;
  late TextEditingController _notesSpecificController;

  // Bed & Upholstery specific
  bool _hasUpholstery = false;
  late TextEditingController _fabricTypeController;
  late TextEditingController _fabricCodeController;
  late TextEditingController _foamDensityController;
  late TextEditingController _cushionsController;
  late TextEditingController _baseTypeController;
  late TextEditingController _storageDrawersController;
  late TextEditingController _legsTypeController;

  // Wardrobe & Cabinet specific
  int _doorsCount = 2;
  String _doorType = 'مفصلي'; // مفصلي / جرار
  int _shelvesCount = 3;
  int _drawersCount = 2;
  bool _hasMirror = false;
  late TextEditingController _mirrorSpecsController;
  late TextEditingController _backSpecController;
  late TextEditingController _accessoriesController;

  // Dining & Table specific
  String _tableShape = 'مستطيل'; // مستطيل / دائري / بيضاوي
  bool _hasExtension = false;
  late TextEditingController _topMaterialController;
  late TextEditingController _tableBaseController;

  // Kitchen specific
  late TextEditingController _facadeMaterialController;
  late TextEditingController _carcassMaterialController;
  bool _hasPlumbingCutouts = false;
  bool _hasApplianceCutouts = false;
  bool _hasLighting = false;
  bool _hasCableHoles = false;

  @override
  void initState() {
    super.initState();
    final c = widget.component;
    _nameController = TextEditingController(text: c.name);
    _qtyController = TextEditingController(text: c.quantity.toString());
    _notesController = TextEditingController(text: c.notes ?? '');

    // Dimensions
    final d = c.dimensions;
    _heightController = TextEditingController(text: d['height']?.toString() ?? '');
    _widthController = TextEditingController(text: d['width']?.toString() ?? '');
    _depthController = TextEditingController(text: d['depth']?.toString() ?? '');
    _lengthController = TextEditingController(text: d['length']?.toString() ?? '');
    _headboardController = TextEditingController(text: d['headboard']?.toString() ?? '');
    _seatHeightController = TextEditingController(text: d['seat_height']?.toString() ?? '');
    _dimensionUnit = d['unit']?.toString() ?? 'سم';

    // Specs
    final s = c.specs;
    _woodTypeController = TextEditingController(text: s['wood_type']?.toString() ?? s['carcass_material']?.toString() ?? '');
    _thicknessController = TextEditingController(text: s['thickness']?.toString() ?? '');
    _finishController = TextEditingController(text: s['finish']?.toString() ?? '');
    _notesSpecificController = TextEditingController(text: s['internal_partitions']?.toString() ?? '');

    // Upholstery & Bed
    _hasUpholstery = s['has_upholstery'] == true || s['upholstery'] != null;
    _fabricTypeController = TextEditingController(text: s['fabric_type']?.toString() ?? '');
    _fabricCodeController = TextEditingController(text: s['fabric_code']?.toString() ?? '');
    _foamDensityController = TextEditingController(text: s['foam_type']?.toString() ?? '');
    _cushionsController = TextEditingController(text: s['cushions_count']?.toString() ?? '');
    _baseTypeController = TextEditingController(text: d['base_type']?.toString() ?? '');
    _storageDrawersController = TextEditingController(text: s['storage_drawers']?.toString() ?? '');
    _legsTypeController = TextEditingController(text: s['legs_type']?.toString() ?? s['legs']?.toString() ?? '');

    // Wardrobe
    _doorsCount = (s['doors_count'] as num?)?.toInt() ?? 2;
    _doorType = s['door_type']?.toString() ?? 'مفصلي';
    _shelvesCount = (s['shelves_count'] as num?)?.toInt() ?? 3;
    _drawersCount = (s['drawers_count'] as num?)?.toInt() ?? 2;
    _hasMirror = s['has_mirror'] == true;
    _mirrorSpecsController = TextEditingController(text: s['mirror_dimensions']?.toString() ?? s['mirror_specs']?.toString() ?? '');
    _backSpecController = TextEditingController(text: s['back_spec']?.toString() ?? '');
    _accessoriesController = TextEditingController(text: s['hinges_accessories']?.toString() ?? s['handles']?.toString() ?? '');

    // Dining
    _tableShape = s['table_shape']?.toString() ?? 'مستطيل';
    _hasExtension = s['extension_mechanism'] != null && !s['extension_mechanism'].toString().contains('بدون');
    _topMaterialController = TextEditingController(text: s['top_material']?.toString() ?? '');
    _tableBaseController = TextEditingController(text: s['base_type']?.toString() ?? '');

    // Kitchen & Office
    _facadeMaterialController = TextEditingController(text: s['facade_material']?.toString() ?? '');
    _carcassMaterialController = TextEditingController(text: s['carcass_material']?.toString() ?? '');
    _hasPlumbingCutouts = s['plumbing_cutouts'] != null;
    _hasApplianceCutouts = s['appliance_cutouts'] != null;
    _hasLighting = s['lighting'] != null;
    _hasCableHoles = s['cable_holes'] == true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _notesController.dispose();
    _heightController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _lengthController.dispose();
    _headboardController.dispose();
    _seatHeightController.dispose();
    _woodTypeController.dispose();
    _thicknessController.dispose();
    _finishController.dispose();
    _notesSpecificController.dispose();
    _fabricTypeController.dispose();
    _fabricCodeController.dispose();
    _foamDensityController.dispose();
    _cushionsController.dispose();
    _baseTypeController.dispose();
    _storageDrawersController.dispose();
    _legsTypeController.dispose();
    _mirrorSpecsController.dispose();
    _backSpecController.dispose();
    _accessoriesController.dispose();
    _topMaterialController.dispose();
    _tableBaseController.dispose();
    _facadeMaterialController.dispose();
    _carcassMaterialController.dispose();
    super.dispose();
  }

  void _saveComponent() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim()) ?? 1;

    final Map<String, dynamic> dimensions = {
      'unit': _dimensionUnit,
    };
    if (_heightController.text.isNotEmpty) dimensions['height'] = double.tryParse(_heightController.text) ?? _heightController.text;
    if (_widthController.text.isNotEmpty) dimensions['width'] = double.tryParse(_widthController.text) ?? _widthController.text;
    if (_depthController.text.isNotEmpty) dimensions['depth'] = double.tryParse(_depthController.text) ?? _depthController.text;
    if (_lengthController.text.isNotEmpty) dimensions['length'] = double.tryParse(_lengthController.text) ?? _lengthController.text;
    if (_headboardController.text.isNotEmpty) dimensions['headboard'] = _headboardController.text.trim();
    if (_seatHeightController.text.isNotEmpty) dimensions['seat_height'] = _seatHeightController.text.trim();
    if (_baseTypeController.text.isNotEmpty) dimensions['base_type'] = _baseTypeController.text.trim();

    final Map<String, dynamic> specs = {};
    if (_woodTypeController.text.isNotEmpty) specs['wood_type'] = _woodTypeController.text.trim();
    if (_thicknessController.text.isNotEmpty) specs['thickness'] = _thicknessController.text.trim();
    if (_finishController.text.isNotEmpty) specs['finish'] = _finishController.text.trim();
    if (_notesSpecificController.text.isNotEmpty) specs['internal_partitions'] = _notesSpecificController.text.trim();

    // Upholstery
    if (_hasUpholstery) {
      specs['has_upholstery'] = true;
      if (_fabricTypeController.text.isNotEmpty) specs['fabric_type'] = _fabricTypeController.text.trim();
      if (_fabricCodeController.text.isNotEmpty) specs['fabric_code'] = _fabricCodeController.text.trim();
      if (_foamDensityController.text.isNotEmpty) specs['foam_type'] = _foamDensityController.text.trim();
      if (_cushionsController.text.isNotEmpty) specs['cushions_count'] = int.tryParse(_cushionsController.text) ?? _cushionsController.text;
    }
    if (_storageDrawersController.text.isNotEmpty) specs['storage_drawers'] = _storageDrawersController.text.trim();
    if (_legsTypeController.text.isNotEmpty) specs['legs_type'] = _legsTypeController.text.trim();

    // Wardrobe & Cabinets
    final isWardrobeOrCabinet = name.contains('دولاب') || name.contains('كومود') || name.contains('تسريحة') || name.contains('بوفيه') || name.contains('نيش') || widget.sectionType.contains('مطبخ');
    if (isWardrobeOrCabinet) {
      specs['doors_count'] = _doorsCount;
      specs['door_type'] = _doorType;
      specs['shelves_count'] = _shelvesCount;
      specs['drawers_count'] = _drawersCount;
      if (_hasMirror) {
        specs['has_mirror'] = true;
        if (_mirrorSpecsController.text.isNotEmpty) specs['mirror_dimensions'] = _mirrorSpecsController.text.trim();
      }
      if (_backSpecController.text.isNotEmpty) specs['back_spec'] = _backSpecController.text.trim();
      if (_accessoriesController.text.isNotEmpty) specs['hinges_accessories'] = _accessoriesController.text.trim();
    }

    // Tables
    if (name.contains('ترابيزة') || name.contains('سفرة') || name.contains('مكتب')) {
      specs['table_shape'] = _tableShape;
      if (_hasExtension) specs['extension_mechanism'] = 'سحاب / امتداد إضافي';
      if (_topMaterialController.text.isNotEmpty) specs['top_material'] = _topMaterialController.text.trim();
      if (_tableBaseController.text.isNotEmpty) specs['base_type'] = _tableBaseController.text.trim();
    }

    // Kitchen
    if (widget.sectionType.contains('مطبخ')) {
      if (_facadeMaterialController.text.isNotEmpty) specs['facade_material'] = _facadeMaterialController.text.trim();
      if (_carcassMaterialController.text.isNotEmpty) specs['carcass_material'] = _carcassMaterialController.text.trim();
      if (_hasPlumbingCutouts) specs['plumbing_cutouts'] = 'فتحات سباكة وعزل مائي';
      if (_hasApplianceCutouts) specs['appliance_cutouts'] = 'فتحات للأجهزة البلت إن';
    }

    if (_hasLighting) specs['lighting'] = 'إضاءة ليد مخفي';
    if (_hasCableHoles) specs['cable_holes'] = true;

    final updated = widget.component.copyWith(
      name: name,
      quantity: qty,
      dimensions: dimensions,
      specs: specs,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final nameLower = widget.component.name.toLowerCase();
    final isBed = nameLower.contains('سرير');
    final isWardrobe = nameLower.contains('دولاب') || nameLower.contains('دريسنج');
    final isCommode = nameLower.contains('كومود');
    final isDresser = nameLower.contains('تسريحة') || nameLower.contains('مراية');
    final isLiving = widget.sectionType.contains('انتريه') || nameLower.contains('كنبة') || nameLower.contains('فوتيه') || nameLower.contains('بوف');
    final isDining = widget.sectionType.contains('سفرة') || nameLower.contains('سفرة') || nameLower.contains('بوفيه') || nameLower.contains('نيش');
    final isKitchen = widget.sectionType.contains('مطبخ');
    final isDesk = nameLower.contains('مكتب') || widget.sectionType.contains('مكتب');

    return Dialog(
      backgroundColor: AppColors.cardNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: 700,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
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
                          color: AppColors.accentGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppColors.accentGold, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تعديل تفاصيل: ${widget.component.name}',
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'قسم: ${widget.sectionType}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
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
                child: ListView(
                  children: [
                    // Row 1: Piece Name & Quantity
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: _nameController,
                            label: 'اسم القطعة *',
                            hint: 'مثال: سرير رئيسي، دولاب 3 دلف، كنبة 3 مقاعد...',
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _qtyController,
                            label: 'عدد القطع *',
                            hint: '1',
                            keyboardType: TextInputType.number,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SECTION: المقاسات والأبعاد
                    _buildSectionHeader('المقاسات والأبعاد الهندسية', Icons.square_foot_rounded),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _widthController,
                            label: isBed ? 'العرض (سم)' : 'العرض / الطول',
                            hint: isBed ? '160' : 'سم',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            controller: isBed ? _lengthController : _depthController,
                            label: isBed ? 'طول السرير (سم)' : 'العمق (سم)',
                            hint: isBed ? '200' : 'سم',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            controller: _heightController,
                            label: 'الارتفاع (سم)',
                            hint: 'سم',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),

                    if (isBed) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _headboardController,
                              label: 'مقاسات وتفاصيل ظهر السرير',
                              hint: 'عرض 160 × ارتفاع 120 سم مع تنجيد',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: _baseTypeController,
                              label: 'نوع قاعدة السرير (الممل)',
                              hint: 'ملل خشب زان / ألواح كونتر / كبتونيه',
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (isLiving) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _seatHeightController,
                              label: 'ارتفاع وعمق الجلسة',
                              hint: 'ارتفاع 45 سم × عمق 60 سم',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: _cushionsController,
                              label: 'عدد المخدات والخداديات',
                              hint: '5 خديدات فايبر سوفت',
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 18),

                    // SECTION: الخامات والسمك والتشطيب
                    _buildSectionHeader('الخامات والتصنيع والتشطيب', Icons.carpenter_rounded),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _woodTypeController,
                            label: isLiving ? 'نوع الهيكل الخشبي الداخلي' : 'نوع الخشب أو الألواح',
                            hint: isLiving ? 'خشب زان أحمر كتل' : 'كونتر اندونيسي / زان / MDF',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _thicknessController,
                            label: 'السمك',
                            hint: '18 مم / 25 مم',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _finishController,
                            label: 'نوع التشطيب والدهان',
                            hint: 'دوكو فرن مط / استر أرو / بولي يوريثان',
                          ),
                        ),
                      ],
                    ),

                    // WARDROBE & COMMODE & DRESSER FIELDS
                    if (isWardrobe || isCommode || isDresser || nameLower.contains('دولاب') || isDining) ...[
                      const SizedBox(height: 18),
                      _buildSectionHeader('الأبواب، الأدراج، والتفاصيل الداخلية', Icons.door_sliding_outlined),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('نوع الأبواب', style: TextStyle(color: AppColors.textWhite, fontSize: 12)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _doorType,
                                  dropdownColor: AppColors.surfaceDark,
                                  style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.surfaceDark,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'مفصلي', child: Text('أبواب مفصلية')),
                                    DropdownMenuItem(value: 'جرار', child: Text('أبواب جرار (سحاب)')),
                                    DropdownMenuItem(value: 'قلاب', child: Text('أبواب قلاب باكم')),
                                    DropdownMenuItem(value: 'بدون أبواب', child: Text('مفتوح / أرفف')),
                                  ],
                                  onChanged: (v) => setState(() => _doorType = v ?? 'مفصلي'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCounterPicker('عدد الأبواب', _doorsCount, (v) => setState(() => _doorsCount = v)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCounterPicker('عدد الأدراج', _drawersCount, (v) => setState(() => _drawersCount = v)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCounterPicker('عدد الأرفف', _shelvesCount, (v) => setState(() => _shelvesCount = v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _backSpecController,
                              label: 'مواصفات الظهر والتجليد',
                              hint: 'أبلكاش سيه 6 مم / كونتر',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: _accessoriesController,
                              label: 'المفصلات والمقابض والإكسسوارات',
                              hint: 'مفصلات هيدروليك باكم / مقابض استانلس ذهبي',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('هل توجد مراية؟', style: TextStyle(color: AppColors.textWhite, fontSize: 13)),
                        subtitle: const Text('مراية على الدلفة أو مراية تسريحة', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        value: _hasMirror,
                        activeColor: AppColors.accentGold,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _hasMirror = val),
                      ),
                      if (_hasMirror) ...[
                        _buildTextField(
                          controller: _mirrorSpecsController,
                          label: 'مقاسات ومواصفات المراية وسمك الزجاج',
                          hint: 'مراية بلجيكي مشطوف 6 مم مقاس 100×80 سم',
                        ),
                      ],
                    ],

                    // UPHOLSTERY FIELDS (Bed, Living, Saloon, Dining Chairs)
                    if (isBed || isLiving || isDining || nameLower.contains('كرسي')) ...[
                      const SizedBox(height: 18),
                      _buildSectionHeader('التنجيد، الأقمشة، والإسفنج', Icons.chair_rounded),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        title: const Text('يتضمن تنجيد (قماش / جلد / إسفنج)', style: TextStyle(color: AppColors.textWhite, fontSize: 13)),
                        value: _hasUpholstery,
                        activeColor: AppColors.accentGold,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _hasUpholstery = val),
                      ),
                      if (_hasUpholstery) ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _fabricTypeController,
                                label: 'نوع القماش أو الجلد',
                                hint: 'قطيفة / كتان تركي / جلد مقلوب',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: _buildTextField(
                                controller: _fabricCodeController,
                                label: 'كود اللون أو الخامة',
                                hint: 'K-402 / بيج فاتح',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _foamDensityController,
                                label: 'نوع الإسفنج وكثافته',
                                hint: 'إسفنج سوفت كثافة 36 / مضغوط',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _legsTypeController,
                          label: 'نوع وشكل الأرجل',
                          hint: 'أرجل خشب زان مخروطة / أرجل استانلس ذهبي',
                        ),
                      ],
                    ],

                    // DINING TABLE & DESK SPECIFIC
                    if (nameLower.contains('ترابيزة') || nameLower.contains('سفرة') || isDesk) ...[
                      const SizedBox(height: 18),
                      _buildSectionHeader('تفاصيل السطح والقاعدة والملحقات', Icons.table_bar_rounded),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _topMaterialController,
                              label: 'خامة سطح العمل / القرصة',
                              hint: 'قشرة أرو طبيعي / رخام كوارتز / HPL',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: _tableBaseController,
                              label: 'خامة وشكل القاعدة / الشاسيه',
                              hint: 'قاعدة زان مزدوجة / شاسيه صلب مط',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('آلية تمديد وسحاب للترابيزة', style: TextStyle(color: AppColors.textWhite, fontSize: 12)),
                              value: _hasExtension,
                              activeColor: AppColors.accentGold,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() => _hasExtension = val ?? false),
                            ),
                          ),
                          if (isDesk)
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('فتحات كابلات دائرية', style: TextStyle(color: AppColors.textWhite, fontSize: 12)),
                                value: _hasCableHoles,
                                activeColor: AppColors.accentGold,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setState(() => _hasCableHoles = val ?? false),
                              ),
                            ),
                        ],
                      ),
                    ],

                    // KITCHEN SPECIFIC
                    if (isKitchen) ...[
                      const SizedBox(height: 18),
                      _buildSectionHeader('تفاصيل وحدات المطبخ والمواصفات المعمارية', Icons.kitchen_rounded),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _facadeMaterialController,
                              label: 'خامة الواجهات والظلف',
                              hint: 'بولي لاك / HPL / جلوس ماكس / خشب زان',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: _carcassMaterialController,
                              label: 'خامة الشاسيه الداخلي (Carcass)',
                              hint: 'كونتر محشو ميلامين / PVC عازل للماء',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('فتحات سباكة وحوض معزولة', style: TextStyle(color: AppColors.textWhite, fontSize: 12)),
                              value: _hasPlumbingCutouts,
                              activeColor: AppColors.accentGold,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() => _hasPlumbingCutouts = v ?? false),
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('فتحات أجهزة بلت إن (فرن/شفاط)', style: TextStyle(color: AppColors.textWhite, fontSize: 12)),
                              value: _hasApplianceCutouts,
                              activeColor: AppColors.accentGold,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() => _hasApplianceCutouts = v ?? false),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Extra features: Lighting & Storage
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('إضاءة ليد مخفية (LED Strip / Spot)', style: TextStyle(color: AppColors.textWhite, fontSize: 12)),
                      value: _hasLighting,
                      activeColor: AppColors.accentGold,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _hasLighting = v ?? false),
                    ),

                    const SizedBox(height: 12),
                    // General Notes for piece
                    _buildTextField(
                      controller: _notesController,
                      label: 'ملاحظات وتوجيهات خاصة بالصنايعي لهذه القطعة',
                      hint: 'أي تفاصيل خاصة بالتجميع، التقسيمات، أو الملحقات...',
                      maxLines: 2,
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
                      onPressed: _saveComponent,
                      child: const Text(
                        'حفظ بيانات القطعة',
                        style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentGold, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.accentGold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: AppColors.surfaceBorder)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textWhite, fontSize: 12)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            filled: true,
            fillColor: AppColors.surfaceDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: isRequired ? (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null : null,
        ),
      ],
    );
  }

  Widget _buildCounterPicker(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textWhite, fontSize: 11), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: value > 0 ? () => onChanged(value - 1) : null,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.remove, size: 16, color: AppColors.textWhite),
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              InkWell(
                onTap: () => onChanged(value + 1),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.add, size: 16, color: AppColors.textWhite),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
