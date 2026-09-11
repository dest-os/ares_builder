import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/github_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AresBuilderApp());
}

class AresBuilderApp extends StatelessWidget {
  const AresBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ares Builder',
      theme: ThemeData.dark(),
      home: const SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ownerController = TextEditingController();
  final _tokenController = TextEditingController();
  final _repoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ownerController.text = prefs.getString('github_owner') ?? '';
      _tokenController.text = prefs.getString('github_token') ?? '';
      _repoController.text = prefs.getString('github_repo') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('github_owner', _ownerController.text.trim());
    await prefs.setString('github_token', _tokenController.text.trim());
    await prefs.setString('github_repo', _repoController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ayarlar başarıyla kaydedildi!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ares Builder - GitHub Ayarları'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ares_bg.png'),
            fit: BoxFit.cover,
            opacity: 0.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _ownerController,
                decoration: const InputDecoration(
                  labelText: 'GitHub Kullanıcı Adı (Owner)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _repoController,
                decoration: const InputDecoration(
                  labelText: 'Depo Adı (Repo - örn: ares_builder)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tokenController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'GitHub Token',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('AYARLARI KAYDET'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
