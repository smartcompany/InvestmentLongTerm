class AssetOption {
  final String id;
  final String type;
  final String symbol;
  final String icon;
  final Map<String, String> names;
  final int? defaultYearsAgo;

  AssetOption({
    required this.id,
    required this.type,
    required this.symbol,
    required this.icon,
    required this.names,
    this.defaultYearsAgo,
  });

  factory AssetOption.fromJson(Map<String, dynamic> json) {
    return AssetOption(
      id: json['id'] as String,
      type: json['type'] as String,
      symbol: json['symbol'] as String,
      icon: (json['icon'] as String?) ?? '📈',
      names: (json['names'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      ),
      defaultYearsAgo: json['defaultYearsAgo'] as int?,
    );
  }

  String displayName(String localeCode) {
    return names[localeCode] ??
        names[_normalizeLocale(localeCode)] ??
        names['en'] ??
        id;
  }

  String _normalizeLocale(String code) {
    if (code.contains('-')) {
      return code.split('-').first;
    }
    return code;
  }
}
