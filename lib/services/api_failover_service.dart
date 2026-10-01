import '../models/api_config_model.dart';

/// Öncelik zincirinden sıradaki kullanılabilir servisi seçer.
/// (Yapay zeka ile otomatik hata düzeltme aşamasında kullanılacak.)
class ApiFailoverService {
  List<ChainEntry> _chain = [];
  Map<String, String> _keys = {};

  void setup(List<ChainEntry> chain, Map<String, String> keys) {
    _chain = chain;
    _keys = keys;
  }

  /// Anahtarı olan ve açık olan ilk kaydı verir. [skip] içindeki uid'ler atlanır.
  ChainEntry? next({Set<String> skip = const <String>{}}) {
    for (final e in _chain) {
      if (!e.enabled) continue;
      if (skip.contains(e.uid)) continue;
      final key = _keys[e.providerId];
      if (key != null && key.trim().isNotEmpty) return e;
    }
    return null;
  }

  String? keyFor(ChainEntry e) => _keys[e.providerId];
}
