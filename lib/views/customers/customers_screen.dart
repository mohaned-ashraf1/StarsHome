import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/customer_receipt_helper.dart';
import '../../core/utils/date_helper.dart';
import '../../models/customer_order_model.dart';
import '../../models/order_payment_model.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customers_provider.dart';
import 'add_edit_order_dialog.dart';
import 'add_payment_dialog.dart';
import 'order_detail_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customersProvider = Provider.of<CustomersProvider>(context);
    final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final filteredOrders = customersProvider.filteredOrders;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: const Text(
          'العملاء والطلبيات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accentGold),
            tooltip: 'تحديث البيانات',
            onPressed: () => customersProvider.loadAll(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.backgroundDark,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'إضافة طلب جديد',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddEditOrderDialog(
              onSave: ({
                required String customerName,
                String? phone,
                required String orderDescription,
                required DateTime startDate,
                DateTime? deliveryDate,
                required double totalAmount,
                required String status,
                String? notes,
                double? initialPayment,
                String paymentMethod = 'نقدي',
                String? paymentNotes,
                bool recordAsIncome = true,
              }) {
                final order = CustomerOrderModel(
                  customerName: customerName,
                  phone: phone,
                  orderDescription: orderDescription,
                  startDate: startDate,
                  deliveryDate: deliveryDate,
                  totalAmount: totalAmount,
                  status: status,
                  notes: notes,
                  createdBy: auth.currentUser?.fullName ?? 'المدير',
                );

                customersProvider.addOrder(
                  order,
                  initialPayment: initialPayment,
                  paymentMethod: paymentMethod,
                  paymentNotes: paymentNotes,
                  recordAsIncome: recordAsIncome,
                  accountsProvider: accountsProvider,
                );
              },
            ),
          );
        },
      ),
      body: customersProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : RefreshIndicator(
              onRefresh: () async => await customersProvider.loadAll(),
              color: AppColors.accentGold,
              backgroundColor: AppColors.surfaceDark,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Metric Overview Cards
                    _buildOverviewMetrics(customersProvider),
                    const SizedBox(height: 16),

                    // 2. Search & Filter Bar
                    _buildSearchAndFilters(context, customersProvider),
                    const SizedBox(height: 14),

                    // 3. Orders List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'قائمة الطلبيات (${filteredOrders.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                        ),
                        if (customersProvider.statusFilter != 'الكل' || customersProvider.searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              customersProvider.setStatusFilter('الكل');
                              customersProvider.setSearchQuery('');
                            },
                            child: const Text('إعادة ضبط الفلتر', style: TextStyle(fontSize: 11, color: AppColors.accentGold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 4. Orders Cards
                    if (filteredOrders.isEmpty)
                      _buildEmptyState(context, customersProvider)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredOrders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          final payments = customersProvider.getPaymentsForOrder(order.id);
                          return _buildOrderCard(
                            context: context,
                            order: order,
                            payments: payments,
                            provider: customersProvider,
                            accountsProvider: accountsProvider,
                            auth: auth,
                          );
                        },
                      ),
                    const SizedBox(height: 70), // Bottom padding for FAB
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewMetrics(CustomersProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'إجمالي الطلبات',
                  '${provider.orders.length}',
                  '${provider.activeOrdersCount} قيد التنفيذ',
                  AppColors.textWhite,
                  Icons.assignment_rounded,
                ),
              ),
              Container(width: 1, height: 45, color: AppColors.surfaceBorder),
              Expanded(
                child: _buildMetricItem(
                  'قيمة الطلبيات',
                  CurrencyFormatter.format(provider.totalOrdersValue),
                  'إجمالي الاتفاقات',
                  AppColors.accentGold,
                  Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'المحصل فعلياً',
                  CurrencyFormatter.format(provider.totalCollected),
                  '${provider.payments.length} دفعات مسددة',
                  AppColors.incomeGreen,
                  Icons.check_circle_rounded,
                ),
              ),
              Container(width: 1, height: 45, color: AppColors.surfaceBorder),
              Expanded(
                child: _buildMetricItem(
                  'المتبقي عند العملاء',
                  CurrencyFormatter.format(provider.totalRemainingBalance),
                  'مستحق التحصيل',
                  AppColors.expenseRed,
                  Icons.pending_actions_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, String subtitle, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, CustomersProvider provider) {
    return Column(
      children: [
        // Search TextField
        TextField(
          style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'بحث باسم العميل، الهاتف، أو مواصفات الطلب...',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            prefixIcon: const Icon(Icons.search, color: AppColors.accentGold, size: 20),
            suffixIcon: provider.searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                    onPressed: () => provider.setSearchQuery(''),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentGold, width: 1.5),
            ),
          ),
          onChanged: (val) => provider.setSearchQuery(val),
        ),
        const SizedBox(height: 10),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('الكل', provider),
              _buildFilterChip('in_progress', provider, label: 'قيد التنفيذ'),
              _buildFilterChip('ready', provider, label: 'جاهز للتسليم'),
              _buildFilterChip('delivered', provider, label: 'تم التسليم'),
              _buildFilterChip('cancelled', provider, label: 'ملغي'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String statusKey, CustomersProvider provider, {String? label}) {
    final isSelected = provider.statusFilter == statusKey;
    final displayLabel = label ?? statusKey;

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        label: Text(
          displayLabel,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? AppColors.backgroundDark : AppColors.textWhite,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.accentGold,
        backgroundColor: AppColors.surfaceDark,
        checkmarkColor: AppColors.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.accentGold : AppColors.surfaceBorder,
          ),
        ),
        onSelected: (_) => provider.setStatusFilter(statusKey),
      ),
    );
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required CustomerOrderModel order,
    required List<OrderPaymentModel> payments,
    required CustomersProvider provider,
    required AccountsProvider accountsProvider,
    required AuthProvider auth,
  }) {
    final totalPaid = order.calculateTotalPaid(payments);
    final remaining = order.calculateRemainingBalance(payments);
    final progress = order.paymentProgress(payments);
    final isSettled = remaining <= 0 && order.totalAmount > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSettled ? AppColors.incomeGreen.withOpacity(0.3) : AppColors.surfaceBorder,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Customer Name, Phone & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            order.phone?.isNotEmpty == true ? order.phone! : 'بدون رقم',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  بدء: ${DateHelper.formatDisplay(order.startDate)}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: order.statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: order.statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        order.statusArabicName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: order.statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.infoBlue, size: 18),
                      tooltip: 'تعديل الطلب والعميل',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddEditOrderDialog(
                            existingOrder: order,
                            onSave: ({
                              required String customerName,
                              String? phone,
                              required String orderDescription,
                              required DateTime startDate,
                              DateTime? deliveryDate,
                              required double totalAmount,
                              required String status,
                              String? notes,
                              double? initialPayment,
                              String? paymentMethod,
                              String? paymentNotes,
                              bool? recordAsIncome,
                            }) {
                              final updated = order.copyWith(
                                customerName: customerName,
                                phone: phone,
                                orderDescription: orderDescription,
                                startDate: startDate,
                                deliveryDate: deliveryDate,
                                totalAmount: totalAmount,
                                status: status,
                                notes: notes,
                              );
                              provider.updateOrder(updated);
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 18),
                      tooltip: 'حذف الطلبية (سلة)',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _confirmDeleteOrder(context, order, provider, accountsProvider);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Order Description Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 15, color: AppColors.accentGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.orderDescription,
                      style: const TextStyle(fontSize: 12, color: AppColors.textWhite),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Delivery Date Row
            if (order.deliveryDate != null) ...[
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 13, color: AppColors.infoBlue),
                  const SizedBox(width: 6),
                  Text(
                    'تاريخ التسليم: ${DateHelper.formatDisplay(order.deliveryDate!)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.infoBlue, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Financial Summary Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAmountColumn('الإجمالي', CurrencyFormatter.format(order.totalAmount), AppColors.textWhite),
                _buildAmountColumn('المسدد (${payments.length} دفعات)', CurrencyFormatter.format(totalPaid), AppColors.incomeGreen),
                _buildAmountColumn(
                  'المتبقي',
                  CurrencyFormatter.format(remaining),
                  remaining > 0 ? AppColors.expenseRed : AppColors.incomeGreen,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.backgroundDark,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isSettled ? AppColors.incomeGreen : AppColors.accentGold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.surfaceBorder, height: 1),
            const SizedBox(height: 8),

            // Action Buttons
            Row(
              children: [
                // Quick Print Receipt
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print_outlined, size: 16, color: AppColors.accentGold),
                    label: const Text('طباعة إيصال', style: TextStyle(fontSize: 11, color: AppColors.accentGold, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accentGold, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      await CustomerReceiptHelper.printReceipt(
                        context: context,
                        order: order,
                        payments: payments,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Quick Add Payment
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16, color: AppColors.backgroundDark),
                    label: const Text('تسجيل دفعة', style: TextStyle(fontSize: 11, color: AppColors.backgroundDark, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddPaymentDialog(
                          order: order,
                          currentPayments: payments,
                          onSave: ({
                            required double amount,
                            required DateTime paymentDate,
                            required String paymentMethod,
                            String? notes,
                            required bool recordAsIncome,
                          }) {
                            final payment = OrderPaymentModel(
                              orderId: order.id,
                              amount: amount,
                              paymentDate: paymentDate,
                              paymentMethod: paymentMethod,
                              notes: notes,
                              createdBy: auth.currentUser?.fullName ?? 'المدير',
                            );
                            provider.addPayment(
                              payment,
                              order: order,
                              recordAsIncome: recordAsIncome,
                              accountsProvider: accountsProvider,
                            );
                          },
                        ),
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

  Widget _buildAmountColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, CustomersProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.people_alt_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'لا توجد طلبيات مطابقة للبحث أو الفلتر',
              style: TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'يمكنك إضافة أول طلبية عميل وسداد دفعاتها وطباعة إيصالها بضغطة زر',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: AppColors.backgroundDark),
              label: const Text('إضافة طلبية جديدة الآن', style: TextStyle(color: AppColors.backgroundDark, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final accounts = Provider.of<AccountsProvider>(context, listen: false);
                showDialog(
                  context: context,
                  builder: (_) => AddEditOrderDialog(
                    onSave: ({
                      required String customerName,
                      String? phone,
                      required String orderDescription,
                      required DateTime startDate,
                      DateTime? deliveryDate,
                      required double totalAmount,
                      required String status,
                      String? notes,
                      double? initialPayment,
                      String paymentMethod = 'نقدي',
                      String? paymentNotes,
                      bool recordAsIncome = true,
                    }) {
                      final order = CustomerOrderModel(
                        customerName: customerName,
                        phone: phone,
                        orderDescription: orderDescription,
                        startDate: startDate,
                        deliveryDate: deliveryDate,
                        totalAmount: totalAmount,
                        status: status,
                        notes: notes,
                        createdBy: auth.currentUser?.fullName ?? 'المدير',
                      );
                      provider.addOrder(
                        order,
                        initialPayment: initialPayment,
                        paymentMethod: paymentMethod,
                        paymentNotes: paymentNotes,
                        recordAsIncome: recordAsIncome,
                        accountsProvider: accounts,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteOrder(
    BuildContext context,
    CustomerOrderModel order,
    CustomersProvider provider,
    AccountsProvider accountsProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('حذف طلبية العميل نهائياً'),
        content: Text(
          'هل أنت متأكد من حذف طلبية "${order.customerName}" (${order.orderDescription})؟\n'
          'سيتم مسح الطلبية وجميع دفعاتها المالية المرتبطة نهائياً.',
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
              await provider.deleteOrder(order.id, accountsProvider: accountsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الطلبية بنجاح')),
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
