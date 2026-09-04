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

  Future<bool> pushFile(String path, String content, String message) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
    
    // Önce dosyanın var olup olmadığını ve SHA değerini kontrol et
    String? sha;
    final getResponse = await http.get(
      url,
      headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    if (getResponse.statusCode == 200) {
      final data = jsonDecode(getResponse.body);
      sha = data['sha'];
    }

    final body = {
      'message': message,
      'content': base64Encode(utf8.encode(content)),
      if (sha != null) 'sha': sha,
    };

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }
}
