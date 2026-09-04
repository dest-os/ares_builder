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
  final TextEditingController _githubTokenController = TextEditingController();
  final TextEditingController _geminiKeyController = TextEditingController();

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AresColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.settings, color: AresColors.accent),
            SizedBox(width: 8),
            Text('Ares Ayarları', style: TextStyle(color: AresColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _githubTokenController,
              style: const TextStyle(color: AresColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'GitHub PAT Token',
                labelStyle: TextStyle(color: AresColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AresColors.accent)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _geminiKeyController,
              style: const TextStyle(color: AresColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                labelStyle: TextStyle(color: AresColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AresColors.accent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: AresColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AresColors.primary),
            onPressed: () {
              // Ayarlar kaydedildi bildirimi
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ayarlar başarıyla kaydedildi!')),
              );
            },
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AresColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AresColors.accent, width: 2),
                boxShadow: const [
                  BoxShadow(color: AresColors.accent, blurRadius: 8, spreadRadius: 1)
                ],
              ),
              child: const Icon(Icons.remove_red_eye_rounded, color: AresColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Ares Builder',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AresColors.accent, size: 26),
            onPressed: _showSettingsDialog,
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
                  border: Border.all(color: AresColors.accent.withOpacity(0.3)),
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
            const SizedBox(height: 16),
            Ares3DButton(
              text: 'Dosya / Kod Yükle',
              icon: Icons.attach_file,
              color: AresColors.surface,
              shadowColor: Colors.black,
              onPressed: () {},
            ),
            const SizedBox(height: 16),
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
