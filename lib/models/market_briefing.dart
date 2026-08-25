class HoldingCondition {
  final String assetId;
  final String name;
  /// hot | steady | choppy | cool | watch
  final String mood;
  final String label;
  final String note;

  const HoldingCondition({
    required this.assetId,
    required this.name,
    required this.mood,
    required this.label,
    required this.note,
  });

  factory HoldingCondition.fromJson(Map<String, dynamic> json) {
    final rawMood = (json['mood'] ?? json['condition'] ?? 'steady')
        .toString()
        .trim()
        .toLowerCase();
    return HoldingCondition(
      assetId: (json['assetId'] ?? json['asset_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      mood: _normalizeMood(rawMood),
      label: (json['label'] ?? '').toString(),
      note: (json['note'] ?? json['blurb'] ?? '').toString(),
    );
  }

  static String _normalizeMood(String raw) {
    const allowed = {'hot', 'steady', 'choppy', 'cool', 'watch'};
    if (allowed.contains(raw)) return raw;
    if (raw.contains('hot') || raw.contains('fire') || raw.contains('불')) {
      return 'hot';
    }
    if (raw.contains('chopp') || raw.contains('volat') || raw.contains('출렁')) {
      return 'choppy';
    }
    if (raw.contains('cool') || raw.contains('cold') || raw.contains('약세')) {
      return 'cool';
    }
    if (raw.contains('watch') || raw.contains('관망') || raw.contains('주의')) {
      return 'watch';
    }
    if (raw.contains('steady') || raw.contains('calm') || raw.contains('잔잔')) {
      return 'steady';
    }
    return 'watch';
  }

  Map<String, dynamic> toJson() => {
        'assetId': assetId,
        'name': name,
        'mood': mood,
        'label': label,
        'note': note,
      };
}

class MarketBriefing {
  final String todayHeadline;
  final String marketSummary;
  final List<HoldingCondition> assetConditions;
  final List<String> holdingsFocus;
  final String nearTermOutlook;
  final List<String> watchPoints;
  final String disclaimer;
  final String asOfDate;

  const MarketBriefing({
    required this.todayHeadline,
    required this.marketSummary,
    required this.assetConditions,
    required this.holdingsFocus,
    required this.nearTermOutlook,
    required this.watchPoints,
    required this.disclaimer,
    required this.asOfDate,
  });

  factory MarketBriefing.fromJson(Map<String, dynamic> json) {
    final conditionsRaw =
        (json['assetConditions'] as List?) ??
        (json['holdingConditions'] as List?) ??
        [];
    final assetConditions = <HoldingCondition>[];
    for (final item in conditionsRaw) {
      if (item is! Map) continue;
      final condition =
          HoldingCondition.fromJson(Map<String, dynamic>.from(item));
      if (condition.assetId.isEmpty && condition.name.isEmpty) continue;
      assetConditions.add(condition);
    }

    return MarketBriefing(
      todayHeadline: json['todayHeadline'] as String? ?? '',
      marketSummary: json['marketSummary'] as String? ?? '',
      assetConditions: assetConditions,
      holdingsFocus: (json['holdingsFocus'] as List? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      nearTermOutlook: json['nearTermOutlook'] as String? ?? '',
      watchPoints: (json['watchPoints'] as List? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      disclaimer: json['disclaimer'] as String? ?? '',
      asOfDate: json['asOfDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'todayHeadline': todayHeadline,
        'marketSummary': marketSummary,
        'assetConditions':
            assetConditions.map((c) => c.toJson()).toList(),
        'holdingsFocus': holdingsFocus,
        'nearTermOutlook': nearTermOutlook,
        'watchPoints': watchPoints,
        'disclaimer': disclaimer,
        'asOfDate': asOfDate,
      };
}
