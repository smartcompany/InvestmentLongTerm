import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/investment_insight.dart';
import '../models/market_briefing.dart';

enum AiHistoryKind { insight, briefing }

class AiHistoryItem {
  final String id;
  final AiHistoryKind kind;
  final DateTime createdAt;
  final String title;
  final String preview;
  final Map<String, dynamic> payload;

  const AiHistoryItem({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.title,
    required this.preview,
    required this.payload,
  });

  InvestmentInsight? asInsight() {
    if (kind != AiHistoryKind.insight) return null;
    return InvestmentInsight.fromJson(payload);
  }

  MarketBriefing? asBriefing() {
    if (kind != AiHistoryKind.briefing) return null;
    return MarketBriefing.fromJson(payload);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'createdAt': createdAt.toIso8601String(),
        'title': title,
        'preview': preview,
        'payload': payload,
      };

  factory AiHistoryItem.fromJson(Map<String, dynamic> json) {
    return AiHistoryItem(
      id: json['id'] as String? ?? '',
      kind: (json['kind'] as String?) == 'briefing'
          ? AiHistoryKind.briefing
          : AiHistoryKind.insight,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      title: json['title'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
    );
  }
}

class AiHistoryService {
  AiHistoryService._();
  static final AiHistoryService shared = AiHistoryService._();

  static const _prefsKey = 'ai_result_history_v1';
  static const _maxItems = 40;

  Future<List<AiHistoryItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => AiHistoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveInsight(InvestmentInsight insight) async {
    final preview = insight.summary.trim();
    await _add(
      AiHistoryItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        kind: AiHistoryKind.insight,
        createdAt: DateTime.now(),
        title: preview.isEmpty ? 'AI Portfolio' : preview,
        preview: preview,
        payload: insight.toJson(),
      ),
    );
  }

  Future<void> saveBriefing(MarketBriefing briefing) async {
    final preview = briefing.todayHeadline.trim().isNotEmpty
        ? briefing.todayHeadline.trim()
        : briefing.marketSummary.trim();
    await _add(
      AiHistoryItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        kind: AiHistoryKind.briefing,
        createdAt: DateTime.now(),
        title: preview.isEmpty ? 'AI Trend' : preview,
        preview: preview,
        payload: briefing.toJson(),
      ),
    );
  }

  Future<void> _add(AiHistoryItem item) async {
    final items = await load();
    items.insert(0, item);
    if (items.length > _maxItems) {
      items.removeRange(_maxItems, items.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> deleteItem(String id) async {
    final items = await load();
    items.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
