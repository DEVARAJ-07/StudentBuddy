import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/secrets/app_secrets.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_pallete.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/home/presentation/pages/student_dashboard.dart';
import 'features/admin/presentation/pages/super_admin_dashboard.dart';
import 'features/admin/presentation/pages/admin_dashboard.dart';
import 'package:flutter/services.dart';

import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';

// Global navigator key for deep link navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style for premium look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          Brightness.light, // White icons for dark background
      statusBarBrightness: Brightness.dark, // Necessary for iOS
      systemNavigationBarColor: AppPallete.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await dotenv.load(fileName: ".env");
  runApp(const AppStarter());
}

class AppStarter extends StatefulWidget {
  const AppStarter({super.key});

  @override
  State<AppStarter> createState() => _AppStarterState();
}

class _AppStarterState extends State<AppStarter> {
  bool _isInitialized = false;
  String? _errorMessage;
  bool _hasSeenSplash = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Load first-launch flag BEFORE Supabase so the splash logic is ready
    final prefs = await SharedPreferences.getInstance();
    _hasSeenSplash = prefs.getBool('has_seen_splash') ?? false;
    _initSupabase();
  }

  Future<void> _initSupabase() async {
    try {
      // Add timeout to prevent indefinite hanging
      await Supabase.initialize(
        url: AppSecrets.supabaseUrl,
        anonKey: AppSecrets.supabaseAnonKey,
      ).timeout(const Duration(seconds: 10));

      // Listen for auth state changes (including password reset)
      _setupDeepLinkListener();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint("Supabase init error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to connect: $e";
          _isInitialized = false;
        });
      }
    }
  }

  void _setupDeepLinkListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      // Handle password recovery event
      if (event == AuthChangeEvent.passwordRecovery) {
        // Navigate to reset password page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final currentTheme = themeProvider.isDarkMode
            ? AppTheme.darkTheme
            : AppTheme.lightTheme;

        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'StudentBuddy',
          debugShowCheckedModeBanner: false,
          theme: currentTheme,
          home: ContentWrapper(
            isInitialized: _isInitialized,
            errorMessage: _errorMessage,
            retryInit: _initSupabase,
            hasSeenSplash: _hasSeenSplash,
          ),
        );
      },
    );
  }
}

/// A wrapper to handle initialization, auth state, and role-based routing
/// outside the MaterialApp's builder to ensure stability during theme changes.
class ContentWrapper extends StatelessWidget {
  final bool isInitialized;
  final String? errorMessage;
  final VoidCallback retryInit;
  final bool hasSeenSplash;

  const ContentWrapper({
    super.key,
    required this.isInitialized,
    this.errorMessage,
    required this.retryInit,
    required this.hasSeenSplash,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppPallete.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Initialization Error",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: retryInit,
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!isInitialized) {
      return const SplashPage();
    }

    final session = Supabase.instance.client.auth.currentSession;

    // CASE 1: Not logged in
    if (session == null) {
      // Show SplashScreen ONLY on the very first ever launch
      if (!hasSeenSplash) {
        return SplashScreen(
          onFinish: () async {
            // Mark splash as seen permanently
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('has_seen_splash', true);
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        );
      }
      // Already seen splash — go straight to login
      return const LoginPage();
    }

    // CASE 2: Already Logged In
    // Skip Splash Screen for instant access (Direct Dashboard)
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Subtle loading skip for active users
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppPallete.primary),
            ),
          );
        }

        final role = snapshot.data;
        if (role == 'super_admin') {
          return const SuperAdminDashboard();
        } else if (role == 'admin') {
          return const AdminDashboard();
        } else {
          return const StudentDashboard();
        }
      },
    );
  }

  Future<String?> _getUserRole() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return null;

        final response = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 5));

        final role = response?['role'] as String?;
        if (role != null) return role;

        retryCount++;
        await Future.delayed(Duration(seconds: retryCount * 1));
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) return null;
        await Future.delayed(Duration(seconds: retryCount * 1));
      }
    }
    return null;
  }
}
