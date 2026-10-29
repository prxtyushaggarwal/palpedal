import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/fleet_provider.dart';
import 'providers/ride_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => FleetProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
      ],
      child: const PalPedalApp(),
    ),
  );
}

class PalPedalApp extends StatelessWidget {
  const PalPedalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'PalPedal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF10B981),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF1E293B),
        ),
        fontFamily: 'Roboto',
      ),
      home: auth.isAuthenticated ? const HomeMapScreen() : const LoginScreen(),
    );
  }
}
