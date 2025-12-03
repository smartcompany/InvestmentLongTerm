import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_lib/share_lib.dart';
import '../l10n/app_localizations.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class CommonShareUI {
  static Widget buildShareSection({
    required BuildContext context,
    required String title,
    required String description,
    required String shareText,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navyMedium,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.ios_share, color: AppColors.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.resultCardTitle.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.homeSubDescription.copyWith(
              color: AppColors.slate300,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showShareOptionsDialog(
                context: context,
                shareText: shareText,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navyDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.share_outlined),
              label: Text(
                l10n.saveAndShare,
                style: AppTextStyles.buttonTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> showShareOptionsDialog({
    required BuildContext context,
    required String shareText,
    Uint8List? chartImageBytes,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.navyMedium,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.shareResults, style: AppTextStyles.buttonTextPrimary),
              const SizedBox(height: 20),
              _ShareOptionTile(
                icon: Icons.chat_bubble_outline,
                title: l10n.kakaoTalk,
                subtitle: l10n.shareWithKakaoTalk,
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  await ShareService.shareToKakao(
                    shareText,
                    onSuccess: () {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.sharedToKakaoTalk),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    onError: (error) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('카카오톡 공유 실패: $error'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    onKakaoNotInstalled: () {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('카카오톡이 설치되어 있지 않습니다'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  );

                  if (context.mounted) navigator.pop();
                },
              ),
              _ShareOptionTile(
                icon: Icons.copy_outlined,
                title: l10n.copyText,
                subtitle: l10n.copyToClipboard,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);

                  await ShareService.copyToClipboard(
                    shareText,
                    onSuccess: () {
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.copiedToClipboard)),
                      );
                    },
                  );

                  if (context.mounted) Navigator.pop(context);
                },
              ),
              _ShareOptionTile(
                icon: Icons.share_outlined,
                title: l10n.basicShare,
                subtitle: chartImageBytes != null
                    ? l10n.shareWithTextAndChart
                    : l10n.basicShareDesc,
                onTap: () async {
                  if (chartImageBytes != null) {
                    await ShareService.shareWithImage(
                      shareText,
                      chartImageBytes,
                      subject: 'Time Capital 계산 결과',
                    );
                  } else {
                    await ShareService.shareText(shareText);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close, style: AppTextStyles.chartLegend),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.gold),
        ),
        title: Text(
          title,
          style: AppTextStyles.resultCardTitle.copyWith(color: Colors.white),
        ),
        subtitle: Text(subtitle, style: AppTextStyles.chartLegend),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
      ),
    );
  }
}
