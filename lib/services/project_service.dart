import 'dart:convert';
import 'package:archive/archive.dart';
import '../core/default_workflow.dart';

class ProjectService {
  /// ZIP'i açar; üst klasörü atar, gereksiz/tehlikeli dosyaları eler.
  static Map<String, List<int>> readZip(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final raw = <String, List<int>>{};
    for (final f in archive) {
      if (!f.isFile) continue;
      final name = f.name.replaceAll('\\', '/');
      raw[name] = f.content as List<int>;
    }

    // pubspec.yaml'ın bulunduğu klasörü proje kökü say.
    var prefix = '';
    final pubspecs = raw.keys
        .where((k) => k == 'pubspec.yaml' || k.endsWith('/pubspec.yaml'))
        .toList()
      ..sort((a, b) => a.length.compareTo(b.length));
    if (pubspecs.isNotEmpty) {
      final p = pubspecs.first;
      prefix = p.substring(0, p.length - 'pubspec.yaml'.length);
    }

    final out = <String, List<int>>{};
    raw.forEach((key, value) {
      if (!key.startsWith(prefix)) return;
      final rel = key.substring(prefix.length);
      if (rel.isEmpty || _skip(rel)) return;
      out[rel] = value;
    });
    return out;
  }

  static bool _skip(String path) {
    if (path.startsWith('/') || path.contains('..')) return true;
    final lower = path.toLowerCase();
    if (lower.startsWith('__macosx/')) return true;
    if (lower.endsWith('.ds_store')) return true;
    if (lower.startsWith('.git/')) return true;
    if (lower.startsWith('.dart_tool/')) return true;
    if (lower.startsWith('build/')) return true;
    if (lower.startsWith('.idea/')) return true;
    if (lower.startsWith('android/.gradle/')) return true;
    if (lower == 'android/local.properties') return true;
    return false;
  }

  /// Derleme dosyası yoksa ekler. Eklediyse true döner.
  static bool ensureWorkflow(Map<String, List<int>> files) {
    if (files.containsKey(kDefaultWorkflowPath)) return false;
    files[kDefaultWorkflowPath] = utf8.encode(kDefaultWorkflow);
    return true;
  }

  /// Metin dosyasıysa içeriği döndürür, değilse null.
  static String? tryDecode(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } catch (_) {
      return null;
    }
  }
}
