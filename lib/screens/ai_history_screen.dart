import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/ai_history_service.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/ai_rich_text.dart';
import '../widgets/investment_insight_dialog.dart';
import '../widgets/market_briefing_dialog.dart';

class AiHistoryScreen extends StatefulWidget {
  const AiHistoryScreen({super.key});

  @override
  State<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends State<AiHistoryScreen> {
  late Future<List<AiHistoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = AiHistoryService.shared.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(l10n.aiHistoryTitle, style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: FutureBuilder<List<AiHistoryItem>>(
        future: _future,
        builder: (context, snapshot) {
          final items = snapshot.data;
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (items == null || items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.aiHistoryEmpty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final isBriefing = item.kind == AiHistoryKind.briefing;
              final date = DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt);
              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    if (isBriefing) {
                      final briefing = item.asBriefing();
                      if (briefing == null) return;
                      await showMarketBriefingDialog(
                        context,
                        briefing: briefing,
                      );
                    } else {
                      final insight = item.asInsight();
                      if (insight == null) return;
                      await showInvestmentInsightDialog(
                        context,
                        insight: insight,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isBriefing
                                ? Icons.newspaper_outlined
                                : Icons.auto_awesome,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBriefing
                                    ? l10n.marketBriefingButton
                                    : l10n.aiInsightButton,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // iOS 시뮬레이터에서 시스템 이모지가 □ 로 깨지므로 Twemoji 사용
                              AiRichText(
                                item.preview.isNotEmpty
                                    ? item.preview
                                    : item.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                                boldStyle: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                date,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: AppColors.textSecondary,
                            onPressed: () async {
                              final shouldDelete = await _confirmDelete(
                                context,
                                l10n,
                              );
                              if (shouldDelete != true) return;

                              await AiHistoryService.shared.deleteItem(item.id);
                              if (!mounted) return;
                              setState(() {
                                _future = AiHistoryService.shared.load();
                              });
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 28,
                          height: 36,
                          child: Center(
                            child: Icon(
                              Icons.chevron_right,
                              size: 22,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            l10n.delete,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            l10n.aiHistoryDeleteConfirm,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n.delete,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
