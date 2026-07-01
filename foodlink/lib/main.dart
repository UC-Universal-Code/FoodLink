import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/cocinero_home_screen.dart';
import 'screens/trabajador_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF20303D),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          primary: const Color(0xFF20303D),
          secondary: const Color(0xFF20303D),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF20303D),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF20303D),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF20303D), width: 2),
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminHome(),
        '/cocinero': (context) => const CocineroHome(),
        '/trabajador': (context) => const TrabajadorHome(),
      },
    );
  }
}