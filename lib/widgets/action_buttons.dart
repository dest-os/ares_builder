import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'code_input_box.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  Future<void> _pickAndLoadFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt', 'json', 'yaml', 'js', 'py', 'cpp', 'html', 'css'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        globalCodeController.text = content;
        _showAresSnackBar(context, 'Dosya başarıyla yüklendi!');
      }
    } catch (e) {
      _showAresSnackBar(context, 'Dosya okunurken bir hata oluştu: $e');
    }
  }

  void _startBuildProcess(BuildContext context) {
    if (globalCodeController.text.trim().isEmpty) {
      _showAresSnackBar(context, 'Lütfen önce kod yapıştırın veya dosya yükleyin!');
      return;
    }
    _showAresSnackBar(context, 'Derleme işlemi başlatılıyor...');
  }

  void _showAresSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF020B14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      bottom: size.height * 0.05,
      left: size.width * 0.11,
      width: size.width * 0.78,
      height: size.height * 0.12,
      child: Row(
        children: [
          // Sol Buton: Dosya / Kod Yükle
          Expanded(
            child: GestureDetector(
              onTap: () => _pickAndLoadFile(context),
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.file_upload_outlined, color: Color(0xFF00E5FF), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Dosya / Kod Yükle',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Sağ Buton: APK Oluştur & Derle
          Expanded(
            child: GestureDetector(
              onTap: () => _startBuildProcess(context),
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.build_outlined, color: Color(0xFF00E5FF), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'APK Oluştur & Derle',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
