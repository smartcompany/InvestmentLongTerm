import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// Asset icons that do not rely on color emoji.
///
/// Color emoji render as `[?]` on some iOS 26.x simulators (Apple CoreText bug).
/// Material Icons + letter avatars work everywhere.
class AssetIcon extends StatelessWidget {
  final String assetId;
  final String? type;
  final double size;
  final Color? color;

  const AssetIcon({
    super.key,
    required this.assetId,
    this.type,
    this.size = 24,
    this.color,
  });

  static ({IconData icon, Color color}) styleFor(
    String assetId, {
    String? type,
  }) {
    final id = assetId.toLowerCase();
    switch (id) {
      case 'bitcoin':
        return (icon: Icons.currency_bitcoin, color: const Color(0xFFF7931A));
      case 'ethereum':
        return (icon: Icons.diamond_outlined, color: const Color(0xFF627EEA));
      case 'ripple':
        return (icon: Icons.water_drop_outlined, color: const Color(0xFF23292F));
      case 'binance':
        return (icon: Icons.toll_outlined, color: const Color(0xFFF3BA2F));
      case 'cardano':
        return (icon: Icons.hexagon_outlined, color: const Color(0xFF0033AD));
      case 'solana':
        return (icon: Icons.blur_on, color: const Color(0xFF9945FF));
      case 'tesla':
        return (icon: Icons.bolt, color: const Color(0xFFE82127));
      case 'google':
        return (icon: Icons.search, color: const Color(0xFF4285F4));
      case 'apple':
        return (icon: Icons.phone_iphone, color: const Color(0xFF555555));
      case 'microsoft':
        return (icon: Icons.window, color: const Color(0xFF00A4EF));
      case 'amazon':
        return (icon: Icons.local_shipping_outlined, color: const Color(0xFFFF9900));
      case 'nvidia':
        return (icon: Icons.memory, color: const Color(0xFF76B900));
      case 'meta':
        return (icon: Icons.groups_outlined, color: const Color(0xFF0668E1));
      case 'cash':
        return (icon: Icons.payments_outlined, color: const Color(0xFF2E7D32));
      case 'gold':
        return (icon: Icons.workspace_premium, color: const Color(0xFFD4AF37));
      case 'silver':
        return (icon: Icons.circle_outlined, color: const Color(0xFF9E9E9E));
      case 'crude_oil':
      case 'brent_oil':
        return (icon: Icons.oil_barrel, color: const Color(0xFF5D4037));
      case 'copper':
        return (icon: Icons.hardware, color: const Color(0xFFB87333));
      case 'natural_gas':
        return (icon: Icons.local_fire_department_outlined, color: const Color(0xFF0288D1));
      case 'wheat':
        return (icon: Icons.grass, color: const Color(0xFFC9A227));
      case 'corn':
        return (icon: Icons.eco_outlined, color: const Color(0xFFFBC02D));
      case 'samsung':
        return (icon: Icons.smartphone, color: const Color(0xFF1428A0));
      case 'sk_hynix':
        return (icon: Icons.sd_card_outlined, color: const Color(0xFFEF5350));
      case 'hyundai':
        return (icon: Icons.directions_car_outlined, color: const Color(0xFF002C5F));
      case 'naver':
        return (icon: Icons.travel_explore, color: const Color(0xFF03C75A));
      case 'kakao':
        return (icon: Icons.chat_bubble_outline, color: const Color(0xFF3C1E1E));
      case 'lg_energy':
        return (icon: Icons.battery_charging_full, color: const Color(0xFFA50034));
      case 'celltrion':
        return (icon: Icons.biotech_outlined, color: const Color(0xFF00897B));
      case 'posco':
        return (icon: Icons.factory_outlined, color: const Color(0xFF1565C0));
      case 'kb_financial':
        return (icon: Icons.account_balance, color: const Color(0xFFFFCC00));
      case 'korean_real_estate':
      case 'korean_seoul_real_estate':
        return (icon: Icons.apartment, color: const Color(0xFF5C6BC0));
      case 'retire_total':
        return (icon: Icons.account_balance_wallet_outlined, color: const Color(0xFF5B8FF7));
      case 'retire_withdraw':
        return (icon: Icons.payments_outlined, color: const Color(0xFFFB923C));
      default:
        return (
          icon: _fallbackIconForType(type),
          color: AppColors.primary,
        );
    }
  }

  static IconData _fallbackIconForType(String? type) {
    switch (type) {
      case 'crypto':
        return Icons.currency_exchange;
      case 'stock':
      case 'korean_stock':
        return Icons.show_chart;
      case 'commodity':
        return Icons.inventory_2_outlined;
      case 'real_estate':
        return Icons.home_work_outlined;
      case 'cash':
        return Icons.payments_outlined;
      default:
        return Icons.trending_up;
    }
  }

  /// Letter used when painting on canvas (e.g. race chart) without emoji.
  static String letterFor(String assetId) {
    final id = assetId.toLowerCase();
    const letters = {
      'bitcoin': 'B',
      'ethereum': 'E',
      'ripple': 'X',
      'binance': 'B',
      'cardano': 'A',
      'solana': 'S',
      'tesla': 'T',
      'google': 'G',
      'apple': 'A',
      'microsoft': 'M',
      'amazon': 'Z',
      'nvidia': 'N',
      'meta': 'f',
      'cash': 'C',
      'gold': 'Au',
      'silver': 'Ag',
      'crude_oil': 'Oil',
      'brent_oil': 'Oil',
      'copper': 'Cu',
      'natural_gas': 'Gas',
      'wheat': 'W',
      'corn': 'C',
      'samsung': 'S',
      'sk_hynix': 'H',
      'hyundai': 'H',
      'naver': 'N',
      'kakao': 'K',
      'lg_energy': 'LG',
      'celltrion': 'C',
      'posco': 'P',
      'kb_financial': 'KB',
      'korean_real_estate': 'RE',
      'korean_seoul_real_estate': 'SE',
      'retire_total': 'A',
      'retire_withdraw': 'W',
    };
    return letters[id] ??
        (id.isNotEmpty ? id[0].toUpperCase() : '?');
  }

  @override
  Widget build(BuildContext context) {
    final style = styleFor(assetId, type: type);
    return Icon(
      style.icon,
      size: size,
      color: color ?? style.color,
    );
  }
}
