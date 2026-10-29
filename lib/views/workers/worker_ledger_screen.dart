import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../models/worker_model.dart';
import '../../providers/workers_provider.dart';
import 'add_financial_item_dialog.dart';

class WorkerLedgerScreen extends StatelessWidget {
  final WorkerModel worker;

  const WorkerLedgerScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final workers = Provider.of<WorkersProvider>(context);

    // Filter events for this worker
    final workerAtt = workers.attendanceRecords.where((a) => a.workerId == worker.id).toList();
    final workerFin = workers.financialItems.where((f) => f.workerId == worker.id).toList();
    final workerPay = workers.payrollSettlements.where((p) => p.workerId == worker.id).toList();

    final totalDays = workerAtt.where((a) => a.status == 'present').length;
    final totalWages = workerAtt.where((a) => a.status == 'present').fold(0.0, (s, a) => s + a.dailyWageApplied);
    final totalOvertime = workerAtt.fold(0.0, (s, a) => s + a.overtimePay);
    final totalBonuses = workerFin.where((f) => f.type == 'bonus').fold(0.0, (s, f) => s + f.amount);
    final totalAdvances = workerFin.where((f) => f.type == 'advance').fold(0.0, (s, f) => s + f.amount);
    final totalDeductions = workerFin.where((f) => f.type == 'deduction').fold(0.0, (s, f) => s + f.amount);
    final totalPaid = workerPay.fold(0.0, (s, p) => s + p.amountPaid);

    final grossEarnings = totalWages + totalOvertime + totalBonuses;
    final netEarned = grossEarnings - totalAdvances - totalDeductions;
    final outstandingBalance = netEarned - totalPaid;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('كشف حساب: ${worker.fullName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.accentGold),
            tooltip: 'إضافة سلفة أو مكافأة',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddFinancialItemDialog(initialWorkerId: worker.id),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Worker Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.accentGold.withOpacity(0.15),
                    child: const Icon(Icons.person, color: AppColors.accentGold, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(worker.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'اليومية: ${CurrencyFormatter.format(worker.dailyWage)} • ساعة الإضافي: ${CurrencyFormatter.format(worker.overtimeHourlyRate)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        if (worker.phone != null && worker.phone!.isNotEmpty)
                          Text('هاتف: ${worker.phone}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 7 Summary Ledger Cards
            const Text('الملخص المالي الشامل للعامل', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _buildStatCard('أيام الحضور الفعلية', '$totalDays يوم', AppColors.textWhite),
                _buildStatCard('مجموع أجر اليوميات', CurrencyFormatter.format(totalWages), AppColors.textWhite),
                _buildStatCard('مجموع أجر الإضافي', CurrencyFormatter.format(totalOvertime), AppColors.infoBlue),
                _buildStatCard('المكافآت المستحقة', CurrencyFormatter.format(totalBonuses), AppColors.incomeGreen),
                _buildStatCard('إجمالي السلف المسحوبة', CurrencyFormatter.format(totalAdvances), AppColors.warningAmber),
                _buildStatCard('إجمالي الخصومات', CurrencyFormatter.format(totalDeductions), AppColors.expenseRed),
                _buildStatCard('المدفوع نقداً للعامل', CurrencyFormatter.format(totalPaid), AppColors.incomeGreen),
                _buildStatCard('الرصيد المتبقي للعامل', CurrencyFormatter.format(outstandingBalance), outstandingBalance > 0 ? AppColors.expenseRed : AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 24),

            // Transactions History
            const Text('سجل العمليات والحركات المالية', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
            const SizedBox(height: 10),

            if (workerFin.isEmpty && workerAtt.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد حركات مسجلة لهذا العامل')))
            else
              ...workerFin.map((f) {
                Color color = f.type == 'advance' ? AppColors.warningAmber : (f.type == 'bonus' ? AppColors.incomeGreen : AppColors.expenseRed);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Text(f.typeArabicName[0], style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${f.typeArabicName}: ${CurrencyFormatter.format(f.amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                    subtitle: Text('${DateHelper.formatDisplay(f.transactionDate)} • ${f.reasonNotes ?? 'بدون ملاحظات'}'),
                    trailing: Text('المسجل: ${f.createdBy}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
