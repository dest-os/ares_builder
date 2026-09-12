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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: globalCodeController,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'monospace',
        ),
        decoration: const InputDecoration(
          hintText: 'Komut veya Kod Yazın...',
          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
