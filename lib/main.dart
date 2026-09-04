import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AresApp());
}

class AresApp extends StatelessWidget {
  const AresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ares Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF0284C7),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
