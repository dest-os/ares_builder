import 'package:flutter/material.dart';
import '../widgets/action_buttons.dart';
import '../widgets/code_input_box.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020B14),
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                // 1. Arka Plan Tasarımı (Sabit Görsel)
                Positioned.fill(
                  child: Image.asset(
                    'assets/ares_bg.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // 2. Ayarlar Çarkı Şeffaf Dokunma Alanı (Sağ Üst)
                Positioned(
                  top: 0,
                  right: 0,
                  width: 100,
                  height: 70,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),

                // 3. Kod Yazma Alanı Şeffaf Katmanı (Tam Görsel Çerçevesi İçine)
                Positioned(
                  top: 110,
                  left: 140,
                  right: 140,
                  height: 80,
                  child: const CodeInputBox(),
                ),

                // 4. Alt Butonlar Şeffaf Katmanları
                const ActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
