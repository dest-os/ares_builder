import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import '../models/github_config_model.dart';
import 'github_service.dart';

/// Artifact'i indirir, içindeki APK'yı çıkarır ve kullanıcıya kaydettirir.
/// Kaydedilen yolu döndürür; kullanıcı vazgeçerse null.
Future<String?> downloadAndSaveApk(
    GithubService github, GithubConfig config, int artifactId) async {
  final zipBytes = await github.downloadArtifact(config, artifactId);
  final archive = ZipDecoder().decodeBytes(zipBytes);
  ArchiveFile? apk;
  for (final f in archive) {
    if (f.isFile && f.name.toLowerCase().endsWith('.apk')) {
      apk = f;
      break;
    }
  }
  if (apk == null) {
    throw GithubException('İndirilen pakette APK bulunamadı.');
  }
  final bytes = Uint8List.fromList(apk.content as List<int>);
  String two(int n) => n.toString().padLeft(2, '0');
  final now = DateTime.now();
  final name =
      'ares_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}.apk';
  return FilePicker.platform.saveFile(
    dialogTitle: 'APK dosyasını kaydet',
    fileName: name,
    bytes: bytes,
  );
}
