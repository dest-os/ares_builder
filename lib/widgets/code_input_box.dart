import 'package:flutter/material.dart';

// Kod metnini diğer modüllerden erişilebilir tutmak için global controller
final TextEditingController globalCodeController = TextEditingController();

class CodeInputBox extends StatelessWidget {
  const CodeInputBox({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      // Arka plandaki "KOD YAZMA ALANI" çerçevesine tam oturan konumlandırma
      top: size.height * 0.58,
      left: size.width * 0.11,
      width: size.width * 0.78,
      height: size.height * 0.23,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent, // Arka plan görselini kapatmaması için şeffaf
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: globalCodeController,
          maxLines: null,
          expands: true,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          decoration: const InputDecoration(
            hintText: 'Kod bloğuna basılı tutup yapıştırın...',
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
