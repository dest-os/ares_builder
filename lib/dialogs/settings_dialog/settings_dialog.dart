import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/app_assets.dart';
import '../../core/app_colors.dart';
import '../../models/api_config_model.dart';
import '../../models/github_config_model.dart';
import '../../services/api_test_service.dart';
import '../../services/github_service.dart';
import '../../services/permission_service.dart';
import '../../services/storage_service.dart';

/// Ayarlar ekranı: hazır tasarım görselinin üstüne canlı alanlar yerleştirilir.
/// Tüm koordinatlar görselin kendi piksel ölçüsündedir (1536 x 1024).
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  static const double _rowH = 42.3; // zincir satır yüksekliği
  static const double _keyStep = 39.4; // anahtar satır aralığı

  double _k = 0.8; // görsel -> ekran ölçeği (build içinde güncellenir)

  final StorageService _storage = StorageService();
  final PermissionService _perm = PermissionService();
  final ApiTestService _tester = ApiTestService();
  final GithubService _github = GithubService();

  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _tokenCtrl = TextEditingController();
  final TextEditingController _repoCtrl =
      TextEditingController(text: 'Ares-Builder/main');

  final Map<String, TextEditingController> _keyCtrls = {};
  final Map<String, bool> _showKey = {};
  final Map<String, KeyStatus> _status = {};
  final Set<String> _testing = {};

  List<ChainEntry> _chain = [];
  Map<String, String> _keys = {};
  bool _failover = true;
  bool _micOk = false;
  bool _notifOk = false;
  bool _loading = true;
  bool _showToken = false;
  String _msg = '';
  Color _msgColor = AppColors.textGray;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _saveAll();
    _userCtrl.dispose();
    _tokenCtrl.dispose();
    _repoCtrl.dispose();
    for (final c in _keyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final gh = await _storage.getGithubConfig();
    final keys = await _storage.getApiKeys();
    final chain = await _storage.getChain();
    final failover = await _storage.getFailover();
    final mic = await _perm.micGranted();
    final notif = await _perm.notificationGranted();
    if (!mounted) return;
    setState(() {
      if (gh != null) {
        _userCtrl.text = gh.username;
        _tokenCtrl.text = gh.token;
        _repoCtrl.text = '${gh.repository}/${gh.branch}';
      }
      _keys = Map<String, String>.from(keys);
      for (final p in Providers.all) {
        final v = _keys[p.id] ?? '';
        _keyCtrls[p.id] = TextEditingController(text: v);
        _showKey[p.id] = false;
        _status[p.id] = v.trim().isEmpty ? KeyStatus.none : KeyStatus.untested;
      }
      _chain = chain.take(StorageService.maxChain).toList();
      _failover = failover;
      _micOk = mic;
      _notifOk = notif;
      _loading = false;
    });
  }

  // ------------------------------------------------------------------
  // Kaydetme ve mesaj
  // ------------------------------------------------------------------
  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _saveAll);
  }

  Future<void> _saveAll() async {
    try {
      await _storage.saveApiKeys(_keys);
      await _storage.saveChain(_chain);
      await _storage.saveFailover(_failover);
    } catch (_) {}
  }

  void _setMsg(String text, {Color color = AppColors.textGray}) {
    if (!mounted) return;
    setState(() {
      _msg = text;
      _msgColor = color;
    });
  }

  // ------------------------------------------------------------------
  // GitHub
  // ------------------------------------------------------------------
  String _repoName() {
    final t = _repoCtrl.text.trim();
    final i = t.indexOf('/');
    return (i < 0 ? t : t.substring(0, i)).trim();
  }

  String _branchName() {
    final t = _repoCtrl.text.trim();
    final i = t.indexOf('/');
    final b = i < 0 ? '' : t.substring(i + 1).trim();
    return b.isEmpty ? 'main' : b;
  }

  Future<void> _saveAndVerifyGithub() async {
    final config = GithubConfig(
      username: _userCtrl.text.trim(),
      token: _tokenCtrl.text.trim(),
      repository: _repoName(),
      branch: _branchName(),
    );
    if (!config.isValid) {
      _setMsg('Kullanıcı adı, token ve "depo/branch" alanını doldur. Örnek: Ares-Builder/main',
          color: AppColors.yellowNeon);
      return;
    }
    await _storage.saveGithubConfig(config);
    _setMsg('Kaydedildi, bağlantı kontrol ediliyor...',
        color: AppColors.cyanNeon);
    final result = await _github.validate(config);
    _setMsg(result,
        color: result.startsWith('✓') ? AppColors.greenNeon : AppColors.redNeon);
  }

  // ------------------------------------------------------------------
  // API testleri
  // ------------------------------------------------------------------
  Color _statusColor(KeyStatus s) {
    switch (s) {
      case KeyStatus.ok:
        return AppColors.greenNeon;
      case KeyStatus.invalid:
        return AppColors.redNeon;
      case KeyStatus.limited:
      case KeyStatus.untested:
      case KeyStatus.error:
        return AppColors.yellowNeon;
      case KeyStatus.none:
        return Colors.white;
    }
  }

  Future<void> _testProvider(String id) async {
    final p = Providers.byId(id);
    final key = (_keys[id] ?? '').trim();
    if (key.isEmpty) {
      setState(() => _status[id] = KeyStatus.none);
      _setMsg('${p.name}: önce API anahtarını gir.',
          color: AppColors.yellowNeon);
      return;
    }
    if (_testing.contains(id)) return;
    setState(() => _testing.add(id));
    final r = await _tester.test(p, key);
    if (!mounted) return;
    setState(() {
      _testing.remove(id);
      _status[id] = r;
    });
    _setMsg('${p.name}: ${ApiTestService.describe(r)}', color: _statusColor(r));
  }

  Future<void> _testAll() async {
    final ids = Providers.all
        .where((p) => (_keys[p.id] ?? '').trim().isNotEmpty)
        .map((p) => p.id)
        .toList();
    if (ids.isEmpty) {
      _setMsg('Test edilecek API anahtarı yok.', color: AppColors.yellowNeon);
      return;
    }
    for (final id in ids) {
      if (!mounted) return;
      await _testProvider(id);
    }
    _setMsg('Tüm testler tamamlandı.', color: AppColors.cyanNeon);
  }

  // ------------------------------------------------------------------
  // Zincir ve anahtar işlemleri
  // ------------------------------------------------------------------
  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final e = _chain.removeAt(oldIndex);
      _chain.insert(newIndex, e);
    });
    _scheduleSave();
  }

  void _resetChain() {
    setState(() => _chain = StorageService.defaultChain());
    _scheduleSave();
    _setMsg('Sıra varsayılana döndü.', color: AppColors.cyanNeon);
  }

  Future<bool> _confirm(String text) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panelBg,
        content: Text(text, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Evet',
                  style: TextStyle(color: AppColors.redNeon))),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _addModelDialog() async {
    if (_chain.length >= StorageService.maxChain) {
      _setMsg('Zincir dolu (en fazla ${StorageService.maxChain} satır). Önce birini sil.',
          color: AppColors.yellowNeon);
      return;
    }
    var pid = Providers.all.first.id;
    final modelCtrl =
        TextEditingController(text: Providers.byId(pid).models.first);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.panelBg,
          title: const Text('API Modeli Ekle',
              style: TextStyle(color: AppColors.cyanNeon, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: pid,
                isExpanded: true,
                dropdownColor: AppColors.panelBg,
                style: const TextStyle(color: Colors.white),
                items: Providers.all
                    .map((p) =>
                        DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setD(() {
                    pid = v;
                    modelCtrl.text = Providers.byId(v).models.first;
                  });
                },
              ),
              TextField(
                controller: modelCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Model adı',
                  hintStyle: TextStyle(color: AppColors.textGray),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ekle')),
          ],
        ),
      ),
    );
    final model = modelCtrl.text.trim();
    if (ok == true && model.isNotEmpty && mounted) {
      setState(() => _chain.add(ChainEntry(providerId: pid, model: model)));
      _scheduleSave();
    }
  }

  Future<void> _addKeyDialog() async {
    var pid = Providers.all.first.id;
    final keyCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.panelBg,
          title: const Text('API Anahtarı Ekle',
              style: TextStyle(color: AppColors.cyanNeon, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: pid,
                isExpanded: true,
                dropdownColor: AppColors.panelBg,
                style: const TextStyle(color: Colors.white),
                items: Providers.all
                    .map((p) =>
                        DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setD(() => pid = v);
                },
              ),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'API anahtarını yapıştır',
                  hintStyle: TextStyle(color: AppColors.textGray),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ekle')),
          ],
        ),
      ),
    );
    final key = keyCtrl.text.trim();
    if (ok == true && key.isNotEmpty && mounted) {
      setState(() {
        _keys[pid] = key;
        _keyCtrls[pid]?.text = key;
        _status[pid] = KeyStatus.untested;
      });
      _scheduleSave();
    }
  }

  Future<void> _clearAllKeys() async {
    if (!await _confirm('Tüm API anahtarları silinsin mi?')) return;
    if (!mounted) return;
    setState(() {
      _keys.clear();
      for (final p in Providers.all) {
        _keyCtrls[p.id]?.text = '';
        _status[p.id] = KeyStatus.none;
      }
    });
    _scheduleSave();
    _setMsg('Tüm anahtarlar silindi.', color: AppColors.cyanNeon);
  }

  void _clearKey(String id) {
    setState(() {
      _keys.remove(id);
      _keyCtrls[id]?.text = '';
      _status[id] = KeyStatus.none;
    });
    _scheduleSave();
  }

  // ------------------------------------------------------------------
  // İzinler
  // ------------------------------------------------------------------
  Future<void> _askMic() async {
    if (_micOk) return;
    final ok = await _perm.requestMicrophone();
    if (mounted) setState(() => _micOk = ok);
  }

  Future<void> _askNotif() async {
    if (_notifOk) return;
    final ok = await _perm.requestNotification();
    if (mounted) setState(() => _notifOk = ok);
  }

  // ------------------------------------------------------------------
  // Yedekle / Yükle
  // ------------------------------------------------------------------
  Future<void> _backup() async {
    final withKeys = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panelBg,
        title: const Text('API anahtarları yedeğe eklensin mi?',
            style: TextStyle(color: AppColors.cyanNeon, fontSize: 16)),
        content: const Text(
          'Yedek dosyası düz metindir. Anahtarları eklersen dosyayı bulan herkes okuyabilir. '
          'GitHub token hiçbir zaman yedeğe eklenmez.\n\nÖnerilen: Hayır.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Evet (riskli)',
                  style: TextStyle(color: AppColors.redNeon))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hayır (güvenli)')),
        ],
      ),
    );
    if (withKeys == null) return;
    try {
      final data = <String, dynamic>{
        'app': 'ares_builder',
        'version': 1,
        'failover': _failover,
        'chain': _chain.map((e) => e.toJson()).toList(),
        'github': {
          'username': _userCtrl.text.trim(),
          'repository': _repoName(),
          'branch': _branchName(),
        },
        if (withKeys) 'keys': _keys,
      };
      final bytes = Uint8List.fromList(
          utf8.encode(const JsonEncoder.withIndent('  ').convert(data)));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Ayar yedeğini kaydet',
        fileName: 'ares_ayarlar.json',
        bytes: bytes,
      );
      _setMsg(path == null ? 'Yedekleme iptal edildi.' : '✓ Yedek kaydedildi.',
          color: path == null ? AppColors.textGray : AppColors.greenNeon);
    } catch (e) {
      _setMsg('Yedekleme hatası: $e', color: AppColors.redNeon);
    }
  }

  Future<void> _restore() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) {
        _setMsg('Dosya okunamadı.', color: AppColors.redNeon);
        return;
      }
      final data = jsonDecode(utf8.decode(bytes));
      if (data is! Map || data['app'] != 'ares_builder') {
        _setMsg('Bu dosya bir Ares Builder yedeği değil.',
            color: AppColors.redNeon);
        return;
      }
      setState(() {
        final chain = data['chain'];
        if (chain is List) {
          final list = <ChainEntry>[];
          for (final item in chain) {
            if (item is Map) {
              list.add(ChainEntry.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          if (list.isNotEmpty) {
            _chain = list.take(StorageService.maxChain).toList();
          }
        }
        if (data['failover'] is bool) _failover = data['failover'] as bool;
        final gh = data['github'];
        if (gh is Map) {
          final repo = (gh['repository'] ?? '').toString();
          final branch = (gh['branch'] ?? 'main').toString();
          if (_userCtrl.text.trim().isEmpty) {
            _userCtrl.text = (gh['username'] ?? '').toString();
          }
          if (repo.isNotEmpty) _repoCtrl.text = '$repo/$branch';
        }
        final keys = data['keys'];
        if (keys is Map) {
          keys.forEach((k, v) {
            final id = k.toString();
            final value = v.toString();
            if (_keyCtrls.containsKey(id) && value.trim().isNotEmpty) {
              _keys[id] = value.trim();
              _keyCtrls[id]!.text = value.trim();
              _status[id] = KeyStatus.untested;
            }
          });
        }
      });
      _scheduleSave();
      _setMsg('✓ Ayarlar yüklendi. GitHub token\'ını yeniden girmen gerekebilir.',
          color: AppColors.greenNeon);
    } catch (e) {
      _setMsg('Yükleme hatası: $e', color: AppColors.redNeon);
    }
  }

  // ------------------------------------------------------------------
  // Görünüm
  // ------------------------------------------------------------------
  Widget _hit(VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.cyanNeon.withOpacity(0.25),
        highlightColor: AppColors.cyanNeon.withOpacity(0.10),
        onTap: onTap,
      ),
    );
  }

  Widget _plainField({
    required TextEditingController controller,
    required String hint,
    required double fs,
    bool obscure = false,
    ValueChanged<String>? onChanged,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: onChanged,
        cursorColor: AppColors.cyanNeon,
        style: TextStyle(color: Colors.white, fontSize: fs),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 7 * _k),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textGray, fontSize: fs),
        ),
      ),
    );
  }

  Widget _chainRow(int i, double k) {
    final e = _chain[i];
    final p = Providers.byId(e.providerId);
    final st = _status[p.id] ?? KeyStatus.none;
    final fs = math.max(10.0, 15 * k);
    final models = List<String>.from(p.models);
    if (!models.contains(e.model)) models.add(e.model);

    return SizedBox(
      key: ValueKey(e.uid),
      height: _rowH * k,
      child: Stack(
        children: [
          // sürükleme tutacağı
          Positioned(
            left: 45 * k,
            top: 0,
            width: 32 * k,
            height: _rowH * k,
            child: ReorderableDragStartListener(
              index: i,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          // servis adı + durum noktası (dokununca satırı aç/kapat)
          Positioned(
            left: 82 * k,
            top: 0,
            width: 185 * k,
            height: _rowH * k,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => e.enabled = !e.enabled);
                _scheduleSave();
              },
              child: Opacity(
                opacity: e.enabled ? 1.0 : 0.4,
                child: Row(
                  children: [
                    SizedBox(width: 8 * k),
                    Container(
                      width: 10 * k,
                      height: 10 * k,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: e.enabled
                            ? _statusColor(st) == Colors.white
                                ? AppColors.textGray
                                : _statusColor(st)
                            : AppColors.textGray,
                      ),
                    ),
                    SizedBox(width: 6 * k),
                    Expanded(
                      child: Text(
                        p.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: fs),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // model seçimi
          Positioned(
            left: 285 * k,
            top: 0,
            width: 132 * k,
            height: _rowH * k,
            child: Opacity(
              opacity: e.enabled ? 1.0 : 0.4,
              child: PopupMenuButton<String>(
                color: AppColors.panelBg,
                tooltip: 'Model seç',
                onSelected: (v) {
                  setState(() => e.model = v);
                  _scheduleSave();
                },
                itemBuilder: (ctx) => models
                    .map((m) => PopupMenuItem<String>(
                          value: m,
                          child: Text(m,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ))
                    .toList(),
                child: SizedBox.expand(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 6 * k, right: 22 * k),
                    child: Text(
                      e.model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: fs * 0.9),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // rol (sıraya göre otomatik)
          Positioned(
            left: 540 * k,
            top: 0,
            width: 90 * k,
            height: _rowH * k,
            child: Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 6 * k),
              child: Text(
                i == 0 ? 'Varsayılan' : 'Yedek $i',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: i == 0 ? AppColors.greenNeon : AppColors.cyanNeon,
                  fontSize: fs * 0.9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Test düğmesi
          Positioned(
            left: 667 * k,
            top: 0,
            width: 85 * k,
            height: _rowH * k,
            child: Stack(
              children: [
                Positioned.fill(child: _hit(() => _testProvider(p.id))),
                if (_testing.contains(p.id))
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: const Color(0xCC071426),
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.cyanNeon),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Sil
          Positioned(
            left: 762 * k,
            top: 0,
            width: 34 * k,
            height: _rowH * k,
            child: _hit(() {
              setState(() => _chain.removeAt(i));
              _scheduleSave();
            }),
          ),
        ],
      ),
    );
  }

  Widget _layers(double k) {
    Widget at(double l, double t, double w, double h, Widget child) {
      return Positioned(
          left: l * k, top: t * k, width: w * k, height: h * k, child: child);
    }

    final fs = math.max(10.0, 15 * k);
    final perms = [
      ['Depolama Erişimi (Storage Access)', 'true'],
      ['Ağ Erişimi (Network Access)', 'true'],
      ['Sesli Komut / Mikrofon İzni', _micOk ? 'true' : 'false'],
      ['Bildirimler (Notifications)', _notifOk ? 'true' : 'false'],
    ];

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            AppAssets.settingsBg,
            fit: BoxFit.fill,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.darkBg,
              alignment: Alignment.center,
              child: const Text('Arka plan görseli bulunamadı',
                  style: TextStyle(color: AppColors.redNeon)),
            ),
          ),
        ),

        // ---------------- GitHub ----------------
        at(165, 195, 300, 38,
            _plainField(controller: _userCtrl, hint: 'Kullanıcı adı', fs: fs)),
        at(
            530,
            195,
            270,
            38,
            _plainField(
                controller: _tokenCtrl,
                hint: 'Token',
                fs: fs,
                obscure: !_showToken)),
        at(803, 195, 40, 38,
            _hit(() => setState(() => _showToken = !_showToken))),
        at(
            915,
            195,
            245,
            38,
            _plainField(
                controller: _repoCtrl, hint: 'Depo-adı/main', fs: fs)),
        at(1208, 183, 217, 55, _hit(_saveAndVerifyGithub)),

        // ---------------- API zinciri ----------------
        at(
          105,
          354,
          700,
          _rowH * StorageService.maxChain,
          ReorderableListView.builder(
            primary: false,
            buildDefaultDragHandles: false,
            physics: const NeverScrollableScrollPhysics(),
            itemExtent: _rowH * k,
            itemCount: _chain.length,
            onReorder: _onReorder,
            proxyDecorator: (child, index, animation) =>
                Material(color: Colors.transparent, child: child),
            itemBuilder: (context, i) => _chainRow(i, k),
          ),
        ),
        at(100, 720, 268, 42, _hit(_addModelDialog)),
        at(445, 720, 158, 42, _hit(_resetChain)),
        at(618, 720, 184, 42, _hit(_testAll)),

        // ---------------- API anahtarları ----------------
        for (var i = 0; i < Providers.all.length; i++) ...[
          at(
            928,
            334 + _keyStep * i - 15,
            140,
            30,
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _testProvider(Providers.all[i].id),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  Providers.all[i].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _statusColor(
                        _status[Providers.all[i].id] ?? KeyStatus.none),
                    fontSize: fs * 0.9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          at(
            1078,
            334 + _keyStep * i - 15,
            267,
            30,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * k),
              child: _plainField(
                controller: _keyCtrls[Providers.all[i].id]!,
                hint: 'API anahtarı',
                fs: fs * 0.9,
                obscure: !(_showKey[Providers.all[i].id] ?? false),
                onChanged: (v) {
                  final id = Providers.all[i].id;
                  _keys[id] = v;
                  setState(() => _status[id] =
                      v.trim().isEmpty ? KeyStatus.none : KeyStatus.untested);
                  _scheduleSave();
                },
              ),
            ),
          ),
          at(
            1352,
            334 + _keyStep * i - 15,
            40,
            30,
            _hit(() {
              final id = Providers.all[i].id;
              setState(() => _showKey[id] = !(_showKey[id] ?? false));
            }),
          ),
          at(1400, 334 + _keyStep * i - 15, 35, 30,
              _hit(() => _clearKey(Providers.all[i].id))),
        ],
        at(862, 720, 213, 42, _hit(_addKeyDialog)),
        at(1215, 720, 222, 42, _hit(_clearAllKeys)),

        // ---------------- Failover ----------------
        at(
          550,
          873,
          172,
          39,
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() => _failover = !_failover);
              _scheduleSave();
            },
            child: Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 18 * k),
              child: Text(
                _failover ? 'AÇIK' : 'KAPALI',
                style: TextStyle(
                  color: _failover ? AppColors.greenNeon : AppColors.redNeon,
                  fontSize: math.max(11.0, 19 * k),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // ---------------- İzinler ----------------
        for (var j = 0; j < perms.length; j++) ...[
          at(
            866,
            836 + 27.0 * j - 12,
            482,
            24,
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: j == 2 ? _askMic : (j == 3 ? _askNotif : null),
              child: Row(
                children: [
                  SizedBox(width: 6 * k),
                  Expanded(
                    child: Text(
                      perms[j][0],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: fs * 0.85),
                    ),
                  ),
                  SizedBox(
                    width: 99 * k,
                    child: Text(
                      perms[j][1] == 'true' ? 'Aktif' : 'İzin Ver',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        color: perms[j][1] == 'true'
                            ? AppColors.greenNeon
                            : AppColors.yellowNeon,
                        fontSize: fs * 0.85,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 136 * k),
                ],
              ),
            ),
          ),
        ],

        // ---------------- Alt düğmeler ----------------
        at(160, 950, 125, 50, _hit(() => Navigator.of(context).pop())),
        at(305, 950, 222, 50, _hit(() => _perm.openSettings())),
        at(547, 950, 220, 50, _hit(_backup)),
        at(797, 962, 276, 45, _hit(_restore)),
        at(1140, 8, 135, 100, _hit(() => Navigator.of(context).pop())),

        // ---------------- Mesaj satırı ----------------
        if (_msg.isNotEmpty)
          at(
            1090,
            952,
            420,
            54,
            IgnorePointer(
              child: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 10 * k),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _msg,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _msgColor,
                    fontSize: math.max(9.0, 13 * k),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.cyanNeon))
          : LayoutBuilder(builder: (context, c) {
              final w = math.min(c.maxWidth, c.maxHeight * 1.5);
              final k = w / 1536;
              _k = k;
              final h = 1024 * k;
              final inset = MediaQuery.of(context).viewInsets.bottom;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: c.maxHeight, minWidth: c.maxWidth),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: inset),
                    child: Center(
                      child: SizedBox(width: w, height: h, child: _layers(k)),
                    ),
                  ),
                ),
              );
            }),
    );
  }
}
