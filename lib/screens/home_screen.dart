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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF03080E),
      body: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double height = constraints.maxHeight;

            return Stack(
              children: [
                // 1. KATMAN: Görseli Ekranın Tamamına Kaplama (Sıfıra Sıfır)
                Positioned.fill(
                  child: Image.asset(
                    'assets/ares_bg.png',
                    fit: BoxFit.fill,
                  ),
                ),

                // 2. KATMAN: KOD YAPIŞTIRMA ALANI (Şeffaf Metin Girişi)
                Positioned(
                  left: width * 0.22,
                  top: height * 0.52,
                  width: width * 0.56,
                  height: height * 0.18,
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
                        hintText: _selectedFileName.isEmpty
                            ? "Kodu buraya yazın veya dosya yükleyin..."
                            : "Dosya: $_selectedFileName",
                        hintStyle: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),

                // 3. KATMAN: Dosya / Kod Yükle Butonu (Şeffaf Tıklama Alanı)
                Positioned(
                  left: width * 0.06,
                  top: height * 0.74,
                  width: width * 0.42,
                  height: height * 0.18,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _pickFiles,
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // 4. KATMAN: APK Oluştur & Derle Butonu (Şeffaf Tıklama Alanı)
                Positioned(
                  left: width * 0.52,
                  top: height * 0.74,
                  width: width * 0.42,
                  height: height * 0.18,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
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

                // 5. KATMAN: Sağ Üstteki Ayarlar Simgesi (Şeffaf Tıklama Alanı)
                Positioned(
                  left: width * 0.87,
                  top: height * 0.05,
                  width: width * 0.10,
                  height: height * 0.20,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
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
    );
  }
}
