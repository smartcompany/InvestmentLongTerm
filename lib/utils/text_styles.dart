import 'package:flutter/material.dart';
import 'colors.dart';

/// 앱 전체에서 사용되는 텍스트 스타일 상수 정의
/// 의미별로 분류하여 일관된 스타일 적용 및 유지보수 용이성 확보
class AppTextStyles {
  // --- 페이지 타이틀 관련 ---

  /// 앱바 타이틀 (예: 투자 결과, 투자 방식 비교)
  static const TextStyle appBarTitle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );

  /// 홈 화면 메인 질문 텍스트 (만약 5년 전에...)
  static const TextStyle homeMainQuestion = TextStyle(
    color: Colors.white,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  /// 홈 화면 서브 설명 (시간을 믿는 투자...)
  static const TextStyle homeSubDescription = TextStyle(
    color: AppColors.slate400,
    fontSize: 16,
    height: 1.5,
  );

  // --- 투자 설정 화면 관련 ---

  /// 설정 화면 자산 타이틀 (예: 비트코인 투자 설정)
  static const TextStyle settingsAssetTitle = TextStyle(
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  /// 설정 화면 섹션 라벨 (예: 투자 시작 시점, 투자 금액)
  static const TextStyle settingsSectionLabel = TextStyle(
    color: AppColors.slate300,
    fontSize: 16,
  );

  /// 설정 화면 금액 입력 필드 텍스트
  static const TextStyle settingsAmountInput = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  /// 설정 화면 금액 입력 prefix ($)
  static const TextStyle settingsAmountPrefix = TextStyle(
    color: AppColors.gold,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  // --- 결과 화면 카드 관련 ---

  /// 결과 카드 타이틀 (예: 단일 투자 현재 가치)
  static const TextStyle resultCardTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  /// 결과 카드 메인 금액 값 (큰 숫자)
  static const TextStyle resultCardValueBig = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
  );

  /// 결과 카드 수익률 (퍼센트)
  static const TextStyle resultCardYield = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 28, // 기본 크기, 상황에 따라 조정 가능
  );

  /// 결과 카드 수익 금액 (투자 대비 수익 +$123)
  static const TextStyle resultCardGain = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 20,
  );

  /// 결과 카드 하단 작은 스탯 라벨 (예: 연평균 수익률 (CAGR))
  static const TextStyle resultStatLabel = TextStyle(fontSize: 15);

  /// 결과 카드 하단 작은 스탯 값
  static const TextStyle resultStatValue = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  /// "최고 수익" 뱃지 텍스트
  static const TextStyle badgeText = TextStyle(
    color: AppColors.navyDark,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );

  // --- 차트 및 기타 ---

  /// 차트 섹션 타이틀 (자산 가치 추이, 월별 상세 내역)
  static const TextStyle chartSectionTitle = TextStyle(
    color: AppColors.slate300,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  /// 차트 범례 (Legend) 텍스트
  static const TextStyle chartLegend = TextStyle(
    color: AppColors.slate300,
    fontSize: 20,
  );

  /// 차트 툴팁 텍스트
  static const TextStyle chartTooltip = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );

  // --- 버튼 관련 ---

  /// 기본 버튼 텍스트 (ElevatedButton 등)
  static const TextStyle buttonTextPrimary = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  /// 자산 선택 버튼 텍스트 (홈 화면)
  static const TextStyle assetButtonText = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  /// 공유 버튼 라벨
  static const TextStyle shareButtonLabel = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // --- 공통/유틸리티 ---

  /// 인사이트 메시지 (시간을 친구로 만든다면...)
  static const TextStyle insightMessage = TextStyle(
    color: AppColors.gold,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.5,
  );
}
