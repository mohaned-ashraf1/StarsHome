import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../models/material_shortage_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shortages_provider.dart';
import '../../providers/manufacturing_provider.dart';
import 'add_edit_shortage_dialog.dart';

class ShortagesScreen extends StatefulWidget {
  const ShortagesScreen({super.key});

  @override
  State<ShortagesScreen> createState() => _ShortagesScreenState();
}

class _ShortagesScreenState extends State<ShortagesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShortagesProvider>(context, listen: false).loadAll();
      Provider.of<ManufacturingProvider>(context, listen: false).loadAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddShortageDialog({MaterialShortageModel? shortageToEdit}) {
    showDialog(
      context: context,
      builder: (_) => AddEditShortageDialog(shortageToEdit: shortageToEdit),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'shortage':
        return AppColors.expenseRed;
      case 'in_progress':
        return AppColors.warningAmber;
      case 'resolved':
        return AppColors.incomeGreen;
      case 'reopened':
        return AppColors.purpleWorker;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortagesProvider = Provider.of<ShortagesProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final filtered = shortagesProvider.filteredShortages;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_late_rounded, color: AppColors.accentGold, size: 22),
            SizedBox(width: 8),
            Text(
              'النواقص — إدارة احتياجات الخامات',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accentGold),
            tooltip: 'تحديث النواقص',
            onPressed: () => shortagesProvider.loadAll(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryNavy,
        icon: const Icon(Icons.add_rounded, fontWeight: FontWeight.bold),
        label: const Text(
          'إضافة خامة ناقصة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _openAddShortageDialog(),
      ),
      body: Column(
        children: [
          // SUMMARY COUNTER CARDS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.cardNavy,
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricBadge(
                    title: 'نواقص نشطة',
                    count: shortagesProvider.activeCount,
                    color: AppColors.expenseRed,
                    icon: Icons.error_outline_rounded,
                    isSelected: shortagesProvider.selectedStatusFilter == 'ناقص' || shortagesProvider.selectedStatusFilter == 'النشطة فقط',
                    onTap: () {
                      shortagesProvider.setStatusFilter(
                        shortagesProvider.selectedStatusFilter == 'ناقص' ? 'الكل' : 'ناقص',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricBadge(
                    title: 'تم توفيرها',
                    count: shortagesProvider.resolvedCount,
                    color: AppColors.incomeGreen,
                    icon: Icons.check_circle_outline_rounded,
                    isSelected: shortagesProvider.selectedStatusFilter == 'تم الحل',
                    onTap: () {
                      shortagesProvider.setStatusFilter(
                        shortagesProvider.selectedStatusFilter == 'تم الحل' ? 'الكل' : 'تم الحل',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricBadge(
                    title: 'إجمالي السجلات',
                    count: shortagesProvider.shortages.length,
                    color: AppColors.infoBlue,
                    icon: Icons.list_alt_rounded,
                    isSelected: shortagesProvider.selectedStatusFilter == 'الكل',
                    onTap: () => shortagesProvider.setStatusFilter('الكل'),
                  ),
                ),
              ],
            ),
          ),

          // SEARCH BAR & FILTER CHIPS
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            color: AppColors.cardNavy,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'بحث باسم الخامة، المواصفات، أمر التصنيع، المسؤول...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentGold, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              shortagesProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                  ),
                  onChanged: (val) => shortagesProvider.setSearchQuery(val),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('الكل', 'الكل', shortagesProvider),
                      _buildFilterChip('ناقص (مطلوب)', 'ناقص', shortagesProvider, color: AppColors.expenseRed),
                      _buildFilterChip('جارٍ المتابعة', 'جارٍ المتابعة', shortagesProvider, color: AppColors.warningAmber),
                      _buildFilterChip('أعيد فتحه', 'أعيد فتحه', shortagesProvider, color: AppColors.purpleWorker),
                      _buildFilterChip('تم الحل', 'تم الحل', shortagesProvider, color: AppColors.incomeGreen),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // SHORTAGES LIST
          Expanded(
            child: shortagesProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              shortagesProvider.selectedStatusFilter == 'تم الحل'
                                  ? Icons.history_rounded
                                  : Icons.check_circle_outline,
                              size: 56,
                              color: shortagesProvider.selectedStatusFilter == 'تم الحل'
                                  ? AppColors.textMuted
                                  : AppColors.incomeGreen,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              shortagesProvider.selectedStatusFilter == 'تم الحل'
                                  ? 'لا توجد نواقص محلولة في السجل حالياً'
                                  : 'لا توجد خامات ناقصة مسجلة',
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'اضغط على زر «إضافة خامة ناقصة» لتسجيل أي احتياج يدويًا',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => shortagesProvider.loadAll(),
                        color: AppColors.accentGold,
                        backgroundColor: AppColors.surfaceDark,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, idx) {
                            final item = filtered[idx];
                            return _buildShortageCard(item, shortagesProvider, auth.currentUser?.fullName ?? 'المدير');
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.18) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.surfaceBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.textWhite : AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    ShortagesProvider provider, {
    Color? color,
  }) {
    final isSelected = provider.selectedStatusFilter == value;
    final activeColor = color ?? AppColors.accentGold;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        backgroundColor: AppColors.surfaceDark,
        selectedColor: activeColor.withOpacity(0.2),
        checkmarkColor: activeColor,
        labelStyle: TextStyle(
          color: isSelected ? activeColor : AppColors.textMuted,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(color: isSelected ? activeColor : AppColors.surfaceBorder),
        onSelected: (_) => provider.setStatusFilter(value),
      ),
    );
  }

  Widget _buildShortageCard(
    MaterialShortageModel shortage,
    ShortagesProvider provider,
    String currentUserName,
  ) {
    final statusColor = _getStatusColor(shortage.status);
    final isResolved = shortage.isResolved;

    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isResolved ? AppColors.surfaceBorder : statusColor.withOpacity(0.5),
          width: isResolved ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Material Name + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shortage.materialName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isResolved ? AppColors.textMuted : AppColors.textWhite,
                          decoration: isResolved ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Text(
                              'الكمية: ${shortage.quantityDisplay}',
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (shortage.manufacturingOrderNumber != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.primaryGreen),
                              ),
                              child: Text(
                                'أمر: ${shortage.manufacturingOrderNumber}',
                                style: const TextStyle(
                                  color: AppColors.incomeGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    shortage.statusArabic,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Specifications & Notes
            if (shortage.specifications != null && shortage.specifications!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المواصفات: ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  Expanded(
                    child: Text(
                      shortage.specifications!,
                      style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            if (shortage.notes != null && shortage.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ملاحظات: ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  Expanded(
                    child: Text(
                      shortage.notes!,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),
            const Divider(color: AppColors.surfaceBorder, height: 1),
            const SizedBox(height: 8),

            // Metadata: Recorded by, Recorded date, Resolved by
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سجله: ${shortage.recordedBy} • ${DateHelper.formatYMD(shortage.recordedAt)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                if (isResolved && shortage.resolvedBy != null)
                  Text(
                    'تم الحل بواسطة: ${shortage.resolvedBy}',
                    style: const TextStyle(color: AppColors.incomeGreen, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Action Buttons Strip
            Row(
              children: [
                if (!isResolved) ...[
                  // Primary Resolve Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.incomeGreen,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text(
                        'تم توفير الخامة (تم الحل)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () async {
                        await provider.resolveShortage(
                          shortageId: shortage.id,
                          resolvedBy: currentUserName,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم تأكيد توفير خامة "${shortage.materialName}" وحفظها في السجل'),
                              backgroundColor: AppColors.incomeGreen,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ] else ...[
                  // Reopen Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warningAmber,
                        side: const BorderSide(color: AppColors.warningAmber),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text(
                        'إعادة فتح النقص (نقصت مجددًا)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () async {
                        await provider.reopenShortage(shortage.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تمت إعادة فتح نقص خامة "${shortage.materialName}" ونقلها للنواقص النشطة'),
                              backgroundColor: AppColors.warningAmber,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],

                const SizedBox(width: 8),
                // Edit Button
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.accentGold, size: 20),
                  tooltip: 'تعديل بيانات النقص',
                  onPressed: () => _openAddShortageDialog(shortageToEdit: shortage),
                ),
                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 20),
                  tooltip: 'حذف السجل',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.cardNavy,
                        title: const Text('حذف سجل النقص', style: TextStyle(color: AppColors.textWhite)),
                        content: Text(
                          'هل أنت متأكد من حذف نقص "${shortage.materialName}" نهائيًا؟',
                          style: const TextStyle(color: AppColors.textMuted),
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

                    if (confirm == true) {
                      await provider.deleteShortage(shortage.id);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
