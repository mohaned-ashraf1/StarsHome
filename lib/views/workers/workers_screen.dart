import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../models/worker_model.dart';
import '../../models/worker_financial_item_model.dart';
import '../../providers/workers_provider.dart';
import '../../providers/auth_provider.dart';
import 'add_worker_dialog.dart';
import 'record_attendance_dialog.dart';
import 'add_financial_item_dialog.dart';
import 'payroll_settlement_dialog.dart';
import 'worker_ledger_screen.dart';
import '../../core/utils/worker_payroll_receipt_helper.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workers = Provider.of<WorkersProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('إدارة العمال وكشف الرواتب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accentGold),
            tooltip: 'تحديث بيانات العمال',
            onPressed: () => workers.loadAll(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accentGold,
          labelColor: AppColors.accentGold,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_outlined), text: 'قائمة العمال'),
            Tab(icon: Icon(Icons.timer_outlined), text: 'الحضور والانصراف'),
            Tab(icon: Icon(Icons.price_change_outlined), text: 'السلف والمكافآت'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'كشف الرواتب الأسبوعي'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Worker List & Add
          _buildWorkerListTab(context, workers, auth),

          // Tab 2: Attendance & Departure
          _buildAttendanceTab(context, workers, auth),

          // Tab 3: Advances, Bonuses, Deductions
          _buildFinancialItemsTab(context, workers, auth),

          // Tab 4: Weekly Payroll Settlements
          _buildWeeklyPayrollTab(context, workers, auth),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryNavy,
        icon: const Icon(Icons.add),
        label: Text(
          _getFabLabel(_tabController.index),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          _handleFabAction(context, _tabController.index);
        },
      ),
    );
  }

  String _getFabLabel(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'إضافة عامل';
      case 1:
        return 'تسجيل حضور';
      case 2:
        return 'سلفة / مكافأة / خصم';
      case 3:
      default:
        return 'تسوية راتب أسبوعي';
    }
  }

  void _handleFabAction(BuildContext context, int tabIndex) {
    switch (tabIndex) {
      case 0:
        showDialog(context: context, builder: (_) => const AddWorkerDialog());
        break;
      case 1:
        showDialog(context: context, builder: (_) => const RecordAttendanceDialog());
        break;
      case 2:
        showDialog(context: context, builder: (_) => const AddFinancialItemDialog());
        break;
      case 3:
        final summaries = Provider.of<WorkersProvider>(context, listen: false).calculatePayrollForPeriod();
        if (summaries.isNotEmpty) {
          showDialog(context: context, builder: (_) => PayrollSettlementDialog(summary: summaries.first));
        }
        break;
    }
  }

  // ================= TAB 1: WORKERS DIRECTORY =================
  Widget _buildWorkerListTab(BuildContext context, WorkersProvider workers, AuthProvider auth) {
    if (workers.workers.isEmpty) {
      return _buildEmptyState('لا يوجد عمال مسجلين بعد. اضغط على زر "إضافة عامل" لإضافة أول عامل.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: workers.workers.length,
      itemBuilder: (context, index) {
        final w = workers.workers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accentGold.withOpacity(0.15),
                  child: const Icon(Icons.person, color: AppColors.accentGold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(w.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: w.isActive ? AppColors.incomeGreen.withOpacity(0.15) : AppColors.expenseRed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              w.isActive ? 'نشط' : 'متوقف',
                              style: TextStyle(fontSize: 10, color: w.isActive ? AppColors.incomeGreen : AppColors.expenseRed, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اليومية: ${CurrencyFormatter.format(w.dailyWage)} • ساعة الإضافي: ${CurrencyFormatter.format(w.overtimeHourlyRate)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'مواعيد العمل الرسمية: من ${DateHelper.formatTimeStringTo12Hour(w.standardStartTime)} إلى ${DateHelper.formatTimeStringTo12Hour(w.standardEndTime)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.infoBlue, size: 20),
                      tooltip: 'تعديل بيانات العامل',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddWorkerDialog(workerToEdit: w),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 20),
                      tooltip: 'حذف العامل (سلة المهملات)',
                      onPressed: () => _confirmDeleteWorker(context, w, workers),
                    ),
                    IconButton(
                      icon: const Icon(Icons.receipt_long, color: AppColors.accentGold, size: 20),
                      tooltip: 'سجل الحساب المالي للعامل',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => WorkerLedgerScreen(worker: w)),
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

  // ================= TAB 2: ATTENDANCE & DEPARTURE =================
  Widget _buildAttendanceTab(BuildContext context, WorkersProvider workers, AuthProvider auth) {
    final records = workers.attendanceForSelectedDate;

    return Column(
      children: [
        // Date Selector Bar
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.accentGold),
                onPressed: () {
                  workers.setSelectedAttendanceDate(
                    workers.selectedAttendanceDate.subtract(const Duration(days: 1)),
                  );
                },
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: workers.selectedAttendanceDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) workers.setSelectedAttendanceDate(picked);
                },
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 18, color: AppColors.accentGold),
                    const SizedBox(width: 8),
                    Text(
                      DateHelper.formatLong(workers.selectedAttendanceDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.accentGold),
                onPressed: () {
                  workers.setSelectedAttendanceDate(
                    workers.selectedAttendanceDate.add(const Duration(days: 1)),
                  );
                },
              ),
            ],
          ),
        ),

        // Attendance Table / List
        Expanded(
          child: records.isEmpty
              ? _buildEmptyState('لم يتم تسجيل حضور لأي عامل في هذا اليوم. اضغط "تسجيل حضور" للبدء.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final att = records[index];
                    final worker = workers.workers.firstWhere((w) => w.id == att.workerId, orElse: () => WorkerModel(fullName: 'عامل غير معروف', dailyWage: 0, overtimeHourlyRate: 0));

                    Color statusColor;
                    String statusText;
                    if (att.status == 'present') {
                      statusColor = AppColors.incomeGreen;
                      statusText = 'حاضر';
                    } else if (att.status == 'absent') {
                      statusColor = AppColors.expenseRed;
                      statusText = 'غائب';
                    } else {
                      statusColor = AppColors.warningAmber;
                      statusText = 'إجازة';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(worker.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withOpacity(0.4)),
                                  ),
                                  child: Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (att.status == 'present') ...[
                              Row(
                                children: [
                                  Text('الحضور: ${DateHelper.formatTimeStringTo12Hour(att.arrivalTime)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  const SizedBox(width: 14),
                                  Text('الانصراف: ${DateHelper.formatTimeStringTo12Hour(att.departureTime)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  const Spacer(),
                                  if (att.overtimeHours > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.infoBlue.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'إضافي: ${att.overtimeHours} ساعة (${CurrencyFormatter.format(att.overtimePay)})',
                                        style: const TextStyle(fontSize: 11, color: AppColors.infoBlue, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'مستحق اليومية: ${CurrencyFormatter.format(att.dailyWageApplied)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                              ),
                            ],
                            if (att.notes != null && att.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('ملاحظات: ${att.notes}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
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

  // ================= TAB 3: ADVANCES, BONUSES, DEDUCTIONS =================
  Widget _buildFinancialItemsTab(BuildContext context, WorkersProvider workers, AuthProvider auth) {
    if (workers.financialItems.isEmpty) {
      return _buildEmptyState('لا توجد سلف أو مكافآت مسجلة بعد.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: workers.financialItems.length,
      itemBuilder: (context, index) {
        final item = workers.financialItems[index];
        final worker = workers.workers.firstWhere((w) => w.id == item.workerId, orElse: () => WorkerModel(fullName: 'عامل', dailyWage: 0, overtimeHourlyRate: 0));

        Color color;
        IconData icon;
        if (item.type == 'advance') {
          color = AppColors.warningAmber;
          icon = Icons.money_off;
        } else if (item.type == 'bonus') {
          color = AppColors.incomeGreen;
          icon = Icons.card_giftcard;
        } else {
          color = AppColors.expenseRed;
          icon = Icons.remove_circle_outline;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Row(
              children: [
                Text(worker.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(item.typeArabicName, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'التاريخ: ${DateHelper.formatDisplay(item.transactionDate)} • المسجل: ${item.createdBy}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                if (item.reasonNotes != null && item.reasonNotes!.isNotEmpty)
                  Text('السبب: ${item.reasonNotes}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyFormatter.format(item.amount),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed, size: 18),
                  tooltip: 'حذف من السجل (سلة)',
                  onPressed: () => _confirmDeleteFinancialItem(context, item, workers),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= TAB 4: WEEKLY PAYROLL =================
  Widget _buildWeeklyPayrollTab(BuildContext context, WorkersProvider workers, AuthProvider auth) {
    final summaries = workers.calculatePayrollForPeriod();
    final grandTotals = workers.getWorkersAggregatedFinancials();

    return Column(
      children: [
        // Week Range Selector
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('فترة الحساب الأسبوعي:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              DropdownButton<PeriodFilterType>(
                value: workers.selectedWeekPeriod,
                dropdownColor: AppColors.surfaceDark,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: PeriodFilterType.currentWeek, child: Text('الأسبوع الحالي')),
                  DropdownMenuItem(value: PeriodFilterType.previousWeek, child: Text('الأسبوع الماضي')),
                  DropdownMenuItem(value: PeriodFilterType.currentMonth, child: Text('الشهر الحالي')),
                ],
                onChanged: (val) {
                  if (val != null) workers.setPayrollWeek(val);
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text('كشف الإدارة المجمع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                onPressed: summaries.isEmpty
                    ? null
                    : () async {
                        final range = DateHelper.getDateRangeForPeriod(workers.selectedWeekPeriod);
                        await WorkerPayrollReceiptHelper.printFactoryManagementPayrollReport(
                          context: context,
                          summaries: summaries,
                          weekStart: range.start,
                          weekEnd: range.end,
                          grandTotals: grandTotals,
                        );
                      },
              ),
            ],
          ),
        ),

        // Grand Total Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPayrollMetric('إجمالي المستحقات', CurrencyFormatter.format(grandTotals['gross'] ?? 0), AppColors.textWhite),
              _buildPayrollMetric('إجمالي السلف والخصم', CurrencyFormatter.format((grandTotals['advances'] ?? 0) + (grandTotals['deductions'] ?? 0)), AppColors.warningAmber),
              _buildPayrollMetric('المدفوع فعلياً', CurrencyFormatter.format(grandTotals['paid'] ?? 0), AppColors.incomeGreen),
              _buildPayrollMetric('المتبقي للمصنع', CurrencyFormatter.format(grandTotals['remaining'] ?? 0), AppColors.expenseRed),
            ],
          ),
        ),

        // Payroll Table / Worker Cards
        Expanded(
          child: summaries.isEmpty
              ? _buildEmptyState('لا توجد بيانات حضور أو رواتب مسجلة لهذه الفترة.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: summaries.length,
                  itemBuilder: (context, index) {
                    final s = summaries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(s.worker.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: s.isSettled ? AppColors.incomeGreen.withOpacity(0.15) : AppColors.warningAmber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    s.isSettled ? 'تمت التصفية' : 'متبقي حساب',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: s.isSettled ? AppColors.incomeGreen : AppColors.warningAmber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Details Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('أيام الحضور: ${s.daysAttended}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                Text('أجر اليوميات: ${CurrencyFormatter.format(s.dailyWagesEarned)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                Text('الإضافي: ${CurrencyFormatter.format(s.overtimeEarnings)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('سلف: ${CurrencyFormatter.format(s.advancesTotal)}', style: const TextStyle(fontSize: 12, color: AppColors.warningAmber)),
                                Text('مكافآت: ${CurrencyFormatter.format(s.bonusesTotal)}', style: const TextStyle(fontSize: 12, color: AppColors.incomeGreen)),
                                Text('خصومات: ${CurrencyFormatter.format(s.deductionsTotal)}', style: const TextStyle(fontSize: 12, color: AppColors.expenseRed)),
                              ],
                            ),
                            const Divider(color: AppColors.surfaceBorder, height: 16),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('صافي المستحق الأسبوعي:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    Text(CurrencyFormatter.format(s.netAmountDue), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('المتبقي للصرف:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    Text(CurrencyFormatter.format(s.remainingDue), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.expenseRed)),
                                  ],
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.accentGold),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.print_outlined, size: 15, color: AppColors.accentGold),
                                  label: const Text(
                                    'إيصال العامل',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                                  ),
                                  onPressed: () async {
                                    final range = DateHelper.getDateRangeForPeriod(workers.selectedWeekPeriod);
                                    await WorkerPayrollReceiptHelper.printSingleWorkerReceipt(
                                      context: context,
                                      summary: s,
                                      weekStart: range.start,
                                      weekEnd: range.end,
                                      attendanceList: workers.attendanceRecords,
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: s.remainingDue > 0 ? AppColors.accentGold : AppColors.surfaceHover,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.payments_outlined, size: 15, color: AppColors.primaryNavy),
                                  label: Text(
                                    s.remainingDue > 0 ? 'صرف المستحقات' : 'تم الصرف',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                                  ),
                                  onPressed: s.remainingDue > 0
                                      ? () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => PayrollSettlementDialog(summary: s),
                                          );
                                        }
                                      : null,
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

  Widget _buildPayrollMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _confirmDeleteWorker(BuildContext context, WorkerModel worker, WorkersProvider workers) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('حذف العامل نهائياً'),
        content: Text(
          'هل أنت متأكد من حذف العامل "${worker.fullName}"؟\n'
          'سيتم مسح بيانات العامل وحضوره وحساباته نهائياً من المصنع.',
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
              await workers.deleteWorker(worker.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف العامل بنجاح')),
                );
              }
            },
            child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFinancialItem(BuildContext context, WorkerFinancialItemModel item, WorkersProvider workers) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('حذف ${item.typeArabicName}'),
        content: Text(
          'هل أنت متأكد من حذف ${item.typeArabicName} بمبلغ ${CurrencyFormatter.format(item.amount)}؟',
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
              await workers.deleteFinancialItem(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف المعاملة بنجاح')),
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
            const Icon(Icons.groups_outlined, size: 50, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
