import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth/create_account_screen.dart';
import 'screens/auth/pin_entry_screen.dart';
import 'screens/main_screen.dart';
import 'infrastructure/repositories/app_repository.dart';
import 'features/auth/auth_service.dart';

void main() {
  // Manual Dependency Injection Set Up
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve the native splash screen until our auth check completes
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  final appRepository = AppRepository();
  final authService = AuthService(repository: appRepository);

  // Seed default categories on first launch
  appRepository.seedDefaultCategories();

  runApp(
    ProviderScope(
      child: KwartaKoApp(authService: authService),
    ),
  );
}

class KwartaKoApp extends StatelessWidget {
  final AuthService authService;

  const KwartaKoApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KwartaKo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F1B2D),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1E2D4A),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: _AuthGate(authService: authService),
    );
  }
}

/// Determines the correct entry screen based on account & PIN state.
/// Removes the native splash once the decision is made.
class _AuthGate extends StatefulWidget {
  final AuthService authService;

  const _AuthGate({required this.authService});

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    _resolveAuth();
  }

  Future<void> _resolveAuth() async {
    final hasAccount = await widget.authService.hasAccount();

    Widget destination;

    if (!hasAccount) {
      destination = CreateAccountScreen(authService: widget.authService);
    } else {
      final pinEnabled = await widget.authService.isPinEnabled();
      if (pinEnabled) {
        destination = PinEntryScreen(authService: widget.authService);
      } else {
        destination = MainScreen(authService: widget.authService);
      }
    }

    // Remove the native splash now that we know where to go
    FlutterNativeSplash.remove();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Blank screen while resolving — hidden behind the native splash
    return const Scaffold(
      backgroundColor: Color(0xFF0F1B2D),
      body: SizedBox.shrink(),
    );
  }
}
