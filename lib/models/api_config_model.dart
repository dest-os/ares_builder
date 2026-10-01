import 'package:flutter/material.dart';

/// Desteklenen yapay zeka servisleri.
class ProviderInfo {
  final String id;
  final String name;
  final String letter;
  final Color color;
  final String kind; // openai | gemini | anthropic | openrouter | cohere
  final String baseUrl;
  final List<String> models;

  const ProviderInfo({
    required this.id,
    required this.name,
    required this.letter,
    required this.color,
    required this.kind,
    required this.baseUrl,
    required this.models,
  });
}

class Providers {
  static const List<ProviderInfo> all = [
    ProviderInfo(
      id: 'gemini',
      name: 'Google Gemini',
      letter: 'G',
      color: Color(0xFF4285F4),
      kind: 'gemini',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      models: ['gemini-2.5-flash', 'gemini-2.5-pro'],
    ),
    ProviderInfo(
      id: 'groq',
      name: 'Groq',
      letter: 'Gq',
      color: Color(0xFFF55036),
      kind: 'openai',
      baseUrl: 'https://api.groq.com/openai/v1',
      models: ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant'],
    ),
    ProviderInfo(
      id: 'openrouter',
      name: 'OpenRouter',
      letter: 'OR',
      color: Color(0xFF6467F2),
      kind: 'openrouter',
      baseUrl: 'https://openrouter.ai/api/v1',
      models: ['openrouter/auto'],
    ),
    ProviderInfo(
      id: 'openai',
      name: 'OpenAI',
      letter: 'AI',
      color: Color(0xFF10A37F),
      kind: 'openai',
      baseUrl: 'https://api.openai.com/v1',
      models: ['gpt-4o-mini', 'gpt-4.1'],
    ),
    ProviderInfo(
      id: 'anthropic',
      name: 'Anthropic Claude',
      letter: 'A',
      color: Color(0xFFD97757),
      kind: 'anthropic',
      baseUrl: 'https://api.anthropic.com/v1',
      models: ['claude-sonnet-5-5', 'claude-haiku-4-5-20251001'],
    ),
    ProviderInfo(
      id: 'mistral',
      name: 'Mistral AI',
      letter: 'M',
      color: Color(0xFFFF7000),
      kind: 'openai',
      baseUrl: 'https://api.mistral.ai/v1',
      models: ['mistral-large-latest', 'mistral-small-latest'],
    ),
    ProviderInfo(
      id: 'cohere',
      name: 'Cohere',
      letter: 'C',
      color: Color(0xFF7CCFA9),
      kind: 'cohere',
      baseUrl: 'https://api.cohere.com/v1',
      models: ['command-r-plus', 'command-r'],
    ),
    ProviderInfo(
      id: 'deepseek',
      name: 'DeepSeek',
      letter: 'DS',
      color: Color(0xFF4D6BFE),
      kind: 'openai',
      baseUrl: 'https://api.deepseek.com',
      models: ['deepseek-chat', 'deepseek-reasoner'],
    ),
    ProviderInfo(
      id: 'xai',
      name: 'xAI (Grok)',
      letter: 'X',
      color: Color(0xFFB0B8C4),
      kind: 'openai',
      baseUrl: 'https://api.x.ai/v1',
      models: ['grok-4', 'grok-3-mini'],
    ),
    ProviderInfo(
      id: 'meta',
      name: 'Meta Llama',
      letter: 'ML',
      color: Color(0xFF0081FB),
      kind: 'openai',
      baseUrl: 'https://api.llama.com/compat/v1',
      models: ['Llama-4-Maverick-17B-128E-Instruct-FP8'],
    ),
  ];

  static ProviderInfo byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return all.first;
  }
}

/// Öncelik zincirindeki bir satır (servis + model).
class ChainEntry {
  static int _counter = 0;

  final String uid;
  final String providerId;
  String model;
  bool enabled;

  ChainEntry({
    required this.providerId,
    required this.model,
    this.enabled = true,
  }) : uid = '${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'model': model,
        'enabled': enabled,
      };

  factory ChainEntry.fromJson(Map<String, dynamic> json) {
    final pid = (json['providerId'] ?? '').toString();
    final p = Providers.byId(pid);
    final m = (json['model'] ?? '').toString();
    return ChainEntry(
      providerId: p.id,
      model: m.isEmpty ? p.models.first : m,
      enabled: json['enabled'] != false,
    );
  }
}

enum KeyStatus { none, untested, ok, invalid, limited, error }
