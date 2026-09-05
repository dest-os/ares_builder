import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _selectedFileName = '';

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

  @override
  Widget build(BuildContext context) {
    // Ekrana tıklanınca klavyeyi kapatmayı sağlayan ana dokunma algılayıcı
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

                  // 2. KATMAN: Şeffaf KOD YAPIŞTIRMA ALANI (Yeni boş kutuya milimetrik oturtuldu)
                  Positioned(
                    left: width * 0.23,  // Yatay başlangıç
                    top: height * 0.53,   // Dikey başlangıç (Boş kutunun üstü)
                    width: width * 0.54,  // Kutunun genişliği
                    height: height * 0.15, // Kutunun yüksekliği (3-4 satır kod sığar)
                    child: Center(
                      child: TextField(
                        controller: _codeController,
                        maxLines: null,
                        expands: true,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          color: Color(0xFF00E5FF), // Neon Mavi
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          // Kutunun içinde hiçbir ipucu yazısı görünmeyecek, 
                          // çünkü resminizdeki "KOD YAZMA ALANI" üstte duruyor.
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

                  // 3. KATMAN: Dosya / Kod Yükle Butonu (Tıklama Alanı)
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

                  // 4. KATMAN: APK Oluştur & Derle Butonu (Tıklama Alanı)
                  Positioned(
                    left: width * 0.52,
                    top: height * 0.75,
                    width: width * 0.42,
                    height: height * 0.16,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        // Klavyeyi kapat
                        FocusScope.of(context).unfocus();

                        if (_codeController.text.isEmpty && _selectedFileName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lütfen kod yazın veya bir dosya seçin.')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ares Builder derleme işlemini başlattı...')),
                          );
                        }
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                  // 5. KATMAN: Sağ Üstteki Ayarlar Simgesi (Tıklama Alanı)
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
