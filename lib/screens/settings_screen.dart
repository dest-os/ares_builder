import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _tokenController = TextEditingController();
  final _geminiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ownerController.text = prefs.getString('github_owner') ?? '';
      _repoController.text = prefs.getString('github_repo') ?? '';
      _tokenController.text = prefs.getString('github_token') ?? '';
      _geminiController.text = prefs.getString('gemini_key') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('github_owner', _ownerController.text.trim());
    await prefs.setString('github_repo', _repoController.text.trim());
    await prefs.setString('github_token', _tokenController.text.trim());
    await prefs.setString('gemini_key', _geminiController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayarlar kaydedildi!'),
          backgroundColor: Color(0xFF00E5FF),
        ),
      );
    }
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            filled: true,
            fillColor: const Color(0xFF071728),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020B14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ayarlar & API Anahtarları',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildInputField(
              label: 'GitHub Kullanıcı Adı (Owner)',
              hint: 'Örn: ibrahim-halil',
              controller: _ownerController,
            ),
            _buildInputField(
              label: 'Depo Adı (Repo)',
              hint: 'Örn: ares_launcher',
              controller: _repoController,
            ),
            _buildInputField(
              label: 'GitHub Personal Access Token (PAT)',
              hint: 'ghp_xxxxxxxxxxxx',
              controller: _tokenController,
              isPassword: true,
            ),
            _buildInputField(
              label: 'Gemini API Key',
              hint: 'AIzaSyxxxxxxxxxxxx',
              controller: _geminiController,
              isPassword: true,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Kaydet',
                  style: TextStyle(
                    color: Color(0xFF020B14),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
