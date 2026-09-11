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

  // Varsayılan GitHub Actions Workflow İçeriği
  final String _defaultWorkflowYaml = '''
name: Build Android APK

on:
  repository_dispatch:
    types: [build-apk]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'
          channel: 'stable'

      - name: Install Dependencies
        run: flutter pub get

      - name: Build APK
        run: flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
''';

  // GitHub'a Dosyaları Otomatik Yükleme ve Derlemeyi Tetikleme
  Future<void> _startBuild() async {
    final codeText = _codeController.text.trim();
    if (codeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce kod yapıştırın veya dosya yükleyin!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sistem kontrol ediliyor ve dosyalar GitHub\'a aktarılıyor...'),
        backgroundColor: Colors.blueAccent,
      ),
    );

    try {
      // 1. OTONOM ADIM: .github/workflows/build_apk.yml VAR MI KONTROL ET, YOKSA OLUŞTUR
      final workflowUrl = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/.github/workflows/build_apk.yml');
      final workflowCheck = await http.get(
        workflowUrl,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github.v3+json'},
      );

      if (workflowCheck.statusCode == 404) {
        // Workflow yoksa otonom olarak oluşturuyoruz
        final workflowBase64 = base64Encode(utf8.encode(_defaultWorkflowYaml));
        await http.put(
          workflowUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'message': 'Ares Builder: Otomatik Workflow Oluşturuldu',
            'content': workflowBase64,
          }),
        );
      }

      // 2. OTONOM ADIM: lib/main.dart DOSYASINI GÜNCELLE VEYA OLUŞTUR
      final mainDartUrl = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/lib/main.dart');
      final mainCheck = await http.get(
        mainDartUrl,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github.v3+json'},
      );

      String? sha;
      if (mainCheck.statusCode == 200) {
        final body = jsonDecode(mainCheck.body);
        sha = body['sha'];
      }

      final codeBase64 = base64Encode(utf8.encode(codeText));
      final putMainResponse = await http.put(
        mainDartUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'Ares Builder: Otomatik Kod Güncellemesi',
          'content': codeBase64,
          if (sha != null) 'sha': sha,
        }),
      );

      if (putMainResponse.statusCode == 200 || putMainResponse.statusCode == 201) {
        // 3. OTONOM ADIM: DERLEMEYİ TETİKLE
        final dispatchUrl = Uri.parse('https://api.github.com/repos/$owner/$repo/dispatches');
        final dispatchResponse = await http.post(
          dispatchUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'event_type': 'build-apk'}),
        );

        if (mounted) {
          if (dispatchResponse.statusCode == 204) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Her şey otomatik hazırlandı ve APK derlemesi başlatıldı!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Derleme tetikleme hatası: ${dispatchResponse.statusCode}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kod aktarım hatası: ${putMainResponse.statusCode}'),
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
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/ares_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.black87),
              ),
            ),
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
            Positioned(
              top: screenSize.height * 0.54,
              left: screenSize.width * 0.25,
              width: screenSize.width * 0.50,
              height: screenSize.height * 0.18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.transparent,
                child: TextField(
                  controller: _codeController,
                  maxLines: null,
                  expands: true,
                  enableInteractiveSelection: true,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Kod bloğuna basılı tutup yapıştırın...",
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 10),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: editableTextState.contextMenuButtonItems,
                    );
                  },
                ),
              ),
            ),
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
