// filepath: lib/main.dart
// MIZAN PLC: UNIFIED WEB PRODUCTION ROUTER (V8.6)
// ARCHITECT: Mizan PLC Chief Systems Architect

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/l10n.dart';
import 'providers/locale_provider.dart';
import 'features/nutrition/providers/nutrition_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'services/sms_gateway_service.dart';

const String mizanUrl = 'https://xztidxvdikyintwiaths.supabase.co';
const String mizanPublicAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6dGlkeHZkaWt5aW50d2lhdGhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMjYyODUsImV4cCI6MjA4NTcwMjI4NX0.ntd5TpKEYfzubCl3ljDqhM_6Ro-ZjsdbIvVexKNLFm8';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: mizanUrl,
      anonKey: mizanPublicAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    // Clear stale sessions at startup
    await Supabase.instance.client.auth.signOut();
  } catch (e) {
    debugPrint("SUPABASE UI INIT ERROR: $e");
  }

  const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'production',
  );

  if (flavor == 'gateway') {
    runApp(const MizanGatewayApp());
  } else {
    final globalAuthProvider = AuthProvider();
    AppRouter.setAuthProvider(globalAuthProvider);
    runApp(MizanApp(authProvider: globalAuthProvider));
  }
}

// Gateway Entry Point
class MizanGatewayApp extends StatefulWidget {
  const MizanGatewayApp({super.key});

  @override
  State<MizanGatewayApp> createState() => _MizanGatewayAppState();
}

class _MizanGatewayAppState extends State<MizanGatewayApp> {
  final MizanSmsGateway _gateway = MizanSmsGateway();

  @override
  void initState() {
    super.initState();
    _initializeGateway();
  }

  Future<void> _initializeGateway() async {
    debugPrint("MIZAN_GATEWAY_LOG: Initializing MizanSmsGateway...");
    await _gateway.startService((log) {
      debugPrint("MIZAN_GATEWAY_LOG: $log");
    });
  }

  @override
  void dispose() {
    _gateway.stopService((log) => debugPrint("MIZAN_GATEWAY_LOG: $log"));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings_input_antenna, size: 64, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                "MIZAN GATEWAY: SENTINEL ACTIVE",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text("Monitoring Outbox Queue..."),
            ],
          ),
        ),
      ),
    );
  }
}

// Production App Entry Point
class MizanApp extends StatelessWidget {
  final AuthProvider authProvider;

  const MizanApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp.router(
            title: 'MIZAN ADMIN DASHBOARD',
            debugShowCheckedModeBanner: false,
            theme: MizanTheme.getTheme(context),
            routerConfig: AppRouter.router,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: L10n.all,
          );
        },
      ),
    );
  }
}
