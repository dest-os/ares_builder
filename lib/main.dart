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
                          'assets/ares_bg.jpg yüklenemedi! Lütfen klasörde ares_bg.jpg adıyla resim olduğundan emin olun.',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),

                // 2. KOD YAPIŞTIRMA ALANI
                Positioned(
                  left: w * 0.22,
                  width: w * 0.56,
                  top: h * 0.50,
                  height: h * 0.18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    color: Colors.transparent,
                    child: TextField(
                      controller: _codeController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'KOD YAPIŞTIRMA ALANI...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                  ),
                ),

                // 3. DOSYA / KOD YÜKLE BUTONU
                Positioned(
                  left: w * 0.06,
                  width: w * 0.41,
                  bottom: h * 0.08,
                  height: h * 0.18,
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

                // 4. APK OLUŞTUR & DERLE BUTONU
                Positioned(
                  right: w * 0.06,
                  width: w * 0.41,
                  bottom: h * 0.08,
                  height: h * 0.18,
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
