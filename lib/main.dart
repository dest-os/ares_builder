import 'package:flutter/material.dart';
import 'theme/ares_theme.dart';
import 'widgets/ares_3d_button.dart';

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
      theme: AresTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AresColors.surface,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.remove_red_eye, color: AresColors.accent, size: 28),
            SizedBox(width: 10),
            Text(
              'Ares Builder',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AresColors.textSecondary),
            onPressed: () {
              // Ayarlar
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Otonom APK Derleyici & Kod Onarıcı',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AresColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AresColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  controller: _codeController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(color: AresColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Flutter / Dart kodlarınızı veya belge metnini buraya yapıştırın...',
                    hintStyle: TextStyle(color: AresColors.textSecondary),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Ares3DButton(
              text: 'Dosya / Kod Yükle',
              icon: Icons.attach_file,
              color: AresColors.surface,
              shadowColor: Colors.black38,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            Ares3DButton(
              text: 'APK Oluştur & Derle',
              icon: Icons.build_circle_outlined,
              color: AresColors.primary,
              shadowColor: AresColors.primaryDark,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
