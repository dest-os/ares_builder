import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020B14),
        primaryColor: const Color(0xFF00E5FF),
      ),
      home: const MainHomeScreen(),
    );
  }
}

// ============================================================================
// ANA EKRAN (MAIN HOME SCREEN)
// ============================================================================
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final TextEditingController _codeController = TextEditingController();

  // Cihaz Depolamasından Dosya / Kod Seçme
  Future<void> _pickAndLoadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt', 'json', 'yaml', 'js', 'py', 'cpp', 'html', 'css'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        setState(() {
          _codeController.text = content;
        });
        _showAresSnackBar('Dosya başarıyla yüklendi!');
      }
    } catch (e) {
      _showAresSnackBar('Dosya okunurken bir hata oluştu: $e');
    }
  }

  // Ares Temalı Özel SnackBar Uyarısı
  void _showAresSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF020B14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  // APK Derleme İşlemi Tetikleme
  void _startBuildProcess() {
    if (_codeController.text.trim().isEmpty) {
      _showAresSnackBar('Lütfen önce kod yapıştırın veya dosya yükleyin!');
      return;
    }
    _showAresSnackBar('Derleme işlemi başlatılıyor...');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Arka Plan Görseli
          Positioned.fill(
            child: Image.asset(
              'assets/ares_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF020B14),
              ),
            ),
          ),

          // Ana İçerik Katmanı
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // ÜST BAR (Başlık, İsim ve Ayarlar Çarkı)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Ares Builder Sol Etiket
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Ares Builder',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      // İbrahim Halil Ezen ve Ayarlar Çarkı (Sağ Üst)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'İbrahim Halil Ezen',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Color(0xFF00E5FF),
                              size: 28,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ORTA ALAN: Ares Göz Simgesi ve Başlıklar
                  Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/ares_eye.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.remove_red_eye_outlined,
                              color: Color(0xFF00E5FF),
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Otonom APK Derleyici .......',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Text(
                        'KOD YAZMA ALANI',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // KOD YAZMA ALANI (Kutu)
                  Container(
                    width: screenSize.width * 0.85,
                    height: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _codeController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Kod bloğuna basılı tutup yapıştırın...',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ALT BUTONLAR (Dosya Yükle / APK Derle)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Dosya / Kod Yükle Butonu
                      ElevatedButton.icon(
                        onPressed: _pickAndLoadFile,
                        icon: const Icon(Icons.file_upload_outlined, color: Color(0xFF00E5FF)),
                        label: const Text(
                          'Dosya / Kod Yükle',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF020B14),
                          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      // APK Oluştur & Derle Butonu
                      ElevatedButton.icon(
                        onPressed: _startBuildProcess,
                        icon: const Icon(Icons.build_outlined, color: Color(0xFF00E5FF)),
                        label: const Text(
                          'APK Oluştur & Derle',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF020B14),
                          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AYARLAR VE API ANAHTARLARI EKRANI (SETTINGS SCREEN)
// ============================================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _repoController = TextEditingController();
  final TextEditingController _patController = TextEditingController();
  final TextEditingController _geminiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Kayıtlı Ayarları Cihazdan Yükleme
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _ownerController.text = prefs.getString('github_owner') ?? '';
      _repoController.text = prefs.getString('github_repo') ?? '';
      _patController.text = prefs.getString('github_pat') ?? '';
      _geminiController.text = prefs.getString('gemini_key') ?? '';
    });
  }

  // Ayarları Cihaza Kaydetme
  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('github_owner', _ownerController.text.trim());
    await prefs.setString('github_repo', _repoController.text.trim());
    await prefs.setString('github_pat', _patController.text.trim());
    await prefs.setString('gemini_key', _geminiController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF020B14),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          content: const Text(
            'Ayarlar başarıyla kaydedildi!',
            style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020B14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ayarlar & API Anahtarları',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF00E5FF).withOpacity(0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1) GitHub Kullanıcı Adı (Owner)
              _buildInputField(
                label: 'GitHub Kullanıcı Adı (Owner)',
                hint: 'Örn: ibrahim-halil',
                controller: _ownerController,
              ),

              const SizedBox(height: 16),

              // 2) Depo Adı (Repo)
              _buildInputField(
                label: 'Depo Adı (Repo)',
                hint: 'Örn: ares_launcher',
                controller: _repoController,
              ),

              const SizedBox(height: 16),

              // 3) GitHub Personal Access Token (PAT)
              _buildInputField(
                label: 'GitHub Personal Access Token (PAT)',
                hint: 'ghp_xxxxxxxxxxxx',
                controller: _patController,
                obscureText: true,
              ),

              const SizedBox(height: 16),

              // 4) Gemini API Key
              _buildInputField(
                label: 'Gemini API Key',
                hint: 'AIzaSyxxxxxxxxxxxxx',
                controller: _geminiController,
                obscureText: true,
              ),

              const SizedBox(height: 28),

              // 5) Kaydet Butonu (Ares Mavi Temalı)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(
                      color: Color(0xFF020B14),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Metin Giriş Kutuları Tasarımı
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 1),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
