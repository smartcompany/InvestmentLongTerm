class InvestmentInsight {
  final String summary;
  final String outlook;
  final List<String> suggestions;
  final List<String> risks;
  final String disclaimer;

  const InvestmentInsight({
    required this.summary,
    required this.outlook,
    required this.suggestions,
    required this.risks,
    required this.disclaimer,
  });

  factory InvestmentInsight.fromJson(Map<String, dynamic> json) {
    return InvestmentInsight(
      summary: json['summary'] as String? ?? '',
      outlook: json['outlook'] as String? ?? '',
      suggestions: (json['suggestions'] as List? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      risks: (json['risks'] as List? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}
