import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/secrets/app_secrets.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_pallete.dart';
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/home/presentation/pages/student_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppStarter());
}

class AppStarter extends StatefulWidget {
  const AppStarter({super.key});

  @override
  State<AppStarter> createState() => _AppStarterState();
}

class _AppStarterState extends State<AppStarter> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initSupabase();
  }

  Future<void> _initSupabase() async {
    try {
      await Supabase.initialize(
        url: AppSecrets.supabaseUrl,
        anonKey: AppSecrets.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint("Supabase init error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          backgroundColor: AppPallete.background,
          body: Center(
            child: CircularProgressIndicator(color: AppPallete.primary),
          ),
        ),
      );
    }

    // Smart Redirect
    final session = Supabase.instance.client.auth.currentSession;
    final startPage = session != null
        ? const StudentDashboard()
        : const WelcomePage();

    return MaterialApp(
      title: 'StudentBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: startPage,
    );
  }
}
