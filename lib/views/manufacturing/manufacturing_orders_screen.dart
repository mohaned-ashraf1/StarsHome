import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../models/manufacturing_order_model.dart';
import '../../providers/manufacturing_provider.dart';
import '../../core/services/manufacturing_pdf_service.dart';
import 'create_manufacturing_order_screen.dart';
import 'manufacturing_order_details_screen.dart';

class ManufacturingOrdersScreen extends StatefulWidget {
  const ManufacturingOrdersScreen({super.key});

  @override
  State<ManufacturingOrdersScreen> createState() => _ManufacturingOrdersScreenState();
}

class _ManufacturingOrdersScreenState extends State<ManufacturingOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _statusFilters = [
    {'key': 'الكل', 'label': 'الكل'},
    {'key': 'new', 'label': 'جديد'},
    {'key': 'awaiting_materials', 'label': 'في انتظار الخامات'},
    {'key': 'ready_to_build', 'label': 'جاهز للتصنيع'},
    {'key': 'in_progress', 'label': 'قيد التصنيع'},
    {'key': 'completed', 'label': 'مكتمل'},
    {'key': 'cancelled', 'label': 'ملغي'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ManufacturingProvider>(context, listen: false).loadAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final mProvider = Provider.of<ManufacturingProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text(
          'أوامر التصنيع وبطاقات الورشة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.backgroundDark,
        icon: const Icon(Icons.add),
        label: const Text('أمر تصنيع جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateManufacturingOrderScreen()),
          );
          if (res == true) {
            mProvider.loadAll();
          }
        },
      ),
      body: Column(
        children: [
          // SEARCH & FILTER BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.cardNavy,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textWhite),
                  decoration: InputDecoration(
                    hintText: 'بحث برقم الأمر، المنتج، العميل، الصنايعي...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.accentGold),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              mProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => mProvider.setSearchQuery(val),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((flt) {
                      final isSelected = mProvider.selectedStatus == flt['key'];
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: FilterChip(
                          label: Text(flt['label']!),
                          selected: isSelected,
                          selectedColor: AppColors.accentGold,
                          backgroundColor: AppColors.surfaceHover,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.backgroundDark : AppColors.textWhite,
                          ),
                          onSelected: (_) => mProvider.setSelectedStatus(flt['key']!),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ORDERS LIST
          Expanded(
            child: mProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
                : mProvider.filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.precision_manufacturing_outlined, size: 54, color: AppColors.textMuted.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد أوامر تصنيع مسجلة',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => mProvider.loadAll(),
                        color: AppColors.accentGold,
                        backgroundColor: AppColors.surfaceDark,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: mProvider.filteredOrders.length,
                          itemBuilder: (ctx, index) {
                            final order = mProvider.filteredOrders[index];
                            return _buildOrderCard(context, order);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, ManufacturingOrderModel order) {
    final statusColor = _getStatusColor(order.status);

    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.surfaceBorder.withOpacity(0.8)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final mProvider = Provider.of<ManufacturingProvider>(context, listen: false);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManufacturingOrderDetailsScreen(order: order),
            ),
          );
          if (mounted) {
            mProvider.loadAll();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Order number & Status chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accentGold.withOpacity(0.6)),
                    ),
                    child: Text(
                      order.orderNumber,
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: statusColor.withOpacity(0.6)),
                    ),
                    child: Text(
                      order.statusArabic,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Product Title & Specs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                  Text(
                    'القطع: ${order.totalPiecesCount}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGoldLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              Text(
                'التصنيف: ${order.productCategory}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),

              // Dimensions display if available
              if (order.dimensions != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'المقاس: ${order.dimensions!.formattedDisplay}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textWhite),
                  ),
                ),
              ],

              const SizedBox(height: 10),
              const Divider(color: AppColors.surfaceBorder, thickness: 0.5),
              const SizedBox(height: 6),

              // Bottom Details Row: Dates & Print Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.customerName != null)
                        Text(
                          'العميل: ${order.customerName}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textWhite, fontWeight: FontWeight.w600),
                        ),
                      if (order.assignedWorkerName != null)
                        Text(
                          'الصنايعي: ${order.assignedWorkerName}',
                          style: const TextStyle(fontSize: 11, color: AppColors.purpleWorker),
                        ),
                      Text(
                        'التاريخ: ${DateHelper.formatYMD(order.manufacturingDate)}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.print_outlined, color: AppColors.accentGold, size: 22),
                        tooltip: 'طباعة سريعة لأمر التصنيع (PDF)',
                        onPressed: () => ManufacturingPdfService.printManufacturingOrder(context, order),
                      ),
                      const Icon(Icons.chevron_left, color: AppColors.textMuted, size: 20),
                    ],
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
