import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/github_config_model.dart';
import '../../services/apk_saver.dart';
import '../../services/github_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/neon_button.dart';

class HistoryDialog extends StatefulWidget {
  const HistoryDialog({super.key});

  @override
  State<HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<HistoryDialog> {
  final StorageService _storage = StorageService();
  final GithubService _github = GithubService();

  GithubConfig? _config;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _msg = '';
  Color _msgColor = AppColors.textGray;
  int? _downloadingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final config = await _storage.getGithubConfig();
      if (config == null || !config.isValid) {
        _finish('GitHub bilgileri eksik. Önce ayarlardan gir.',
            AppColors.yellowNeon, []);
        return;
      }
      _config = config;
      final items = await _github.listArtifacts(config);
      _finish(items.isEmpty ? 'Henüz indirilecek APK yok.' : '', AppColors.textGray,
          items);
    } on GithubException catch (e) {
      _finish(e.message, AppColors.redNeon, []);
    } catch (_) {
      _finish('Liste alınamadı. İnterneti kontrol et.', AppColors.redNeon, []);
    }
  }

  void _finish(String msg, Color color, List<Map<String, dynamic>> items) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _msg = msg;
      _msgColor = color;
      _items = items;
    });
  }

  String _dateText(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (d == null) return '-';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  String _sizeText(dynamic raw) {
    final n = raw is num ? raw : 0;
    return '${(n / 1048576).toStringAsFixed(1)} MB';
  }

  Future<void> _download(Map<String, dynamic> item) async {
    final config = _config;
    final id = item['id'];
    if (config == null || id is! int) return;
    setState(() {
      _downloadingId = id;
      _msg = 'İndiriliyor...';
      _msgColor = AppColors.cyanNeon;
    });
    try {
      final path = await downloadAndSaveApk(_github, config, id);
      if (!mounted) return;
      setState(() {
        _downloadingId = null;
        if (path == null) {
          _msg = 'Kaydetme iptal edildi.';
          _msgColor = AppColors.textGray;
        } else {
          _msg = '✓ APK kaydedildi: $path';
          _msgColor = AppColors.greenNeon;
        }
      });
    } on GithubException catch (e) {
      if (!mounted) return;
      setState(() {
        _downloadingId = null;
        _msg = e.message;
        _msgColor = AppColors.redNeon;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloadingId = null;
        _msg = 'İndirme hatası: $e';
        _msgColor = AppColors.redNeon;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
          horizontal: size.width * 0.12, vertical: size.height * 0.08),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppColors.cyanNeon.withOpacity(0.7), width: 1.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.download, color: AppColors.cyanNeon),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Geçmiş APK\'lar',
                        style: TextStyle(
                            color: AppColors.cyanNeon,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.cyanNeon),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (_msg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_msg,
                      style: TextStyle(
                          color: _msgColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.cyanNeon))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final it = _items[i];
                        final id = it['id'];
                        final busy = _downloadingId != null && _downloadingId == id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(it['name']?.toString() ?? 'APK',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${_dateText(it['created_at'])}  •  ${_sizeText(it['size_in_bytes'])}',
                                        style: const TextStyle(
                                            color: AppColors.textGray,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              NeonButton(
                                label: busy ? 'İndiriliyor...' : 'İndir',
                                icon: Icons.download,
                                onTap: _downloadingId != null
                                    ? null
                                    : () => _download(it),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
