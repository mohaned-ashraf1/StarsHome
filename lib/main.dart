import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/accounts_provider.dart';
import 'providers/workers_provider.dart';
import 'providers/contractors_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/customers_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/manufacturing_provider.dart';
import 'providers/shortages_provider.dart';
import 'views/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StarsHomesApp());
}

class StarsHomesApp extends StatelessWidget {
  const StarsHomesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AccountsProvider()),
        ChangeNotifierProvider(create: (_) => WorkersProvider()),
        ChangeNotifierProvider(create: (_) => ContractorsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => CustomersProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => ManufacturingProvider()),
        ChangeNotifierProvider(create: (_) => ShortagesProvider()),
      ],
      child: MaterialApp(
        title: 'STARS HOMES',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [
          Locale('ar', 'EG'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
