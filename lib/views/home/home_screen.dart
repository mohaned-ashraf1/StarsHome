import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/workers_provider.dart';
import '../../providers/contractors_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/customers_provider.dart';
import '../../providers/manufacturing_provider.dart';
import '../../providers/shortages_provider.dart';
import '../../providers/inventory_provider.dart';
import '../accounts/accounts_screen.dart';
import '../workers/workers_screen.dart';
import '../contractors/contractors_screen.dart';
import '../customers/customers_screen.dart';
import '../manufacturing/manufacturing_orders_screen.dart';
import '../inventory/inventory_screen.dart';
import '../shortages/shortages_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_screen.dart';
import '../sync/sync_status_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).loadAll();
      Provider.of<ShortagesProvider>(context, listen: false).loadAll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Auto-sync when app returns to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[HomeScreen] App resumed — triggering background sync');
      SyncService.instance.syncNow().ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final accounts = Provider.of<AccountsProvider>(context);
    final workers = Provider.of<WorkersProvider>(context);
    final contractors = Provider.of<ContractorsProvider>(context);
    final dashboard = Provider.of<DashboardProvider>(context);
    final customers = Provider.of<CustomersProvider>(context);
    final manufacturing = Provider.of<ManufacturingProvider>(context);
    final shortages = Provider.of<ShortagesProvider>(context);
    final inventory = Provider.of<InventoryProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.accentGold),
          tooltip: 'الإعدادات والنسخ الاحتياطي',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'STARS HOMES',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              auth.currentUser?.fullName ?? 'م/ ابراهيم نجم',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Synchronization Status Badge
          ValueListenableBuilder<SyncStatus>(
            valueListenable: SyncService.instance.statusNotifier,
            builder: (context, status, _) {
              return ValueListenableBuilder<int>(
                valueListenable: SyncService.instance.pendingCountNotifier,
                builder: (context, pendingCount, _) {
                  return _buildSyncBadge(context, status, pendingCount);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textMuted),
            tooltip: 'تسجيل الخروج',
            onPressed: () {
              auth.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Watermark logo - bottom center, semi-transparent
            Positioned(
              bottom: -20,
              left: 0,
              right: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.06,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 260,
                    height: 260,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: () async {
                await accounts.loadAll();
                await workers.loadAll();
                await contractors.loadAll();
                await customers.loadAll(accountsProvider: accounts);
                await manufacturing.loadAll();
                await inventory.loadAll();
                await shortages.loadAll();
                await SyncService.instance.syncNow();
              },
              color: AppColors.accentGold,
              backgroundColor: AppColors.surfaceDark,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. SECTION ONE: ACCOUNTS / الحسابات
                    _buildSectionCard(
                      context: context,
                      title: AppStrings.sectionAccounts,
                      icon: Icons.payments_rounded,
                      iconColor: AppColors.accentGold,
                      accentBorderColor: AppColors.accentGold.withOpacity(0.4),
                      trailingSummary: CurrencyFormatter.format(accounts.filteredPurchasesTotalAmount),
                      trailingLabel: 'المصروفات الشهرية',
                      trailingColor: AppColors.accentGold,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AccountsScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // 2. SECTION TWO: WORKERS / العمال
                    _buildSectionCard(
                      context: context,
                      title: AppStrings.sectionWorkers,
                      icon: Icons.engineering_rounded,
                      iconColor: AppColors.purpleWorker,
                      accentBorderColor: AppColors.purpleWorker.withOpacity(0.4),
                      trailingSummary: '${workers.attendanceForSelectedDate.length} حاضرين',
                      trailingLabel: 'تسجيل اليوم',
                      trailingColor: AppColors.purpleWorker,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WorkersScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // 3. SECTION THREE: EXTERNAL WORKERS & CONTRACTORS / الاشتراكات
                    _buildSectionCard(
                      context: context,
                      title: AppStrings.sectionContractors,
                      icon: Icons.handshake_rounded,
                      iconColor: AppColors.infoBlue,
                      accentBorderColor: AppColors.infoBlue.withOpacity(0.4),
                      trailingSummary: CurrencyFormatter.format(contractors.filteredPaymentsTotalAmount),
                      trailingLabel: 'مدفوعات الشهر',
                      trailingColor: AppColors.infoBlue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContractorsScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // 4. SECTION FOUR: CUSTOMERS & ORDERS / العملاء والطلبيات
                    _buildSectionCard(
                      context: context,
                      title: AppStrings.sectionCustomers,
                      icon: Icons.person_rounded,
                      iconColor: AppColors.accentGold,
                      accentBorderColor: AppColors.accentGold.withOpacity(0.5),
                      trailingSummary: CurrencyFormatter.format(customers.totalRemainingBalance),
                      trailingLabel: 'المتبقي عند العملاء',
                      trailingColor: customers.totalRemainingBalance > 0 ? AppColors.expenseRed : AppColors.incomeGreen,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CustomersScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // 5. SECTION FIVE: MANUFACTURING ORDERS / أوامر التصنيع
                    _buildSectionCard(
                      context: context,
                      title: AppStrings.sectionManufacturing,
                      icon: Icons.precision_manufacturing_rounded,
                      iconColor: AppColors.warningAmber,
                      accentBorderColor: AppColors.warningAmber.withOpacity(0.4),
                      trailingSummary: '${manufacturing.openOrdersCount} أوامر نشطة',
                      trailingLabel: 'أوامر قيد التشغيل',
                      trailingColor: AppColors.warningAmber,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ManufacturingOrdersScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // 6. SECTION SIX: INVENTORY / المخزون والخامات
                    _buildSectionCard(
                      context: context,
                      title: AppStrings.sectionInventory,
                      icon: Icons.inventory_2_rounded,
                      iconColor: AppColors.incomeGreen,
                      accentBorderColor: AppColors.incomeGreen.withOpacity(0.4),
                      trailingSummary: '${inventory.items.length} أصناف مسجلة',
                      trailingLabel: inventory.lowStockCount > 0
                          ? '${inventory.lowStockCount} أوشك على النفاذ'
                          : 'المخزون مستقر',
                      trailingColor: inventory.lowStockCount > 0
                          ? AppColors.warningAmber
                          : AppColors.incomeGreen,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InventoryScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // 7. SECTION SEVEN: SHORTAGES / النواقص واحتياجات الخامات
                    _buildSectionCard(
                      context: context,
                      title: AppStrings.sectionShortages,
                      icon: Icons.assignment_late_rounded,
                      iconColor: shortages.activeCount > 0 ? AppColors.expenseRed : AppColors.accentGold,
                      accentBorderColor: shortages.activeCount > 0 ? AppColors.expenseRed.withOpacity(0.5) : AppColors.surfaceBorder,
                      trailingSummary: shortages.activeCount > 0 ? '${shortages.activeCount} خامات ناقصة' : 'لا توجد نواقص',
                      trailingLabel: shortages.activeCount > 0 ? 'مطلوبة للورشة' : 'جميع الاحتياجات متوفرة',
                      trailingColor: shortages.activeCount > 0 ? AppColors.expenseRed : AppColors.incomeGreen,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShortagesScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // 8. SECTION EIGHT: DASHBOARD / لوحة التحكم
                    _buildSectionCard(
                      context: context,
                      title: AppStrings.sectionDashboard,
                      icon: Icons.trending_up_rounded,
                      iconColor: AppColors.incomeGreen,
                      accentBorderColor: AppColors.incomeGreen.withOpacity(0.4),
                      trailingSummary: CurrencyFormatter.format(dashboard.calculateNetCashFlow(accounts)),
                      trailingLabel: 'صافي النقدية',
                      trailingColor: dashboard.calculateNetCashFlow(accounts) >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 26),

                    // Bottom Factory Footer
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'STARS HOMES • نظام الإدارة المالية المحمي',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'قاعدة بيانات موحدة مشتركة • مزامنة فورية وآمنة',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.accentGold.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color accentBorderColor,
    required String trailingSummary,
    required String trailingLabel,
    Color? trailingColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: iconColor.withOpacity(0.15),
        highlightColor: iconColor.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentBorderColor, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: iconColor.withOpacity(0.3), width: 1.2),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '$trailingLabel: ',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          trailingSummary,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: trailingColor ?? AppColors.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncBadge(BuildContext context, SyncStatus status, int pendingCount) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status) {
      case SyncStatus.online:
      case SyncStatus.synced:
        badgeColor = AppColors.syncConnected;
        badgeText = '';
        badgeIcon = Icons.cloud_done_rounded;
        break;
      case SyncStatus.syncing:
        badgeColor = AppColors.syncSyncing;
        badgeText = '';
        badgeIcon = Icons.sync_rounded;
        break;
      case SyncStatus.pendingChanges:
        badgeColor = AppColors.syncPending;
        badgeText = '$pendingCount';
        badgeIcon = Icons.cloud_queue_rounded;
        break;
      case SyncStatus.offline:
        badgeColor = AppColors.syncOffline;
        badgeText = '';
        badgeIcon = Icons.cloud_off_rounded;
        break;
    }

    return InkWell(
      onTap: () {
        // Navigate to full sync status screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SyncStatusScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badgeIcon, size: 16, color: badgeColor),
            if (badgeText.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                badgeText,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
