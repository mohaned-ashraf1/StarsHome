import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import 'add_edit_inventory_item_dialog.dart';
import 'stock_movement_dialog.dart';
import 'material_shortages_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invProvider = Provider.of<InventoryProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text(
          'إدارة المخزون والخامات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          labelColor: AppColors.accentGold,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2_rounded, size: 20),
              text: 'الأصناف (${invProvider.items.length})',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: invProvider.lowStockCount > 0,
                label: Text('${invProvider.lowStockCount}'),
                backgroundColor: AppColors.expenseRed,
                child: const Icon(Icons.warning_amber_rounded, size: 20),
              ),
              text: 'نواقص وخامات',
            ),
            const Tab(
              icon: Icon(Icons.history_rounded, size: 20),
              text: 'حركات المخزن',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.backgroundDark,
        icon: const Icon(Icons.add),
        label: const Text('إضافة صنف جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddEditInventoryItemDialog(),
          );
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: ALL INVENTORY ITEMS
          _buildItemsTab(context, invProvider),

          // TAB 2: SHORTAGES & LOW STOCK ALERTS
          _buildShortagesTab(context, invProvider),

          // TAB 3: MOVEMENTS LEDGER
          _buildMovementsTab(context, invProvider),
        ],
      ),
    );
  }

  Widget _buildItemsTab(BuildContext context, InventoryProvider invProvider) {
    return Column(
      children: [
        // Search & Category Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.cardNavy,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: InputDecoration(
                  hintText: 'بحث في الأصناف والخامات...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.accentGold),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            invProvider.setSearchQuery('');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (val) => invProvider.setSearchQuery(val),
              ),
              const SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: invProvider.availableCategories.map((cat) {
                    final isSelected = invProvider.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.accentGold,
                        backgroundColor: AppColors.surfaceHover,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.backgroundDark : AppColors.textWhite,
                        ),
                        onSelected: (_) => invProvider.setSelectedCategory(cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Low stock alert banner
        if (invProvider.lowStockCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.expenseRed.withOpacity(0.15),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.expenseRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تنبيه: يوجد ${invProvider.lowStockCount} أصناف وصلت للحد الأدنى من المخزون',
                    style: const TextStyle(fontSize: 12, color: AppColors.expenseRed, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // Items list
        Expanded(
          child: invProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
              : invProvider.filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 50, color: AppColors.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 10),
                          const Text('لا توجد أصناف تطابق البحث', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => invProvider.loadAll(),
                      color: AppColors.accentGold,
                      backgroundColor: AppColors.surfaceDark,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: invProvider.filteredItems.length,
                        itemBuilder: (ctx, index) {
                          final item = invProvider.filteredItems[index];
                          return _buildItemCard(context, item);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, InventoryItemModel item) {
    final isLow = item.isLowStock;

    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLow ? AppColors.expenseRed.withOpacity(0.6) : AppColors.surfaceBorder,
          width: isLow ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Category & Edit/Delete
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.materialName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textWhite,
                              ),
                            ),
                          ),
                          if (isLow) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.expenseRed.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('مخزون منخفض', style: TextStyle(fontSize: 10, color: AppColors.expenseRed, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(item.category, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.accentGold, size: 20),
                  tooltip: 'تعديل الصنف',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddEditInventoryItemDialog(itemToEdit: item),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 20),
                  tooltip: 'حذف الصنف نهائياً (سلة)',
                  onPressed: () => _confirmDeleteItem(context, item),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Stocks Summary Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardNavy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStockCol('الرصيد الفعلي', '${item.currentStock} ${item.unit}', AppColors.textWhite),
                  _buildStockCol('المحجوز للأوامر', '${item.reservedStock} ${item.unit}', AppColors.warningAmber),
                  _buildStockCol('المتاح للتشغيل', '${item.availableStock} ${item.unit}', AppColors.incomeGreen),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Pricing & Min Level info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.unitCost > 0)
                  Text('سعر الوحدة: ${CurrencyFormatter.format(item.unitCost)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted))
                else
                  const SizedBox(),
                if (item.minimumStockLevel > 0)
                  Text('حد الطلب: ${item.minimumStockLevel} ${item.unit}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.surfaceBorder, thickness: 0.5),

            // Quick Stock Movement Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.incomeGreen,
                      side: const BorderSide(color: AppColors.incomeGreen),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('وارد (+)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => StockMovementDialog(item: item, initialMovementType: 'receipt'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warningAmber,
                      side: const BorderSide(color: AppColors.warningAmber),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    icon: const Icon(Icons.remove, size: 16),
                    label: const Text('صرف (-)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => StockMovementDialog(item: item, initialMovementType: 'issue'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.infoBlue,
                      side: const BorderSide(color: AppColors.infoBlue),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('تسوية جرد', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => StockMovementDialog(item: item, initialMovementType: 'adjustment'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildShortagesTab(BuildContext context, InventoryProvider invProvider) {
    final lowStockItems = invProvider.lowStockItems;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Button to open Full Manufacturing Shortages Screen
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.backgroundDark,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.assignment_late_rounded),
          label: const Text(
            'عرض نواقص أوامر التصنيع الحالية وقوائم الطلب',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MaterialShortagesScreen()),
            );
          },
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.expenseRed, size: 20),
            const SizedBox(width: 8),
            Text(
              'أصناف المخزن التي وصلت لحد الأمان (${lowStockItems.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textWhite),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (lowStockItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('لا توجد أصناف وصلت لحد الأمان الأدنى حالياً', style: TextStyle(color: AppColors.textMuted)),
            ),
          )
        else
          ...lowStockItems.map((item) {
            return Card(
              color: AppColors.surfaceDark,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.expenseRed),
              ),
              child: ListTile(
                title: Text(item.materialName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textWhite, fontSize: 14)),
                subtitle: Text('الرصيد الفعلي: ${item.currentStock} ${item.unit} • حد الطلب: ${item.minimumStockLevel} ${item.unit}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.incomeGreen, padding: const EdgeInsets.symmetric(horizontal: 10)),
                  child: const Text('توريد وارد', style: TextStyle(color: AppColors.textWhite, fontSize: 11)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => StockMovementDialog(item: item, initialMovementType: 'receipt'),
                    );
                  },
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMovementsTab(BuildContext context, InventoryProvider invProvider) {
    final movements = invProvider.movements;

    if (movements.isEmpty) {
      return const Center(
        child: Text('لا توجد حركات مخزن مسجلة', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: movements.length,
      itemBuilder: (ctx, index) {
        final mov = movements[index];
        final item = invProvider.items.cast<InventoryItemModel?>().firstWhere(
          (i) => i?.id == mov.inventoryItemId,
          orElse: () => null,
        );

        Color movColor = AppColors.infoBlue;
        if (mov.movementType == 'receipt' || mov.movementType == 'return') movColor = AppColors.incomeGreen;
        if (mov.movementType == 'issue') movColor = AppColors.warningAmber;

        return Card(
          color: AppColors.surfaceDark,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: movColor.withOpacity(0.15),
              child: Icon(
                mov.movementType == 'receipt' ? Icons.add : (mov.movementType == 'issue' ? Icons.remove : Icons.swap_horiz),
                color: movColor,
              ),
            ),
            title: Text(
              item?.materialName ?? 'صنف خامات',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textWhite, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mov.movementTypeArabic}: ${mov.quantity} ${item?.unit ?? "وحدة"}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: movColor, fontSize: 12),
                ),
                if (mov.reasonNotes != null && mov.reasonNotes!.isNotEmpty)
                  Text(mov.reasonNotes!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(
                  '${DateHelper.formatYMD(mov.createdAt)} • بواسطة: ${mov.createdBy}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteItem(BuildContext context, InventoryItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('حذف الصنف من المخزن'),
        content: Text(
          'هل أنت متأكد من حذف الصنف "${item.materialName}" نهائياً من المخزن؟',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<InventoryProvider>(context, listen: false).deleteItem(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الصنف من المخزن بنجاح')),
                );
              }
            },
            child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
