import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/github_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _selectedFileName = '';
  bool _isLoading = false;

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt', 'json', 'png', 'jpg', 'jpeg', 'zip'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFileName = result.files.map((f) => f.name).join(', ');
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${result.files.length} dosya seçildi: $_selectedFileName')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya seçilirken hata oluştu: $e')),
        );
      }
    }
  }

  /// Yapıştırılan metni parçalayıp haritalandırır
  Map<String, String> _parseCodeText(String rawText) {
    final Map<String, String> files = {};
    final lines = rawText.split('\n');

    String? currentFileName;
    StringBuffer currentContent = StringBuffer();

    for (var line in lines) {
      if (line.trim().startsWith('# FILE:') || line.trim().startsWith('// FILE:')) {
        if (currentFileName != null) {
          files[currentFileName] = currentContent.toString().trim();
          currentContent.clear();
        }
        currentFileName = line.replaceAll('# FILE:', '').replaceAll('// FILE:', '').trim();
      } else {
        if (currentFileName != null) {
          currentContent.writeln(line);
        }
      }
    }

    if (currentFileName != null && currentContent.isNotEmpty) {
      files[currentFileName] = currentContent.toString().trim();
    }

    return files;
  }

  /// GitHub'a Gönderme ve Derleme Mantığı
  Future<void> _startBuildProcess() async {
    FocusScope.of(context).unfocus();

    final rawText = _codeController.text.trim();
    if (rawText.isEmpty && _selectedFileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kod yazın veya bir dosya seçin.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('github_token') ?? '';
      final owner = prefs.getString('github_username') ?? '';
      
      // Metnin içinden REPO_NAME oku veya varsayılan depoyu kullan
      String repo = 'ares_launcher';
      if (rawText.contains('REPO_NAME:')) {
        final repoLine = rawText.split('\n').firstWhere((l) => l.contains('REPO_NAME:'));
        repo = repoLine.replaceAll('REPO_NAME:', '').trim();
      }

      if (token.isEmpty || owner.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hata: Ayarlar ekranından GitHub Token ve Kullanıcı Adını kaydedin.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final githubService = GitHubService(token: token, owner: owner, repo: repo);

      // Metni parçala
      final filesToSend = _parseCodeText(rawText);

      if (filesToSend.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hata: Metin içinde geçerli dosya başlığı (# FILE: path) bulunamadı.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$repo deposuna ${filesToSend.length} dosya gönderiliyor...')),
        );
      }

      // Dosyaları GitHub'a Yükle
      final success = await githubService.pushMultipleFiles(
        filesToSend,
        'Auto build commit by Ares Builder',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Başarılı! Dosyalar GitHub\'a aktarıldı, derleme başladı.')),
          );
          _codeController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hata: Dosyalar aktarılamadı. Token izinlerini ve ağ bağlantısını kontrol edin.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF03080E),
        body: SizedBox.expand(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double height = constraints.maxHeight;

              return Stack(
                children: [
                  // 1. KATMAN: Arka Plan Görseli
                  Positioned.fill(
                    child: Image.asset(
                      'assets/ares_bg.png',
                      fit: BoxFit.fill,
                    ),
                  ),

                  // 2. KATMAN: Şeffaf KOD YAPIŞTIRMA ALANI
                  Positioned(
                    left: width * 0.23,
                    top: height * 0.53,
                    width: width * 0.54,
                    height: height * 0.15,
                    child: Center(
                      child: TextField(
                        controller: _codeController,
                        maxLines: null,
                        expands: true,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: _selectedFileName.isEmpty ? "" : "Dosya: $_selectedFileName",
                          hintStyle: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(5.0),
                        ),
                      ),
                    ),
                  ),

                  // 3. KATMAN: Dosya / Kod Yükle Butonu
                  Positioned(
                    left: width * 0.06,
                    top: height * 0.75,
                    width: width * 0.42,
                    height: height * 0.16,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _pickFiles,
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                  // 4. KATMAN: APK Oluştur & Derle Butonu
                  Positioned(
                    left: width * 0.52,
                    top: height * 0.75,
                    width: width * 0.42,
                    height: height * 0.16,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _isLoading ? null : _startBuildProcess,
                      child: Container(
                        color: Colors.transparent,
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF00E5FF),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),

                  // 5. KATMAN: Sağ Üstteki Ayarlar Simgesi
                  Positioned(
                    left: width * 0.87,
                    top: height * 0.06,
                    width: width * 0.10,
                    height: height * 0.19,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        FocusScope.of(context).unfocus();
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
        ),
      ),
    );
  }
}
