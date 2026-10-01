import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_config_model.dart';
import '../models/github_config_model.dart';

class StorageService {
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const int maxChain = 8;

  static const String _githubKey = 'github_config';
  static const String _keysKey = 'api_keys';
  static const String _chainKey = 'api_chain';
  static const String _failoverKey = 'failover_enabled';

  // ---------- GitHub ----------
  Future<void> saveGithubConfig(GithubConfig config) async {
    await _secure.write(key: _githubKey, value: jsonEncode(config.toJson()));
  }

  Future<GithubConfig?> getGithubConfig() async {
    try {
      final s = await _secure.read(key: _githubKey);
      if (s == null || s.isEmpty) return null;
      final data = jsonDecode(s);
      if (data is! Map) return null;
      return GithubConfig.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  // ---------- API anahtarları ----------
  Future<Map<String, String>> getApiKeys() async {
    try {
      final s = await _secure.read(key: _keysKey);
      if (s == null || s.isEmpty) return {};
      final data = jsonDecode(s);
      if (data is! Map) return {};
      final out = <String, String>{};
      data.forEach((k, v) {
        final value = v.toString();
        if (value.trim().isNotEmpty) out[k.toString()] = value;
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveApiKeys(Map<String, String> keys) async {
    final clean = <String, String>{};
    keys.forEach((k, v) {
      if (v.trim().isNotEmpty) clean[k] = v.trim();
    });
    await _secure.write(key: _keysKey, value: jsonEncode(clean));
  }

  // ---------- Öncelik zinciri ----------
  static List<ChainEntry> defaultChain() {
    return Providers.all
        .take(maxChain)
        .map((p) => ChainEntry(providerId: p.id, model: p.models.first))
        .toList();
  }

  Future<List<ChainEntry>> getChain() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_chainKey);
      if (s == null || s.isEmpty) return defaultChain();
      final data = jsonDecode(s);
      if (data is! List) return defaultChain();
      final list = <ChainEntry>[];
      for (final item in data) {
        if (item is Map) {
          list.add(ChainEntry.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return list.take(maxChain).toList();
    } catch (_) {
      return defaultChain();
    }
  }

  Future<void> saveChain(List<ChainEntry> chain) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _chainKey, jsonEncode(chain.map((e) => e.toJson()).toList()));
  }

  // ---------- Failover ----------
  Future<bool> getFailover() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_failoverKey) ?? true;
  }

  Future<void> saveFailover(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_failoverKey, value);
  }
}
