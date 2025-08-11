import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:splitzy/utils/theme_provider.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/services/local_storage_service.dart';
import 'package:splitzy/services/contacts_service.dart';
import 'package:splitzy/services/cache_service.dart';
import 'package:splitzy/services/optimized_data_service.dart';
import 'package:splitzy/services/notification_service.dart';
import 'package:splitzy/screens/home_screen.dart';
import 'package:splitzy/screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print("Firebase initialized successfully");
    }

    // Initialize local storage
    await LocalStorageService.initialize();
    if (kDebugMode) {
      print("Local storage initialized successfully");
    }

    // Initialize notification service
    await NotificationService().initialize();
    if (kDebugMode) {
      print("Notification service initialized successfully");
    }

  } catch (e) {
    if (kDebugMode) {
      print("Initialization error: $e");
    }
    // Continue anyway to show error screen
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DatabaseService()),
        ChangeNotifierProvider(create: (_) => ContactsService()),
        ChangeNotifierProvider(create: (_) => CacheService()),
        ChangeNotifierProxyProvider<CacheService, OptimizedDataService>(
          create: (context) => OptimizedDataService(context.read<CacheService>()),
          update: (context, cacheService, previous) =>
          previous ?? OptimizedDataService(cacheService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Splitzy',
          themeMode: themeProvider.themeMode,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authService = context.read<AuthService>();
      final isSignedIn = authService.isSignedIn; // Changed from isLoggedIn() to isSignedIn

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isSignedIn ? const HomeScreen() : const LoginScreen(),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Auth check error: $e");
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            // App name
            const Text(
              'Splitzy',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Tagline
            const Text(
              'Split expenses with friends',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}