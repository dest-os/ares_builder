import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

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
      debugShowCheckedModeBanner: false,
      title: 'Ares Builder',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        String fileName = result.files.single.name;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Yüklendi: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya açma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startBuild() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce kod yapıştırın veya dosya yükleyin!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Derleme komutu GitHub\'a gönderiliyor...'),
        backgroundColor: Colors.blueAccent,
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final owner = prefs.getString('github_owner') ?? '';
      final repo = prefs.getString('github_repo') ?? '';
      final token = prefs.getString('github_token') ?? '';

      if (owner.isEmpty || repo.isEmpty || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lütfen Ayarlar sayfasında tüm GitHub bilgilerini girin!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final url = Uri.parse('https://api.github.com/repos/$owner/$repo/dispatches');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'event_type': 'build-apk'}),
      );

      if (mounted) {
        if (response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('APK Derleme Başlatıldı! GitHub Actions sekmesinden takip edebilirsiniz.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${response.statusCode} - ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      // Ekranın boş bir yerine dokunulduğunda klavyeyi kapatır
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 1. TAM ARKA PLAN GÖRSELİ
            Positioned.fill(
              child: Image.asset(
                'assets/ares_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.black87),
              ),
            ),

            // 2. SAĞ ÜST: AYARLAR (Çark İkon Alanı)
            Positioned(
              top: screenSize.height * 0.04,
              right: screenSize.width * 0.02,
              width: screenSize.width * 0.15,
              height: screenSize.height * 0.25,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // 3. TAM GÖZÜN ALTINDAKİ "KOD YAZMA ALANI" (Şeffaf Metin Kutusu)
            Positioned(
              top: screenSize.height * 0.48,
              left: screenSize.width * 0.18,
              width: screenSize.width * 0.64,
              height: screenSize.height * 0.28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: Colors.transparent,
                child: TextField(
                  controller: _codeController,
                  maxLines: null,
                  expands: true,
                  enableInteractiveSelection: true, // Kopyala/Yapıştır menüsünü aktif eder
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Kod bloğuna basılı tutup yapıştırın...",
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                    border: InputBorder.none,
                  ),
                  // Android / iOS varsayılan yapıştırma menüsünü garanti eder
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: editableTextState.contextMenuButtonItems,
                    );
                  },
                ),
              ),
            ),

            // 4. SOL ALT: DOSYA / KOD YÜKLE BUTON ALANI
            Positioned(
              bottom: screenSize.height * 0.04,
              left: screenSize.width * 0.04,
              width: screenSize.width * 0.42,
              height: screenSize.height * 0.20,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _pickFile();
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // 5. SAĞ ALT: APK OLUŞTUR & DERLE BUTON ALANI
            Positioned(
              bottom: screenSize.height * 0.04,
              right: screenSize.width * 0.04,
              width: screenSize.width * 0.42,
              height: screenSize.height * 0.20,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _startBuild();
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _tokenController = TextEditingController();
  final _geminiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ownerController.text = prefs.getString('github_owner') ?? '';
      _repoController.text = prefs.getString('github_repo') ?? '';
      _tokenController.text = prefs.getString('github_token') ?? '';
      _geminiKeyController.text = prefs.getString('gemini_api_key') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('github_owner', _ownerController.text.trim());
    await prefs.setString('github_repo', _repoController.text.trim());
    await prefs.setString('github_token', _tokenController.text.trim());
    await prefs.setString('gemini_api_key', _geminiKeyController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ayarlar başarıyla kaydedildi!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar & API Anahtarları'),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GitHub Kullanıcı Adı (Owner)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _ownerController,
                decoration: const InputDecoration(hintText: 'Örn: ibrahim-halil', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),

              const Text('Depo Adı (Repo)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _repoController,
                decoration: const InputDecoration(hintText: 'Örn: ares_launcher', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),

              const Text('GitHub Personal Access Token (PAT)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _tokenController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'ghp_xxxxxxxxxxxx', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),

              const Text('Gemini API Key', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _geminiKeyController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'AIzaSyxxxxxxxxxxxx', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
                  child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
