import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubService {
  final String token;
  final String owner;
  final String repo;

  GitHubService({
    required this.token,
    required this.owner,
    required this.repo,
  });

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        'User-Agent': 'AresBuilder-App',
      };

  /// Deponun boş olup olmadığını kontrol eder ve gerekiyorsa varsayılan dalı başlatır.
  Future<void> ensureRepoInitialized() async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/branches');
    final response = await http.get(url, headers: _headers);

    // Depo boşsa (404 veya boş liste dönerse) otomatik bir README.md göndererek depoyu başlat
    if (response.statusCode == 404 || (response.statusCode == 200 && jsonDecode(response.body).isEmpty)) {
      await pushFile('README.md', '# $repo\nCreated automatically by Ares Builder.', 'Initial commit by Ares Builder');
    }
  }

  /// Dosya yükleme veya güncelleme işlemi
  Future<bool> pushFile(String path, String content, String message) async {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$cleanPath');

    String? sha;
    try {
      // 1. Önce dosyanın var olup olmadığını kontrol et
      final getResponse = await http.get(url, headers: _headers);
      if (getResponse.statusCode == 200) {
        final data = jsonDecode(getResponse.body);
        sha = data['sha'];
      }

      // 2. Base64 formatına çevir ve body hazırla
      final contentBase64 = base64Encode(utf8.encode(content));
      final body = {
        'message': message,
        'content': contentBase64,
        if (sha != null) 'sha': sha,
      };

      // 3. PUT isteği gönder
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('GitHub API Error [$cleanPath]: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('GitHubService Exception [$cleanPath]: $e');
      return false;
    }
  }

  /// Birden fazla dosyayı sırayla yükler
  Future<bool> pushMultipleFiles(Map<String, String> files, String commitMessage) async {
    await ensureRepoInitialized();

    bool allSuccess = true;
    for (var entry in files.entries) {
      final success = await pushFile(entry.key, entry.value, commitMessage);
      if (!success) {
        allSuccess = false;
        print('Dosya yüklenemedi: ${entry.key}');
      }
    }
    return allSuccess;
  }
}
