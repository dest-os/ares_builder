import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Tabletlerde geri/ev tuşlarının kaybolmaması için kenardan kenara transparan görünüm
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      navigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Otomatik Yatay Mod Yapılandırması
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
              content: Text('Dosya yüklendi: $fileName'),
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

  // OTONOM LAUNCHER PROJE ŞABLONLARI
  final String _defaultPubspec = '''
name: ares_launcher
description: "Ares Builder Tarafından Otomatik Üretilen Dinamik Launcher"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  http: ^1.2.0
  shared_preferences: ^2.2.2
  file_picker: ^8.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/backgrounds/
    - assets/skins/
''';

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
      - name: Repoyu Klonla
        uses: actions/checkout@v4

      - name: Java 17 Kur
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Flutter SDK Kur
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Bağımlılıkları Yükle
        run: flutter pub get

      - name: APK Derle
        run: flutter build apk --release

      - name: APK Artifact Olarak Yükle
        uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
''';

  final String _defaultAndroidManifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

    <application
        android:label="Ares Launcher"
        android:name="\${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize"
            android:screenOrientation="sensorLandscape">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
''';

  // GitHub REST API Dosya Push/Create Metodu
  Future<bool> _pushFileToGithub({
    required String owner,
    required String repo,
    required String token,
    required String filePath,
    required String content,
    required String commitMessage,
  }) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$filePath');

    final getRes = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github.v3+json'},
    );

    String? sha;
    if (getRes.statusCode == 200) {
      final body = jsonDecode(getRes.body);
      sha = body['sha'];
    }

    final contentBase64 = base64Encode(utf8.encode(content));
    final putRes = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': commitMessage,
        'content': contentBase64,
        if (sha != null) 'sha': sha,
      }),
    );

    return (putRes.statusCode == 200 || putRes.statusCode == 201);
  }

  // OTONOM TÜM PROJE AĞACINI KURMA VE DERLEMEYİ BAŞLATMA
  Future<void> _startBuild() async {
    final codeText = _codeController.text.trim();
    if (codeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce kod yapıştırın!'),
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
            content: Text('Lütfen Ayarlar sayfasında tüm GitHub bilgilerini eksiksiz girin!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sıfırdan Proje Ağacı Hazırlanıyor ve Kodlar Aktarılıyor...'),
        backgroundColor: Colors.blueAccent,
        duration: Duration(seconds: 3),
      ),
    );

    try {
      // 1. ADIM: pubspec.yaml Kurulumu
      await _pushFileToGithub(
        owner: owner,
        repo: repo,
        token: token,
        filePath: 'pubspec.yaml',
        content: _defaultPubspec,
        commitMessage: 'Ares Builder: pubspec.yaml otonom kuruldu',
      );

      // 2. ADIM: GitHub Actions Workflow Kurulumu
      await _pushFileToGithub(
        owner: owner,
        repo: repo,
        token: token,
        filePath: '.github/workflows/build_apk.yml',
        content: _defaultWorkflowYaml,
        commitMessage: 'Ares Builder: Workflow otonom kuruldu',
      );

      // 3. ADIM: AndroidManifest.xml Kurulumu (İzinler Dahil)
      await _pushFileToGithub(
        owner: owner,
        repo: repo,
        token: token,
        filePath: 'android/app/src/main/AndroidManifest.xml',
        content: _defaultAndroidManifest,
        commitMessage: 'Ares Builder: AndroidManifest otonom kuruldu',
      );

      // 4. ADIM: Assets Klasör Tutucuları (.gitkeep)
      await _pushFileToGithub(
        owner: owner,
        repo: repo,
        token: token,
        filePath: 'assets/backgrounds/.gitkeep',
        content: '',
        commitMessage: 'Ares Builder: Arka plan klasörü hazırlandı',
      );

      await _pushFileToGithub(
        owner: owner,
        repo: repo,
        token: token,
        filePath: 'assets/skins/.gitkeep',
        content: '',
        commitMessage: 'Ares Builder: Skins klasörü hazırlandı',
      );

      // 5. ADIM: Yapıştırılan Kodu lib/main.dart Olarak Yükleme
      bool codeSuccess = await _pushFileToGithub(
        owner: owner,
        repo: repo,
        token: token,
        filePath: 'lib/main.dart',
        content: codeText,
        commitMessage: 'Ares Builder: Launcher Ana Kodu Yüklendi',
      );

      if (codeSuccess) {
        // 6. ADIM: GitHub Actions APK Derlemesini Tetikleme
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
                content: Text('Tüm dosya ağacı oluşturuldu ve APK derlemesi başarıyla başlatıldı!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
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
            const SnackBar(
              content: Text('Kod aktarılırken hata oluştu! GitHub Token izinlerinizi kontrol edin.'),
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
            // Siberpunk Arka Plan
            Positioned.fill(
              child: Image.asset(
                'assets/images/ares_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.black87),
              ),
            ),

            // Ayarlar Butonu (Sağ Üst Dokunmatik Alan)
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

            // Kod Yapıştırma Metin Alanı (Orta)
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
                    hintText: "Kod alanına basılı tutup yapıştırın...",
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

            // Dosya / Kod Yükle Butonu (Sol Alt)
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

            // APK Oluştur & Derle Butonu (Sağ Alt)
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
                decoration: const InputDecoration(hintText: 'Örn: github_kullanici_adin', border: OutlineInputBorder()),
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
