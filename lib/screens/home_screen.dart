import 'package:flutter/material.dart';
import 'settings_screen.dart';

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
      backgroundColor: const Color(0xFF03080E),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          return Stack(
            children: [
              // 1. KATMAN: Ekranı Tam Kaplayan Arka Plan Görseli
              Positioned.fill(
                child: Image.asset(
                  'assets/images/ares_bg.png',
                  fit: BoxFit.cover,
                ),
              ),

              // 2. KATMAN: Şeffaf Kod Giriş Alanı (Görseldeki "KOD YAPIŞTIRMA ALANI" üzerine gelir)
              Positioned(
                left: width * 0.230,
                top: height * 0.530,
                width: width * (0.770 - 0.230),
                height: height * (0.670 - 0.530),
                child: TextField(
                  controller: _codeController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '', // Görseldeki yazı kalacak, tıkladığında buraya yazacak
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),

              // 3. KATMAN: Şeffaf "Dosya / Kod Yükle" Buton Katmanı (Sol Alt)
              Positioned(
                left: width * 0.080,
                top: height * 0.760,
                width: width * (0.480 - 0.080),
                height: height * (0.910 - 0.760),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dosya seçme alanı açılıyor...')),
                    );
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),

              // 4. KATMAN: Şeffaf "APK Oluştur & Derle" Buton Katmanı (Sağ Alt)
              Positioned(
                left: width * 0.520,
                top: height * 0.760,
                width: width * (0.920 - 0.520),
                height: height * (0.910 - 0.760),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('APK derleme işlemi tetiklendi...')),
                    );
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),

              // 5. KATMAN: Şeffaf Ayarlar Butonu (Sağ Üst Altıgen İkon)
              Positioned(
                left: width * 0.830,
                top: height * 0.100,
                width: width * (0.940 - 0.830),
                height: height * (0.280 - 0.100),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
