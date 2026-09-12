import 'package:flutter/material.dart';
import 'package:ares_builder/widgets/code_input_box.dart';
import 'package:ares_builder/widgets/action_buttons.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020B14),
      resizeToAvoidBottomInset: false, // Klavyenin ekranı sıkıştırmasını engeller
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Arka Plan Görseli - Ekranı uçtan uca kaplar
              Image.asset(
                'assets/images/ares_bg.png',
                fit: BoxFit.fill, // Kenar boşluklarını sıfırlayıp tam doldurur
              ),
              // Kod Yazma Alanı Katmanı
              const CodeInputBox(),
              // Buton Katmanları
              const ActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
