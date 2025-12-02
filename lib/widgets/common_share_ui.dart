import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
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
                  await _shareToKakao(
                    context,
                    shareText,
                    chartImageBytes: chartImageBytes,
                  );
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
                subtitle: chartImageBytes != null
                    ? '텍스트와 차트 이미지 함께 공유'
                    : l10n.basicShareDesc,
                onTap: () async {
                  if (chartImageBytes != null) {
                    await _shareWithImage(context, shareText, chartImageBytes);
                  } else {
                    await Share.share(shareText);
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

  /// 카카오톡 공유 (SDK 사용)
  static Future<void> _shareToKakao(
    BuildContext context,
    String shareText, {
    Uint8List? chartImageBytes,
  }) async {
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
      // 카카오톡 공유는 텍스트만 공유 (이미지는 기본 공유에서만 사용)
      // 카카오톡 SDK는 이미지 URL이 필요하므로 서버 업로드 없이는 이미지 공유 불가
      debugPrint('🔍 [카카오톡 공유] 텍스트만 공유 - TextTemplate 사용');

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

  /// 이미지와 함께 기본 공유
  static Future<void> _shareWithImage(
    BuildContext context,
    String shareText,
    Uint8List imageBytes,
  ) async {
    try {
      debugPrint('🔍 [기본 공유] 이미지 포함 공유 시작');
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/chart_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      // Write image bytes to file
      await file.writeAsBytes(imageBytes);
      debugPrint('✅ [기본 공유] 이미지 파일 생성: ${file.path}');

      // Share with image and text
      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: shareText,
        subject: 'Time Capital 계산 결과',
      );
      debugPrint('✅ [기본 공유] 공유 완료');

      // Clean up: delete temporary file after a delay
      Future.delayed(Duration(seconds: 5), () async {
        try {
          if (await file.exists()) {
            await file.delete();
            debugPrint('✅ [기본 공유] 임시 파일 삭제 완료');
          }
        } catch (e) {
          debugPrint('⚠️ [기본 공유] 파일 삭제 실패: $e');
        }
      });
    } catch (e) {
      debugPrint('❌ [기본 공유] 에러: $e');
      // Fallback to text-only share if image sharing fails
      await Share.share(shareText);
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
