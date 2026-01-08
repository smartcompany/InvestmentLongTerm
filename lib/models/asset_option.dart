import 'dart:ui' as ui;

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

  /// 로케일별 자산 이름을 반환합니다. localeCode가 제공되지 않으면 시스템 로케일을 사용합니다.
  String displayName([String? localeCode]) {
    // localeCode가 제공되지 않으면 시스템 로케일 사용
    final systemLocaleCode =
        localeCode ?? ui.PlatformDispatcher.instance.locale.languageCode;
    return names[systemLocaleCode] ??
        names[_normalizeLocale(systemLocaleCode)] ??
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
