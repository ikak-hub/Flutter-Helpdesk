import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/ticket_list_page.dart';
import 'pages/ticket_detail_page.dart';
import 'pages/create_ticket_page.dart';
import 'pages/profile_page.dart';

void main() {
  runApp(const HelpdeskApp());
}

class HelpdeskApp extends StatefulWidget {
  const HelpdeskApp({super.key});

  @override
  State<HelpdeskApp> createState() => _HelpdeskAppState();
}

class _HelpdeskAppState extends State<HelpdeskApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Ticketing Helpdesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => DashboardScreen(onToggleTheme: _toggleTheme, themeMode: _themeMode),
        '/tickets': (context) => const TicketListScreen(),
        '/ticket-detail': (context) => const TicketDetailScreen(),
        '/create-ticket': (context) => const CreateTicketScreen(),
        '/profile': (context) => ProfileScreen(onToggleTheme: _toggleTheme, themeMode: _themeMode),
      },
    );
  }
}
