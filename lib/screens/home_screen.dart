import 'package:flutter/material.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isBuilding = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03080E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double height = constraints.maxHeight;

            return Stack(
              children: [
                // 1. KATMAN: Arka Plan Görseli
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/ares_bg.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // 2. KATMAN: Sağ Üst Paneldeki İsminiz (Tam Ortalı ve Büyük)
                Positioned(
                  left: width * 0.628,
                  top: height * 0.120,
                  width: width * (0.825 - 0.628),
                  height: height * (0.280 - 0.120),
                  child: Center(
                    child: Text(
                      'İbrahim Halil Ezen',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF00E5FF),
                        fontSize: width * 0.038,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // 3. KATMAN: Ayarlar Butonu (Sağ Üst Köşe)
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.cyan),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),

                // 4. KATMAN: Orta Kod Giriş Alanı
                Positioned(
                  left: width * 0.230,
                  top: height * 0.540,
                  width: width * (0.770 - 0.230),
                  height: height * (0.635 - 0.540),
                  child: TextField(
                    controller: _codeController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Kod yapıştırın veya dosya yükleyin...',
                      hintStyle: TextStyle(color: Color(0xFF00D2FF)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),

                // 5. KATMAN: Alt Butonlar (APK Derle)
                Positioned(
                  bottom: height * 0.08,
                  left: width * 0.10,
                  right: width * 0.10,
                  child: ElevatedButton.icon(
                    onPressed: _isBuilding
                        ? null
                        : () {
                            setState(() {
                              _isBuilding = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('APK derleme işlemi tetiklendi...'),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isBuilding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.build_rounded, color: Colors.white),
                    label: Text(
                      _isBuilding ? 'Derleniyor...' : 'APK Oluştur & Derle',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
