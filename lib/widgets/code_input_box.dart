import 'package:flutter/material.dart';

final TextEditingController globalCodeController = TextEditingController();

class CodeInputBox extends StatefulWidget {
  const CodeInputBox({super.key});

  @override
  State<CodeInputBox> createState() => _CodeInputBoxState();
}

class _CodeInputBoxState extends State<CodeInputBox> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      top: size.height * 0.54,   // Arka plandaki siyah kutunun dikey konumu
      left: size.width * 0.22,  // Arka plandaki siyah kutunun yatay konumu
      width: size.width * 0.56, // Kutu genişliği
      height: size.height * 0.16, // Kutu yüksekliği
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: TextField(
          controller: globalCodeController,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 13,
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(
            hintText: 'Komut veya Kod Yazın...',
            hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
