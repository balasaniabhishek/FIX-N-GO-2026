import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'earnings_screen.dart';
import 'job_detail_screen.dart';
import 'my_jobs_screen.dart';
import 'profile_screen.dart';
import 'payment_screen.dart';
import 'withdrawal_screen.dart';
import 'support_screen.dart';
import 'notifications_screen.dart';
import 'kyc_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'edit_profile_screen.dart';
import 'bank_details_screen.dart';
import 'notification_settings_screen.dart';
import 'theme/app_theme.dart';
import 'theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const FixNGoTechApp(),
    ),
  );
}

class FixNGoTechApp extends StatelessWidget {
  const FixNGoTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? AppColors.bg : AppColors.bgLight,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: 'FixTech',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/kyc': (context) => KycScreen(),
        '/job_detail': (context) => JobDetailScreen(),
        '/earnings': (context) => EarningsScreen(),
        '/my_jobs': (context) => MyJobsScreen(),
        '/profile': (context) => ProfileScreen(),
        '/payment': (context) => PaymentScreen(),
        '/withdrawal': (context) => WithdrawalScreen(),
        '/support': (context) => SupportScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/privacy': (context) => PrivacyPolicyScreen(),
        '/terms': (context) => TermsOfServiceScreen(),
        '/edit_profile': (context) => EditProfileScreen(),
        '/bank_details': (context) => BankDetailsScreen(),
        '/notification_settings': (context) => NotificationSettingsScreen(),
      },
    );
  }
}
