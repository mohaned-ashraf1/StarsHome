import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../models/manufacturing_order_model.dart';
import '../../providers/manufacturing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/manufacturing_pdf_service.dart';
import '../shortages/add_edit_shortage_dialog.dart';

class ManufacturingOrderDetailsScreen extends StatefulWidget {
  final ManufacturingOrderModel order;

  const ManufacturingOrderDetailsScreen({super.key, required this.order});

  @override
  State<ManufacturingOrderDetailsScreen> createState() => _ManufacturingOrderDetailsScreenState();
}

class _ManufacturingOrderDetailsScreenState extends State<ManufacturingOrderDetailsScreen> {
  late ManufacturingOrderModel _order;
  bool _isActionRunning = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  void _refreshOrder() {
    final mProvider = Provider.of<ManufacturingProvider>(context, listen: false);
    final match = mProvider.orders.cast<ManufacturingOrderModel?>().firstWhere(
      (o) => o?.id == _order.id,
      orElse: () => null,
    );
    if (match != null && mounted) {
      setState(() {
        _order = match;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final mProvider = Provider.of<ManufacturingProvider>(context, listen: false);
    setState(() => _isActionRunning = true);
    await mProvider.updateOrderStatus(orderId: _order.id, newStatus: newStatus);
    _refreshOrder();
    if (mounted) setState(() => _isActionRunning = false);
  }

  Future<void> _startWorkshopProduction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('بدء تشغيل وتصنيع الأمر بالورشة', style: TextStyle(color: AppColors.textWhite)),
        content: const Text(
          'سيتم تحديث حالة أمر التصنيع إلى "قيد التصنيع" واعتماد جاهزية الخامات وبدء العمل.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.incomeGreen),
            child: const Text('تأكيد بدء التصنيع', style: TextStyle(color: AppColors.textWhite)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final mProvider = Provider.of<ManufacturingProvider>(context, listen: false);

    setState(() => _isActionRunning = true);
    try {
      await mProvider.issueMaterialsToWorkshop(
        orderId: _order.id,
        createdBy: auth.currentUser?.signature ?? (auth.isOwner ? 'المالك' : 'المدير'),
      );
      _refreshOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم بدء التصنيع وتحديث حالة أمر التشغيل بنجاح'),
            backgroundColor: AppColors.incomeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.expenseRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionRunning = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('حذف أمر التصنيع', style: TextStyle(color: AppColors.textWhite)),
        content: const Text(
          'هل أنت متأكد من حذف أمر التصنيع هذا نهائيًا؟',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            child: const Text('تأكيد الحذف', style: TextStyle(color: AppColors.textWhite)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final mProvider = Provider.of<ManufacturingProvider>(context, listen: false);
    final nav = Navigator.of(context);
    await mProvider.deleteOrder(_order.id);
    if (mounted) {
      nav.pop();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return AppColors.infoBlue;
      case 'awaiting_materials':
        return AppColors.warningAmber;
      case 'ready_to_build':
        return AppColors.purpleWorker;
      case 'in_progress':
        return AppColors.accentGold;
      case 'completed':
        return AppColors.incomeGreen;
      case 'cancelled':
        return AppColors.expenseRed;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_order.status);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text(
          'أمر تصنيع ${_order.orderNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: AppColors.accentGold),
            tooltip: 'طباعة بطاقة التصنيع (PDF)',
            onPressed: () => ManufacturingPdfService.printManufacturingOrder(context, _order),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed),
            tooltip: 'حذف أمر التصنيع',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _isActionRunning
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // STATUS & OVERVIEW CARD
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardNavy,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _order.displayTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_order.productCategory} • إجمالي القطع: ${_order.totalPiecesCount} قطعة',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              _order.statusArabic,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.surfaceBorder, thickness: 1),
                      const SizedBox(height: 8),

                      // Status Selector Dropdown
                      Row(
                        children: [
                          const Text('تغيير الحالة: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.surfaceBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _order.status,
                                  dropdownColor: AppColors.surfaceDark,
                                  isExpanded: true,
                                  style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                                  items: const [
                                    DropdownMenuItem(value: 'new', child: Text('جديد')),
                                    DropdownMenuItem(value: 'awaiting_materials', child: Text('في انتظار الخامات')),
                                    DropdownMenuItem(value: 'ready_to_build', child: Text('جاهز للتصنيع')),
                                    DropdownMenuItem(value: 'in_progress', child: Text('قيد التصنيع')),
                                    DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
                                    DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) _updateStatus(val);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // CLIENT & WORKER CARD
                _buildSectionHeader('بيانات العميل والصنايعي المسؤول', Icons.badge_outlined),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 18, color: AppColors.accentGold),
                              const SizedBox(width: 6),
                              Text(
                                'العميل: ${_order.customerName ?? "غير مسجل بالاسم"}',
                                style: const TextStyle(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.engineering_outlined, size: 18, color: AppColors.accentGold),
                              const SizedBox(width: 6),
                              Text(
                                'المسؤول: ${_order.assignedWorkerName ?? "ورشة المصنع"}',
                                style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: AppColors.surfaceBorder, thickness: 0.5),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'تاريخ البدء: ${DateHelper.formatYMD(_order.manufacturingDate)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          if (_order.expectedCompletionDate != null)
                            Text(
                              'التسليم المتوقع: ${DateHelper.formatYMD(_order.expectedCompletionDate!)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.accentGold, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // FURNITURE SECTIONS (If multi-section)
                if (_order.sections.isNotEmpty) ...[
                  _buildSectionHeader('أقسام الأثاث والمكونات (${_order.sections.length} أقسام)', Icons.weekend_rounded),
                  ..._order.sections.map((section) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                section.sectionName,
                                style: const TextStyle(
                                  color: AppColors.accentGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${section.totalPiecesCount} قطعة',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Divider(color: AppColors.surfaceBorder, thickness: 0.5),
                          const SizedBox(height: 6),
                          ...section.components.map((comp) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${comp.quantity}x ',
                                    style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comp.name,
                                          style: const TextStyle(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          comp.dimensionsSummary,
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                        ),
                                        if (comp.specsSummary.isNotEmpty)
                                          Text(
                                            comp.specsSummary,
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                ],

                // RAW MATERIALS LIST
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('الخامات المطلوبة للتصنيع (${_order.materials.length} خامات)', Icons.layers_rounded),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: AppColors.expenseRed),
                      icon: const Icon(Icons.report_problem_outlined, size: 16),
                      label: const Text('تسجيل خامة ناقصة', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddEditShortageDialog(
                            initialOrderId: _order.id,
                            initialOrderNumber: _order.orderNumber,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      if (_order.materials.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(
                            child: Text('لا توجد خامات مسجلة لهذا الأمر', style: TextStyle(color: AppColors.textMuted)),
                          ),
                        )
                      else
                        ..._order.materials.map((mat) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.cardNavy,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mat.materialName,
                                        style: const TextStyle(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      if (mat.specifications != null || mat.thicknessGrade != null)
                                        Text(
                                          '${mat.thicknessGrade ?? ""} ${mat.specifications ?? ""}',
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceDark,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    mat.quantityDisplay,
                                    style: const TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // NOTES CARD
                if (_order.notes != null && _order.notes!.isNotEmpty) ...[
                  _buildSectionHeader('ملاحظات وتعليمات المصنع', Icons.notes_rounded),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Text(
                      _order.notes!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textWhite),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ACTION BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.incomeGreen,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('بدء التصنيع في الورشة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: _startWorkshopProduction,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentGold,
                          side: const BorderSide(color: AppColors.accentGold),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('طباعة بطاقة الورشة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () => ManufacturingPdfService.printManufacturingOrder(context, _order),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentGold, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.accentGold,
            ),
          ),
        ],
      ),
    );
  }
}
