import '../models/my_asset.dart';
import '../providers/app_state_provider.dart';
import '../providers/currency_provider.dart';
import 'currency_converter.dart';

/// 자산별 저장 통화·표시 금액 변환
class AssetCurrency {
  static String currencyForType(String? type) {
    if (type == 'korean_stock' || type == 'real_estate') {
      return '₩';
    }
    return '\$';
  }

  static String originalCurrency(
    String assetId,
    AppStateProvider appProvider, {
    String? assetType,
  }) {
    if (assetId == 'cash') {
      return CurrencyProvider.shared.getCurrencySymbol();
    }

    if (assetType != null && assetType.isNotEmpty) {
      return currencyForType(assetType);
    }

    try {
      final assetOption = appProvider.assets.firstWhere((a) => a.id == assetId);
      return currencyForType(assetOption.type);
    } catch (_) {}

    // 커스텀 id인데 타입 정보가 없으면 심볼 휴리스틱
    if (assetId.startsWith('custom_')) {
      final lower = assetId.toLowerCase();
      if (lower.contains('.ks') || lower.contains('.kq')) {
        return '₩';
      }
    }

    return '\$';
  }

  /// UI에 표시할 금액 (현재 가치 우선, 사용자 표시 통화로 변환)
  static Future<double> displayAmount(
    MyAsset asset,
    AppStateProvider appProvider,
  ) async {
    final target = CurrencyProvider.shared.getCurrencySymbol();

    if (asset.currentValue != null) {
      final from = originalCurrency(
        asset.assetId,
        appProvider,
        assetType: asset.assetType,
      );
      if (from == target) return asset.currentValue!;
      return CurrencyConverter.shared.convert(
        asset.currentValue!,
        from,
        target,
      );
    }

    return asset.initialAmount;
  }
}
