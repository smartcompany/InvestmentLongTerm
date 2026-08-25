import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import 'asset_icon.dart';

/// Yahoo 검색으로 카탈로그 밖 종목을 고릅니다.
/// 선택 시 `{id, name, symbol, type}` 맵을 반환합니다.
Future<Map<String, String>?> showAssetSearchSheet(
  BuildContext context, {
  required String assetType,
  required AppLocalizations l10n,
}) {
  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AssetSearchSheet(assetType: assetType, l10n: l10n),
  );
}

class AssetSearchSheet extends StatefulWidget {
  final String assetType;
  final AppLocalizations l10n;

  const AssetSearchSheet({
    super.key,
    required this.assetType,
    required this.l10n,
  });

  @override
  State<AssetSearchSheet> createState() => _AssetSearchSheetState();
}

class _AssetSearchSheetState extends State<AssetSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final results = await ApiService.searchAssets(
        query,
        type: widget.assetType,
        lang: lang,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _error = null;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _error = widget.l10n.searchAssetFailed;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.searchAssetTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: l10n.searchAssetHint,
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              l10n.searchingAssets,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_controller.text.trim().isEmpty) {
      return Center(
        child: Text(
          l10n.searchAssetHint,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          l10n.noSearchResults,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _results[index];
        final id = item['id'] as String? ?? '';
        final name = item['name'] as String? ?? '';
        final symbol = item['symbol'] as String? ?? '';
        final type = item['type'] as String? ?? widget.assetType;
        final exchange = item['exchange'] as String?;

        return Material(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.pop(context, {
                'id': id,
                'name': name,
                'symbol': symbol,
                'type': type,
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  AssetIcon(assetId: id, type: type, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          exchange != null && exchange.isNotEmpty
                              ? '$symbol · $exchange'
                              : symbol,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
