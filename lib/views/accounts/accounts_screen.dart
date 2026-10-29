import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/export_helper.dart';
import '../../models/purchase_model.dart';
import '../../models/income_model.dart';
import '../../models/debt_advance_model.dart';
import '../../core/utils/debt_advance_receipt_helper.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import 'add_purchase_dialog.dart';
import 'add_income_dialog.dart';
import 'add_debt_advance_dialog.dart';
import 'record_debt_payment_dialog.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
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
    final accounts = Provider.of<AccountsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('قسم الحسابات والمالية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accentGold),
            tooltip: 'طباعة تقرير PDF',
            onPressed: () {
              ExportHelper.printFinancialSummaryReport(
                context: context,
                periodTitle: DateHelper.getPeriodLabel(accounts.selectedPeriod),
                totalIncome: accounts.filteredIncomesTotalAmount,
                totalExpenses: accounts.filteredPurchasesTotalAmount,
                workerBalances: 0.0,
                netCashFlow: accounts.filteredIncomesTotalAmount - accounts.filteredPurchasesTotalAmount,
                topPurchases: accounts.filteredPurchases,
                topIncomes: accounts.filteredIncomes,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accentGold),
            tooltip: 'تحديث الحسابات',
            onPressed: () => accounts.loadAll(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          labelColor: AppColors.accentGold,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'المشتريات والمصروفات'),
            Tab(icon: Icon(Icons.savings_outlined), text: 'الداخل المالي'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'السلف والمديونيات'),
            Tab(icon: Icon(Icons.pie_chart_outline), text: 'البحث والتقارير'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Purchases & Expenses
          _buildPurchasesTab(context, accounts, auth),

          // Tab 2: Factory Income
          _buildIncomeTab(context, accounts, auth),

          // Tab 3: Debts & Advances
          _buildDebtsAdvancesTab(context, accounts, auth),

          // Tab 4: Detailed Financial Search & Breakdown
          _buildReportingTab(context, accounts),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryNavy,
        icon: const Icon(Icons.add),
        label: Text(
          _tabController.index == 1
              ? 'تسجيل داخل'
              : _tabController.index == 2
                  ? 'تسجيل سلفة / مديونية'
                  : 'تسجيل مشتريات / مصروف',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          if (_tabController.index == 1) {
            showDialog(
              context: context,
              builder: (_) => const AddIncomeDialog(),
            );
          } else if (_tabController.index == 2) {
            showDialog(
              context: context,
              builder: (_) => const AddDebtAdvanceDialog(),
            );
          } else {
            showDialog(
              context: context,
              builder: (_) => const AddPurchaseDialog(),
            );
          }
        },
      ),
    );
  }

  // ================= TAB 1: PURCHASES =================
  Widget _buildPurchasesTab(BuildContext context, AccountsProvider accounts, AuthProvider auth) {
    return Column(
      children: [
        // Period & Search Filter Bar
        _buildFilterBar(context, accounts),

        // Summary Statistics Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                label: 'إجمالي المبالغ',
                value: CurrencyFormatter.format(accounts.filteredPurchasesTotalAmount),
                color: AppColors.expenseRed,
              ),
              _buildMetricItem(
                label: 'إجمالي الكميات',
                value: accounts.filteredPurchasesTotalQuantity > 0
                    ? accounts.filteredPurchasesTotalQuantity.toStringAsFixed(1)
                    : '—',
                color: AppColors.textWhite,
              ),
              _buildMetricItem(
                label: 'عدد الحركات',
                value: '${accounts.filteredPurchasesTransactionCount}',
                color: AppColors.accentGold,
              ),
            ],
          ),
        ),

        // Purchases List
        Expanded(
          child: accounts.filteredPurchases.isEmpty
              ? _buildEmptyState('لا توجد حركات مشتريات مطابقة للبحث أو الفترة المحددة')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: accounts.filteredPurchases.length,
                  itemBuilder: (context, index) {
                    final p = accounts.filteredPurchases[index];
                    return _buildPurchaseCard(context, p, accounts, auth);
                  },
                ),
        ),
      ],
    );
  }

  // ================= TAB 2: INCOME =================
  Widget _buildIncomeTab(BuildContext context, AccountsProvider accounts, AuthProvider auth) {
    return Column(
      children: [
        _buildFilterBar(context, accounts),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.incomeGreen.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                label: 'إجمالي الداخل',
                value: CurrencyFormatter.format(accounts.filteredIncomesTotalAmount),
                color: AppColors.incomeGreen,
              ),
              _buildMetricItem(
                label: 'عدد الحركات',
                value: '${accounts.filteredIncomesTransactionCount}',
                color: AppColors.accentGold,
              ),
            ],
          ),
        ),
        Expanded(
          child: accounts.filteredIncomes.isEmpty
              ? _buildEmptyState('لا توجد مقبوضات مسجلة في هذه الفترة')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: accounts.filteredIncomes.length,
                  itemBuilder: (context, index) {
                    final inc = accounts.filteredIncomes[index];
                    return _buildIncomeCard(context, inc, accounts, auth);
                  },
                ),
        ),
      ],
    );
  }

  // ================= TAB 3: DEBTS & ADVANCES =================
  Widget _buildDebtsAdvancesTab(BuildContext context, AccountsProvider accounts, AuthProvider auth) {
    return Column(
      children: [
        _buildFilterBar(context, accounts),

        // Type & Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildDebtFilterChip(accounts, 'all', 'الكل'),
              const SizedBox(width: 8),
              _buildDebtFilterChip(accounts, 'advance', 'السلف النقدية'),
              const SizedBox(width: 8),
              _buildDebtFilterChip(accounts, 'debt_receivable', 'مديونيات لنا'),
              const SizedBox(width: 8),
              _buildDebtFilterChip(accounts, 'debt_payable', 'مديونيات علينا'),
              const SizedBox(width: 12),
              Container(width: 1, height: 20, color: AppColors.surfaceBorder),
              const SizedBox(width: 12),
              _buildDebtStatusChip(accounts, 'all', 'كل الحالات'),
              const SizedBox(width: 8),
              _buildDebtStatusChip(accounts, 'active', 'السارية فقط'),
              const SizedBox(width: 8),
              _buildDebtStatusChip(accounts, 'settled', 'المسددة بالكامل'),
            ],
          ),
        ),

        // Summary Statistics Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warningAmber.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                label: 'إجمالي المبالغ',
                value: CurrencyFormatter.format(accounts.filteredDebtsAdvancesTotalAmount),
                color: AppColors.textWhite,
              ),
              _buildMetricItem(
                label: 'المتبقي المطلوب',
                value: CurrencyFormatter.format(accounts.filteredDebtsAdvancesTotalRemaining),
                color: accounts.filteredDebtsAdvancesTotalRemaining > 0 ? AppColors.expenseRed : AppColors.incomeGreen,
              ),
              _buildMetricItem(
                label: 'إجمالي المسدد',
                value: CurrencyFormatter.format(accounts.filteredDebtsAdvancesTotalPaid),
                color: AppColors.incomeGreen,
              ),
              _buildMetricItem(
                label: 'عدد السندات',
                value: '${accounts.filteredDebtsAdvancesCount}',
                color: AppColors.accentGold,
              ),
            ],
          ),
        ),

        // Debts and Advances List
        Expanded(
          child: accounts.filteredDebtsAdvances.isEmpty
              ? _buildEmptyState('لا توجد سلف أو مديونيات مسجلة مطابقة للبحث أو الفترة المحددة')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: accounts.filteredDebtsAdvances.length,
                  itemBuilder: (context, index) {
                    final item = accounts.filteredDebtsAdvances[index];
                    return _buildDebtAdvanceCard(context, item, accounts, auth);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDebtFilterChip(AccountsProvider accounts, String type, String label) {
    final isSelected = accounts.debtTypeFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.accentGold.withOpacity(0.2),
      backgroundColor: AppColors.surfaceDark,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.accentGold : AppColors.textMuted,
      ),
      side: BorderSide(color: isSelected ? AppColors.accentGold : AppColors.surfaceBorder),
      onSelected: (_) => accounts.setDebtTypeFilter(type),
    );
  }

  Widget _buildDebtStatusChip(AccountsProvider accounts, String status, String label) {
    final isSelected = accounts.debtStatusFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.infoBlue.withOpacity(0.2),
      backgroundColor: AppColors.surfaceDark,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.infoBlue : AppColors.textMuted,
      ),
      side: BorderSide(color: isSelected ? AppColors.infoBlue : AppColors.surfaceBorder),
      onSelected: (_) => accounts.setDebtStatusFilter(status),
    );
  }

  Widget _buildDebtAdvanceCard(BuildContext context, DebtAdvanceModel item, AccountsProvider accounts, AuthProvider auth) {
    Color typeColor;
    if (item.type == 'advance') {
      typeColor = AppColors.warningAmber;
    } else if (item.type == 'debt_receivable') {
      typeColor = AppColors.infoBlue;
    } else {
      typeColor = AppColors.expenseRed;
    }

    final isSettled = item.isSettled;
    final progress = item.amount > 0 ? (item.paidAmount / item.amount).clamp(0.0, 1.0) : 0.0;
    final payments = accounts.getPaymentsForDebt(item.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Person Name + Phone + Type Badge + Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.personName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textWhite),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: typeColor.withOpacity(0.4), width: 0.8),
                            ),
                            child: Text(
                              item.typeLabel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
                            ),
                          ),
                        ],
                      ),
                      if (item.phone != null && item.phone!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(item.phone!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSettled ? AppColors.incomeGreen.withOpacity(0.15) : AppColors.warningAmber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSettled ? AppColors.incomeGreen : AppColors.warningAmber, width: 0.8),
                  ),
                  child: Text(
                    isSettled ? 'مسددة بالكامل' : 'سارية',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSettled ? AppColors.incomeGreen : AppColors.warningAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Financial Breakdown in 3 mini boxes
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('أصل المبلغ', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(CurrencyFormatter.format(item.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المسدد', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(CurrencyFormatter.format(item.paidAmount),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.incomeGreen)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المتبقي المطلوب', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(item.remainingAmount),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: item.remainingAmount > 0 ? AppColors.expenseRed : AppColors.incomeGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Repayment Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.surfaceBorder,
                valueColor: AlwaysStoppedAnimation<Color>(isSettled ? AppColors.incomeGreen : AppColors.accentGold),
              ),
            ),
            const SizedBox(height: 8),

            // Dates & Notes
            Row(
              children: [
                Text(
                  'تاريخ السلفة: ${DateHelper.formatDisplay(item.transactionDate)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                if (item.dueDate != null) ...[
                  const Spacer(),
                  Text(
                    'الاستحقاق: ${DateHelper.formatDisplay(item.dueDate!)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.accentGold),
                  ),
                ],
              ],
            ),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'البيان: ${item.notes!}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
            const Divider(color: AppColors.surfaceBorder, height: 16),

            // Actions: Print Receipt, Record Payment, Delete
            Row(
              children: [
                // Print Receipt Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentGold,
                    side: const BorderSide(color: AppColors.accentGold, width: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('طباعة إيصال', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    DebtAdvanceReceiptHelper.printReceipt(
                      context: context,
                      item: item,
                      payments: payments,
                    );
                  },
                ),
                const SizedBox(width: 8),

                // Record Payment Button (if not fully settled)
                if (!isSettled)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.incomeGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: const Text('سداد دفعة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => RecordDebtPaymentDialog(debtAdvance: item),
                      );
                    },
                  ),

                const Spacer(),

                // Delete Button (Owner)
                if (auth.isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 20),
                    tooltip: 'حذف السند',
                    onPressed: () {
                      _confirmDeleteDebtAdvance(context, item, accounts);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDebtAdvance(BuildContext context, DebtAdvanceModel item, AccountsProvider accounts) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('تأكيد حذف السند'),
        content: Text('هل أنت متأكد من حذف سند "${item.personName}" بمبلغ ${CurrencyFormatter.format(item.amount)}؟ سيتم حذف سجل السداد التابع له أيضاً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed, foregroundColor: Colors.white),
            onPressed: () {
              accounts.deleteDebtAdvance(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  // ================= TAB 4: REPORTING & ITEM SEARCH =================
  Widget _buildReportingTab(BuildContext context, AccountsProvider accounts) {
    // Grouping by item name to answer "How much spent on X this week / month / year"
    Map<String, double> itemTotals = {};
    Map<String, double> itemQuantities = {};
    Map<String, int> itemCounts = {};

    for (var p in accounts.filteredPurchases) {
      itemTotals[p.itemName] = (itemTotals[p.itemName] ?? 0.0) + p.totalAmount;
      if (p.quantity != null) {
        itemQuantities[p.itemName] = (itemQuantities[p.itemName] ?? 0.0) + p.quantity!;
      }
      itemCounts[p.itemName] = (itemCounts[p.itemName] ?? 0) + 1;
    }

    final sortedItems = itemTotals.keys.toList()
      ..sort((a, b) => itemTotals[b]!.compareTo(itemTotals[a]!));

    return Column(
      children: [
        _buildFilterBar(context, accounts),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'تحليل إجمالي الإنفاق حسب الصنف / البند خلال ${DateHelper.getPeriodLabel(accounts.selectedPeriod)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentGold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: sortedItems.isEmpty
              ? _buildEmptyState('لا توجد بيانات إنفاق مسجلة')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: sortedItems.length,
                  itemBuilder: (context, index) {
                    final itemName = sortedItems[index];
                    final totalSpent = itemTotals[itemName]!;
                    final totalQty = itemQuantities[itemName] ?? 0;
                    final count = itemCounts[itemName]!;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accentGold.withOpacity(0.15),
                          child: Text('${index + 1}', style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text(
                          '${totalQty > 0 ? 'الكمية: ${totalQty.toStringAsFixed(1)} • ' : ''}عدد العمليات: $count',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        trailing: Text(
                          CurrencyFormatter.format(totalSpent),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.expenseRed),
                        ),
                        onTap: () {
                          // Quick filter by this item
                          _searchController.text = itemName;
                          accounts.setSearchQuery(itemName);
                          _tabController.animateTo(0);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Filter Bar with Period dropdown and Search field
  Widget _buildFilterBar(BuildContext context, AccountsProvider accounts) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              // Period Dropdown
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PeriodFilterType>(
                      value: accounts.selectedPeriod,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceDark,
                      icon: const Icon(Icons.calendar_month, color: AppColors.accentGold, size: 20),
                      style: const TextStyle(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.w600),
                      items: PeriodFilterType.values.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(DateHelper.getPeriodLabel(p)),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        if (val == PeriodFilterType.custom) {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            builder: (ctx, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.accentGold,
                                  onPrimary: AppColors.primaryNavy,
                                  surface: AppColors.surfaceDark,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (range != null) {
                            accounts.setPeriod(PeriodFilterType.custom, start: range.start, end: range.end);
                          }
                        } else if (val != null) {
                          accounts.setPeriod(val);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Search Box
              Expanded(
                flex: 6,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث باسم البند (مثال: أبلكاش)...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.accentGold),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              accounts.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => accounts.setSearchQuery(val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({required String label, required String value, required Color color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildPurchaseCard(BuildContext context, PurchaseModel p, AccountsProvider accounts, AuthProvider auth) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.itemName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textWhite),
                  ),
                ),
                Text(
                  CurrencyFormatter.format(p.totalAmount),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.expenseRed),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(p.category, style: const TextStyle(fontSize: 11, color: AppColors.accentGold)),
                ),
                if (p.quantity != null && p.unitPrice != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'الكمية: ${p.quantity} × ${CurrencyFormatter.format(p.unitPrice!)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
                const Spacer(),
                Text(
                  DateHelper.formatDisplay(p.transactionDate),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            if (p.notes != null && p.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('ملاحظات: ${p.notes}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المسجل: ${p.createdBy}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.infoBlue, size: 18),
                      tooltip: 'تعديل المصروف',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddPurchaseDialog(purchaseToEdit: p),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 18),
                      tooltip: 'حذف المصروف نهائياً (سلة)',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _confirmDeletePurchasePermanently(context, p, accounts);
                      },
                    ),
                    if (auth.isOwner) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppColors.warningAmber, padding: EdgeInsets.zero),
                        icon: const Icon(Icons.undo, size: 14),
                        label: const Text('إلغاء المعاملة', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          _confirmReversePurchase(context, p, accounts, auth);
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard(BuildContext context, IncomeModel inc, AccountsProvider accounts, AuthProvider auth) {
    final isCustomerPayment = inc.sourceName.contains('دفعة عميل');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isCustomerPayment) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, size: 18, color: AppColors.accentGold),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inc.sourceName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textWhite),
                      ),
                      if (isCustomerPayment) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'دفعة طلبية عميل',
                            style: TextStyle(fontSize: 10, color: AppColors.accentGold, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.format(inc.amount),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.incomeGreen),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${DateHelper.formatDisplay(inc.transactionDate)} • المسجل: ${inc.createdBy}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.infoBlue, size: 18),
                      tooltip: 'تعديل الإيراد',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddIncomeDialog(incomeToEdit: inc),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 18),
                      tooltip: 'حذف الإيراد نهائياً (سلة)',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _confirmDeleteIncome(context, inc, accounts);
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (inc.notes != null && inc.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('ملاحظات: ${inc.notes}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ],
        ),
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
            const Icon(Icons.inbox_outlined, size: 50, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePurchasePermanently(BuildContext context, PurchaseModel p, AccountsProvider accounts) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('حذف المصروف نهائياً'),
        content: Text(
          'هل أنت متأكد من حذف مصروف "${p.itemName}" بمبلغ ${CurrencyFormatter.format(p.totalAmount)}؟\n'
          'سيتم مسحه نهائياً من الحسابات والمصروفات.',
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
              await accounts.deletePurchasePermanently(p.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف المصروف نهائياً بنجاح')),
                );
              }
            },
            child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteIncome(BuildContext context, IncomeModel inc, AccountsProvider accounts) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('حذف الإيراد / الداخل'),
        content: Text(
          'هل أنت متأكد من حذف إيراد "${inc.sourceName}" بمبلغ ${CurrencyFormatter.format(inc.amount)}؟',
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
              await accounts.deleteIncome(inc.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الإيراد بنجاح')),
                );
              }
            },
            child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmReversePurchase(BuildContext context, PurchaseModel p, AccountsProvider accounts, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('تأكيد إلغاء العملية'),
        content: Text('هل أنت متأكد من إلغاء معاملة "${p.itemName}" بمبلغ ${CurrencyFormatter.format(p.totalAmount)}؟ لن يتم حذفها نهائياً حفاظاً على سجل التدقيق المالي.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed, foregroundColor: Colors.white),
            onPressed: () {
              accounts.reversePurchase(p.id, auth.currentUser?.fullName ?? 'المالك');
              Navigator.pop(ctx);
            },
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
  }
}
