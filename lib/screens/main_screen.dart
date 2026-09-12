import 'package:flutter/material.dart';
import 'package:ares_builder/widgets/code_input_box.dart';
import 'package:ares_builder/widgets/action_buttons.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020B14),
      resizeToAvoidBottomInset: false, // Klavyenin ekranı büzmesini engeller
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // 1. Arka Plan Görseli
            Positioned.fill(
              child: Image.asset(
                'assets/images/ares_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            // 2. Metin Giriş Alanı
            const CodeInputBox(),
            // 3. Alt Buton Alanları
            const ActionButtons(),
          ],
        ),
      ),
    );
  }
}
