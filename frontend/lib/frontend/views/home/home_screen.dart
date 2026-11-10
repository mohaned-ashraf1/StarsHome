import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stars_home/frontend/constants/app_colors.dart';
import 'package:stars_home/frontend/constants/app_strings.dart';
import 'package:stars_home/backend/services/sync_service.dart';
import 'package:stars_home/backend/utils/currency_formatter.dart';
import 'package:stars_home/backend/providers/auth_provider.dart';
import 'package:stars_home/backend/providers/accounts_provider.dart';
import 'package:stars_home/backend/providers/workers_provider.dart';
import 'package:stars_home/backend/providers/contractors_provider.dart';
import 'package:stars_home/backend/providers/dashboard_provider.dart';
import 'package:stars_home/backend/providers/customers_provider.dart';
import 'package:stars_home/backend/providers/manufacturing_provider.dart';
import 'package:stars_home/backend/providers/shortages_provider.dart';
import 'package:stars_home/backend/providers/inventory_provider.dart';
import 'package:stars_home/frontend/views/accounts/accounts_screen.dart';
import 'package:stars_home/frontend/views/workers/workers_screen.dart';
import 'package:stars_home/frontend/views/contractors/contractors_screen.dart';
import 'package:stars_home/frontend/views/customers/customers_screen.dart';
import 'package:stars_home/frontend/views/manufacturing/manufacturing_orders_screen.dart';
import 'package:stars_home/frontend/views/inventory/inventory_screen.dart';
import 'package:stars_home/frontend/views/shortages/shortages_screen.dart';
import 'package:stars_home/frontend/views/dashboard/dashboard_screen.dart';
import 'package:stars_home/frontend/views/settings/settings_screen.dart';
import 'package:stars_home/frontend/views/sync/sync_status_screen.dart';
import 'package:stars_home/frontend/views/auth/login_screen.dart';
import 'package:stars_home/backend/services/update_service.dart';
import 'package:stars_home/frontend/views/settings/update_center_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isManualSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SyncService.instance.syncDataVersionNotifier.addListener(_onSyncDataUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).loadAll();
      Provider.of<ShortagesProvider>(context, listen: false).loadAll();
      // Auto-sync on startup
      SyncService.instance.syncNow().then((_) {
        if (mounted) SyncService.reloadAllProviders(context);
      }).ignore();
      // Proactive background update check
      _checkUpdateOnStartup();
    });
  }

  Future<void> _checkUpdateOnStartup() async {
    try {
      final info = await UpdateService.instance.checkForUpdates();
      if (info.hasUpdate && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.accentGold, width: 1.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.system_update_rounded, color: AppColors.accentGold, size: 24),
                SizedBox(width: 8),
                Text(
                  'تحديث جديد متاح',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'يتوفر إصدار جديد من النظام (v${info.latestVersion}).\nهل ترغب في فتح مركز التحديثات للترقية الآن؟',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('لاحقاً', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpdateCenterScreen()),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 18, color: AppColors.backgroundDark),
                label: const Text(
                  'تحديث الآن',
                  style: TextStyle(color: AppColors.backgroundDark, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      // Silent error: do not interrupt user if offline or network drops
    }
  }

  void _onSyncDataUpdated() {
    if (mounted) {
      SyncService.reloadAllProviders(context);
    }
  }

  @override
  void dispose() {
    SyncService.instance.syncDataVersionNotifier.removeListener(_onSyncDataUpdated);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Auto-sync when app returns to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[HomeScreen] App resumed — triggering background sync');
      SyncService.instance.syncNow().then((_) {
        if (mounted) SyncService.reloadAllProviders(context);
      }).ignore();
    }
  }

  Future<void> _handleManualSync() async {
    if (_isManualSyncing) return;
    setState(() => _isManualSyncing = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGold),
            ),
            SizedBox(width: 12),
            Text('جاري المزامنة مع السيرفر السحابي...', style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        backgroundColor: AppColors.surfaceDark,
        duration: Duration(seconds: 4),
      ),
    );

    final success = await SyncService.instance.syncNow();
    if (!mounted) return;
    await SyncService.reloadAllProviders(context);
    if (!mounted) return;
    setState(() => _isManualSyncing = false);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ تمت المزامنة وتحديث كافة البيانات بنجاح!'
              : '⚠️ تعذرت المزامنة — يرجى التأكد من الاتصال بالإنترنت',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: success ? AppColors.incomeGreen : AppColors.expenseRed,
        duration: const Duration(seconds: 3),
      ),
    );
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
                await SyncService.instance.syncNow();
                if (!mounted) return;
                await SyncService.reloadAllProviders(this.context);
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
                    const SizedBox(height: 20),
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

    if (_isManualSyncing || status == SyncStatus.syncing) {
      badgeColor = AppColors.accentGold;
      badgeText = 'مزامنة...';
      badgeIcon = Icons.sync_rounded;
    } else {
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
    }

    return Tooltip(
      message: 'اضغط لمزامنة فورية (اضغط مطولاً لسجل المزامنة)',
      child: InkWell(
        onTap: _handleManualSync,
        onLongPress: () {
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
      ),
    );
  }
}
