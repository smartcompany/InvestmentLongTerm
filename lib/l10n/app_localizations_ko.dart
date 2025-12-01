// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get selectAssetQuestion => '어떤 자산에 투자 하시겠습니까?';

  @override
  String get loadingAssetData => '자산 데이터 불러오는 중...';

  @override
  String get loadAssetError => '자산 정보 로드 실패';

  @override
  String get retry => '다시 시도';

  @override
  String investmentSettingsTitle(Object assetName) {
    return '$assetName 투자 설정';
  }

  @override
  String get investmentAmountLabel => '투자 금액';

  @override
  String get investmentTypeLabel => '투자 방식';

  @override
  String get singleInvestment => '단일 투자';

  @override
  String get recurringInvestment => '정기 투자';

  @override
  String get investmentDurationLabel => '투자 기간';

  @override
  String get viewResults => '결과 보기';

  @override
  String get enterInvestmentAmount => '투자 금액을 입력해주세요';

  @override
  String yearsAgo(Object count) {
    return '$count년 전';
  }

  @override
  String investmentSummary(Object amount, Object assetName, Object type) {
    return '$assetName에 $amount를 $type로 투자했다면?';
  }

  @override
  String singleInvestmentDate(Object date) {
    return '$date에 한번에 투자';
  }

  @override
  String recurringInvestmentDate(Object date, Object frequency) {
    return '$date부터 $frequency 투자';
  }

  @override
  String get monthly => '매월';

  @override
  String get weekly => '매주';

  @override
  String get fetchingPriceData => '실제 가격 데이터를 가져오는 중...';

  @override
  String get errorOccurred => '오류가 발생했습니다';

  @override
  String get goBack => '돌아가기';

  @override
  String get investmentResults => '투자 결과';

  @override
  String get bestReturn => '최고 수익';

  @override
  String get cagr => '연평균 수익률 (CAGR)';

  @override
  String get returnOnInvestment => '투자 대비 수익';

  @override
  String totalInvested(Object amount) {
    return '총 투자금 $amount';
  }

  @override
  String get compareInvestmentStrategies => '투자 방식 비교';

  @override
  String get assetGrowthTrend => '자산 성장 추이';

  @override
  String get insightMessage => '시간을 친구로 만든다면,\n시장은 당신의 편입니다.';

  @override
  String get share => '공유하기';

  @override
  String get recalculate => '다시 계산';

  @override
  String get shareResults => '결과 공유하기';

  @override
  String get copyText => '텍스트 복사';

  @override
  String get copyTextDesc => '텍스트로 결과 복사하기';

  @override
  String get copiedToClipboard => '복사되었습니다';

  @override
  String get close => '닫기';

  @override
  String shareTextTitle(Object assetName, Object yearsAgo) {
    return '만약 $yearsAgo년 전에 $assetName에 투자했다면 지금 얼마일까?';
  }

  @override
  String get shareTextFooter => 'InvestLongTerm 계산 결과';

  @override
  String homeQuestionPart1(Object yearsAgo) {
    return '만약 $yearsAgo년 전에';
  }

  @override
  String homeQuestionPart2(Object assetName) {
    return '$assetName을 샀다면\n지금 얼마일까?';
  }

  @override
  String get homeDescription => '시간을 믿는 투자, 그 결과를 직접 확인해보세요.';

  @override
  String get crypto => '암호화폐';

  @override
  String get stock => '미국 주식';

  @override
  String get failedToLoadAssetList => '자산 목록을 불러오지 못했습니다.';

  @override
  String get frequencySelectionHint => '둘 다 선택하면 단일 투자와 함께 그래프로 비교해볼 수 있어요.';

  @override
  String get investmentFrequencyLabel => '투자 주기 (중복 선택 가능)';

  @override
  String calculationError(Object error) {
    return '계산 실패: $error';
  }

  @override
  String investmentStartDate(Object yearsAgo) {
    return '투자 시작 시점: $yearsAgo년 전';
  }

  @override
  String get monthlyAndWeekly => '매월과 매주';

  @override
  String summarySingle(Object amount, Object assetName, Object yearsAgo) {
    return '$yearsAgo년 전부터 $assetName에 \$$amount를 한 번 투자했다면...';
  }

  @override
  String summaryRecurring(
    Object amount,
    Object assetName,
    Object freqLabel,
    Object yearsAgo,
  ) {
    return '$yearsAgo년 전부터 $assetName에 $freqLabel 각각 동일한 총 투자금 \$$amount을 투자하면 어떻게 될까요?';
  }

  @override
  String get saveAndShare => '저장 & 공유하기';

  @override
  String get basicShare => '기본 공유';

  @override
  String get basicShareDesc => '메신저, 메일 등으로 공유';

  @override
  String get copyToClipboard => '클립보드에 결과 복사';
}
