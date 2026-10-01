import 'package:http/http.dart' as http;
import '../models/api_config_model.dart';

/// API anahtarının geçerli olup olmadığını, servisin model listesi
/// adresine küçük bir istek atarak kontrol eder (ücret doğurmaz).
class ApiTestService {
  Future<KeyStatus> test(ProviderInfo p, String key) async {
    final k = key.trim();
    if (k.isEmpty) return KeyStatus.none;
    try {
      Uri url;
      Map<String, String> headers;
      switch (p.kind) {
        case 'gemini':
          url = Uri.parse('${p.baseUrl}/models');
          headers = {'x-goog-api-key': k};
          break;
        case 'anthropic':
          url = Uri.parse('${p.baseUrl}/models');
          headers = {'x-api-key': k, 'anthropic-version': '2023-06-01'};
          break;
        case 'openrouter':
          url = Uri.parse('${p.baseUrl}/auth/key');
          headers = {'Authorization': 'Bearer $k'};
          break;
        default:
          url = Uri.parse('${p.baseUrl}/models');
          headers = {'Authorization': 'Bearer $k'};
      }
      final res =
          await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return KeyStatus.ok;
      if (res.statusCode == 401 || res.statusCode == 403 || res.statusCode == 400) {
        return KeyStatus.invalid;
      }
      if (res.statusCode == 429) return KeyStatus.limited;
      return KeyStatus.error;
    } catch (_) {
      return KeyStatus.error;
    }
  }

  static String describe(KeyStatus s) {
    switch (s) {
      case KeyStatus.none:
        return 'anahtar girilmemiş';
      case KeyStatus.untested:
        return 'henüz test edilmedi';
      case KeyStatus.ok:
        return 'çalışıyor';
      case KeyStatus.invalid:
        return 'anahtar geçersiz';
      case KeyStatus.limited:
        return 'kullanım limiti dolu (anahtar geçerli)';
      case KeyStatus.error:
        return 'bağlantı kurulamadı';
    }
  }
}
