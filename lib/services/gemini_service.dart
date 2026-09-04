import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;

  GeminiService({required this.apiKey});

  Future<String?> fixFlutterCode(String errorCode, String currentCode) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final prompt = '''
Sen bir uzman Flutter geliştiricisisin. 
Aşağıdaki Flutter derleme hatasını incele ve koddaki hatayı tamamen düzelt.
Sadece düzeltilmiş Dart kodunu döndür, başka açıklama ekleme.

HATA LOGU:
$errorCode

MEVCUT KOD:
$currentCode
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String text = data['candidates'][0]['content']['parts'][0]['text'];
        // Markdown kod bloklarını temizle
        return text.replaceAll('```dart', '').replaceAll('```', '').trim();
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
