import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/github_config_model.dart';

class GithubException implements Exception {
  final String message;
  GithubException(this.message);

  @override
  String toString() => message;
}

class GithubService {
  static const String _api = 'https://api.github.com';
  final http.Client _client = http.Client();

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'Content-Type': 'application/json',
      };

  Uri _repoUri(GithubConfig c, String path, [Map<String, String>? query]) {
    final base =
        '$_api/repos/${c.username.trim()}/${c.repository.trim()}$path';
    final uri = Uri.parse(base);
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  String _errorMessage(http.Response r) {
    try {
      final data = jsonDecode(r.body);
      if (data is Map && data['message'] != null) {
        return '${data['message']} (${r.statusCode})';
      }
    } catch (_) {}
    final body = r.body.length > 120 ? r.body.substring(0, 120) : r.body;
    return 'HTTP ${r.statusCode} $body';
  }

  Map<String, dynamic> _json(http.Response r) {
    final data = jsonDecode(r.body);
    if (data is Map) return Map<String, dynamic>.from(data);
    throw GithubException('GitHub beklenmeyen bir cevap verdi.');
  }

  /// Yönlendirme (302) veren adreslerde, yetki başlığını yönlendirilen
  /// adrese göndermeden cevabı alır. (Artifact ve log indirme için)
  Future<http.Response> _getFollow(Uri url, String token) async {
    final req = http.Request('GET', url);
    req.followRedirects = false;
    req.headers.addAll(_headers(token));
    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 301 ||
        res.statusCode == 302 ||
        res.statusCode == 303 ||
        res.statusCode == 307 ||
        res.statusCode == 308) {
      final loc = res.headers['location'];
      if (loc == null || loc.isEmpty) {
        throw GithubException('İndirme adresi alınamadı.');
      }
      return _client.get(Uri.parse(loc));
    }
    return res;
  }

  // ------------------------------------------------------------------
  // Bağlantı doğrulama
  // ------------------------------------------------------------------
  Future<String> validate(GithubConfig c) async {
    try {
      final r = await _client
          .get(_repoUri(c, ''), headers: _headers(c.token))
          .timeout(const Duration(seconds: 20));
      if (r.statusCode == 401) {
        return '✗ Token geçersiz veya süresi dolmuş.';
      }
      if (r.statusCode == 404) {
        return '✗ Depo bulunamadı (kullanıcı/depo adı yanlış ya da token bu depoya yetkili değil).';
      }
      if (r.statusCode != 200) {
        return '✗ GitHub hatası: ${_errorMessage(r)}';
      }
      final data = _json(r);
      final perms = data['permissions'];
      final canPush = perms is Map && perms['push'] == true;
      if (!canPush) {
        return '✗ Depoya yazma yetkisi yok. Token izinlerini kontrol et.';
      }
      final b = await _client
          .get(_repoUri(c, '/branches/${c.branch.trim()}'),
              headers: _headers(c.token))
          .timeout(const Duration(seconds: 20));
      if (b.statusCode == 404) {
        return '✓ Bağlantı tamam. "${c.branch}" branch\'i henüz yok (depo boşsa ilk yüklemede oluşur).';
      }
      return '✓ Bağlantı başarılı, yazma yetkisi var.';
    } catch (e) {
      return '✗ Bağlantı kurulamadı. İnterneti kontrol et.';
    }
  }

  // ------------------------------------------------------------------
  // Projeyi tek commit ile yükleme
  // ------------------------------------------------------------------
  Future<void> pushProject({
    required GithubConfig config,
    required Map<String, List<int>> files,
    required String message,
    void Function(double)? onProgress,
    void Function(String)? onLog,
  }) async {
    final token = config.token;
    final branch = config.branch.trim();

    Future<http.Response> getRef() => _client.get(
        _repoUri(config, '/git/ref/heads/$branch'),
        headers: _headers(token));

    var ref = await getRef();
    if (ref.statusCode == 404 || ref.statusCode == 409) {
      onLog?.call('Depo boş veya branch yok, ilk dosya oluşturuluyor...');
      final init = await _client.put(
        _repoUri(config, '/contents/.ares_init'),
        headers: _headers(token),
        body: jsonEncode({
          'message': 'Ares Builder: ilk kurulum [skip ci]',
          'content': base64Encode(utf8.encode('ares')),
          'branch': branch,
        }),
      );
      if (init.statusCode != 200 && init.statusCode != 201) {
        throw GithubException(
            'Branch "$branch" bulunamadı ve oluşturulamadı: ${_errorMessage(init)}');
      }
      ref = await getRef();
    }
    if (ref.statusCode == 401) {
      throw GithubException('Token geçersiz. Ayarlardan yeniden gir.');
    }
    if (ref.statusCode != 200) {
      throw GithubException('Branch okunamadı: ${_errorMessage(ref)}');
    }

    final headSha = _json(ref)['object']['sha'].toString();
    final commitRes = await _client.get(
        _repoUri(config, '/git/commits/$headSha'),
        headers: _headers(token));
    if (commitRes.statusCode != 200) {
      throw GithubException('Commit okunamadı: ${_errorMessage(commitRes)}');
    }
    final baseTree = _json(commitRes)['tree']['sha'].toString();

    final paths = files.keys.toList();
    final entries = <Map<String, dynamic>>[];
    var done = 0;
    for (var i = 0; i < paths.length; i += 4) {
      final chunk = paths.sublist(i, math.min(i + 4, paths.length));
      final shas = await Future.wait(
          chunk.map((p) => _createBlob(config, files[p]!)));
      for (var j = 0; j < chunk.length; j++) {
        entries.add({
          'path': chunk[j],
          'mode': chunk[j].endsWith('gradlew') ? '100755' : '100644',
          'type': 'blob',
          'sha': shas[j],
        });
      }
      done += chunk.length;
      onProgress?.call(done / paths.length * 0.9);
    }

    final treeRes = await _client.post(
      _repoUri(config, '/git/trees'),
      headers: _headers(token),
      body: jsonEncode({'base_tree': baseTree, 'tree': entries}),
    );
    if (treeRes.statusCode != 201) {
      throw GithubException(
          'Dosya ağacı oluşturulamadı: ${_errorMessage(treeRes)}\n'
          'İpucu: Token\'da "Contents" ve "Workflows" yazma izni olmalı.');
    }
    final treeSha = _json(treeRes)['sha'].toString();

    final newCommit = await _client.post(
      _repoUri(config, '/git/commits'),
      headers: _headers(token),
      body: jsonEncode({
        'message': message,
        'tree': treeSha,
        'parents': [headSha],
      }),
    );
    if (newCommit.statusCode != 201) {
      throw GithubException('Commit oluşturulamadı: ${_errorMessage(newCommit)}');
    }
    final newSha = _json(newCommit)['sha'].toString();

    final upd = await _client.patch(
      _repoUri(config, '/git/refs/heads/$branch'),
      headers: _headers(token),
      body: jsonEncode({'sha': newSha, 'force': false}),
    );
    if (upd.statusCode != 200) {
      throw GithubException('Branch güncellenemedi: ${_errorMessage(upd)}');
    }
    onProgress?.call(1.0);
  }

  Future<String> _createBlob(GithubConfig c, List<int> bytes) async {
    String lastError = '';
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final r = await _client.post(
          _repoUri(c, '/git/blobs'),
          headers: _headers(c.token),
          body: jsonEncode({'content': base64Encode(bytes), 'encoding': 'base64'}),
        );
        if (r.statusCode == 201) return _json(r)['sha'].toString();
        lastError = _errorMessage(r);
      } catch (e) {
        lastError = 'bağlantı hatası';
      }
      await Future.delayed(Duration(seconds: 1 + attempt));
    }
    throw GithubException('Dosya yüklenemedi: $lastError');
  }

  // ------------------------------------------------------------------
  // Derleme (GitHub Actions)
  // ------------------------------------------------------------------
  Future<Set<int>> listRunIds(GithubConfig c) async {
    final r = await _client.get(
        _repoUri(c, '/actions/runs', {'per_page': '20'}),
        headers: _headers(c.token));
    if (r.statusCode != 200) return <int>{};
    final runs = _json(r)['workflow_runs'];
    final ids = <int>{};
    if (runs is List) {
      for (final run in runs) {
        if (run is Map && run['id'] is int) ids.add(run['id'] as int);
      }
    }
    return ids;
  }

  Future<void> triggerBuild(GithubConfig c) async {
    final r = await _client.post(
      _repoUri(c, '/actions/workflows/build_apk.yml/dispatches'),
      headers: _headers(c.token),
      body: jsonEncode({'ref': c.branch.trim()}),
    );
    if (r.statusCode != 204) {
      throw GithubException(
          'Derleme başlatılamadı: ${_errorMessage(r)}\n'
          'İpucu: Token\'da "Actions" yazma izni olmalı.');
    }
  }

  /// Tetiklemeden sonra oluşan yeni derleme kaydını bulur.
  Future<Map<String, dynamic>> waitForNewRun(
      GithubConfig c, Set<int> before) async {
    for (var i = 0; i < 30; i++) {
      await Future.delayed(const Duration(seconds: 4));
      final r = await _client.get(
          _repoUri(c, '/actions/runs', {'per_page': '20'}),
          headers: _headers(c.token));
      if (r.statusCode != 200) continue;
      final runs = _json(r)['workflow_runs'];
      if (runs is List) {
        for (final run in runs) {
          if (run is Map &&
              run['id'] is int &&
              !before.contains(run['id'] as int) &&
              run['event'] == 'workflow_dispatch') {
            return Map<String, dynamic>.from(run);
          }
        }
      }
    }
    throw GithubException(
        'Derleme kaydı bulunamadı. Depodaki "Actions" sekmesini kontrol et.');
  }

  Future<Map<String, dynamic>> getRun(GithubConfig c, int runId) async {
    final r = await _client.get(_repoUri(c, '/actions/runs/$runId'),
        headers: _headers(c.token));
    if (r.statusCode != 200) {
      throw GithubException('Derleme durumu okunamadı: ${_errorMessage(r)}');
    }
    return _json(r);
  }

  Future<List<Map<String, dynamic>>> getJobs(GithubConfig c, int runId) async {
    final r = await _client.get(_repoUri(c, '/actions/runs/$runId/jobs'),
        headers: _headers(c.token));
    if (r.statusCode != 200) return [];
    final jobs = _json(r)['jobs'];
    final out = <Map<String, dynamic>>[];
    if (jobs is List) {
      for (final j in jobs) {
        if (j is Map) out.add(Map<String, dynamic>.from(j));
      }
    }
    return out;
  }

  /// Başarısız olan işin log metnini getirir.
  Future<String> getFailedJobLog(
      GithubConfig c, List<Map<String, dynamic>> jobs) async {
    for (final j in jobs) {
      if (j['conclusion'] == 'failure' && j['id'] is int) {
        final r = await _getFollow(
            _repoUri(c, '/actions/jobs/${j['id']}/logs'), c.token);
        if (r.statusCode == 200) return r.body;
      }
    }
    return '';
  }

  // ------------------------------------------------------------------
  // Artifact (APK) işlemleri
  // ------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> listArtifacts(GithubConfig c,
      {int? runId}) async {
    final path = runId == null
        ? '/actions/artifacts'
        : '/actions/runs/$runId/artifacts';
    final r = await _client.get(_repoUri(c, path, {'per_page': '30'}),
        headers: _headers(c.token));
    if (r.statusCode != 200) {
      throw GithubException('APK listesi alınamadı: ${_errorMessage(r)}');
    }
    final list = _json(r)['artifacts'];
    final out = <Map<String, dynamic>>[];
    if (list is List) {
      for (final a in list) {
        if (a is Map && a['expired'] != true) {
          out.add(Map<String, dynamic>.from(a));
        }
      }
    }
    return out;
  }

  Future<Uint8List> downloadArtifact(GithubConfig c, int artifactId) async {
    final r = await _getFollow(
        _repoUri(c, '/actions/artifacts/$artifactId/zip'), c.token);
    if (r.statusCode != 200) {
      throw GithubException('APK indirilemedi: ${_errorMessage(r)}');
    }
    return r.bodyBytes;
  }
}
