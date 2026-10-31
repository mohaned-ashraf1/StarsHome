import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/whatsapp_service.dart';
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
import '../../widgets/user_role_badge.dart';
import '../manufacturing/create_manufacturing_order_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final customersProvider = Provider.of<CustomersProvider>(context);
    final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final orders = customersProvider.orders.where((o) => o.id == widget.orderId).toList();
    if (orders.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.primaryNavy,
          title: const Text('تفاصيل الطلب'),
        ),
        body: const Center(
          child: Text('الطلب غير موجود أو تم حذفه', style: TextStyle(color: AppColors.textWhite)),
        ),
      );
    }

    final order = orders.first;
    final payments = customersProvider.getPaymentsForOrder(order.id);
    final totalPaid = order.calculateTotalPaid(payments);
    final remaining = order.calculateRemainingBalance(payments);
    final progress = order.paymentProgress(payments);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.customerName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textWhite),
            ),
            Text(
              'طلب #${order.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontSize: 11, color: AppColors.accentGold),
            ),
          ],
        ),
        actions: [
          // WhatsApp Share
          if (order.phone != null && order.phone!.trim().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
              tooltip: 'إرسال الفاتورة وتأكيد الطلب عبر واتساب',
              onPressed: () => WhatsAppService.sendOrderViaWhatsApp(
                context: context,
                order: order,
                payments: payments,
              ),
            ),
          // Edit Order
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.accentGold),
            tooltip: 'تعديل بيانات الطلب',
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
                    String paymentMethod = 'نقدي',
                    String? paymentNotes,
                    bool recordAsIncome = true,
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
                      createdBy: auth.currentUser?.signature ?? (auth.isOwner ? 'المالك' : 'المدير'),
                    );
                    customersProvider.updateOrder(updated);
                  },
                ),
              );
            },
          ),
          // Delete Order
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed),
            tooltip: 'حذف الطلب',
            onPressed: () => _confirmDeleteOrder(context, order, customersProvider, accountsProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Status & Quick Actions Bar
            _buildStatusHeader(order, customersProvider),
            const SizedBox(height: 16),

            // 2. Financial Overview & Progress Card
            _buildFinancialCard(order, payments, totalPaid, remaining, progress),
            const SizedBox(height: 16),

            // 3. Two Big Action Buttons: PRINT RECEIPT & ADD PAYMENT
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, color: AppColors.backgroundDark, size: 22),
                    label: const Text(
                      'طباعة إيصال للعميل',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.backgroundDark,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
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
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_card_rounded, color: AppColors.textWhite, size: 20),
                    label: const Text(
                      'تسجيل دفعة جديدة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.incomeGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
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
                              createdBy: auth.currentUser?.signature ?? (auth.isOwner ? 'المالك' : 'المدير'),
                            );
                            customersProvider.addPayment(
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
            const SizedBox(height: 10),

            // WhatsApp Action
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
              label: const Text(
                'إرسال تفاصيل الطلب والفاتورة PDF عبر واتساب 📲',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: () => WhatsAppService.sendOrderViaWhatsApp(
                context: context,
                order: order,
                payments: payments,
              ),
            ),
            const SizedBox(height: 12),

            // Shortcut to create Manufacturing Order
            OutlinedButton.icon(
              icon: const Icon(Icons.precision_manufacturing_rounded, color: AppColors.accentGold),
              label: const Text(
                'إنشاء أمر تصنيع وبطاقة ورشة لهذا الطلب',
                style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accentGold),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateManufacturingOrderScreen(
                      initialCustomerOrderId: order.id,
                      initialCustomerName: order.customerName,
                      initialProductName: order.orderDescription,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 4. Order Specifications / Description Card
            _buildDescriptionCard(order),
            const SizedBox(height: 18),

            // 5. Installments Breakdown Section
            _buildPaymentsList(order, payments, customersProvider, accountsProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(CustomerOrderModel order, CustomersProvider provider) {
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.accentGold, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textWhite),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          order.phone?.isNotEmpty == true ? order.phone! : 'بدون رقم هاتف',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('سُجّل بواسطة: ', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        UserRoleBadge(createdBy: order.createdBy, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge with menu
              PopupMenuButton<String>(
                initialValue: order.status,
                onSelected: (newStatus) {
                  provider.updateOrderStatus(order.id, newStatus);
                },
                color: AppColors.surfaceDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'in_progress', child: Text('قيد التنفيذ بالمصنع', style: TextStyle(color: AppColors.textWhite))),
                  const PopupMenuItem(value: 'ready', child: Text('جاهز للتسليم', style: TextStyle(color: AppColors.infoBlue))),
                  const PopupMenuItem(value: 'delivered', child: Text('تم التسليم والانتهاء', style: TextStyle(color: AppColors.incomeGreen))),
                  const PopupMenuItem(value: 'cancelled', child: Text('ملغي', style: TextStyle(color: AppColors.expenseRed))),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: order.statusColor.withOpacity(0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        order.statusArabicName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: order.statusColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: order.statusColor, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          const SizedBox(height: 10),

          // Dates Timeline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateItem('تاريخ الاتفاق والبدء', DateHelper.formatDisplay(order.startDate), Icons.date_range_outlined, AppColors.textWhite),
              const Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 16),
              _buildDateItem(
                'تاريخ التسليم المتفق عليه',
                order.deliveryDate != null ? DateHelper.formatDisplay(order.deliveryDate!) : 'غير محدد',
                Icons.local_shipping_outlined,
                order.deliveryDate != null && order.deliveryDate!.isBefore(DateTime.now()) && order.status != 'delivered'
                    ? AppColors.expenseRed
                    : AppColors.accentGold,
              ),
            ],
          ),
          if (order.isDueWithinOneWeek || order.isOverdue) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (order.isOverdue ? AppColors.expenseRed : AppColors.warningAmber).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (order.isOverdue ? AppColors.expenseRed : AppColors.warningAmber).withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    order.isOverdue ? Icons.error_outline : Icons.alarm,
                    color: order.isOverdue ? AppColors.expenseRed : AppColors.warningAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.deliveryWarningText ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: order.isOverdue ? AppColors.expenseRed : AppColors.warningAmber,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'تذكير بموعد التسليم للتنسيق مع العميل',
                          style: TextStyle(fontSize: 10, color: AppColors.textWhite),
                        ),
                      ],
                    ),
                  ),
                  if (order.phone != null && order.phone!.trim().isNotEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.chat, size: 14),
                      label: const Text('تذكير واتساب', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        WhatsAppService.sendDeliveryReminderViaWhatsApp(
                          context: context,
                          order: order,
                          daysRemaining: order.daysUntilDelivery ?? 0,
                          payments: provider.getPaymentsForOrder(order.id),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialCard(
    CustomerOrderModel order,
    List<OrderPaymentModel> payments,
    double totalPaid,
    double remaining,
    double progress,
  ) {
    final isSettled = remaining <= 0 && order.totalAmount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceDark,
            AppColors.cardNavy,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الموقف المالي للدفعات والأقساط',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textWhite),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSettled ? AppColors.incomeGreen.withOpacity(0.2) : AppColors.warningAmber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSettled ? 'خالص السداد بالكامل' : 'سداد بنظام الدفعات',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSettled ? AppColors.incomeGreen : AppColors.warningAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Metrics Columns
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  title: 'إجمالي المبلغ',
                  amount: CurrencyFormatter.format(order.totalAmount),
                  color: AppColors.textWhite,
                  icon: Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricBox(
                  title: 'إجمالي المسدد',
                  amount: CurrencyFormatter.format(totalPaid),
                  color: AppColors.incomeGreen,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricBox(
                  title: 'المتبقي المستحق',
                  amount: CurrencyFormatter.format(remaining),
                  color: remaining > 0 ? AppColors.expenseRed : AppColors.incomeGreen,
                  icon: Icons.pending_actions_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('نسبة السداد المنجزة:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.backgroundDark,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSettled ? AppColors.incomeGreen : AppColors.accentGold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(CustomerOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppColors.accentGold, size: 18),
              SizedBox(width: 8),
              Text(
                'مواصفات وتفاصيل الطلب المطلوب:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textWhite),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Text(
              order.orderDescription,
              style: const TextStyle(fontSize: 13, color: AppColors.textWhite, height: 1.5),
            ),
          ),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded, size: 14, color: AppColors.accentGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ملاحظات: ${order.notes!}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentsList(
    CustomerOrderModel order,
    List<OrderPaymentModel> payments,
    CustomersProvider provider,
    AccountsProvider accountsProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded, color: AppColors.accentGold, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'سجل الدفعات المسددة',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textWhite),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${payments.length} دفعات',
                      style: const TextStyle(fontSize: 10, color: AppColors.accentGold, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (payments.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: const Column(
                children: [
                  Icon(Icons.payment_outlined, size: 40, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text('لم يتم تسجيل أي دفعات لهذا الطلب حتى الآن', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('اضغط على "تسجيل دفعة جديدة" بالأعلى لإضافة الدفعة الأولى أو العربون', style: TextStyle(color: AppColors.accentGold, fontSize: 11)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = payments[index];
                final installmentNumber = payments.length - index;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      // Number Badge
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.incomeGreen.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '#$installmentNumber',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.incomeGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  CurrencyFormatter.format(p.amount),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.incomeGreen,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceDark,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.surfaceBorder),
                                  ),
                                  child: Text(
                                    p.paymentMethod,
                                    style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.notes?.isNotEmpty == true ? p.notes! : 'دفعة سداد نقدية',
                              style: const TextStyle(fontSize: 11, color: AppColors.textWhite),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'بتاريخ: ${DateHelper.formatDisplay(p.paymentDate)}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            UserRoleBadge(createdBy: p.createdBy, compact: true),
                          ],
                        ),
                      ),

                      // Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                        tooltip: 'حذف الدفعة',
                        onPressed: () {
                          _confirmDeletePayment(context, p, provider, accountsProvider);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _confirmDeletePayment(
    BuildContext context,
    OrderPaymentModel payment,
    CustomersProvider provider,
    AccountsProvider accountsProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('تأكيد حذف الدفعة', style: TextStyle(color: AppColors.textWhite)),
        content: Text(
          'هل أنت متأكد من حذف هذه الدفعة بمبلغ ${CurrencyFormatter.format(payment.amount)}؟\nسيتم تعديل رصيد الطلب وإلغاء حركتها من وارد الخزينة إن وجدت.',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            child: const Text('حذف', style: TextStyle(color: AppColors.textWhite)),
            onPressed: () {
              provider.deletePayment(payment.id, accountsProvider: accountsProvider);
              Navigator.pop(ctx);
            },
          ),
        ],
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
        title: const Text('تأكيد حذف الطلب بالكامل', style: TextStyle(color: AppColors.expenseRed)),
        content: Text(
          'هل أنت متأكد من حذف طلب العميل "${order.customerName}"؟\nسيتم حذف كافة الدفعات المرتبطة به نهائياً.',
          style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
        ),
        actions: [
          TextButton(
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            child: const Text('حذف نهائي', style: TextStyle(color: AppColors.textWhite)),
            onPressed: () {
              provider.deleteOrder(order.id, accountsProvider: accountsProvider);
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to customers list
            },
          ),
        ],
      ),
    );
  }
}
