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
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _repoController = TextEditingController();

  bool _isSettingsOpen = false; // Ayarlar penceresinin açık olup olmadığını kontrol eder

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Ekranın klavyeden dolayı sıkışmasını engeller
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

                // 2. SAĞ ÜST AYARLAR BUTONU
                Positioned(
                  right: w * 0.05,
                  top: h * 0.06,
                  width: w * 0.12,
                  height: h * 0.22,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        setState(() {
                          _isSettingsOpen = true;
                        });
                      },
                      child: Container(),
                    ),
                  ),
                ),

                // 3. KOD YAPIŞTIRMA ALANI
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

                // 6. AYARLAR PENCERESİ (Özel Sabit Katman - Klavye Sorunsuz Çalışır)
                if (_isSettingsOpen)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black87,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Container(
                            width: w * 0.65,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xAA00E5FF),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.settings, color: Color(0xFF00E5FF)),
                                    SizedBox(width: 10),
                                    Text(
                                      'AYARLAR',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'GitHub Repository & Build Yapılandırması',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _tokenController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: 'GitHub Token',
                                    labelStyle: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12),
                                    filled: true,
                                    fillColor: Colors.black45,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _repoController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: 'Repo Adı',
                                    labelStyle: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12),
                                    filled: true,
                                    fillColor: Colors.black45,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isSettingsOpen = false;
                                        });
                                      },
                                      child: const Text('İptal', style: TextStyle(color: Colors.white54)),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00E5FF),
                                        foregroundColor: Colors.black,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isSettingsOpen = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Ayarlar Kaydedildi! (Token: ${_tokenController.text.isNotEmpty ? "Mevcut" : "Boş"})',
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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
