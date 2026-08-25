class RetireHolding {
  final String assetId;
  final String? assetName;
  final String? assetType;
  final String? symbol;
  double quantity;
  double? currentPrice;
  bool isLoadingPrice;

  RetireHolding({
    required this.assetId,
    this.assetName,
    this.assetType,
    this.symbol,
    this.quantity = 1,
    this.currentPrice,
    this.isLoadingPrice = false,
  });

  double get valuation {
    final price = currentPrice;
    if (price == null || !price.isFinite || price <= 0) return 0;
    return quantity * price;
  }

  /// 가격 API 원본 통화 (한국 주식·부동산 = 원, 그 외 = 달러)
  String get sourceCurrency {
    if (assetType == 'korean_stock' || assetType == 'real_estate') {
      return '₩';
    }
    final lowerId = assetId.toLowerCase();
    final lowerSymbol = (symbol ?? '').toLowerCase();
    if (lowerSymbol.endsWith('.ks') ||
        lowerSymbol.endsWith('.kq') ||
        lowerId.contains('.ks') ||
        lowerId.contains('.kq')) {
      return '₩';
    }
    return '\$';
  }

  RetireHolding copyWith({
    String? assetId,
    String? assetName,
    String? assetType,
    String? symbol,
    double? quantity,
    double? currentPrice,
    bool? isLoadingPrice,
    bool clearPrice = false,
  }) {
    return RetireHolding(
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      assetType: assetType ?? this.assetType,
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      currentPrice: clearPrice ? null : (currentPrice ?? this.currentPrice),
      isLoadingPrice: isLoadingPrice ?? this.isLoadingPrice,
    );
  }
}
