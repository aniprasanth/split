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
import 'package:splitzy/utils/error_screen.dart';
import 'firebase_options.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    bool initializationSuccess = false;

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

      initializationSuccess = true;
    } catch (e) {
      if (kDebugMode) {
        print("Initialization error: $e");
      }
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
        child: MyApp(initializationSuccess: initializationSuccess),
      ),
    );
  }, (error, stack) {
    if (kDebugMode) {
      print('Uncaught error: $error');
      print('Stack trace: $stack');
    }
  });
}

class MyApp extends StatelessWidget {
  final bool initializationSuccess;

  const MyApp({
    super.key,
    required this.initializationSuccess,
  });

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
          home: initializationSuccess 
              ? const SplashScreen() 
              : const ErrorScreen(message: 'Failed to initialize app'),
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
      final isSignedIn = authService.isSignedIn;

      if (!mounted) return;

      await Future.delayed(const Duration(seconds: 2)); // Minimum splash duration

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
      body: SafeArea(
        child: Center(
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
      ),
    );
  }
}

// Error screen widget
class ErrorScreen extends StatelessWidget {
  final String message;
  
  const ErrorScreen({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Phoenix.rebirth(context);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}