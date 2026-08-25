import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:share_lib/share_lib.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class CommonShareUI {
  static Rect _shareOriginFromContext(BuildContext context) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize && !box.size.isEmpty) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.7),
      width: 100,
      height: 100,
    );
  }

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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.ios_share, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.resultCardTitle.copyWith(
                    color: AppColors.textPrimary,
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
              color: AppColors.textSecondary,
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
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final shareOrigin = _shareOriginFromContext(context);
    final messenger = ScaffoldMessenger.of(context);

    // 선택한 액션을 시트 닫힌 뒤에 실행 (iOS에서 모달 위 공유 시트 미표시 방지)
    final action = await showModalBottomSheet<Future<void> Function()>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 1.5),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.shareResults,
                          style: AppTextStyles.appBarTitle,
                        ),
                        const SizedBox(height: 20),
                        _ShareOptionTile(
                          icon: Icons.chat_bubble_outline,
                          title: l10n.kakaoTalk,
                          subtitle: l10n.shareWithKakaoTalk,
                          onTap: () {
                            Navigator.of(sheetContext).pop(() async {
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
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                },
                                onKakaoNotInstalled: () {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('카카오톡이 설치되어 있지 않습니다'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                              );
                            });
                          },
                        ),
                        _ShareOptionTile(
                          icon: Icons.copy_outlined,
                          title: l10n.copyText,
                          subtitle: l10n.copyToClipboard,
                          onTap: () {
                            Navigator.of(sheetContext).pop(() async {
                              await ShareService.copyToClipboard(
                                shareText,
                                onSuccess: () {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.copiedToClipboard),
                                    ),
                                  );
                                },
                              );
                            });
                          },
                        ),
                        _ShareOptionTile(
                          icon: Icons.share_outlined,
                          title: l10n.basicShare,
                          subtitle: chartImageBytes != null
                              ? l10n.shareWithTextAndChart
                              : l10n.basicShareDesc,
                          onTap: () {
                            Navigator.of(sheetContext).pop(() async {
                              debugPrint(
                                '🔍 [기본 공유] 시트 닫힌 후 공유 시작 '
                                '(image=${chartImageBytes != null}, '
                                'origin=$shareOrigin, '
                                'textLen=${shareText.length})',
                              );
                              try {
                                if (chartImageBytes != null) {
                                  final ok = await ShareService.shareWithImage(
                                    shareText,
                                    chartImageBytes,
                                    subject: l10n.shareTextHeader,
                                    sharePositionOrigin: shareOrigin,
                                  );
                                  if (!ok) {
                                    throw Exception('shareWithImage returned false');
                                  }
                                } else {
                                  // share_plus 직접 호출 — iOS popover origin 필수
                                  await Share.share(
                                    shareText,
                                    subject: l10n.shareTextHeader,
                                    sharePositionOrigin: shareOrigin,
                                  );
                                }
                                debugPrint('✅ [기본 공유] 완료');
                              } catch (e, st) {
                                debugPrint('❌ [기본 공유] 실패: $e\n$st');
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('공유를 시작하지 못했습니다: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text(
                            l10n.close,
                            style: AppTextStyles.chartLegend,
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(sheetContext).padding.bottom,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (action != null) {
      // 모달 dismiss 애니메이션이 끝난 뒤 시스템 공유 시트 present
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await action();
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              title: Text(
                title,
                style: AppTextStyles.resultCardTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(subtitle, style: AppTextStyles.chartLegend),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
