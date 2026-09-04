import 'package:flutter/material.dart';

void main() {
  runApp(const AresBuilderApp());
}

class AresBuilderApp extends StatelessWidget {
  const AresBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ares Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0E15),
      ),
      home: const AresMainScreen(),
    );
  }
}

class AresMainScreen extends StatefulWidget {
  const AresMainScreen({super.key});

  @override
  State<AresMainScreen> createState() => _AresMainScreenState();
}

class _AresMainScreenState extends State<AresMainScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF090A10),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Üst Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Ares Builder',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Color(0xFF00E5FF), size: 28),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Göz Logosu Alanı
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.remove_red_eye_outlined,
                    size: 70,
                    color: Color(0xFF00E5FF),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Otonom APK Derleyici .......',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Genişletilmiş Kod Yapıştırma Alanı
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF121420),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _codeController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'KOD YAPIŞTIRMA ALANI...',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Alt Aksiyon Butonları
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF121420),
                          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          'Dosya / Kod Yükle',
                          style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          'APK Oluştur & Derle',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
