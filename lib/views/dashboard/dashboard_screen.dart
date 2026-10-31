import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/workers_provider.dart';
import '../../providers/contractors_provider.dart';
import '../../providers/manufacturing_provider.dart';
import '../../providers/shortages_provider.dart';
import '../../providers/customers_provider.dart';
import '../customers/customers_screen.dart';
import '../manufacturing/manufacturing_orders_screen.dart';
import '../shortages/shortages_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = Provider.of<DashboardProvider>(context);
    final accounts = Provider.of<AccountsProvider>(context);
    final workers = Provider.of<WorkersProvider>(context);
    final contractors = Provider.of<ContractorsProvider>(context);
    final manufacturing = Provider.of<ManufacturingProvider>(context);
    final shortages = Provider.of<ShortagesProvider>(context);
    final customers = Provider.of<CustomersProvider>(context);

    final totalIncome = dashboard.calculateTotalIncome(accounts);
    final totalExpenses = dashboard.calculateTotalExpenses(accounts);
    final netCashFlow = totalIncome - totalExpenses;
    final workerSummary = dashboard.calculateWorkerSummary(workers);
    final categoryBreakdown = dashboard.getCategoryBreakdown(accounts);
    final contractorBreakdown = dashboard.getContractorBreakdown(contractors);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('لوحة التحكم والمؤشرات المالية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accentGold),
            tooltip: 'تحديث لوحة المؤشرات',
            onPressed: () {
              accounts.loadAll();
              workers.loadAll();
              contractors.loadAll();
              manufacturing.loadAll();
              shortages.loadAll();
              customers.loadAll();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Filter Bar
            _buildPeriodSelector(context, dashboard),
            const SizedBox(height: 14),

            // Delivery Warning Alert Banner (if any customer orders due soon or overdue)
            if (customers.ordersDueSoon.isNotEmpty) ...[
              _buildDeliveryWarningCard(context, customers),
              const SizedBox(height: 14),
            ],

            // 4 Primary Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: AppStrings.totalIncome,
                    value: CurrencyFormatter.format(totalIncome),
                    icon: Icons.arrow_downward_rounded,
                    color: AppColors.incomeGreen,
                    subtitle: 'إجمالي المقبوضات النقدية المحصلة',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: AppStrings.totalExpenses,
                    value: CurrencyFormatter.format(totalExpenses),
                    icon: Icons.arrow_upward_rounded,
                    color: AppColors.expenseRed,
                    subtitle: 'مشتريات + أجور + سلف + ورش',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'حساب العمال المستحق',
                    value: CurrencyFormatter.format(workerSummary['remaining'] ?? 0),
                    icon: Icons.people_outline,
                    color: AppColors.purpleWorker,
                    subtitle: 'متبقي رواتب عمال لم تصرف',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'صافي التدفق النقدي',
                    value: CurrencyFormatter.format(netCashFlow),
                    icon: Icons.account_balance_wallet_outlined,
                    color: netCashFlow >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                    subtitle: 'الداخل الفعلي - الخارج الفعلي',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Operational Cards: Manufacturing & Inventory
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManufacturingOrdersScreen()),
                      );
                    },
                    child: _buildMetricCard(
                      title: 'أوامر التصنيع المفتوحة',
                      value: '${manufacturing.openOrdersCount} أوامر',
                      icon: Icons.precision_manufacturing_rounded,
                      color: AppColors.warningAmber,
                      subtitle: 'أوامر جارية وفي انتظار الخامات',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShortagesScreen()),
                      );
                    },
                    child: _buildMetricCard(
                      title: 'النواقص واحتياجات الخامات',
                      value: '${shortages.activeCount} خامات ناقصة',
                      icon: Icons.assignment_late_rounded,
                      color: shortages.activeCount > 0 ? AppColors.expenseRed : AppColors.incomeGreen,
                      subtitle: shortages.activeCount > 0 ? 'مطلوب توفيرها للورشة' : 'جميع الاحتياجات متوفرة',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Chart 1: Income vs Expenses Comparison
            _buildIncomeExpensesBarChart(totalIncome, totalExpenses),
            const SizedBox(height: 20),

            // Chart 2: Expenses Category Distribution
            _buildCategoryDistributionChart(categoryBreakdown),
            const SizedBox(height: 20),

            // Worker Accounts Detailed Ledger Summary
            _buildWorkerAccountDetailsCard(workerSummary),
            const SizedBox(height: 20),

            // Chart 3: External Workshops / Contractors Breakdown
            _buildContractorBreakdownCard(contractorBreakdown),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, DashboardProvider dashboard) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('فترة التحليل:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
          DropdownButton<PeriodFilterType>(
            value: dashboard.selectedPeriod,
            dropdownColor: AppColors.surfaceDark,
            underline: const SizedBox(),
            items: PeriodFilterType.values.map((p) {
              return DropdownMenuItem(value: p, child: Text(DateHelper.getPeriodLabel(p)));
            }).toList(),
            onChanged: (val) async {
              if (val == PeriodFilterType.custom) {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (range != null) {
                  dashboard.setPeriod(PeriodFilterType.custom, start: range.start, end: range.end);
                }
              } else if (val != null) {
                dashboard.setPeriod(val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(fontSize: 10, color: AppColors.textMuted.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpensesBarChart(double income, double expenses) {
    final maxVal = (income > expenses ? income : expenses);
    final topBound = maxVal > 0 ? maxVal * 1.2 : 1000.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مقارنة الداخل بالخارج النقدي',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textWhite),
          ),
          const SizedBox(height: 4),
          const Text(
            'تحليل حركة السيولة النقدية الفعلية داخل المصنع',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: topBound,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        if (val == 0) return const Text('الداخل', style: TextStyle(color: AppColors.incomeGreen, fontWeight: FontWeight.bold));
                        if (val == 1) return const Text('الخارج', style: TextStyle(color: AppColors.expenseRed, fontWeight: FontWeight.bold));
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(toY: income, color: AppColors.incomeGreen, width: 36, borderRadius: BorderRadius.circular(8)),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(toY: expenses, color: AppColors.expenseRed, width: 36, borderRadius: BorderRadius.circular(8)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistributionChart(Map<String, double> categories) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const Center(child: Text('لا توجد مصروفات مسجلة بالفترة المحددة')),
      );
    }

    final colors = [
      AppColors.accentGold,
      AppColors.infoBlue,
      AppColors.purpleWorker,
      AppColors.woodWarm,
      AppColors.warningAmber,
      Colors.teal,
      Colors.pinkAccent,
      Colors.cyan,
    ];

    int idx = 0;
    final total = categories.values.fold(0.0, (s, v) => s + v);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'توزيع المصروفات حسب التصنيف',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textWhite),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: categories.entries.map((e) {
                  final color = colors[idx++ % colors.length];
                  final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
                  return PieChartSectionData(
                    value: e.value,
                    color: color,
                    title: '$pct%',
                    radius: 40,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: categories.entries.map((e) {
              final color = colors[categories.keys.toList().indexOf(e.key) % colors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${e.key}: ${CurrencyFormatter.format(e.value)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerAccountDetailsCard(Map<String, double> summary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purpleWorker.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص حسابات العمال والأجور',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.purpleWorker),
          ),
          const SizedBox(height: 12),
          _buildSummaryLine('إجمالي مستحق العمل واليوميات', CurrencyFormatter.format(summary['gross'] ?? 0)),
          _buildSummaryLine('مجموع ساعات وأجر الإضافي', CurrencyFormatter.format(summary['overtime'] ?? 0)),
          _buildSummaryLine('المكافآت الممنوحة (+)', CurrencyFormatter.format(summary['bonuses'] ?? 0), color: AppColors.incomeGreen),
          _buildSummaryLine('السلف المسحوبة المخصومة (-)', CurrencyFormatter.format(summary['advances'] ?? 0), color: AppColors.warningAmber),
          _buildSummaryLine('الخصومات الجزائية (-)', CurrencyFormatter.format(summary['deductions'] ?? 0), color: AppColors.expenseRed),
          _buildSummaryLine('الرواتب المدفوعة فعلياً', CurrencyFormatter.format(summary['paid'] ?? 0), color: AppColors.incomeGreen),
          const Divider(color: AppColors.surfaceBorder, height: 16),
          _buildSummaryLine('الرصيد المتبقي المستحق للعمال', CurrencyFormatter.format(summary['remaining'] ?? 0), color: AppColors.expenseRed, isBold: true),
        ],
      ),
    );
  }

  Widget _buildContractorBreakdownCard(Map<String, double> contractors) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.infoBlue.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مدفوعات الورش والاشتراكات الخارجية',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.infoBlue),
          ),
          const SizedBox(height: 12),
          if (contractors.isEmpty)
            const Text('لا توجد مدفوعات اشتراكات خارجية بالفترة المحددة', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
          else
            ...contractors.entries.map((e) => _buildSummaryLine(e.key, CurrencyFormatter.format(e.value))),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String title, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: isBold ? AppColors.textWhite : AppColors.textMuted, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? AppColors.textWhite)),
        ],
      ),
    );
  }

  Widget _buildDeliveryWarningCard(BuildContext context, CustomersProvider customers) {
    final dueCount = customers.ordersDueSoon.length;
    final overdueCount = customers.ordersDueSoon.where((o) => o.isOverdue).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: overdueCount > 0 ? AppColors.expenseRed : AppColors.warningAmber,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (overdueCount > 0 ? AppColors.expenseRed : AppColors.warningAmber).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  overdueCount > 0 ? Icons.error_outline : Icons.alarm_rounded,
                  color: overdueCount > 0 ? AppColors.expenseRed : AppColors.warningAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تنبيه مواعيد التسليم للعملاء ($dueCount طلبات)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: overdueCount > 0 ? AppColors.expenseRed : AppColors.warningAmber,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      overdueCount > 0
                          ? 'يوجد $overdueCount طلبات تجاوزت موعد التسليم و${dueCount - overdueCount} تستحق التسليم خلال أسبوع.'
                          : 'يوجد $dueCount طلبات تستحق التسليم لعملائها خلال 7 أيام القادمة.',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: overdueCount > 0 ? AppColors.expenseRed : AppColors.warningAmber,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            icon: Icon(
              Icons.visibility_outlined,
              size: 16,
              color: overdueCount > 0 ? AppColors.expenseRed : AppColors.warningAmber,
            ),
            label: Text(
              'متابعة الطلبيات وإرسال تذكيرات واتساب',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: overdueCount > 0 ? AppColors.expenseRed : AppColors.warningAmber,
              ),
            ),
            onPressed: () {
              customers.setStatusFilter('due_soon');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomersScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
