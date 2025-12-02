import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
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
                  await _shareToKakao(context, shareText);
                  if (context.mounted) navigator.pop();
                },
              ),
              _ShareOptionTile(
                icon: Icons.copy_outlined,
                title: l10n.copyText,
                subtitle: l10n.copyToClipboard,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: shareText));
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.copiedToClipboard)),
                  );
                },
              ),
              _ShareOptionTile(
                icon: Icons.share_outlined,
                title: l10n.basicShare,
                subtitle: l10n.basicShareDesc,
                onTap: () async {
                  await Share.share(shareText);
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

  /// 카카오톡 공유 (SDK 사용)
  static Future<void> _shareToKakao(
    BuildContext context,
    String shareText,
  ) async {
    // context를 async gap 전에 미리 저장
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    debugPrint('🔍 [카카오톡 공유] SDK 방식 시작');

    // 카카오톡 설치 여부 확인
    if (await ShareClient.instance.isKakaoTalkSharingAvailable() == false) {
      debugPrint('❌ [카카오톡 공유] 카카오톡 미설치');
      messenger.showSnackBar(
        SnackBar(
          content: Text('카카오톡이 설치되어 있지 않습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // SDK 방식으로 카카오톡에 바로 공유 - TextTemplate 사용
      debugPrint('🔍 [카카오톡 공유] TextTemplate 생성 중...');

      final template = TextTemplate(
        text: shareText,
        link: Link(), // 빈 링크로 앱 이동 방지
      );

      debugPrint('🔍 [카카오톡 공유] shareDefault 호출 중...');
      final uri = await ShareClient.instance.shareDefault(template: template);
      debugPrint('🔍 [카카오톡 공유] shareDefault 완료, URI: $uri');

      if (await canLaunchUrl(uri)) {
        debugPrint('🔍 [카카오톡 공유] launchUrl 실행 중...');
        await launchUrl(uri);
        debugPrint('✅ [카카오톡 공유] 성공');
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.sharedToKakaoTalk),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [카카오톡 공유] 에러: $e');
      debugPrint('❌ [카카오톡 공유] 스택 트레이스: $stackTrace');

      messenger.showSnackBar(
        SnackBar(
          content: Text('카카오톡 공유 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
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
