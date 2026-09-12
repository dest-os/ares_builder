import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/settings_screen.dart';
import 'widgets/code_input_box.dart';
import 'widgets/action_buttons.dart';

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

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // GestureDetector ile boş yere basınca klavyeyi kapatıyoruz
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 1. Arka Plan Görseli (Birebir Korunuyor)
            Positioned.fill(
              child: Image.asset(
                'assets/ares_bg.png',
                fit: BoxFit.cover,
              ),
            ),

            // 2. Ayarlar Butonu (Sağ Üst Köşedeki Çerçeveye Hizalı)
            Positioned(
              top: size.height * 0.04,
              right: size.width * 0.03,
              child: IconButton(
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
            ),

            // 3. Kod Yazma Kutusu (Orta Çerçeveye Hizalı)
            const CodeInputBox(),

            // 4. Alt Butonlar (Alt Çerçevelere Hizalı)
            const ActionButtons(),
          ],
        ),
      ),
    );
  }
}
