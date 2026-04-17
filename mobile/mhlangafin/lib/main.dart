import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/dashboard_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/transfer_page.dart';
import 'pages/digital_card_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_users_page.dart';
import 'pages/admin_transactions_page.dart';
import 'pages/admin_main_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Custom status bar theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  
  runApp(const MhlangaFinApp());
}

class MhlangaFinApp extends StatelessWidget {
  const MhlangaFinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MhlangaFin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        fontFamily: 'Inter', // Note: ensure fonts are added to pubspec.yaml if desired
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
          secondary: Colors.blue[600]!,
          background: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black),
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/transfer': (context) => const TransferPage(),
        '/digital-card': (context) => const DigitalCardPage(),
        '/admin': (context) => const AdminMainPage(),
        '/admin-dashboard': (context) => const AdminDashboardPage(),
        '/admin-users': (context) => const AdminUsersPage(),
        '/admin-transactions': (context) => const AdminTransactionsPage(),
      },
    );
  }
}