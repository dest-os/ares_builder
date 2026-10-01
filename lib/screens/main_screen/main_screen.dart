import 'dart:convert';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/app_assets.dart';
import '../../core/app_colors.dart';
import '../../dialogs/history_dialog/history_dialog.dart';
import '../../dialogs/settings_dialog/settings_dialog.dart';
import '../../models/build_log_model.dart';
import '../../services/apk_saver.dart';
import '../../services/github_service.dart';
import '../../services/project_service.dart';
import '../../services/storage_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final StorageService _storage = StorageService();
  final GithubService _github = GithubService();
  final TextEditingController _codeCtrl = TextEditingController();
  final List<BuildLog> _logs = [];

  Map<String, List<int>>? _project;
  String? _currentPath;
  String _originalText = '';

  double _uploadProgress = 0;
  double _buildProgress = 0;
  bool _busy = false;
  bool _apiReady = false;
  String _lastErrorLog = '';

  @override
  void initState() {
    super.initState();
    _log(LogLevel.info, 'Ares Builder hazır. Önce proje ZIP dosyasını yükle.');
    _refreshApiReady();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _log(LogLevel level, String message) {
    if (!mounted) return;
    setState(() {
      _logs.add(BuildLog(level, message));
      if (_logs.length > 300) _logs.removeAt(0);
    });
  }

  Future<void> _refreshApiReady() async {
    final keys = await _storage.getApiKeys();
    final chain = await _storage.getChain();
    final ready = chain.any((e) =>
        e.enabled && (keys[e.providerId] ?? '').trim().isNotEmpty);
    if (mounted) setState(() => _apiReady = ready);
  }

  // ------------------------------------------------------------------
  // Dosya / ZIP yükleme
  // ------------------------------------------------------------------
  Future<void> _pickFile() async {
    if (_busy) return;
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.any, withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _log(LogLevel.error, 'Dosya okunamadı: ${file.name}');
        return;
      }
      if (file.name.toLowerCase().endsWith('.zip')) {
        _loadZip(file.name, bytes);
      } else {
        _loadSingleFile(file.name, bytes);
      }
    } catch (e) {
      _log(LogLevel.error, 'Dosya seçilirken hata: $e');
    }
  }

  void _loadZip(String name, List<int> bytes) {
    try {
      final files = ProjectService.readZip(bytes);
      if (files.isEmpty) {
        _log(LogLevel.error, 'ZIP boş görünüyor: $name');
        return;
      }
      _project = files;
      _log(LogLevel.success, 'ZIP açıldı: $name (${files.length} dosya)');
      if (!files.containsKey('pubspec.yaml')) {
        _log(LogLevel.warning,
            'pubspec.yaml bulunamadı. Flutter projesi olmayabilir.');
      }
      if (!files.containsKey('.github/workflows/build_apk.yml')) {
        _log(LogLevel.info,
            'Derleme dosyası yok, yükleme sırasında otomatik eklenecek.');
      }
      String? pick;
      if (files.containsKey('lib/main.dart')) {
        pick = 'lib/main.dart';
      } else if (files.containsKey('pubspec.yaml')) {
        pick = 'pubspec.yaml';
      }
      if (pick != null) {
        final text = ProjectService.tryDecode(files[pick]!);
        if (text != null) _showInEditor(pick, text);
      }
    } catch (e) {
      _log(LogLevel.error, 'ZIP açılamadı: $e');
    }
  }

  void _loadSingleFile(String name, List<int> bytes) {
    final text = ProjectService.tryDecode(bytes);
    if (text == null) {
      _log(LogLevel.error,
          'Bu dosya metin değil. Proje için ZIP, düzenleme için metin dosyası seç.');
      return;
    }
    if (_project == null) {
      setState(() {
        _codeCtrl.text = text;
        _originalText = text;
        _currentPath = null;
      });
      _log(LogLevel.warning,
          'Dosya editöre alındı ama proje yok. Derlemek için önce ZIP yükle.');
      return;
    }
    String? path;
    for (final k in _project!.keys) {
      if (k.split('/').last == name) {
        path = k;
        break;
      }
    }
    path ??= name.endsWith('.dart') ? 'lib/$name' : name;
    _project![path] = bytes;
    _showInEditor(path, text);
    _log(LogLevel.success, 'Dosya projede güncellendi: $path');
  }

  void _showInEditor(String path, String text) {
    setState(() {
      _currentPath = path;
      _codeCtrl.text = text;
      _originalText = text;
    });
    _log(LogLevel.info, 'Editörde: $path');
  }

  void _applyEditorEdits() {
    if (_project == null || _currentPath == null) return;
    if (_codeCtrl.text != _originalText) {
      _project![_currentPath!] = utf8.encode(_codeCtrl.text);
      _originalText = _codeCtrl.text;
      _log(LogLevel.info, 'Editördeki değişiklik projeye uygulandı: $_currentPath');
    }
  }

  // ------------------------------------------------------------------
  // GitHub'a yükle, derle, APK'yı indir
  // ------------------------------------------------------------------
  void _setProgress({double? upload, double? build}) {
    if (!mounted) return;
    setState(() {
      if (upload != null) _uploadProgress = upload;
      if (build != null) _buildProgress = build;
    });
  }

  Future<void> _buildApk() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _uploadProgress = 0;
      _buildProgress = 0;
    });
    try {
      final config = await _storage.getGithubConfig();
      if (config == null || !config.isValid) {
        _log(LogLevel.error,
            'GitHub bilgileri eksik. Sağ üstteki ayarlardan gir.');
        return;
      }
      if (_project == null || _project!.isEmpty) {
        _log(LogLevel.error, 'Önce proje ZIP dosyasını yükle.');
        return;
      }
      _applyEditorEdits();
      final files = Map<String, List<int>>.from(_project!);
      if (ProjectService.ensureWorkflow(files)) {
        _log(LogLevel.info, 'Derleme dosyası (build_apk.yml) eklendi.');
      }

      _log(LogLevel.build,
          'GitHub\'a yükleniyor (${files.length} dosya)...');
      await _github.pushProject(
        config: config,
        files: files,
        message: 'Ares Builder: proje güncellendi [skip ci]',
        onProgress: (p) => _setProgress(upload: p),
        onLog: (m) => _log(LogLevel.info, m),
      );
      _setProgress(upload: 1.0);
      _log(LogLevel.success, 'Kod GitHub\'a yüklendi.');

      final before = await _github.listRunIds(config);
      await _github.triggerBuild(config);
      _log(LogLevel.build, 'Derleme başlatıldı, GitHub hazırlanıyor...');
      final run = await _github.waitForNewRun(config, before);
      final runId = run['id'] as int;
      _log(LogLevel.build, 'Derleme #$runId çalışıyor...');

      final started = DateTime.now();
      final seen = <String>{};
      var cur = run;
      List<Map<String, dynamic>> jobs = [];
      while (true) {
        await Future.delayed(const Duration(seconds: 8));
        if (!mounted) return;
        if (DateTime.now().difference(started) > const Duration(minutes: 40)) {
          _log(LogLevel.warning,
              'Derleme 40 dakikayı aştı, takip durduruldu. GitHub Actions sekmesine bak.');
          return;
        }
        cur = await _github.getRun(config, runId);
        jobs = await _github.getJobs(config, runId);
        var total = 0;
        var done = 0;
        for (final j in jobs) {
          final steps = (j['steps'] as List?) ?? [];
          for (final s in steps) {
            total++;
            if (s['status'] == 'completed') {
              done++;
              final name = s['name'].toString();
              if (seen.add(name)) {
                final ok = s['conclusion'] == 'success' ||
                    s['conclusion'] == 'skipped';
                _log(ok ? LogLevel.info : LogLevel.error,
                    ok ? 'Adım tamam: $name' : 'Adım başarısız: $name');
              }
            }
          }
        }
        if (total > 0) _setProgress(build: done / total * 0.95);
        if (cur['status'] == 'completed') break;
      }

      final conclusion = cur['conclusion'];
      if (conclusion == 'success') {
        _log(LogLevel.success, 'Derleme tamamlandı. APK indiriliyor...');
        final arts = await _github.listArtifacts(config, runId: runId);
        if (arts.isEmpty) {
          _log(LogLevel.error, 'Derleme bitti ama APK paketi bulunamadı.');
          return;
        }
        final path = await downloadAndSaveApk(
            _github, config, arts.first['id'] as int);
        _setProgress(build: 1.0);
        if (path == null) {
          _log(LogLevel.warning,
              'Kaydetme iptal edildi. "Geçmiş APK\'lar / İndir" ile tekrar indirebilirsin.');
        } else {
          _log(LogLevel.success, 'APK kaydedildi: $path');
        }
      } else {
        _log(LogLevel.error, 'Derleme başarısız: $conclusion');
        final raw = await _github.getFailedJobLog(config, jobs);
        if (raw.isNotEmpty) {
          _lastErrorLog = raw;
          final stamp = RegExp(r'^\d{4}-\d{2}-\d{2}T[\d:.]+Z\s?');
          final lines = raw
              .split('\n')
              .map((l) => l.replaceFirst(stamp, '').trimRight())
              .where((l) => l.trim().isNotEmpty)
              .toList();
          final tail = lines.sublist(math.max(0, lines.length - 20));
          for (final l in tail) {
            _log(LogLevel.error, l);
          }
        }
      }
    } on GithubException catch (e) {
      _log(LogLevel.error, e.message);
    } catch (e) {
      _log(LogLevel.error, 'Beklenmeyen hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------------
  // Pencereler
  // ------------------------------------------------------------------
  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsDialog()),
    );
    await _refreshApiReady();
  }

  Future<void> _openHistory() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const HistoryDialog(),
    );
  }

  // ------------------------------------------------------------------
  // Arayüz
  // ------------------------------------------------------------------
  Widget _hit(VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.cyanNeon.withOpacity(0.25),
        highlightColor: AppColors.cyanNeon.withOpacity(0.10),
        onTap: onTap,
      ),
    );
  }

  Widget _bar(double value) {
    final v = value.clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: v,
          heightFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cyanNeon.withOpacity(0.85),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                    color: AppColors.cyanNeon.withOpacity(0.6), blurRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Center(
        child: AspectRatio(
          aspectRatio: 1536 / 1024,
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            final s = w / 1536;

            Widget at(double l, double t, double ww, double hh, Widget child) {
              return Positioned(
                left: l * w,
                top: t * h,
                width: ww * w,
                height: hh * h,
                child: child,
              );
            }

            final codeFont = math.max(11.0, 17 * s);
            final logFont = math.max(10.0, 15 * s);

            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    AppAssets.mainScreenBg,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.darkBg,
                      alignment: Alignment.center,
                      child: const Text('Arka plan görseli bulunamadı',
                          style: TextStyle(color: AppColors.redNeon)),
                    ),
                  ),
                ),

                // Kod yazma alanı
                at(
                  0.208,
                  0.451,
                  0.56,
                  0.125,
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: TextField(
                      controller: _codeCtrl,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      autocorrect: false,
                      enableSuggestions: false,
                      cursorColor: AppColors.cyanNeon,
                      style: TextStyle(
                        color: AppColors.cyanNeon,
                        fontFamily: 'monospace',
                        fontSize: codeFont,
                        height: 1.3,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText:
                            'Proje ZIP dosyasını yükle veya kodunu buraya yaz / yapıştır...',
                        hintStyle: TextStyle(
                          color: AppColors.textGray,
                          fontFamily: 'monospace',
                          fontSize: codeFont,
                        ),
                      ),
                    ),
                  ),
                ),

                // Canlı log paneli
                at(
                  0.196,
                  0.656,
                  0.585,
                  0.125,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[_logs.length - 1 - index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: logFont,
                                color: Colors.white70,
                              ),
                              children: [
                                TextSpan(text: '[${log.timeText}] '),
                                TextSpan(
                                  text: '[${log.tag}] ',
                                  style: TextStyle(
                                      color: log.color,
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: log.message),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // İlerleme çubukları (sol: yükleme, sağ: derleme)
                at(0.184, 0.283, 0.085, 0.041, _bar(_uploadProgress)),
                at(0.732, 0.283, 0.085, 0.041, _bar(_buildProgress)),

                // API durumu
                at(
                  0.791,
                  0.127,
                  0.072,
                  0.025,
                  Row(
                    children: [
                      Container(
                        width: 8 * math.max(s, 0.8),
                        height: 8 * math.max(s, 0.8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _apiReady
                              ? AppColors.greenNeon
                              : AppColors.redNeon,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _apiReady ? 'API Ready' : 'API Yok',
                            style: TextStyle(
                              color: _apiReady
                                  ? AppColors.greenNeon
                                  : AppColors.redNeon,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Dokunma alanları
                at(0.869, 0.015, 0.115, 0.17, _hit(_openSettings)),
                at(0.795, 0.371, 0.18, 0.057, _hit(_openHistory)),
                at(0.070, 0.210, 0.110, 0.170, _hit(_busy ? null : _pickFile)),
                at(0.062, 0.832, 0.426, 0.096, _hit(_busy ? null : _pickFile)),
                at(0.508, 0.832, 0.436, 0.096, _hit(_busy ? null : _buildApk)),

                // Derleme sürerken buton üstü bilgi
                if (_busy)
                  at(
                    0.508,
                    0.832,
                    0.436,
                    0.096,
                    IgnorePointer(
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Derleniyor... lütfen bekle',
                          style: TextStyle(
                            color: AppColors.yellowNeon,
                            fontWeight: FontWeight.bold,
                            fontSize: math.max(12.0, 20 * s),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
