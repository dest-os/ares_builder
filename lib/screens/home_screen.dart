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
      body: Container(
        color: const Color(0xFF03080E),
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
                    fit: BoxFit.cover,
                  ),
                ),

                // 2. KATMAN: Merkezlenmiş Kod Yazma / Metin Alanı (Dikeyde ortalandı ve Neon Mavi yapıldı)
                Positioned(
                  left: width * 0.250,
                  top: height * 0.585,
                  width: width * (0.750 - 0.250),
                  height: height * (0.710 - 0.585),
                  child: Center(
                    child: TextField(
                      controller: _codeController,
                      maxLines: null,
                      expands: true,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF), 
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: _selectedFileName.isEmpty 
                            ? "Kodu buraya yazın veya dosya yükleyin..." 
                            : "Dosya: $_selectedFileName",
                        hintStyle: const TextStyle(
                          color: Color(0xFF00E5FF), 
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),

                // 3. KATMAN: Dosya / Kod Yükle Butonu
                Positioned(
                  left: width * 0.080,
                  top: height * 0.760,
                  width: width * (0.480 - 0.080),
                  height: height * (0.910 - 0.760),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _pickFiles,
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // 4. KATMAN: APK Oluştur & Derle Butonu
                Positioned(
                  left: width * 0.520,
                  top: height * 0.760,
                  width: width * (0.920 - 0.520),
                  height: height * (0.910 - 0.760),
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

                // 5. KATMAN: Ayarlar Butonu (Sağ Üst)
                Positioned(
                  left: width * 0.830,
                  top: height * 0.100,
                  width: width * (0.940 - 0.830),
                  height: height * (0.280 - 0.100),
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
