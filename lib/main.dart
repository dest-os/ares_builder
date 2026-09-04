import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const AresBuilderApp());
  });
}

class AresBuilderApp extends StatelessWidget {
  const AresBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ares Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
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

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.settings, color: Color(0xFF00E5FF)),
              SizedBox(width: 10),
              Text(
                'AYARLAR',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GitHub Repository & Build Yapılandırması',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 15),
              TextField(
                decoration: InputDecoration(
                  labelText: 'GitHub Token',
                  labelStyle: const TextStyle(color: Color(0xFF00E5FF)),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Repo Adı',
                  labelStyle: const TextStyle(color: Color(0xFF00E5FF)),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ayarlar Kaydedildi!')),
                );
              },
              child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                // 1. TAM ARAYÜZ ARKA PLAN GÖRSELİ
                Positioned.fill(
                  child: Image.asset(
                    'assets/ares_bg.jpg',
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          'assets/ares_bg.jpg yüklenemedi!',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),

                // 2. SAĞ ÜST AYARLAR BUTONU (Görseldeki Dişli/Çark İkonunun Üstü)
                Positioned(
                  right: w * 0.05,
                  top: h * 0.06,
                  width: w * 0.12,
                  height: h * 0.22,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => _showSettingsDialog(context),
                      child: Container(),
                    ),
                  ),
                ),

                // 3. KOD YAPIŞTIRMA ALANI (Görseldeki siyah çerçevenin tam içi)
                Positioned(
                  left: w * 0.25,
                  width: w * 0.50,
                  top: h * 0.56,
                  height: h * 0.14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    color: Colors.transparent,
                    child: TextField(
                      controller: _codeController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'KOD YAPIŞTIRMA ALANI...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ),
                ),

                // 4. DOSYA / KOD YÜKLE BUTONU
                Positioned(
                  left: w * 0.08,
                  width: w * 0.38,
                  bottom: h * 0.08,
                  height: h * 0.16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dosya Yükleme Paneli Açılıyor...')),
                        );
                      },
                      child: Container(),
                    ),
                  ),
                ),

                // 5. APK OLUŞTUR & DERLE BUTONU
                Positioned(
                  right: w * 0.08,
                  width: w * 0.38,
                  bottom: h * 0.08,
                  height: h * 0.16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('APK Derleme İşlemi Başlatıldı!')),
                        );
                      },
                      child: Container(),
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
