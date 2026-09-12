import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020B14),
      appBar: AppBar(
        title: const Text('Ares Builder Ayarları'),
        backgroundColor: const Color(0xFF020B14),
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Derleme ve GitHub Konfigürasyonları',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Buradan APK derleme parametrelerini ve GitHub Secrets ayarlarınızı yönetebilirsiniz.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
