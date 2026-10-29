import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../models/contractor_model.dart';
import '../../models/contractor_payment_model.dart';
import '../../providers/contractors_provider.dart';
import '../../providers/auth_provider.dart';
import 'add_contractor_dialog.dart';
import 'record_contractor_payment_dialog.dart';

class ContractorsScreen extends StatefulWidget {
  const ContractorsScreen({super.key});

  @override
  State<ContractorsScreen> createState() => _ContractorsScreenState();
}

class _ContractorsScreenState extends State<ContractorsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contractors = Provider.of<ContractorsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('قسم الاشتراكات والورش الخارجية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accentGold),
            tooltip: 'تحديث بيانات الاشتراكات',
            onPressed: () => contractors.loadAll(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          labelColor: AppColors.accentGold,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.handshake_outlined), text: 'الورش والخدمات'),
            Tab(icon: Icon(Icons.payments_outlined), text: 'سجل المدفوعات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Contractors List
          _buildContractorsListTab(context, contractors, auth),

          // Tab 2: Payments History & Date Filters
          _buildPaymentsTab(context, contractors, auth),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryNavy,
        icon: const Icon(Icons.add),
        label: Text(
          _tabController.index == 0 ? 'إضافة ورشة / فني' : 'تسجيل دفعة اشتراك',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          if (_tabController.index == 0) {
            showDialog(context: context, builder: (_) => const AddContractorDialog());
          } else {
            showDialog(context: context, builder: (_) => const RecordContractorPaymentDialog());
          }
        },
      ),
    );
  }

  // ================= TAB 1: WORKSHOPS LIST =================
  Widget _buildContractorsListTab(BuildContext context, ContractorsProvider contractors, AuthProvider auth) {
    if (contractors.contractors.isEmpty) {
      return _buildEmptyState('لا توجد ورش خارجية مسجلة بعد. اضغط "إضافة ورشة / فني" للبدء.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: contractors.contractors.length,
      itemBuilder: (context, index) {
        final c = contractors.contractors[index];
        final totalPaid = contractors.getTotalPaidToContractor(c.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.infoBlue.withOpacity(0.15),
                  child: const Icon(Icons.construction, color: AppColors.infoBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.infoBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.serviceType,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.infoBlue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (c.phone != null && c.phone!.isNotEmpty)
                        Text('هاتف: ${c.phone}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      if (c.notes != null && c.notes!.isNotEmpty)
                        Text(c.notes!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Text(
                        'إجمالي المسدد للورشة: ${CurrencyFormatter.format(totalPaid)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.infoBlue, size: 20),
                      tooltip: 'تعديل بيانات الورشة',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddContractorDialog(contractorToEdit: c),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 20),
                      tooltip: 'حذف الورشة (سلة المهملات)',
                      onPressed: () => _confirmDeleteContractor(context, c, contractors),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_card_rounded, color: AppColors.accentGold, size: 20),
                      tooltip: 'تسجيل دفعة نقدية للورشة',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => RecordContractorPaymentDialog(initialContractorId: c.id),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= TAB 2: PAYMENTS HISTORY =================
  Widget _buildPaymentsTab(BuildContext context, ContractorsProvider contractors, AuthProvider auth) {
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              // Period Dropdown
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PeriodFilterType>(
                      value: contractors.selectedPeriod,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceDark,
                      items: PeriodFilterType.values.map((p) {
                        return DropdownMenuItem(value: p, child: Text(DateHelper.getPeriodLabel(p), style: const TextStyle(fontSize: 12)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) contractors.setPeriod(val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Search Box (e.g. searching "الدهان")
              Expanded(
                flex: 6,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث بالورشة أو الخدمة (مثال: الدهان)...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.accentGold),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              contractors.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (val) => contractors.setSearchQuery(val),
                ),
              ),
            ],
          ),
        ),

        // Total Paid in Period
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.infoBlue.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('إجمالي مدفوعات الاشتراكات بالفترة', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 3),
                  Text(
                    CurrencyFormatter.format(contractors.filteredPaymentsTotalAmount),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.infoBlue),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('عدد الدفعات المسجلة', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 3),
                  Text(
                    '${contractors.filteredPaymentsCount}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Payments List
        Expanded(
          child: contractors.filteredPayments.isEmpty
              ? _buildEmptyState('لا توجد مدفوعات مسجلة لهذه الفترة أو مطابقة للبحث')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: contractors.filteredPayments.length,
                  itemBuilder: (context, index) {
                    final p = contractors.filteredPayments[index];
                    final contractor = contractors.contractors.firstWhere((c) => c.id == p.contractorId, orElse: () => ContractorModel(name: 'ورشة', serviceType: ''));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(contractor.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.infoBlue.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(contractor.serviceType, style: const TextStyle(fontSize: 10, color: AppColors.infoBlue)),
                                ),
                                const Spacer(),
                                Text(
                                  CurrencyFormatter.format(p.amount),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.infoBlue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('البيان: ${p.description}', style: const TextStyle(fontSize: 13, color: AppColors.textWhite)),
                            if (p.relatedOrder != null && p.relatedOrder!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('الأوردر / المنتج: ${p.relatedOrder}', style: const TextStyle(fontSize: 12, color: AppColors.accentGold)),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('التاريخ: ${DateHelper.formatDisplay(p.paymentDate)} • المسجل: ${p.createdBy}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 18),
                                  tooltip: 'حذف الدفعة (سلة)',
                                  onPressed: () => _confirmDeletePayment(context, p, contractors),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDeleteContractor(BuildContext context, ContractorModel contractor, ContractorsProvider contractors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('حذف الورشة نهائياً'),
        content: Text(
          'هل أنت متأكد من حذف ورشة "${contractor.name}"؟\n'
          'سيتم مسح سجل دفعاتها وحساباتها من الاشتراكات.',
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
              await contractors.deleteContractor(contractor.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الورشة بنجاح')),
                );
              }
            },
            child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePayment(BuildContext context, ContractorPaymentModel payment, ContractorsProvider contractors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('حذف دفعة الاشتراك'),
        content: Text(
          'هل أنت متأكد من حذف هذه الدفعة بمبلغ ${CurrencyFormatter.format(payment.amount)}؟',
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
              await contractors.deletePayment(payment.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الدفعة بنجاح')),
                );
              }
            },
            child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handshake_outlined, size: 50, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
